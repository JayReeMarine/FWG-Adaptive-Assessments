import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/scoring_service.dart';
import 'session_repository.dart';

class FlagRepository {
  final SupabaseClient _sp;
  FlagRepository({SupabaseClient? client})
      : _sp = client ?? Supabase.instance.client;

  /// Save risk flags for all scored domains after session completion.
  /// Each domain gets one flag row with its risk level and score details.
  Future<void> saveFlags({
    required int sessionId,
    required List<DomainScore> scores,
    int? userId,
  }) async {
    final uid = userId ?? SessionRepository.defaultUserId;

    for (final score in scores) {
      await _sp.from('flag').insert({
        'user_id': uid,
        'session_id': sessionId,
        'domain': score.domain,
        'level': score.level.name,
        'details': score.toJson(),
      });
    }

    print('[FlagRepo] saved ${scores.length} flags for session=$sessionId');
  }

  /// Get the latest flags for a user (most recent session).
  Future<List<Map<String, dynamic>>> getLatestFlags({int? userId}) async {
    final uid = userId ?? SessionRepository.defaultUserId;

    final rows = await _sp
        .from('flag')
        .select('*')
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(10);

    return List<Map<String, dynamic>>.from(rows);
  }
}
