import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/env.dart';
import 'utils/constants.dart';
import 'screens/home_page.dart';

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
      title: 'Navigator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const HomePage(),
    );
  }
}
