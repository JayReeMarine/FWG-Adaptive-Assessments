import '../models/ui_question.dart';

/// Risk levels used for flag generation.
enum RiskLevel { none, mild, moderate, high }

/// Per-domain score result.
class DomainScore {
  final String domain;
  final int totalScore;
  final int maxPossible;
  final int questionCount;
  final RiskLevel level;

  DomainScore({
    required this.domain,
    required this.totalScore,
    required this.maxPossible,
    required this.questionCount,
    required this.level,
  });

  Map<String, dynamic> toJson() => {
        'domain': domain,
        'total_score': totalScore,
        'max_possible': maxPossible,
        'question_count': questionCount,
        'level': level.name,
      };
}

/// Calculates per-question scores and aggregates them into domain-level
/// risk assessments.
class ScoringService {
  /// Calculate the score for a single question based on the user's answer.
  /// For SCALE: selected index is the score (e.g., 0-3 for PHQ-style).
  /// For NUMERIC: the numeric value itself.
  /// For MULTI: number of selections.
  static int? questionScore(UiQuestion q) {
    if (!q.isAnswered) return null;

    switch (q.answerKind) {
      case 'SCALE':
        return q.selected.first; // index maps directly to score value
      case 'NUMERIC':
        return q.numericAnswer?.toInt();
      case 'MULTI':
        return q.selected.length;
      default:
        return null;
    }
  }

  /// Aggregate answered questions by domain and compute risk levels.
  /// Only includes domains that have at least one answered question.
  static List<DomainScore> calculateDomainScores(List<UiQuestion> questions) {
    // Group answered questions by domain
    final Map<String, List<UiQuestion>> byDomain = {};
    for (final q in questions) {
      if (q.domain == null || !q.isAnswered) continue;
      byDomain.putIfAbsent(q.domain!, () => []).add(q);
    }

    final List<DomainScore> results = [];
    for (final entry in byDomain.entries) {
      final domain = entry.key;
      final domainQuestions = entry.value;

      int total = 0;
      int maxPossible = 0;

      for (final q in domainQuestions) {
        final score = questionScore(q);
        if (score != null) {
          total += score;
          maxPossible += _maxScoreForQuestion(q);
        }
      }

      final level = _classifyRisk(domain, total, maxPossible);

      results.add(DomainScore(
        domain: domain,
        totalScore: total,
        maxPossible: maxPossible,
        questionCount: domainQuestions.length,
        level: level,
      ));
    }

    return results;
  }

  /// Max possible score for a single question.
  static int _maxScoreForQuestion(UiQuestion q) {
    switch (q.answerKind) {
      case 'SCALE':
        // max index = options.length - 1
        return q.options.isEmpty ? 0 : q.options.length - 1;
      case 'MULTI':
        return q.options.length;
      case 'NUMERIC':
        return 100; // placeholder; depends on question
      default:
        return 0;
    }
  }

  /// Classify risk based on percentage of max score.
  /// Mental health uses PHQ-style thresholds adapted to question count.
  /// Other domains use generic percentage-based thresholds.
  static RiskLevel _classifyRisk(
      String domain, int total, int maxPossible) {
    if (maxPossible == 0) return RiskLevel.none;

    final pct = total / maxPossible;

    // Mental health: tighter thresholds (PHQ-9/GAD-7 inspired)
    if (domain.toUpperCase() == 'MENTAL HEALTH') {
      if (pct < 0.25) return RiskLevel.none;
      if (pct < 0.50) return RiskLevel.mild;
      if (pct < 0.75) return RiskLevel.moderate;
      return RiskLevel.high;
    }

    // Alcohol / Smoking: lower threshold triggers concern
    if (domain.toUpperCase() == 'ALCOHOL' ||
        domain.toUpperCase() == 'SMOKING/VAPING') {
      if (pct < 0.20) return RiskLevel.none;
      if (pct < 0.40) return RiskLevel.mild;
      if (pct < 0.60) return RiskLevel.moderate;
      return RiskLevel.high;
    }

    // Generic domains (dietary, physical activity, women's health)
    if (pct < 0.25) return RiskLevel.none;
    if (pct < 0.50) return RiskLevel.mild;
    if (pct < 0.75) return RiskLevel.moderate;
    return RiskLevel.high;
  }
}
