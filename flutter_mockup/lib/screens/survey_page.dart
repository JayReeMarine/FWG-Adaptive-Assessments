import 'package:flutter/material.dart';
import '../repositories/question_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/rule_repository.dart';
import '../repositories/flag_repository.dart';
import '../models/ui_question.dart';
import '../models/branch_rule.dart';
import '../services/branching_engine.dart';
import '../services/scoring_service.dart';
import '../utils/constants.dart';
import '../config/comparison_scenario.dart';
import '../services/llm_service.dart';
import '../widgets/progress_bar.dart';
import '../widgets/question_card.dart';
import 'completion_page.dart';

class SurveyPage extends StatefulWidget {
  final SurveyType surveyType;
  final int periodMonth;
  final int periodYear;

  /// Research comparison mode.
  /// - [SurveyMode.baseline] (default): uses BranchingEngine + live DB rules.
  /// - [SurveyMode.enhanced]: replaces the Mental Health domain with the
  ///   hardcoded mock enhanced path from comparison_scenario.dart.
  final SurveyMode mode;

  const SurveyPage({
    super.key,
    required this.surveyType,
    required this.periodMonth,
    required this.periodYear,
    this.mode = SurveyMode.baseline,
  });

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  final _questionRepo = QuestionRepository();
  final _sessionRepo = SessionRepository();
  final _ruleRepo = RuleRepository();
  final _flagRepo = FlagRepository();

  int _currentIndex = 0;
  List<UiQuestion> _allQuestions = [];
  List<UiQuestion> _visibleQuestions = [];
  bool loading = true;
  String? error;

  int? _sessionId;
  late BranchingEngine _engine;

  // Track previous domain for transition detection
  String? _previousDomain;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final List<UiQuestion> questions;
      if (widget.surveyType == SurveyType.foundational) {
        // Exclude Women's Health for male users
        final all = await _questionRepo.fetchFoundational();
        questions = all
            .where((q) => q.domain?.toUpperCase() != 'WOMEN HEALTH')
            .toList();
      } else if (widget.mode == SurveyMode.enhanced) {
        // Enhanced monthly: Mental Health only, LLM-generated questions.
        // Falls back to hardcoded mock if API unavailable.
        final allMonthly = await _questionRepo.fetchMonthly();
        final baselineMhQuestions = allMonthly
            .where((q) => q.domain?.toUpperCase() == 'MENTAL HEALTH')
            .toList();
        final enhancedMH = await LlmService.generateEnhancedMentalHealthQuestions(
          alexSeed,
          baselineMhQuestions,
        );
        questions = enhancedMH; // MH only — Step 3
      } else {
        // Baseline monthly: Mental Health only — Step 3
        final allMonthly = await _questionRepo.fetchMonthly();
        questions = allMonthly
            .where((q) => q.domain?.toUpperCase() == 'MENTAL HEALTH')
            .toList();
      }
      // ignore: avoid_print
      print('[SurveyPage] loaded ${questions.length} ${widget.surveyType.name} questions');

      List<BranchRule> rules;
      try {
        rules = await _ruleRepo.fetchAll();
        // ignore: avoid_print
        print('[SurveyPage] loaded ${rules.length} rules');
      } catch (e) {
        // ignore: avoid_print
        print('[SurveyPage] rules unavailable: $e');
        rules = [];
      }

      _engine = BranchingEngine(rules: rules);

      final sessionId = await _sessionRepo.createSession(
        periodMonth: widget.periodMonth,
        periodYear: widget.periodYear,
      );
      // ignore: avoid_print
      print('[SurveyPage] session id=$sessionId');

