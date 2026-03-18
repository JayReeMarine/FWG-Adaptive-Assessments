import 'package:supabase_flutter/supabase_flutter.dart';

class SessionRepository {
  final SupabaseClient _sp;
  SessionRepository({SupabaseClient? client})
      : _sp = client ?? Supabase.instance.client;

  // Hardcoded user ID until auth is implemented
  static const int defaultUserId = 1;

  /// Create a new session and return its ID.
  Future<int> createSession({
    required int periodMonth,
    required int periodYear,
    int? userId,
  }) async {
    final row = await _sp
        .from('session')
        .insert({
          'user_id': userId ?? defaultUserId,
          'period_month': periodMonth,
          'period_year': periodYear,
        })
        .select('id')
        .single();
    return row['id'] as int;
  }

  /// Save a single response for a question in the current session.
  Future<void> saveResponse({
    required int sessionId,
    required int questionId,
    num? valueNumber,
    int? valueScale,
    Map<String, dynamic>? raw,
  }) async {
    // Upsert: if user goes back and re-answers, update instead of duplicate
    // First check if a response already exists
    final existing = await _sp
        .from('response')
        .select('id')
        .eq('session_id', sessionId)
        .eq('question_id', questionId)
        .maybeSingle();

    if (existing != null) {
      // Update existing response
      await _sp.from('response').update({
        'value_number': valueNumber,
        'value_scale': valueScale,
        'raw': raw,
      }).eq('id', existing['id'] as int);
    } else {
      // Insert new response
      await _sp.from('response').insert({
        'session_id': sessionId,
        'question_id': questionId,
        'value_number': valueNumber,
        'value_scale': valueScale,
        'raw': raw,
      });
    }
  }

  /// Mark session as completed.
  Future<void> completeSession(int sessionId) async {
    await _sp.from('session').update({
      'completed_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', sessionId);
  }
}
