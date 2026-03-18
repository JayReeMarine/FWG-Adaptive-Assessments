class ScaleDto {
  final int id;
  final int minValue;
  final int maxValue;
  final Map<String, dynamic>? labels; // {"0":"Not at all", "1":"Several days", ...}
  final bool reversed;

  ScaleDto({
    required this.id,
    required this.minValue,
    required this.maxValue,
    required this.labels,
    required this.reversed,
  });

  factory ScaleDto.fromMap(Map<String, dynamic> m) {
    return ScaleDto(
      id: m['id'] as int,
      minValue: (m['min_value'] as int?) ?? 0,
      maxValue: (m['max_value'] as int?) ?? 1,
      labels: m['labels'] as Map<String, dynamic>?,
      reversed: m['reversed'] as bool? ?? false,
    );
  }
}
