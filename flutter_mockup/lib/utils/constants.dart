import 'package:flutter/material.dart';
import '../models/question.dart';

class AppColors {
  static final Color primary = Colors.blue[400]!;
  static final Color secondary = Colors.blue[300]!;
  static final Color cardBackground = Colors.blue[200]!;
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Colors.white;
}

class AppData {
  static List<Question> getSurveyQuestions() {
    return [
      Question(
        question: 'How old are you?',
        options: ['0-9', '10-19', '20-29', '30-39', '10-19', '40-59', '59-60', '69-70', '70+'],
        helpTitle: 'Why do we ask this?',
        helpText: 'Body text for whatever you\'d like to say. Add main takeaway points, quotes, anecdotes, or even a very very short story.',
      ),
      Question(
        question: 'What is your favorite color?',
        options: ['Red', 'Blue', 'Green', 'Yellow', 'Purple', 'Orange'],
        helpTitle: 'Why do we ask this?',
        helpText: 'Understanding your color preferences helps us personalize your experience.',
      ),
      Question(
        question: 'Which hobbies do you enjoy?',
        options: ['Reading', 'Sports', 'Gaming', 'Cooking', 'Travel', 'Music'],
        helpTitle: 'Why do we ask this?',
        helpText: 'Your hobbies help us recommend relevant content and connect you with like-minded people.',
      ),
    ];
  }
}