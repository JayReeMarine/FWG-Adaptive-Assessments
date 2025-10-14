import 'package:flutter/material.dart';
import '../models/ui_question.dart'; // Use UiQuestion instead of mock Question
import '../utils/constants.dart';
import 'help_dialog.dart';

class QuestionCard extends StatelessWidget {
  final UiQuestion question; // <- change type to UiQuestion
  final int questionNumber;
  final Function(int) onOptionToggle;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const QuestionCard({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.onOptionToggle,
    this.onPrevious,
    this.onNext,
  });

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => HelpDialog(question: question), // pass UiQuestion
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question $questionNumber',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              InkWell(
                onTap: () => _showHelpDialog(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Icon(Icons.help_outline, size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Question text (UiQuestion.title)
          Text(
            question.title, // <- was question.question
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 30),

          // Options list
          Expanded(
            child: ListView.builder(
              itemCount: question.options.length,
              itemBuilder: (context, index) {
                final isSelected = question.selected.contains(index);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: InkWell(
                    onTap: () => onOptionToggle(index),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (value) => onOptionToggle(index),
                          activeColor: Colors.black,
                          checkColor: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          question.options[index],
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: onPrevious,
                icon: const Icon(Icons.arrow_back, size: 40),
                color: Colors.black,
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.arrow_forward, size: 40),
                color: Colors.black,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
