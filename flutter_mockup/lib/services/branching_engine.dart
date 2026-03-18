import '../models/branch_rule.dart';
import '../models/ui_question.dart';

/// The BranchingEngine evaluates branching rules against user answers
/// and determines which questions should be visible.
///
/// Flow:
/// 1. All questions are loaded.
/// 2. Questions that are "show" targets of any rule start HIDDEN.
/// 3. When a trigger question is answered, rules are re-evaluated.
/// 4. If a rule's condition is met → its "show" targets become visible.
/// 5. If a rule's condition is NOT met → its "show" targets stay hidden.
class BranchingEngine {
  final List<BranchRule> rules;

  /// Set of question IDs that are conditionally shown (hidden by default).
  /// These are all question IDs that appear in any rule's "show" list.
  late final Set<int> _conditionalIds;

  /// Map: triggerQuestionId → list of rules triggered by that question.
  late final Map<int, List<BranchRule>> _rulesByTrigger;

  BranchingEngine({required this.rules}) {
    // Build lookup structures
    _conditionalIds = <int>{};
    _rulesByTrigger = {};

    for (final rule in rules) {
      _conditionalIds.addAll(rule.showIds);

      _rulesByTrigger
          .putIfAbsent(rule.triggerQuestionId, () => [])
          .add(rule);
    }
  }

  /// Given all questions and current answers, return the list of
  /// questions that should be visible right now.
  ///
  /// [allQuestions] — the full question list from DB.
  /// The engine reads each question's `.answer` property to evaluate rules.
  List<UiQuestion> getVisibleQuestions(List<UiQuestion> allQuestions) {
    // Build a lookup: questionId → answer
    final answers = <int, dynamic>{};
    for (final q in allQuestions) {
      if (q.isAnswered) {
        answers[q.questionId] = q.answer;
      }
    }

    // Determine which conditional questions should be shown
    final shownByRules = <int>{};
    final hiddenByRules = <int>{};

    for (final rule in rules) {
      final triggerAnswer = answers[rule.triggerQuestionId];
      final conditionMet = rule.evaluate(triggerAnswer);

      if (conditionMet) {
        shownByRules.addAll(rule.showIds);
        hiddenByRules.addAll(rule.hideIds);
      }
    }

    // Filter questions
    return allQuestions.where((q) {
      // If this question is explicitly hidden by an active rule, hide it
      if (hiddenByRules.contains(q.questionId)) return false;

      // If this question is a conditional target (in some rule's "show" list),
      // only show it if an active rule says to show it
      if (_conditionalIds.contains(q.questionId)) {
        return shownByRules.contains(q.questionId);
      }

      // Otherwise, always show
      return true;
    }).toList();
  }

  /// Check if a specific question ID is a trigger for any rule.
  bool isTrigger(int questionId) => _rulesByTrigger.containsKey(questionId);
}
