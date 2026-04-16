import 'package:flutter/material.dart';
import '../config/symptom_descriptions.dart';
import '../repositories/session_repository.dart';
import '../services/scoring_service.dart';
import '../utils/constants.dart';
import 'home_page.dart';
import 'survey_page.dart';

// ─── Hardcoded Month 1 reference data (Sophie persona) ────────────────────
// Only Mental Health had a non-zero risk in Month 1; all other domains were
// "none" so they are omitted — the card will simply skip the comparison row.

class _PrevMonth {
  final int score;
  final int max;
  final RiskLevel level;
  const _PrevMonth(this.score, this.max, this.level);
}

const _previousMonth = <String, _PrevMonth>{
  'MENTAL HEALTH': _PrevMonth(3, 10, RiskLevel.mild),
};

class CompletionPage extends StatelessWidget {
  final SurveyType completedType;
  final int periodMonth;
  final int periodYear;
  final List<DomainScore> domainScores;

  const CompletionPage({
    super.key,
    required this.completedType,
    required this.periodMonth,
    required this.periodYear,
    this.domainScores = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isFoundational = completedType == SurveyType.foundational;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('Complete',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.check, color: Colors.green, size: 44),
              ),
              const SizedBox(height: 20),
              Text(
                isFoundational
                    ? 'Foundational Assessment Complete!'
                    : 'Monthly Check-in Complete!',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                isFoundational
                    ? 'Great job! You can now start your first monthly check-in.'
                    : 'Thank you! Your responses have been saved.\nCome back next month for your next check-in.',
                style: const TextStyle(
                    fontSize: 15, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),

              // Domain score summary
              if (domainScores.isNotEmpty) ...[
                const SizedBox(height: 28),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Your Results',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ),
                const SizedBox(height: 12),
                ...domainScores.map((ds) => _buildScoreCard(ds)),
              ],

              const SizedBox(height: 32),

              // Primary action
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isFoundational) {
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
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HomePage()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    isFoundational
                        ? 'Start Monthly Check-in'
                        : 'Back to Home',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              if (!isFoundational) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
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
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.divider),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('(Demo) Next Month Survey'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(DomainScore ds) {
    final description = SymptomDescriptions.get(ds.domain, ds.level);
    final prev = _previousMonth[ds.domain.toUpperCase()];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row (icon + name + badge) — unchanged ──
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _riskColor(ds.level).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_riskIcon(ds.level),
                      color: _riskColor(ds.level), size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_domainLabel(ds.domain),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(
                        'Score: ${ds.totalScore}/${ds.maxPossible}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _riskColor(ds.level).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _riskLabel(ds.level),
                    style: TextStyle(
                      color: _riskColor(ds.level),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            // ── Symptom description ──
            if (description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],

            // ── Previous month comparison ──
            if (prev != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 12),
              _buildPreviousMonthRow(ds, prev),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviousMonthRow(DomainScore current, _PrevMonth prev) {
    final curIdx = RiskLevel.values.indexOf(current.level);
    final prevIdx = RiskLevel.values.indexOf(prev.level);

    String trendText;
    IconData trendIcon;
    Color trendColor;

    if (curIdx > prevIdx) {
      trendText = 'Increased from last month';
      trendIcon = Icons.trending_up;
      trendColor = Colors.orange;
    } else if (curIdx < prevIdx) {
      trendText = 'Improved from last month';
      trendIcon = Icons.trending_down;
      trendColor = Colors.green;
    } else {
      trendText = 'Same as last month';
      trendIcon = Icons.trending_flat;
      trendColor = AppColors.textSecondary;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bar_chart_rounded,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              'Last month: ${_riskLabel(prev.level)} (${prev.score}/${prev.max})',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const SizedBox(width: 22),
            Icon(trendIcon, size: 14, color: trendColor),
            const SizedBox(width: 4),
            Text(
              trendText,
              style: TextStyle(
                fontSize: 12,
                color: trendColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }


  Color _riskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.none:
        return Colors.green;
      case RiskLevel.mild:
        return Colors.amber[700]!;
      case RiskLevel.moderate:
        return Colors.orange;
      case RiskLevel.high:
        return Colors.red;
    }
  }

  IconData _riskIcon(RiskLevel level) {
    switch (level) {
      case RiskLevel.none:
        return Icons.check_circle;
      case RiskLevel.mild:
        return Icons.info;
      case RiskLevel.moderate:
        return Icons.warning_amber;
      case RiskLevel.high:
        return Icons.error;
    }
  }

  String _riskLabel(RiskLevel level) {
    switch (level) {
      case RiskLevel.none:
        return 'Low Risk';
      case RiskLevel.mild:
        return 'Mild';
      case RiskLevel.moderate:
        return 'Moderate';
      case RiskLevel.high:
        return 'High';
    }
  }

  String _domainLabel(String domain) {
    switch (domain.toUpperCase()) {
      case 'MENTAL HEALTH':
        return 'Mental Health';
      case 'DIETARY':
        return 'Dietary';
      case 'PHYSICAL ACTIVITY':
        return 'Physical Activity';
      case 'WOMEN HEALTH':
        return "Women's Health";
      case 'ALCOHOL':
        return 'Alcohol';
      case 'SMOKING/VAPING':
        return 'Smoking/Vaping';
      default:
        return domain;
    }
  }
}
