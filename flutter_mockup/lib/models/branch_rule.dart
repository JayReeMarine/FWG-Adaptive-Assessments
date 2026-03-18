/// Represents a branching rule loaded from the `rule` table.
///
/// expression example:  {"op": ">=", "value": 1}
///   → "if the trigger question's answer >= 1"
///
/// target_action example: {"show": [101, 102], "hide": [103]}
///   → show question IDs 101 & 102, hide 103
class BranchRule {
  final int id;
  final String name;
  final int triggerQuestionId;
  final Map<String, dynamic> expression;
  final Map<String, dynamic> targetAction;

  BranchRule({
    required this.id,
    required this.name,
    required this.triggerQuestionId,
    required this.expression,
    required this.targetAction,
  });

  factory BranchRule.fromMap(Map<String, dynamic> m) {
    return BranchRule(
      id: m['id'] as int,
      name: (m['name'] ?? '') as String,
      triggerQuestionId: m['trigger_question_id'] as int,
      expression: m['expression'] as Map<String, dynamic>? ?? {},
      targetAction: m['target_action'] as Map<String, dynamic>? ?? {},
    );
  }

  /// IDs of questions to show when condition is met.
  List<int> get showIds =>
      (targetAction['show'] as List<dynamic>?)?.cast<int>() ?? [];

  /// IDs of questions to hide when condition is met.
  List<int> get hideIds =>
      (targetAction['hide'] as List<dynamic>?)?.cast<int>() ?? [];

  /// Evaluate the rule's expression against a given answer value.
  /// Returns true if the condition is satisfied.
  bool evaluate(dynamic answerValue) {
    if (answerValue == null) return false;

    final op = expression['op'] as String?;
    final ruleValue = expression['value'];

    if (op == null || ruleValue == null) return false;

    // Convert both to num for comparison if possible
    final num? a = _toNum(answerValue);
    final num? b = _toNum(ruleValue);

    switch (op) {
      case '==':
        return a != null && b != null ? a == b : answerValue == ruleValue;
      case '!=':
        return a != null && b != null ? a != b : answerValue != ruleValue;
      case '>':
        return a != null && b != null && a > b;
      case '>=':
        return a != null && b != null && a >= b;
      case '<':
        return a != null && b != null && a < b;
      case '<=':
        return a != null && b != null && a <= b;
      case 'any':
        // "any" means: answer is not null / not empty → condition is met
        return true;
      default:
        return false;
    }
  }

  static num? _toNum(dynamic v) {
    if (v is num) return v;
    if (v is String) return num.tryParse(v);
    return null;
  }
}
