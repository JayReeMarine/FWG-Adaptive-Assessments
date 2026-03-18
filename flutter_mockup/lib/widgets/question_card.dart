import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ui_question.dart'; // Use UiQuestion instead of mock Question
import '../utils/constants.dart';
import 'help_dialog.dart';

class QuestionCard extends StatelessWidget {
  final UiQuestion question;
  final int questionNumber;
  final Function(int) onOptionToggle;
  final Function(num?)? onNumericChanged;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const QuestionCard({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.onOptionToggle,
    this.onNumericChanged,
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
          if (question.answerKind == 'NUMERIC') ...[
            // Not a list; just a single numeric input field
          TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [
              // allow integers or decimals (and optional leading minus)
              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$')),
            ],
            decoration: const InputDecoration(
              labelText: 'Enter a number',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              final n = num.tryParse(value);
              question.numericAnswer = n;
              onNumericChanged?.call(n);
            },
          ),
          const SizedBox(height: 16),
        ] else if (question.answerKind == 'SCALE') ...[
          RadioGroup<int>(
            groupValue:
                question.selected.isNotEmpty ? question.selected.first : null,
            onChanged: (int? value) {
              if (value != null) {
                onOptionToggle(value);
              }
            },
            child: Column(
              children: List.generate(
                question.options.length,
                (index) => RadioListTile<int>(
                  value: index,
                  title: Text(question.options[index]),
                ),
              ),
            ),
          ),
        ],


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
