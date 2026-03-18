import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ui_question.dart';
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
      builder: (BuildContext context) => HelpDialog(question: question),
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

          // Question text
          Text(
            question.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 30),

          // Answer input — depends on answerKind
          Expanded(child: _buildAnswerInput()),

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

  Widget _buildAnswerInput() {
    switch (question.answerKind) {
      case 'NUMERIC':
        return _buildNumericInput();
      case 'SCALE':
        return _buildScaleInput();
      case 'MULTI':
        return _buildMultiSelectInput();
      default:
        return Center(child: Text('Unsupported type: ${question.answerKind}'));
    }
  }

  Widget _buildNumericInput() {
    return Column(
      children: [
        TextField(
          keyboardType: TextInputType.number,
          inputFormatters: [
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
      ],
    );
  }

  Widget _buildScaleInput() {
    return SingleChildScrollView(
      child: RadioGroup<int>(
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
    );
  }

  Widget _buildMultiSelectInput() {
    return SingleChildScrollView(
      child: Column(
        children: List.generate(
          question.options.length,
          (index) => CheckboxListTile(
            value: question.selected.contains(index),
            title: Text(question.options[index]),
            onChanged: (bool? checked) {
              onOptionToggle(index);
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
      ),
    );
  }
}
