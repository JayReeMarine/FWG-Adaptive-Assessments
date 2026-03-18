import 'package:flutter/material.dart';
import '../repositories/question_repository.dart';
import '../repositories/session_repository.dart';
import '../models/ui_question.dart';
import '../utils/constants.dart';
import '../widgets/progress_bar.dart';
import '../widgets/question_card.dart';
import 'completion_page.dart';

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  final _questionRepo = QuestionRepository();
  final _sessionRepo = SessionRepository();

  int current = 0;
  List<UiQuestion> items = [];
  bool loading = true;
  String? error;

  int? _sessionId; // current session ID in DB

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // 1) Load questions
      final data = await _questionRepo.fetchByQuestionnaire(1);
      print('[SurveyPage] loaded ${data.length} questions');

      // 2) Create a session for this survey run
      final now = DateTime.now();
      final sessionId = await _sessionRepo.createSession(
        periodMonth: now.month,
        periodYear: now.year,
      );
      print('[SurveyPage] created session id=$sessionId');

      setState(() {
        items = data;
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

  double get progress =>
      items.isEmpty ? 0.0 : (current + 1) / items.length;

  void toggleOption(int index) {
    setState(() {
      final q = items[current];
      if (q.selected.contains(index)) {
        q.selected.remove(index);
      } else {
        // For SCALE: single select — clear previous
        if (q.answerKind == 'SCALE') {
          q.selected.clear();
        }
        q.selected.add(index);
      }
    });
  }

  /// Save the current question's response to Supabase.
  Future<void> _saveCurrentResponse() async {
    if (_sessionId == null) return;

    final q = items[current];

    // Skip if no answer was given
    if (q.answerKind == 'NUMERIC' && q.numericAnswer == null) return;
    if (q.answerKind == 'SCALE' && q.selected.isEmpty) return;

    try {
      if (q.answerKind == 'NUMERIC') {
        await _sessionRepo.saveResponse(
          sessionId: _sessionId!,
          questionId: q.questionId,
          valueNumber: q.numericAnswer,
        );
      } else if (q.answerKind == 'SCALE') {
        await _sessionRepo.saveResponse(
          sessionId: _sessionId!,
          questionId: q.questionId,
          valueScale: q.selected.first,
        );
      }
      print('[SurveyPage] saved response for q=${q.questionId}');
    } catch (e) {
      print('[SurveyPage] failed to save response: $e');
    }
  }

  void next() async {
    // Save current answer before moving
    await _saveCurrentResponse();

    if (current < items.length - 1) {
      setState(() => current++);
    } else {
      // Complete the session
      if (_sessionId != null) {
        try {
          await _sessionRepo.completeSession(_sessionId!);
          print('[SurveyPage] session $_sessionId completed');
        } catch (e) {
          print('[SurveyPage] failed to complete session: $e');
        }
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CompletionPage()),
      );
    }
  }

  void prev() {
    if (current > 0) {
      setState(() => current--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Center(
          child: Text('9:41',
              style: TextStyle(color: Colors.white, fontSize: 18)),
        ),
      ),
      body: Builder(
        builder: (_) {
          if (loading) return const Center(child: CircularProgressIndicator());
          if (error != null) return Center(child: Text('Load failed: $error'));
          if (items.isEmpty) return const Center(child: Text('No questions'));

          return Column(
            children: [
              SurveyProgressBar(progress: progress),
              Expanded(
                child: QuestionCard(
                  question: items[current],
                  questionNumber: current + 1,
                  onOptionToggle: toggleOption,
                  onNumericChanged: (value) {
                    items[current].numericAnswer = value;
                  },
                  onPrevious: current > 0 ? prev : null,
                  onNext: next,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
