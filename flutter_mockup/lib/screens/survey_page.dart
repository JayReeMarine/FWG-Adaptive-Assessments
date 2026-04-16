import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../widgets/help_dialog.dart';
import 'completion_page.dart';

class SurveyPage extends StatefulWidget {
  final SurveyType surveyType;
  final int periodMonth;
  final int periodYear;

  /// Research comparison mode.
  /// - [SurveyMode.baseline] (default): uses BranchingEngine + live DB rules.
  /// - [SurveyMode.enhanced]: replaces the Mental Health domain with the
  ///   LLM-generated path from LlmService.
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
  final _scrollController = ScrollController();

  int _currentIndex = 0;
  List<UiQuestion> _allQuestions = [];
  List<UiQuestion> _visibleQuestions = [];
  bool loading = true;
  String? error;

  int? _sessionId;
  late BranchingEngine _engine;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
          sophieSeed,
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  double get progress =>
      _visibleQuestions.isEmpty
          ? 0.0
          : (_currentIndex + 1) / _visibleQuestions.length;

  void toggleOption(int questionIndex, int optionIndex) {
    setState(() {
      final q = _visibleQuestions[questionIndex];
      switch (q.answerKind) {
        case 'SCALE':
          q.selected.clear();
          q.selected.add(optionIndex);
          break;
        case 'MULTI':
          if (q.selected.contains(optionIndex)) {
            q.selected.remove(optionIndex);
          } else {
            q.selected.add(optionIndex);
          }
          break;
        default:
          q.selected.add(optionIndex);
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
    final q = _visibleQuestions[_currentIndex];
    if (q.required && !q.isAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer this question before continuing.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    await _saveCurrentResponse();

    if (_currentIndex < _visibleQuestions.length - 1) {
      setState(() => _currentIndex++);
      _scrollToBottom();
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

  // ── Build ─────────────────────────────────────────────────────────────────

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
                child: CircularProgressIndicator(color: AppColors.primary));
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
                        style: const TextStyle(
                            color: AppColors.textSecondary)),
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

          return Column(
            children: [
              SurveyProgressBar(
                progress: progress,
                domainLabel: domainLabel,
                currentQuestion: _currentIndex + 1,
                totalQuestions: _visibleQuestions.length,
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                  itemCount: _currentIndex + 1,
                  itemBuilder: (context, index) {
                    final q = _visibleQuestions[index];
                    return index < _currentIndex
                        ? _buildAnsweredItem(q, index)
                        : _buildActiveItem(q, index);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Answered question (locked, compact) ──────────────────────────────────

  void _goToPrevious() {
    if (_currentIndex <= 0) return;
    // Clear the current question's answer, step back one
    final current = _visibleQuestions[_currentIndex];
    current.selected.clear();
    current.numericAnswer = null;
    setState(() => _currentIndex--);
    _scrollToBottom();
  }

  Widget _buildAnsweredItem(UiQuestion q, int index) {
    String answerText;
    if (q.answerKind == 'NUMERIC') {
      answerText = q.numericAnswer?.toString() ?? '—';
    } else {
      answerText = q.selected.map((i) => q.options[i]).join(', ');
    }

    return Container(
      key: ValueKey('answered_${q.questionId}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _qBadge('Q${index + 1}'),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  q.title,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  answerText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.check_circle_outline,
              size: 18, color: AppColors.primary),
        ],
      ),
    );
  }

  // ── Active question (interactive) ─────────────────────────────────────────

  Widget _buildActiveItem(UiQuestion q, int index) {
    final isLast = _currentIndex == _visibleQuestions.length - 1;
    return Card(
      key: ValueKey('active_${q.questionId}'),
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _qBadge('Q${index + 1}'),
                if (q.help.isNotEmpty)
                  InkWell(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => HelpDialog(question: q),
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.help_outline,
                          size: 18, color: AppColors.primary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Question text
            Text(
              q.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Answer input
            _buildInlineAnswerInput(q, index),
            const SizedBox(height: 16),

            // Buttons row
            Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _goToPrevious,
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Previous'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.divider),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                if (_currentIndex > 0) const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      isLast ? 'Submit' : 'Next',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Inline answer inputs ──────────────────────────────────────────────────

  Widget _buildInlineAnswerInput(UiQuestion q, int questionIndex) {
    switch (q.answerKind) {
      case 'NUMERIC':
        return _buildInlineNumericInput(q);
      case 'SCALE':
      case 'MULTI':
        return _buildInlineChoiceInput(q, questionIndex);
      default:
        return Text('Unsupported type: ${q.answerKind}',
            style: const TextStyle(color: AppColors.textSecondary));
    }
  }

  // Key on TextField prevents previous answer leaking into next numeric question
  Widget _buildInlineNumericInput(UiQuestion q) {
    return TextField(
      key: ValueKey('numeric_${q.questionId}'),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$')),
      ],
      decoration: InputDecoration(
        labelText: 'Enter a number',
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onChanged: (value) {
        final n = num.tryParse(value);
        q.numericAnswer = n;
        _recalculateVisible();
      },
    );
  }

  Widget _buildInlineChoiceInput(UiQuestion q, int questionIndex) {
    return Column(
      children: List.generate(q.options.length, (optionIndex) {
        final selected = q.selected.contains(optionIndex);
        final isMulti = q.answerKind == 'MULTI';
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => toggleOption(questionIndex, optionIndex),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.divider,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: isMulti
                            ? BoxShape.rectangle
                            : BoxShape.circle,
                        borderRadius:
                            isMulti ? BorderRadius.circular(4) : null,
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          width: 2,
                        ),
                        color: selected
                            ? AppColors.primary
                            : Colors.transparent,
                      ),
                      child: selected
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        q.options[optionIndex],
                        style: TextStyle(
                          fontSize: 15,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _qBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Future<void> _showExitDialog(BuildContext context) async {
    final nav = Navigator.of(context);
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    if (shouldExit == true && mounted) {
      nav.pop();
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