      setState(() {
        _allQuestions = questions;
        _visibleQuestions = _engine.getVisibleQuestions(questions);
        _sessionId = sessionId;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  void _recalculateVisible() {
    final oldVisible = _visibleQuestions;
    final newVisible = _engine.getVisibleQuestions(_allQuestions);

    UiQuestion? currentQ;
    if (_currentIndex < oldVisible.length) {
      currentQ = oldVisible[_currentIndex];
    }

    setState(() {
      _visibleQuestions = newVisible;
      if (currentQ != null) {
        final newIndex = newVisible.indexWhere(
            (q) => q.questionId == currentQ!.questionId);
        if (newIndex >= 0) _currentIndex = newIndex;
      }
      if (_currentIndex >= _visibleQuestions.length) {
        _currentIndex = _visibleQuestions.length - 1;
      }
      if (_currentIndex < 0) _currentIndex = 0;
    });
  }

  double get progress =>
      _visibleQuestions.isEmpty
          ? 0.0
          : (_currentIndex + 1) / _visibleQuestions.length;

  void toggleOption(int index) {
    setState(() {
      final q = _visibleQuestions[_currentIndex];
      switch (q.answerKind) {
        case 'SCALE':
          q.selected.clear();
          q.selected.add(index);
          break;
        case 'MULTI':
          if (q.selected.contains(index)) {
            q.selected.remove(index);
          } else {
            q.selected.add(index);
          }
          break;
        default:
          q.selected.add(index);
      }
    });
    _recalculateVisible();
  }

  Future<void> _saveCurrentResponse() async {
    if (_sessionId == null) return;
    if (_currentIndex >= _visibleQuestions.length) return;

    final q = _visibleQuestions[_currentIndex];
    if (!q.isAnswered) return;

    final score = ScoringService.questionScore(q);

    try {
      switch (q.answerKind) {
        case 'NUMERIC':
          await _sessionRepo.saveResponse(
            sessionId: _sessionId!,
            questionId: q.questionId,
            valueNumber: q.numericAnswer,
            score: score,
          );
          break;
        case 'SCALE':
          await _sessionRepo.saveResponse(
            sessionId: _sessionId!,
            questionId: q.questionId,
            valueScale: q.selected.first,
            score: score,
          );
          break;
        case 'MULTI':
          await _sessionRepo.saveResponse(
            sessionId: _sessionId!,
            questionId: q.questionId,
            raw: {'selected': q.selected.toList()},
            score: score,
          );
          break;
      }
      // ignore: avoid_print
      print('[SurveyPage] saved q=${q.questionId} score=$score');
    } catch (e) {
      // ignore: avoid_print
      print('[SurveyPage] save failed: $e');
    }
  }

  void next() async {
    await _saveCurrentResponse();

    if (_currentIndex < _visibleQuestions.length - 1) {
      final currentDomain = _visibleQuestions[_currentIndex].domain;
      setState(() {
        _previousDomain = currentDomain;
        _currentIndex++;
      });
    } else {
      List<DomainScore> domainScores = [];

      if (_sessionId != null) {
        try {
          domainScores =
              ScoringService.calculateDomainScores(_visibleQuestions);
          for (final ds in domainScores) {
            // ignore: avoid_print
            print('[SurveyPage] ${ds.domain}: '
                '${ds.totalScore}/${ds.maxPossible} -> ${ds.level.name}');
          }

          await _flagRepo.saveFlags(
            sessionId: _sessionId!,
            scores: domainScores,
          );

          await _sessionRepo.completeSession(_sessionId!);
          // ignore: avoid_print
          print('[SurveyPage] session completed with ${domainScores.length} flags');
        } catch (e) {
          // ignore: avoid_print
          print('[SurveyPage] complete failed: $e');
        }
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CompletionPage(
            completedType: widget.surveyType,
            periodMonth: widget.periodMonth,
            periodYear: widget.periodYear,
            domainScores: domainScores,
          ),
        ),
      );
    }
  }

  void prev() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeLabel = widget.surveyType == SurveyType.foundational
        ? 'Foundational Assessment'
        : widget.mode == SurveyMode.enhanced
            ? 'Monthly Check-in · LLM-based'
            : 'Monthly Check-in · Rule-based';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => _showExitDialog(context),
        ),
        title: Text(typeLabel,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        centerTitle: true,
      ),
      body: Builder(
        builder: (_) {
          if (loading) {
            return const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primary));
          }
          if (error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Load failed: $error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            );
          }
          if (_visibleQuestions.isEmpty) {
            return const Center(child: Text('No questions'));
          }

          final currentQ = _visibleQuestions[_currentIndex];
          final domainLabel = currentQ.domain != null
              ? _domainLabel(currentQ.domain!)
              : null;

          // Detect domain transition
          final showDomainTransition = _previousDomain != null &&
              currentQ.domain != null &&
              _previousDomain != currentQ.domain;

          return Column(
            children: [
              SurveyProgressBar(
                progress: progress,
                domainLabel: domainLabel,
                currentQuestion: _currentIndex + 1,
                totalQuestions: _visibleQuestions.length,
              ),

              // Domain transition banner
              if (showDomainTransition && domainLabel != null)
                Container(
                  width: double.infinity,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz,
                          size: 18,
                          color: AppColors.accent),
                      const SizedBox(width: 8),
                      Text(
                        'Now entering: $domainLabel',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: QuestionCard(
                  question: currentQ,
                  questionNumber: _currentIndex + 1,
                  onOptionToggle: toggleOption,
                  onNumericChanged: (value) {
                    currentQ.numericAnswer = value;
                    _recalculateVisible();
                  },
                  onPrevious: _currentIndex > 0 ? prev : null,
                  onNext: next,
                  isLast:
                      _currentIndex == _visibleQuestions.length - 1,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showExitDialog(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Leave Assessment?'),
        content: const Text(
            'Your progress so far has been saved, but the session will remain incomplete.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (shouldExit == true) {
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  String _domainLabel(String domain) {
    switch (domain.toUpperCase()) {
      case 'MENTAL HEALTH':
        return 'Mental Health';
      case 'DIETARY':
        return 'Dietary';
      case 'PHYSICAL ACTIVITY':
        return 'Physical Activity';
      case 'WOMEN HEALTH':
        return "Women's Health";
      case 'ALCOHOL':
        return 'Alcohol';
      case 'SMOKING/VAPING':
        return 'Smoking/Vaping';
      default:
        return domain;
    }
  }
}
