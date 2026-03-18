// This is a view-friendly model to keep UI simple and decoupled from DB schema.
class UiQuestion {
  final int questionId;        // DB question.id — needed to save responses
  final String title;          // question text
  final String help;           // explanation/help text
  final List<String> options;  // rendered choices for current widget
  final String answerKind;     // hint for widget switching (numeric vs scale)
  final bool required;
  final String? domain;        // 'mental' | 'diet' | 'activity' | etc.
  final bool periodQuestion;   // false = foundational, true = monthly/periodic

  // state kept in UI layer
  final Set<int> selected;
  num? numericAnswer;          // for NUMERIC type answers

  UiQuestion({
    required this.questionId,
    required this.title,
    required this.help,
    required this.options,
    required this.answerKind,
    required this.required,
    this.domain,
    this.periodQuestion = false,
    Set<int>? selected,
    this.numericAnswer,
  }) : selected = selected ?? <int>{};

  /// Returns the user's answer in a format suitable for rule evaluation.
  /// For SCALE: returns the selected index (int).
  /// For MULTI: returns count of selected items (int).
  /// For NUMERIC: returns the numeric value (num).
  /// Returns null if unanswered.
  dynamic get answer {
    if (answerKind == 'SCALE' && selected.isNotEmpty) {
      return selected.first;
    }
    if (answerKind == 'MULTI' && selected.isNotEmpty) {
      return selected.length; // number of selections
    }
    if (answerKind == 'NUMERIC' && numericAnswer != null) {
      return numericAnswer;
    }
    return null;
  }

  bool get isAnswered => answer != null;
}
