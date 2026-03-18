import 'package:flutter/material.dart';
import '../repositories/question_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/rule_repository.dart';
import '../models/ui_question.dart';
import '../models/branch_rule.dart';
import '../services/branching_engine.dart';
import '../utils/constants.dart';
import '../widgets/progress_bar.dart';
import '../widgets/question_card.dart';
import 'completion_page.dart';

class SurveyPage extends StatefulWidget {
  final SurveyType surveyType;
  final int periodMonth;
  final int periodYear;

  const SurveyPage({
    super.key,
    required this.surveyType,
    required this.periodMonth,
    required this.periodYear,
  });

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  final _questionRepo = QuestionRepository();
  final _sessionRepo = SessionRepository();
  final _ruleRepo = RuleRepository();

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

  Future<void> _load() async {
    try {
      // 1) Load questions based on survey type
      final List<UiQuestion> questions;
      if (widget.surveyType == SurveyType.foundational) {
        questions = await _questionRepo.fetchFoundational();
      } else {
        questions = await _questionRepo.fetchMonthly();
      }
      print('[SurveyPage] loaded ${questions.length} ${widget.surveyType.name} questions');

      // 2) Load branching rules
      List<BranchRule> rules;
      try {
        rules = await _ruleRepo.fetchAll();
        print('[SurveyPage] loaded ${rules.length} rules');
      } catch (e) {
        print('[SurveyPage] rules unavailable: $e');
        rules = [];
      }

      // 3) Create branching engine
      _engine = BranchingEngine(rules: rules);

      // 4) Create session
      final sessionId = await _sessionRepo.createSession(
        periodMonth: widget.periodMonth,
        periodYear: widget.periodYear,
      );
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

    try {
      switch (q.answerKind) {
        case 'NUMERIC':
          await _sessionRepo.saveResponse(
            sessionId: _sessionId!,
            questionId: q.questionId,
            valueNumber: q.numericAnswer,
          );
          break;
        case 'SCALE':
          await _sessionRepo.saveResponse(
            sessionId: _sessionId!,
            questionId: q.questionId,
            valueScale: q.selected.first,
          );
          break;
        case 'MULTI':
          await _sessionRepo.saveResponse(
            sessionId: _sessionId!,
            questionId: q.questionId,
            raw: {'selected': q.selected.toList()},
          );
          break;
      }
      print('[SurveyPage] saved q=${q.questionId}');
    } catch (e) {
      print('[SurveyPage] save failed: $e');
    }
  }

  void next() async {
    await _saveCurrentResponse();

    if (_currentIndex < _visibleQuestions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      if (_sessionId != null) {
        try {
          await _sessionRepo.completeSession(_sessionId!);
          print('[SurveyPage] session completed');
        } catch (e) {
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
        : 'Monthly Check-in';

    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Center(
          child: Text(typeLabel,
              style: const TextStyle(color: Colors.white, fontSize: 18)),
        ),
      ),
      body: Builder(
        builder: (_) {
          if (loading) return const Center(child: CircularProgressIndicator());
          if (error != null) return Center(child: Text('Load failed: $error'));
          if (_visibleQuestions.isEmpty) {
            return const Center(child: Text('No questions'));
          }

          final currentQ = _visibleQuestions[_currentIndex];

          return Column(
            children: [
              SurveyProgressBar(progress: progress),
              if (currentQ.domain != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 20, right: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      label: Text(
                        _domainLabel(currentQ.domain!),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                      backgroundColor: _domainColor(currentQ.domain!),
                    ),
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
                ),
              ),
            ],
          );
        },
      ),
    );
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

  Color _domainColor(String domain) {
    switch (domain.toUpperCase()) {
      case 'MENTAL HEALTH':
        return Colors.purple;
      case 'DIETARY':
        return Colors.green;
      case 'PHYSICAL ACTIVITY':
        return Colors.orange;
      case 'WOMEN HEALTH':
        return Colors.pink;
      case 'ALCOHOL':
        return Colors.red;
      case 'SMOKING/VAPING':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}
