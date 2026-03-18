class QuestionDto {
  final int id;
  final int questionnaireId;
  final String text;
  final String? explanation;
  final bool required;
  final String answerKind;   // 'NUMERIC' | 'SCALE'
  final int? unitId;         // when NUMERIC
  final num? minNumeric;     // when NUMERIC
  final num? maxNumeric;     // when NUMERIC
  final int? precisionDp;    // when NUMERIC
  final bool periodQuestion;
  final int? scaleId;        // when SCALE
  final String? domain;      // 'mental' | 'diet' | 'activity' | 'women_health' | 'alcohol'
  final bool branching;      // true if this question triggers branching rules

  QuestionDto({
    required this.id,
    required this.questionnaireId,
    required this.text,
    this.explanation,
    required this.required,
    required this.answerKind,
    this.unitId,
    this.minNumeric,
    this.maxNumeric,
    this.precisionDp,
    required this.periodQuestion,
    this.scaleId,
    this.domain,
    this.branching = false,
  });

  factory QuestionDto.fromMap(Map<String, dynamic> m) {
    return QuestionDto(
      id: m['id'] as int,
      questionnaireId: m['questionnaire_id'] as int,
      text: (m['text'] ?? '') as String,
      explanation: m['explanation'] as String?,
      required: m['required'] as bool,
      answerKind: m['answer_kind'] as String,
      unitId: m['unit_id'] as int?,
      minNumeric: m['min_numeric'] as num?,
      maxNumeric: m['max_numeric'] as num?,
      precisionDp: m['precision_dp'] as int?,
      periodQuestion: m['period_question'] as bool? ?? false,
      scaleId: m['scale_id'] as int?,
      domain: m['domain'] as String?,
      branching: m['branching'] as bool? ?? false,
    );
  }
}
