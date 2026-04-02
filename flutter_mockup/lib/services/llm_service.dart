// ─────────────────────────────────────────────────────────────────────────────
// llm_service.dart
//
// Generates enhanced Mental Health questions using Google Gemini (free tier).
//
// Takes a UserSeed (Month 1 health snapshot) and the baseline monthly MH
// questions, sends them to Gemini with a structured prompt, and parses the
// response into a List<UiQuestion> ready for SurveyPage.
//
// Falls back to the hardcoded mock path (comparison_scenario.dart) if:
//   - GEMINI_API_KEY is not set
//   - the API call fails for any reason
//   - the JSON response cannot be parsed
//
// Free tier limits (Gemini 1.5 Flash):
//   15 requests/minute · 1 million tokens/day · 0 cost
//   Get your key at: https://aistudio.google.com/apikey
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/ui_question.dart';
import '../config/comparison_scenario.dart';
import '../core/config/env.dart';

class LlmService {
  static const _modelName = 'gemini-2.5-flash';

  // ─── Public API ─────────────────────────────────────────────────────────────

  /// Generates personalised Month 2 Mental Health questions from the user's Seed.
  ///
  /// [seed]             - the user's Month 1 health snapshot (e.g. alexSeed)
  /// [baselineMhQuestions] - the baseline monthly MH questions from the DB,
  ///                         used so the LLM knows what it is improving on.
  ///
  /// Returns a [List<UiQuestion>] ready to be prepended to the monthly survey.
  /// Automatically falls back to the hardcoded mock on any failure.
  static Future<List<UiQuestion>> generateEnhancedMentalHealthQuestions(
    UserSeed seed,
    List<UiQuestion> baselineMhQuestions,
  ) async {
    if (geminiApiKey.isEmpty) {
      // ignore: avoid_print
      print('[LlmService] GEMINI_API_KEY not set — using hardcoded fallback');
      return buildEnhancedMentalHealthQuestions();
    }

    try {
      final model = GenerativeModel(
        model: _modelName,
        apiKey: geminiApiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.3, // low temperature = more consistent, structured output
        ),
      );

      final prompt = _buildPrompt(seed, baselineMhQuestions);
      // ignore: avoid_print
      print('[LlmService] Sending prompt to Gemini...');

      final response = await model.generateContent([Content.text(prompt)]);
      final raw = response.text ?? '';

      // ignore: avoid_print
      print('[LlmService] Response received (${raw.length} chars)');

      final questions = _parseResponse(raw);
      // ignore: avoid_print
      print('[LlmService] Parsed ${questions.length} enhanced questions');
      return questions;
    } catch (e) {
      // ignore: avoid_print
      print('[LlmService] Failed: $e — using hardcoded fallback');
      return buildEnhancedMentalHealthQuestions();
    }
  }

  // ─── Prompt builder ─────────────────────────────────────────────────────────

  static String _buildPrompt(UserSeed seed, List<UiQuestion> baselineQs) {
    // Serialise the seed into readable JSON for the prompt
    final seedContext = {
      'version': seed.version,
      'demographics': {
        'age': seed.demographics.age,
        'gender': seed.demographics.gender,
        'background': seed.demographics.background,
        'occupation': seed.demographics.occupation,
      },
      'domainRiskLevels': seed.domainRiskLevels,
      'contextNotes': seed.contextNotes,
    };

    // Format the baseline questions clearly for the model
    final baselineLines = baselineQs.map((q) {
      return '  [Q${q.questionId}] ${q.title}\n'
          '  Options: ${q.options.join(' / ')}';
    }).join('\n\n');

    return '''
You are an adaptive health assessment engine for a research project comparing rule-based vs LLM-based health questionnaires.

Your task is to generate personalised Month 2 mental health questions for the user described below. The questions must be meaningfully better than the rule-based baseline — more relevant, clearer, and less repetitive — based on the user's Month 1 health snapshot.

═══════════════════════════════════════
USER SEED — Month 1 health snapshot
═══════════════════════════════════════
${const JsonEncoder.withIndent('  ').convert(seedContext)}

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

4. INCLUDE Q39 (functional impact): Even though the single-month Q18 score (= 1, "Several days") does not meet the rule threshold of ≥2, the two-month persistent pattern justifies surfacing this question early. Adapt the phrasing to match this user's student context (e.g., "attending classes" instead of generic "work").

5. SKIP Q20 (isolation question): The seed shows Q20 was low and stable in Month 1 ("isolation score was low and stable"). Do not include it — no new information is expected.

For each question, write a short "help" string explaining why this version was chosen over the baseline (2–3 sentences, plain language).

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
  }

  // ─── Response parser ─────────────────────────────────────────────────────────

  static List<UiQuestion> _parseResponse(String raw) {
    // Strip markdown code fences if the model added them despite the instruction
    var clean = raw.trim();
    if (clean.startsWith('```')) {
      clean = clean.replaceFirst(RegExp(r'^```[a-z]*\n?'), '');
      clean = clean.replaceFirst(RegExp(r'\n?```$'), '');
    }

    final List<dynamic> parsed = jsonDecode(clean) as List<dynamic>;

    return parsed.map((item) {
      final map = item as Map<String, dynamic>;
      return UiQuestion(
        questionId: (map['questionId'] as num).toInt(),
        title: map['title'] as String,
        help: (map['help'] as String?) ?? '',
        options: (map['options'] as List<dynamic>).cast<String>(),
        answerKind: (map['answerKind'] as String?) ?? 'SCALE',
        required: true,
        domain: 'MENTAL HEALTH',
        periodQuestion: true,
      );
    }).toList();
  }
}
