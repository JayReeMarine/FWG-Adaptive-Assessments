import 'package:flutter/material.dart';
import '../config/comparison_scenario.dart';
import '../utils/constants.dart';

/// Side-by-side research comparison screen.
///
/// Shows the Mental Health domain question paths for Sophie's Month 2 run:
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
              _tagChip('v${sophieSeed.version}', AppColors.primary),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${sophieSeed.demographics.background}  ·  '
            'Age ${sophieSeed.demographics.age}  ·  Month 2',
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
                sophieSeed.domainRiskLevels['MENTAL HEALTH']!.toUpperCase(),
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
          ...sophieSeed.contextNotes.map(
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
          _buildHowToReadCard(),
          const SizedBox(height: 16),
          _buildKeyInsightCard(),
          const SizedBox(height: 20),
          _sectionHeader('RULE-BASED', AppColors.primary, Icons.account_tree_outlined),
          const SizedBox(height: 4),
          Text(
            '${baselineMentalHealthPath.length - 1} questions shown  ·  1 blocked by hard threshold',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          _buildRule13Card(),
          const SizedBox(height: 8),
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
          _buildLlmApproachCard(),
          const SizedBox(height: 8),
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

  // ── How to read this page ─────────────────────────────────────────────────

  Widget _buildHowToReadCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Text(
                'HOW TO READ THIS PAGE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Same user. Same question bank. Different approach.\n'
            'Scroll down to see what each system asks Sophie — and why the '
            'questions look different. The Evaluation tab scores each approach '
            'on 6 research dimensions.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── Key Insight card ──────────────────────────────────────────────────────

  Widget _buildKeyInsightCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            const Color(0xFF1565C0).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 14, color: AppColors.accent),
              SizedBox(width: 6),
              Text(
                'KEY INSIGHT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Sophie has been Mild risk for two months in a row. '
            'The rule-based system doesn\'t know that — it blocks Q39 '
            'because her single-month score never crossed the threshold. '
            'The LLM-based system reads her Month\u00a01 history and unlocks '
            'Q39 anyway, skips the question that didn\'t change, '
            'and rewrites questions in student language.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 4: Rule 13 callout ───────────────────────────────────────────────

  Widget _buildRule13Card() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.rule, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                children: [
                  TextSpan(
                    text: 'Rule 13  ',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  TextSpan(
                    text: 'Q18 score ≥ 2 (More than half the days) ',
                  ),
                  TextSpan(
                    text: '\u2192 show Q39',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: "  \u00b7  Single-month threshold only. "
                        "No memory of prior months. "
                        "Sophie\u2019s score\u00a0=\u00a01 \u2192 Q39 is permanently blocked this run.",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 5: LLM approach summary card ────────────────────────────────────

  Widget _buildLlmApproachCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFF1565C0).withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_outlined,
              size: 14, color: Color(0xFF1565C0)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'The LLM selects and refines the question set on the fly based on '
              'the user\'s Month 1 seed. Rather than changing the branching logic, '
              'it decides which questions are worth asking this month '
              '(skipping low-signal ones like Q20), unlocks questions early when '
              'longitudinal patterns justify it (Q39), and rewrites phrasing to '
              'match the user\'s context (student-specific language, history reference).',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
        ],
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
            '6 Evaluation Dimensions',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Each card compares how the rule-based and LLM-based paths '
            'perform on one quality dimension. These criteria are used '
            'to evaluate both approaches in the user study.',
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
            _dimensionRow('Rule-based', d.baseline, AppColors.primary),
            const SizedBox(height: 6),
            _dimensionRow('LLM-based', d.enhanced, const Color(0xFF1565C0)),
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
