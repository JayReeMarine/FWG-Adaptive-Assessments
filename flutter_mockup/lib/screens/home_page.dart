import 'package:flutter/material.dart';
import '../repositories/session_repository.dart';
import '../utils/constants.dart';
import 'survey_page.dart';

/// Landing page that determines which survey to show.
/// - If foundational assessment is not done → start it.
/// - If foundational is done and current month is not done → start monthly.
/// - If everything is done → show "come back next month".
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _sessionRepo = SessionRepository();
  bool _loading = true;
  SurveyType? _nextType;
  int _nextMonth = 0;
  int _nextYear = 0;
  bool _allDone = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final next = await _sessionRepo.getNextSurvey();
      // Check if the monthly for this month is already done
      if (next.type == SurveyType.monthly) {
        final now = DateTime.now();
        final done = await _sessionRepo.hasCompletedMonthly(
          month: now.month,
          year: now.year,
        );
        if (done) {
          setState(() {
            _allDone = true;
            _loading = false;
          });
          return;
        }
      }

      setState(() {
        _nextType = next.type;
        _nextMonth = next.month;
        _nextYear = next.year;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _startSurvey() {
    if (_nextType == null) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SurveyPage(
          surveyType: _nextType!,
          periodMonth: _nextMonth,
          periodYear: _nextYear,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Center(
          child: Text('Adaptive Assessment',
              style: TextStyle(color: Colors.white, fontSize: 18)),
        ),
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _allDone
                ? _buildAllDone()
                : _buildReadyToStart(),
      ),
    );
  }

  Widget _buildReadyToStart() {
    final isFoundational = _nextType == SurveyType.foundational;
    final title = isFoundational
        ? 'Welcome!'
        : 'Monthly Check-in';
    final subtitle = isFoundational
        ? 'Let\'s start with your foundational health assessment.'
        : 'Time for your ${_monthName(_nextMonth)} $_nextYear check-in.';

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFoundational ? Icons.assignment : Icons.calendar_month,
            size: 80,
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),
          Text(title,
              style:
                  const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(subtitle,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _startSurvey,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              isFoundational ? 'Start Assessment' : 'Start Check-in',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllDone() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 80, color: Colors.green),
          const SizedBox(height: 24),
          const Text('All caught up!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text(
            'You\'ve completed this month\'s assessment.\nCome back next month for your next check-in.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          // Demo button: allow starting next month's survey for testing
          OutlinedButton(
            onPressed: () {
              final now = DateTime.now();
              final nextMonth = now.month == 12 ? 1 : now.month + 1;
              final nextYear = now.month == 12 ? now.year + 1 : now.year;
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
            child: const Text('(Demo) Start Next Month'),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return month >= 1 && month <= 12 ? names[month] : 'Month $month';
  }
}
