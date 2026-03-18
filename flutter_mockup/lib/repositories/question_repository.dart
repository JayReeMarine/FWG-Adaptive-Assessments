import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/question_dto.dart';
import '../models/scale_dto.dart';
import '../models/ui_question.dart';

class QuestionRepository {
  final SupabaseClient _sp;
  QuestionRepository({SupabaseClient? client})
      : _sp = client ?? Supabase.instance.client;

  /// Fetch ALL active questions.
  Future<List<UiQuestion>> fetchAllQuestions() async {
    final rows = await _sp
        .from('question')
        .select('*')
        .order('id', ascending: true);

    return _mapToUiQuestions(rows as List);
  }

  /// Fetch foundational questions only (period_question = false).
  Future<List<UiQuestion>> fetchFoundational() async {
    final rows = await _sp
        .from('question')
        .select('*')
        .eq('period_question', false)
        .order('id', ascending: true);

    return _mapToUiQuestions(rows as List);
  }

  /// Fetch monthly questions only (period_question = true).
  Future<List<UiQuestion>> fetchMonthly() async {
    final rows = await _sp
        .from('question')
        .select('*')
        .eq('period_question', true)
        .order('id', ascending: true);

    return _mapToUiQuestions(rows as List);
  }

  Future<List<UiQuestion>> _mapToUiQuestions(List rows) async {
    final dtos = rows
        .map((e) => QuestionDto.fromMap(e as Map<String, dynamic>))
        .toList();

    // batch-read scales
    final scaleIds = dtos
        .map((q) => q.scaleId)
        .where((id) => id != null)
        .cast<int>()
        .toSet()
        .toList();

    final Map<int, ScaleDto> scales = {};
    if (scaleIds.isNotEmpty) {
      final sRows = await _sp.from('scale').select('*').inFilter('id', scaleIds);
      for (final r in (sRows as List)) {
        final s = ScaleDto.fromMap(r as Map<String, dynamic>);
        scales[s.id] = s;
      }
    }

    return dtos.map((q) {
      List<String> options = [];

      if (q.answerKind == 'SCALE' || q.answerKind == 'MULTI') {
        final s = q.scaleId != null ? scales[q.scaleId!] : null;
        if (s != null) {
          if (s.labels != null && s.labels!.isNotEmpty) {
            final sorted = s.labels!.entries.toList()
              ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
            options = sorted.map((e) => e.value.toString()).toList();
          } else {
            options = List.generate(
              s.maxValue - s.minValue + 1,
              (i) => (s.minValue + i).toString(),
            );
          }
        }
      }

      return UiQuestion(
        questionId: q.id,
        title: q.text,
        help: q.explanation ?? '',
        options: options,
        answerKind: q.answerKind,
        required: q.required,
        domain: q.domain,
        periodQuestion: q.periodQuestion,
      );
    }).toList();
  }
}
