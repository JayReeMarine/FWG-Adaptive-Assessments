// This is a view-friendly model to keep UI simple and decoupled from DB schema.
class UiQuestion {
  final int questionId;        // DB question.id — needed to save responses
  final String title;          // question text
  final String help;           // explanation/help text
  final List<String> options;  // rendered choices for current widget
  final String answerKind;     // hint for widget switching (numeric vs scale)
  final bool required;

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
    Set<int>? selected,
    this.numericAnswer,
  }) : selected = selected ?? <int>{};
}
