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

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final fDone = await _sessionRepo.hasCompletedFoundational();
      setState(() {
        _foundationalDone = fDone;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _startSurvey(SurveyType type, {SurveyMode mode = SurveyMode.baseline}) {
    final now = DateTime.now();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurveyPage(
          surveyType: type,
          periodMonth: type == SurveyType.foundational ? 0 : now.month,
          periodYear: type == SurveyType.foundational ? 0 : now.year,
          mode: mode,
        ),
      ),
    ).then((_) => _checkStatus());
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
                          horizontal: 24, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Section 1: Foundational Assessment ───────────
                          _buildSectionLabel('Step 1 — Baseline Profile'),
                          const SizedBox(height: 10),
                          _buildFoundationalCard(),

                          const SizedBox(height: 28),

                          // ── Section 2: Monthly Check-In ──────────────────
                          _buildSectionLabel('Step 2 — Monthly Check-In'),
                          const SizedBox(height: 6),
                          Text(
                            'Choose your assessment approach. Each path uses the same questions '
                            'but adapts them differently.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildMonthlyCard(
                            label: 'Rule-based',
                            subtitle:
                                'Fixed branching logic — predefined rules control '
                                'which follow-up questions appear.',
                            icon: Icons.account_tree_outlined,
                            color: AppColors.primary,
                            mode: SurveyMode.baseline,
                          ),
                          const SizedBox(height: 10),
                          _buildMonthlyCard(
                            label: 'LLM-based',
                            subtitle:
                                'Personalised questions generated from your health '
                                'profile using Gemini AI.',
                            icon: Icons.auto_awesome_outlined,
                            color: const Color(0xFF1565C0),
                            mode: SurveyMode.enhanced,
                          ),

                          const SizedBox(height: 16),

                          // ── Side-by-side comparison link ─────────────────
                          _buildSideBySideLink(),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

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
            'Adaptive Health Assessments',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );
  }

  // ── Foundational Assessment card ──────────────────────────────────────────

  Widget _buildFoundationalCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _startSurvey(SurveyType.foundational),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _foundationalDone
                      ? Colors.green.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _foundationalDone ? Icons.check_circle : Icons.assignment_outlined,
                  color: _foundationalDone ? Colors.green : AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Foundational Assessment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'One-time baseline profile — covers all 6 health domains. '
                      'This feeds into your monthly check-in.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (_foundationalDone) ...[
                      const SizedBox(height: 6),
                      const Text(
                        '✓ Completed',
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

  // ── Monthly Check-In card (rule-based / LLM-based) ────────────────────────

  Widget _buildMonthlyCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required SurveyMode mode,
  }) {
    final now = DateTime.now();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.25), width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
          ).then((_) => _checkStatus());
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Monthly Check-In',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: color.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
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
              Icon(Icons.chevron_right,
                  color: color.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Side-by-side comparison link ─────────────────────────────────────────

  Widget _buildSideBySideLink() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ComparisonPage()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2), width: 1),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.primary.withValues(alpha: 0.04),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.compare_arrows,
                size: 18,
                color: AppColors.primary.withValues(alpha: 0.8)),
            const SizedBox(width: 8),
            Text(
              'View Rule-based vs LLM-based Side-by-Side',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right,
                size: 16,
                color: AppColors.primary.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}
