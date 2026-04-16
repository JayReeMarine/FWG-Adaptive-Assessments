import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../repositories/session_repository.dart';
import '../utils/constants.dart';
import 'survey_page.dart';
import 'comparison_page.dart';

// ── Update this URL once the PDF is hosted (e.g. GitHub raw or Vercel static) ─
// For local Flutter web dev, place user_guide.pdf in flutter_mockup/web/ and
// set this to '/user_guide.pdf'. For production, use the full hosted URL.
const _kUserGuideUrl = '/user_guide.pdf';

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
                          // ── User Guide banner ────────────────────────────
                          _buildUserGuideBanner(),
                          const SizedBox(height: 20),

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

                          // ── What's the difference? ────────────────────────
                          _buildWhatsTheDifferenceCard(),

                          const SizedBox(height: 12),

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

  // ── What's the difference? ───────────────────────────────────────────────

  Widget _buildWhatsTheDifferenceCard() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2), width: 1),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.background,
        ),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(Icons.help_outline,
              size: 18, color: AppColors.primary.withValues(alpha: 0.8)),
          title: Text(
            "What's the difference?",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary.withValues(alpha: 0.9),
            ),
          ),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.primary.withValues(alpha: 0.6),
          children: [
            _diffRow(
              icon: Icons.account_tree_outlined,
              color: AppColors.primary,
              label: 'Rule-based',
              description:
                  'Uses fixed rules to decide which questions appear. '
                  'Every user sees the same set of questions each month — '
                  'only certain follow-ups are unlocked based on your answers.',
            ),
            const SizedBox(height: 12),
            _diffRow(
              icon: Icons.auto_awesome_outlined,
              color: const Color(0xFF1565C0),
              label: 'LLM-based',
              description:
                  'Uses AI (Gemini) to personalise your questions based on '
                  'what you reported last month. It skips questions that '
                  'didn\'t change, unlocks follow-ups earlier if your history '
                  'suggests it, and rewrites questions in language relevant to you.',
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline,
                      size: 14, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Both approaches ask about the same health topics. '
                      'The difference is how the questions are chosen and '
                      'worded for you specifically.',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _diffRow({
    required IconData icon,
    required Color color,
    required String label,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── User Guide banner ─────────────────────────────────────────────────────

  Widget _buildUserGuideBanner() {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.base.resolve(_kUserGuideUrl);
        final launched = await launchUrl(uri, webOnlyWindowName: '_blank');

        if (!launched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open the User Guide.'),
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          border: Border.all(color: const Color(0xFFFFCC02), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.menu_book_rounded,
                size: 20, color: Color(0xFFF57F17)),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New here? Read the User Guide',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF57F17),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Step-by-step instructions for completing the study tasks.',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new,
                size: 14, color: Color(0xFFF57F17)),
          ],
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
