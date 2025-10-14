class Question {
  final String question;
  final List<String> options;
  final String helpTitle;
  final String helpText;
  Set<int> selected;

  Question({
    required this.question,
    required this.options,
    required this.helpTitle,
    required this.helpText,
    Set<int>? selected,
  }) : selected = selected ?? {};
}