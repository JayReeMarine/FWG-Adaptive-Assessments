import 'package:supabase_flutter/supabase_flutter.dart';

/// Session types used to distinguish foundational vs monthly assessments.
enum SurveyType { foundational, monthly }

class SessionRepository {
  final SupabaseClient _sp;
  SessionRepository({SupabaseClient? client})
      : _sp = client ?? Supabase.instance.client;

  // Hardcoded user ID until auth is implemented
  static const int defaultUserId = 1;

  /// Check if the user has completed a foundational assessment.
  Future<bool> hasCompletedFoundational({int? userId}) async {
    final row = await _sp
        .from('session')
        .select('id')
        .eq('user_id', userId ?? defaultUserId)
        .eq('period_month', 0) // month=0 indicates foundational
        .not('completed_at', 'is', null)
        .maybeSingle();
    return row != null;
  }

  /// Check if the user has already completed a monthly session for a given month/year.
  Future<bool> hasCompletedMonthly({
    required int month,
    required int year,
    int? userId,
  }) async {
    final row = await _sp
        .from('session')
        .select('id')
        .eq('user_id', userId ?? defaultUserId)
        .eq('period_month', month)
        .eq('period_year', year)
        .not('completed_at', 'is', null)
        .maybeSingle();
    return row != null;
  }

  /// Determine what the user should do next.
  /// Returns the survey type and the target month/year for monthly.
  Future<({SurveyType type, int month, int year})> getNextSurvey({
    int? userId,
  }) async {
    final foundationalDone = await hasCompletedFoundational(userId: userId);
    if (!foundationalDone) {
      return (type: SurveyType.foundational, month: 0, year: 0);
    }

    // Find the next month that hasn't been completed
    final now = DateTime.now();
    final completed = await hasCompletedMonthly(
      month: now.month,
      year: now.year,
      userId: userId,
    );

    if (!completed) {
      return (type: SurveyType.monthly, month: now.month, year: now.year);
    }

    // Current month is done — show next month (for testing/demo)
    final nextMonth = now.month == 12 ? 1 : now.month + 1;
    final nextYear = now.month == 12 ? now.year + 1 : now.year;
    return (type: SurveyType.monthly, month: nextMonth, year: nextYear);
  }

  /// Create a new session and return its ID.
  /// For foundational: use periodMonth=0, periodYear=0.
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
    final existing = await _sp
        .from('response')
        .select('id')
        .eq('session_id', sessionId)
        .eq('question_id', questionId)
        .maybeSingle();

    if (existing != null) {
      await _sp.from('response').update({
        'value_number': valueNumber,
        'value_scale': valueScale,
        'raw': raw,
      }).eq('id', existing['id'] as int);
    } else {
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
