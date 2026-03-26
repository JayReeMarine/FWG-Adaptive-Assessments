import 'package:flutter/material.dart';
import '../repositories/session_repository.dart';
import '../utils/constants.dart';
import 'survey_page.dart';
import 'comparison_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _sessionRepo = SessionRepository();
  bool _loading = true;
  bool _foundationalDone = false;
  bool _monthlyDone = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final fDone = await _sessionRepo.hasCompletedFoundational();
      final now = DateTime.now();
      final mDone = await _sessionRepo.hasCompletedMonthly(
        month: now.month,
        year: now.year,
      );
      setState(() {
        _foundationalDone = fDone;
        _monthlyDone = mDone;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _startSurvey(SurveyType type) {
    final now = DateTime.now();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurveyPage(
          surveyType: type,
          periodMonth: type == SurveyType.foundational ? 0 : now.month,
          periodYear: type == SurveyType.foundational ? 0 : now.year,
        ),
      ),
    ).then((_) => _checkStatus()); // refresh status on return
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Health',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildAssessmentCard(
                            title: 'Foundational Assessment',
                            subtitle:
                                'One-time baseline health profile that covers all domains.',
                            icon: Icons.assignment,
                            completed: _foundationalDone,
                            onTap: () =>
                                _startSurvey(SurveyType.foundational),
                          ),
                          const SizedBox(height: 12),
                          _buildAssessmentCard(
                            title: 'Monthly Check-in',
                            subtitle:
                                'Recurring adaptive assessment — tracks changes over time.',
                            icon: Icons.calendar_month,
                            completed: _monthlyDone,
                            onTap: () => _startSurvey(SurveyType.monthly),
                          ),
                          if (_monthlyDone) ...[
                            const SizedBox(height: 12),
                            _buildDemoCard(),
                          ],
                          const SizedBox(height: 24),
                          _buildComparisonSection(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Navigator logo area
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.explore, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 12),
          const Text(
            'Navigator',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Adaptive Assessments',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool completed,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: completed
                      ? Colors.green.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  completed ? Icons.check_circle : icon,
                  color: completed ? Colors.green : AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (completed) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Completed',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  // ── Research comparison section ──────────────────────────────────────────
  Widget _buildComparisonSection() {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Research Comparison',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ComparisonPage()),
              ),
              child: Row(
                children: [
                  Text(
                    'View Side-by-Side',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      size: 16,
                      color: AppColors.primary.withValues(alpha: 0.8)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildComparisonCard(
          label: 'Baseline',
          subtitle: 'Rule-based adaptive path — standard branching engine',
          color: AppColors.primary,
          icon: Icons.rule,
          mode: SurveyMode.baseline,
          now: now,
        ),
        const SizedBox(height: 8),
        _buildComparisonCard(
          label: 'Enhanced',
          subtitle: 'Mock LLM-style path — Mental Health scenario (Alex, Month 2)',
          color: const Color(0xFF1565C0),
          icon: Icons.auto_awesome,
          mode: SurveyMode.enhanced,
          now: now,
        ),
      ],
    );
  }

  Widget _buildComparisonCard({
    required String label,
    required String subtitle,
    required Color color,
    required IconData icon,
    required SurveyMode mode,
    required DateTime now,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.3), width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SurveyPage(
                surveyType: SurveyType.monthly,
                periodMonth: now.month,
                periodYear: now.year,
                mode: mode,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoCard() {
    return Card(
      elevation: 0,
      color: AppColors.divider.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final now = DateTime.now();
          final nextMonth = now.month == 12 ? 1 : now.month + 1;
          final nextYear = now.month == 12 ? now.year + 1 : now.year;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SurveyPage(
                surveyType: SurveyType.monthly,
                periodMonth: nextMonth,
                periodYear: nextYear,
              ),
            ),
          ).then((_) => _checkStatus());
        },
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.science, size: 18, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text(
                '(Demo) Start Next Month',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
