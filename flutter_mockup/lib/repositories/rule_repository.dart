import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/branch_rule.dart';

class RuleRepository {
  final SupabaseClient _sp;
  RuleRepository({SupabaseClient? client})
      : _sp = client ?? Supabase.instance.client;

  /// Fetch all branching rules from the `rule` table.
  Future<List<BranchRule>> fetchAll() async {
    final rows = await _sp.from('rule').select('*');
    return (rows as List)
        .map((e) => BranchRule.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
