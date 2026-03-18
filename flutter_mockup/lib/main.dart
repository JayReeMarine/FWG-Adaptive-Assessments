import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/env.dart';
import 'screens/survey_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

    // ✅ Fail fast if env not provided
  if (supabaseUrl.isEmpty || supabaseAnon.isEmpty) {
    throw Exception(
      'Missing SUPABASE_URL or SUPABASE_ANON_KEY. '
      'Run with --dart-define to provide them.',
    );
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnon);

  // ✅ Tiny ping to verify DB/RLS
  try {
    final rows = await Supabase.instance.client
        .from('question')
        .select('id')
        .limit(1);
    // ignore: avoid_print
    print('[boot] supabase ok. sample=${rows}');
  } catch (e) {
    // ignore: avoid_print
    print('[boot] supabase failed: $e');
    rethrow;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Survey App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SurveyPage(),
    );
  }
}
