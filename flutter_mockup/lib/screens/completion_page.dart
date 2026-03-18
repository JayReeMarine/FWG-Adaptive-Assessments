import 'package:flutter/material.dart';
import '../repositories/session_repository.dart';
import '../utils/constants.dart';
import 'home_page.dart';
import 'survey_page.dart';

class CompletionPage extends StatelessWidget {
  final SurveyType completedType;
  final int periodMonth;
  final int periodYear;

  const CompletionPage({
    super.key,
    required this.completedType,
    required this.periodMonth,
    required this.periodYear,
  });

  @override
  Widget build(BuildContext context) {
    final isFoundational = completedType == SurveyType.foundational;

    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('Survey Complete',
            style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 100),
              const SizedBox(height: 20),
              Text(
                isFoundational
                    ? 'Foundational Assessment Complete!'
                    : 'Monthly Check-in Complete!',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isFoundational
                    ? 'Great job! You can now start your first monthly check-in.'
                    : 'Thank you! Your responses have been saved.\nCome back next month for your next check-in.',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              if (isFoundational) ...[
                // After foundational → start first monthly
                ElevatedButton(
                  onPressed: () {
                    final now = DateTime.now();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SurveyPage(
                          surveyType: SurveyType.monthly,
                          periodMonth: now.month,
                          periodYear: now.year,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Start Monthly Check-in',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ] else ...[
                // After monthly → go home
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back to Home',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
                const SizedBox(height: 16),
                // Demo: next month button
                OutlinedButton(
                  onPressed: () {
                    final nextMonth =
                        periodMonth == 12 ? 1 : periodMonth + 1;
                    final nextYear =
                        periodMonth == 12 ? periodYear + 1 : periodYear;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SurveyPage(
                          surveyType: SurveyType.monthly,
                          periodMonth: nextMonth,
                          periodYear: nextYear,
                        ),
                      ),
                    );
                  },
                  child: const Text('(Demo) Next Month Survey'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
