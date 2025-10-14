import 'package:flutter/material.dart';
import '../models/question.dart';
import '../utils/constants.dart';
import '../widgets/progress_bar.dart';
import '../widgets/question_card.dart';

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  int currentQuestion = 0;
  late List<Question> questions;

  @override
  void initState() {
    super.initState();
    questions = AppData.getSurveyQuestions();
  }

  double get progress => (currentQuestion + 1) / questions.length;

  void toggleOption(int index) {
    setState(() {
      if (questions[currentQuestion].selected.contains(index)) {
        questions[currentQuestion].selected.remove(index);
      } else {
        questions[currentQuestion].selected.add(index);
      }
    });
  }

  void goToNextQuestion() {
    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
      });
    }
  }

  void goToPreviousQuestion() {
    if (currentQuestion > 0) {
      setState(() {
        currentQuestion--;
      });
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
          child: Text(
            '9:41',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
      body: Column(
        children: [
          SurveyProgressBar(progress: progress),
          Expanded(
            child: QuestionCard(
              question: questions[currentQuestion],
              questionNumber: currentQuestion + 1,
              onOptionToggle: toggleOption,
              onPrevious: currentQuestion > 0 ? goToPreviousQuestion : null,
              onNext: currentQuestion < questions.length - 1 ? goToNextQuestion : null,
            ),
          ),
        ],
      ),
    );
  }
}