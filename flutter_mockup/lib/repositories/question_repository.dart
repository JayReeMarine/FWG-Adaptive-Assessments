import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/question_dto.dart';
import '../models/scale_dto.dart';
import '../models/ui_question.dart';

class QuestionRepository {
  final SupabaseClient _sp;
  QuestionRepository({SupabaseClient? client})
      : _sp = client ?? Supabase.instance.client;

  Future<void> resetQuestionnaireId({bool all = false}) async {
    try {
      if (all) {
        await _sp
            .from('question')
            .update({'questionnaire_id': 1})
            .filter('questionnaire_id', 'is', null);
        return;
      } 

      await _sp
          .from('question')
          .update({'questionnaire_id': 1})
          .eq('period_question', true)
          .filter('questionnaire_id', 'is', null);
    

    } catch (e) {
      print('Error updating questionnaire id: $e');
    }
  }

  // Fetch questions by questionnaire and map them to UiQuestion
  Future<List<UiQuestion>> fetchByQuestionnaire(int questionnaireId) async {
    // 1) read questions
    final rows = await _sp
        .from('question')
        .select('*')
        .eq('questionnaire_id', questionnaireId)
        .order('id', ascending: true)
        .limit(6);

    final dtos = (rows as List)
        .map((e) => QuestionDto.fromMap(e as Map<String, dynamic>))
        .toList();
  
    await _sp
        .from('question')
        .update({'questionnaire_id': null}) 
        .inFilter('id', dtos.map((q) => q.id).toList());
    
    if ((rows as List).length < 6) {
      resetQuestionnaireId(all: true);
    }

    if (rows.isEmpty) {
      return fetchByQuestionnaire(questionnaireId);
    }

    // 2) batch-read scales (only for SCALE)
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

    // 3) map DTO → UiQuestion
    return dtos.map((q) {
      List<String> options = [];

      if (q.answerKind == 'SCALE') {
        final s = q.scaleId != null ? scales[q.scaleId!] : null;
        if (s != null) {
          // If labels exist, use them in key order; otherwise generate numbers
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
      } else {
        // NUMERIC: show simple “ticks” for now (UI can switch to TextField later)
        final min = (q.minNumeric ?? 0).toDouble();
        final max = (q.maxNumeric ?? 10).toDouble();
        final steps = 5; // simple equally spaced ticks for display
        final step = steps > 0 ? (max - min) / steps : 1;
        final values = <double>[];
        for (var i = 0; i <= steps; i++) {
          values.add((min + step * i));
        }
        options = values.map((v) {
          final dp = (q.precisionDp ?? 0);
          return v.toStringAsFixed(dp.clamp(0, 6));
        }).toList();
      }

      return UiQuestion(
        title: q.text,
        help: q.explanation ?? '',
        options: options,
        answerKind: q.answerKind,
        required: q.required,
      );
    }).toList();
  }
}
