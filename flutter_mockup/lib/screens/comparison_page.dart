import 'package:flutter/material.dart';
import '../config/comparison_scenario.dart';
import '../utils/constants.dart';

/// Side-by-side research comparison screen.
///
/// Shows the Mental Health domain question paths for Alex's Month 2 run:
///   • Question Paths tab — Baseline questions (with blocked indicator)
///                          vs Enhanced questions (with why labels)
///   • Evaluation tab     — 6-dimension comparison table (Zach's criteria)
///
/// Used for supervisor demos and the Step 5/6 comparison environment.
class ComparisonPage extends StatefulWidget {
  const ComparisonPage({super.key});

  @override
  State<ComparisonPage> createState() => _ComparisonPageState();
}

class _ComparisonPageState extends State<ComparisonPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Rule-based vs LLM-based',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Question Paths'),
            Tab(text: 'Evaluation'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSeedCard(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQuestionPathsTab(),
                _buildEvaluationTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Scenario Seed Card ────────────────────────────────────────────────────

  Widget _buildSeedCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grain, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text(
                'SCENARIO SEED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              _tagChip('v${alexSeed.version}', AppColors.primary),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${alexSeed.demographics.background}  ·  '
            'Age ${alexSeed.demographics.age}  ·  Month 2',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              const Text(
                'Mental Health: ',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              _tagChip(
                alexSeed.domainRiskLevels['MENTAL HEALTH']!.toUpperCase(),
                Colors.amber[700]!,
              ),
              const SizedBox(width: 6),
              const Text(
                '(persistent — 2 months)',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...alexSeed.contextNotes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                  Expanded(
                    child: Text(
                      note,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Question Paths Tab ────────────────────────────────────────────────────

  Widget _buildQuestionPathsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('RULE-BASED', AppColors.primary, Icons.account_tree_outlined),
          const SizedBox(height: 4),
          Text(
            '${baselineMentalHealthPath.length - 1} questions shown  ·  1 blocked by hard threshold',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          ...baselineMentalHealthPath.map(_buildBaselineCard),
          const SizedBox(height: 20),
          _sectionHeader(
              'LLM-BASED', const Color(0xFF1565C0), Icons.auto_awesome_outlined),
          const SizedBox(height: 4),
          const Text(
            '4 questions shown  ·  1 skipped (low stable score)  ·  1 new question',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          ...enhancedMentalHealthPath.map(_buildEnhancedCard),
          _buildSkippedNote(),
        ],
      ),
    );
  }

  Widget _buildBaselineCard(BaselineQuestion q) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: q.blocked
              ? Colors.red.withValues(alpha: 0.35)
              : AppColors.divider,
        ),
      ),
      color: q.blocked
          ? Colors.red.withValues(alpha: 0.03)
          : AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _qBadge(
                  'Q${q.id}',
                  q.blocked ? Colors.red : AppColors.primary,
                ),
                const SizedBox(width: 8),
                if (q.blocked) _tagChip('BLOCKED', Colors.red),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              q.text,
              style: TextStyle(
                fontSize: 13,
                color: q.blocked
                    ? Colors.red.shade700
                    : AppColors.textPrimary,
                fontStyle:
                    q.blocked ? FontStyle.italic : FontStyle.normal,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              q.note,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedCard(EnhancedQuestion q) {
    final isMock = q.id == -1;
    final isUnlocked = q.id == 39;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFF1565C0).withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _qBadge(
                  isMock ? 'NEW' : 'Q${q.id}',
                  const Color(0xFF1565C0),
                ),
                const SizedBox(width: 8),
                if (isMock) _tagChip('NEW QUESTION', Colors.teal),
                if (isUnlocked)
                  _tagChip('UNLOCKED EARLY', const Color(0xFF1565C0)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              q.text,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline,
                    size: 12, color: AppColors.accent),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    q.why,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkippedNote() {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      color: Colors.grey.withValues(alpha: 0.04),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.skip_next, size: 16, color: AppColors.textSecondary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Q20 (isolation) — SKIPPED: Low and stable score in Month 1. '
                'No new information expected.',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Evaluation Tab ────────────────────────────────────────────────────────

  Widget _buildEvaluationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Zach\'s 6 Evaluation Dimensions',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'How well does each path score on the criteria used in the user study?',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ...comparisonSummary.map(_buildDimensionCard),
        ],
      ),
    );
  }

  Widget _buildDimensionCard(ComparisonDimension d) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              d.name,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _dimensionRow('Baseline', d.baseline, AppColors.primary),
            const SizedBox(height: 6),
            _dimensionRow('Enhanced', d.enhanced, const Color(0xFF1565C0)),
          ],
        ),
      ),
    );
  }

  Widget _dimensionRow(String label, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 68,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionHeader(String label, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _qBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _tagChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
