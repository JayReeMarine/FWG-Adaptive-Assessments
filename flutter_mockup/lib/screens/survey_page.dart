import 'package:flutter/material.dart';
import '../repositories/question_repository.dart';
import '../models/ui_question.dart';
import '../utils/constants.dart';
import '../widgets/progress_bar.dart';
import '../widgets/question_card.dart';

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  final repo = QuestionRepository();

  int current = 0;
  List<UiQuestion> items = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Load questions from DB
  Future<void> _load() async {
    try {
      final data = await repo.fetchByQuestionnaire(1);
      // DEBUG: print what we loaded from Supabase
      // This helps ensure we're not using any stale mock path.
      // ignore: avoid_print
      print('[SurveyPage] loaded ${data.length} questions '
            'first="${data.isNotEmpty ? data.first.title : 'none'}"');

      setState(() {
        items = data;
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
    // Update selected set for UiQuestion
    setState(() {
      final q = items[current];
      if (q.selected.contains(index)) {
        q.selected.remove(index);
      } else {
        q.selected.add(index);
      }
    });
  }

  void next() {
    if (current < items.length - 1) {
      setState(() => current++);
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

          // You already have QuestionCard/ProgressBar widgets — reuse them
          return Column(
            children: [
              SurveyProgressBar(progress: progress),
              Expanded(
                child: QuestionCard(
                  // Adapt if your QuestionCard expects different props
                  question: items[current],         // pass UiQuestion
                  questionNumber: current + 1,
                  onOptionToggle: toggleOption,
                  onPrevious: current > 0 ? prev : null,
                  onNext: current < items.length - 1 ? next : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
