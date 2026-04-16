// test_llm.dart — standalone Gemini API test (run from project root)
// Usage: dart run test_llm.dart <GEMINI_API_KEY>

import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final apiKey = args.isNotEmpty ? args[0] : Platform.environment['GEMINI_API_KEY'] ?? '';
  if (apiKey.isEmpty) {
    print('Usage: dart run test_llm.dart <GEMINI_API_KEY>');
    exit(1);
  }

  print('=== Gemini LLM Service Test ===\n');

  // ── Mock sophieSeed ────────────────────────────────────────────────────────
  final seed = {
    'version': 'Month 1',
    'demographics': {
      'age': 24,
      'gender': 'Female',
      'background': 'East Asian international student',
      'occupation': 'University student',
    },
    'domainRiskLevels': {
      'MENTAL HEALTH': 'mild',
      'DIETARY': 'none',
      'PHYSICAL ACTIVITY': 'none',
      'ALCOHOL': 'none',
      'SMOKING/VAPING': 'none',
      'WOMEN HEALTH': 'none',
    },
    'contextNotes': [
      'Reported low mood on several days (Q18 score = 1)',
      'Isolation score was low and stable (Q20 score = 0)',
      'No functional impact reported in Month 1 (Q39 not triggered)',
      'Two-month persistent mild pattern — longitudinal signal not captured by baseline',
    ],
  };

  // ── Mock baseline MH questions (from Questionnaire v4 monthly flow) ───────
  final baselineQuestions = [
    {'id': 18, 'text': 'In the past month, have you felt low in mood, sad, hopeless, nervous, worried, or restless?', 'options': 'Not at all / Several days / More than half the days / Nearly every day'},
    {'id': 19, 'text': 'In the past month, how often have you felt that important things in your life were difficult to manage?', 'options': 'Never / Rarely / Sometimes / Often / Always'},
    {'id': 20, 'text': 'In the past month, how often do you feel isolated from others?', 'options': 'Not at all / Several days / More than half the days / Nearly every day'},
    {'id': 39, 'text': '[BLOCKED by Rule 13] In the past month, have these feelings made it harder for you to manage your work, daily tasks, or relationships?', 'options': 'No / Yes'},
  ];

  final baselineLines = baselineQuestions
      .map((q) => '  [Q${q['id']}] ${q['text']}\n  Options: ${q['options']}')
      .join('\n\n');

  // ── Prompt ─────────────────────────────────────────────────────────────────
  final prompt = '''
You are an adaptive health assessment engine for a research project comparing rule-based vs LLM-based health questionnaires.

Your task is to generate personalised Month 2 mental health questions for the user described below. The questions must be meaningfully better than the rule-based baseline — more relevant, clearer, and less repetitive — based on the user\'s Month 1 health snapshot.

═══════════════════════════════════════
USER SEED — Month 1 health snapshot
═══════════════════════════════════════
${const JsonEncoder.withIndent('  ').convert(seed)}

═══════════════════════════════════════
BASELINE QUESTIONS — rule-based system (Month 2)
═══════════════════════════════════════
$baselineLines

═══════════════════════════════════════
RULES — what your enhanced version must do
═══════════════════════════════════════
1. REPHRASE Q18: Reference the Month 1 history explicitly. The user reported low mood "on several days" last month. Acknowledge this continuity so the user feels the system remembers them.

2. REPHRASE Q19: Replace the vague phrase "important things in your life" with occupation-specific language. This user is a university student — use "studies, daily responsibilities, or relationships" instead.

3. ADD a new trend-direction question (use questionId: -1): The user has had two consecutive months of Mild Mental Health risk. Add a question asking whether things are getting better, about the same, or getting worse. This captures longitudinal signal the rule-based system cannot detect.

4. INCLUDE Q39 (functional impact): Even though the single-month Q18 score (= 1, "Several days") does not meet the rule threshold of ≥2, the two-month persistent pattern justifies surfacing this question early. Adapt the phrasing to match this user\'s student context.

5. SKIP Q20 (isolation question): The seed shows Q20 was low and stable in Month 1. Do not include it — no new information is expected.

For each question, write a short "help" string explaining why this version was chosen over the baseline (2–3 sentences).

═══════════════════════════════════════
OUTPUT — return ONLY valid JSON, no markdown, no explanation
═══════════════════════════════════════
Return a JSON array where each object has these fields:
{
  "questionId": <integer — use the DB question id, or -1 for the new trend question>,
  "title": "<the question text shown to the user>",
  "help": "<brief explanation of why this enhanced version was chosen>",
  "options": ["<option 1>", "<option 2>", ...],
  "answerKind": "SCALE"
}
''';

  // ── Call Gemini REST API ───────────────────────────────────────────────────
  final url = Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
  );

  final body = jsonEncode({
    'contents': [
      {
        'parts': [
          {'text': prompt}
        ]
      }
    ],
    'generationConfig': {
      'temperature': 0.3,
      'responseMimeType': 'application/json',
    },
  });

  print('Calling Gemini API...\n');

  final client = HttpClient();
  try {
    final request = await client.postUrl(url);
    request.headers.set('Content-Type', 'application/json; charset=utf-8');
    request.add(utf8.encode(body));
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode != 200) {
      print('ERROR ${response.statusCode}: $responseBody');
      exit(1);
    }

    final json = jsonDecode(responseBody) as Map<String, dynamic>;
    final raw = (json['candidates'] as List).first['content']['parts'].first['text'] as String;

    // Strip markdown fences if present
    var clean = raw.trim();
    if (clean.startsWith('```')) {
      clean = clean.replaceFirst(RegExp(r'^```[a-z]*\n?'), '');
      clean = clean.replaceFirst(RegExp(r'\n?```$'), '');
    }

    // ── Parse and display ──────────────────────────────────────────────────
    final questions = jsonDecode(clean) as List<dynamic>;

    print('✅ SUCCESS — ${questions.length} enhanced questions generated:\n');
    print('─' * 60);

    for (var i = 0; i < questions.length; i++) {
      final q = questions[i] as Map<String, dynamic>;
      final qId = q['questionId'];
      final label = qId == -1 ? 'NEW (trend)' : 'Q$qId';
      print('[$label]');
      print('Title  : ${q['title']}');
      print('Options: ${(q['options'] as List).join(' / ')}');
      print('Why    : ${q['help']}');
      print('─' * 60);
    }

  } finally {
    client.close();
  }
}
