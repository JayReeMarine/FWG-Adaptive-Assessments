// ─────────────────────────────────────────────────────────────────────────────
// comparison_scenario.dart
//
// Defines the hardcoded Mental Health comparison scenario used to demonstrate
// baseline vs enhanced adaptive questioning.
//
// This file is the research comparison config — it is intentionally separate
// from the live BranchingEngine so that the baseline DB logic is not modified.
//
// User profile (seed):
//   Alex — 24F, East Asian international student
//   Month 1 result: Mental Health risk = Mild
//   Month 2 context: same or slightly worsening trend
//
// The UserSeed class below mirrors the FWG "Seed" architecture concept:
// a distilled, immutable snapshot of a user's health baseline used to
// initialise adaptive assessment engines.  In this prototype it is a mock
// (hardcoded), but the shape matches what a real seed would look like.
//
// Step 4 / 5 / 6 of FYP research comparison work.
// ─────────────────────────────────────────────────────────────────────────────

import '../models/ui_question.dart';

// ─── UserSeed — FWG Seed architecture mock ───────────────────────────────────

/// A structured snapshot of a user's health baseline.
///
/// In the FWG Seed concept a Seed is:
///   - Immutable once created for a given period
///   - Versioned longitudinally (one seed per month)
///   - Used to initialise adaptive assessment inference and guidance engines
///
/// This class is a *mock* implementation for the research comparison demo.
/// It holds only the fields relevant to the Mental Health scenario.
class UserSeed {
  /// Unique user identifier (placeholder — auth not yet implemented).
  final String userId;

  /// Seed version label, e.g. "Month 1", "Month 2".
  final String version;

  /// User demographic context used for question personalisation.
  final UserDemographics demographics;

  /// Domain risk levels from the previous assessment period.
  final Map<String, String> domainRiskLevels;

  /// Free-form context notes surfaced to the adaptive engine.
  final List<String> contextNotes;

  const UserSeed({
    required this.userId,
    required this.version,
    required this.demographics,
    required this.domainRiskLevels,
    required this.contextNotes,
  });
}

class UserDemographics {
  final int age;
  final String gender;
  final String background;
  final String occupation;

  const UserDemographics({
    required this.age,
    required this.gender,
    required this.background,
    required this.occupation,
  });
}

// ─── Alex's Month 1 Seed (mock) ──────────────────────────────────────────────

/// The hardcoded seed representing Alex's health baseline after Month 1.
///
/// This seed is what the enhanced adaptive engine would consume at the start
/// of Month 2 to personalise question selection and phrasing.
const alexSeed = UserSeed(
  userId: 'mock-alex-001',
  version: 'Month 1',
  demographics: UserDemographics(
    age: 24,
    gender: 'Female',
    background: 'East Asian international student',
    occupation: 'University student',
  ),
  domainRiskLevels: {
    'MENTAL HEALTH': 'mild',       // persistent — same in Month 2
    'DIETARY': 'none',
    'PHYSICAL ACTIVITY': 'none',
    'ALCOHOL': 'none',
    'SMOKING/VAPING': 'none',
    'WOMEN HEALTH': 'none',
  },
  contextNotes: [
    'Reported low mood on several days (Q18 score = 1)',
    'Isolation score was low and stable (Q20 score = 0)',
    'No functional impact reported in Month 1 (Q39 not triggered)',
    'Two-month persistent mild pattern — longitudinal signal not captured by baseline',
  ],
);

/// Describes the Mental Health domain questions for ONE monthly check-in
/// under the baseline rule-based system, for Alex's Month 2 run.
///
/// These are the questions the BranchingEngine would return:
///   ID 18 — mood frequency (SCALE, scale_id=1)
///   ID 19 — manage important things (SCALE, scale_id=4)
///   ID 20 — isolated from others (SCALE, scale_id=1)
///   ID 39 — functional impact  [only shown if Q18 >= 2, per Rule 13]
///
/// In Alex's scenario: Q18 answer = 1 (Several days) → Rule 13 NOT triggered
///   → Q39 is HIDDEN.  This is the core limitation the enhanced version fixes.
const baselineMentalHealthPath = [
  _BaselineQuestion(
    id: 18,
    text: 'In the past month, how often have you felt low mood, sad, '
        'hopeless, nervous, worried, or restless?',
    options: ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'],
    note: 'Generic — identical phrasing every month for every user.',
  ),
  _BaselineQuestion(
    id: 19,
    text: 'In the past month, how often have you felt that important things '
        'in your life were difficult to manage?',
    options: ['Never', 'Rarely', 'Sometimes', 'Often', 'Always'],
    note: 'No context from Month 1. "Important things" is vague.',
  ),
  _BaselineQuestion(
    id: 20,
    text: 'In the past month, how often do you feel isolated from others?',
    options: ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'],
    note: 'Same as Month 1. Not skipped even if Month 1 score was low.',
  ),
  _BaselineQuestion(
    id: 39,
    text: '[HIDDEN — functional impact question not shown because '
        'Alex\'s Q18 score = 1 (Several days), which is below the ≥2 threshold '
        'required by Rule 13. Even though two months of Mild scores indicate a '
        'persistent pattern, this question is never surfaced.]',
    options: [],
    note: 'Hard threshold blocks this question. No longitudinal awareness.',
    blocked: true,
  ),
];

/// Describes the Mental Health domain questions for the SAME monthly check-in
/// under the MOCK enhanced adaptive system, for Alex's Month 2 run.
///
/// Key differences from baseline:
///   1. Q18 phrasing references Month 1 history ("you reported…")
///   2. Q19 phrasing adapted for student context ("studies, responsibilities")
///   3. New question: trend direction (getting better / same / worse)
///   4. Q39 unlocked early based on two-month pattern, not hard score threshold
///   5. Q20 skipped — low & stable score from Month 1, no new information
const enhancedMentalHealthPath = [
  _EnhancedQuestion(
    id: 18,
    text: 'Over the past month, have you continued to experience feelings like '
        'low mood, worry, or restlessness? Last month you reported this '
        'happening on several days.',
    options: ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'],
    why: 'References Month 1. Acknowledges continuity rather than repeating '
        'the same generic question.',
  ),
  _EnhancedQuestion(
    id: 19,
    text: 'In the past month, has it felt harder than usual to stay on top '
        'of your studies, daily responsibilities, or relationships?',
    options: ['Never', 'Rarely', 'Sometimes', 'Often', 'Always'],
    why: 'Student-specific phrasing ("studies, responsibilities") replaces '
        'the vague "important things in your life". More relevant to Alex\'s context.',
  ),
  _EnhancedQuestion(
    id: -1, // mock — not yet in DB
    text: 'Since you\'ve reported similar feelings for two months in a row, '
        'how would you describe the change over the past month?',
    options: ['Getting better', 'About the same', 'Getting worse'],
    why: 'New trend-direction question triggered by two-month persistent pattern. '
        'Not based on a single-month score threshold. '
        'Captures longitudinal signal the baseline cannot detect.',
  ),
  _EnhancedQuestion(
    id: 39,
    text: 'Have these feelings made it harder for you to manage your daily life — '
        'for example, attending classes, completing work, or maintaining relationships?',
    options: ['No', 'Yes'],
    why: 'Unlocked early because of the two-month Mild pattern, even though '
        'the single-month score does not meet the ≥2 threshold. '
        'Student-specific examples replace generic "work, daily tasks".',
  ),
  // Q20 (isolation) is deliberately skipped:
  // Alex's Month 1 isolation score was low and stable.
  // The enhanced system de-prioritises questions unlikely to yield new information.
];

// ─── Evaluation summary ───────────────────────────────────────────────────────

/// Comparison of baseline vs enhanced for each of Zach's 6 evaluation dimensions.
const comparisonSummary = [
  _Dimension(
    name: 'Relevance',
    baseline: 'Generic questions for all users at any month',
    enhanced: 'Questions adapted to student context and Month 1 history',
  ),
  _Dimension(
    name: 'Clarity',
    baseline: 'Clinical phrasing — "important things in your life were difficult to manage"',
    enhanced: 'Contextualised — "studies, daily responsibilities, or relationships"',
  ),
  _Dimension(
    name: 'Non-repetitiveness',
    baseline: 'Q20 asked every month regardless of prior low stable score',
    enhanced: 'Q20 skipped — no new information expected based on Month 1',
  ),
  _Dimension(
    name: 'Logical progression',
    baseline: 'Three standalone questions, no narrative link',
    enhanced: 'Q1 references Month 1 → trend Q → functional impact Q',
  ),
  _Dimension(
    name: 'Perceived adaptiveness',
    baseline: 'No indication the system knows the user\'s history',
    enhanced: 'Q1 explicitly acknowledges Month 1: "Last month you reported…"',
  ),
  _Dimension(
    name: 'Sensitivity / appropriateness',
    baseline: 'Identical clinical wording for all cultural backgrounds',
    enhanced: 'Softer tone reduces stigma barrier; student context reduces alienation',
  ),
];

// ─── Data classes (plain Dart — no Flutter dependencies) ─────────────────────

class _BaselineQuestion {
  final int id;
  final String text;
  final List<String> options;
  final String note;
  final bool blocked;
  const _BaselineQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.note,
    this.blocked = false,
  });
}

class _EnhancedQuestion {
  final int id;
  final String text;
  final List<String> options;
  final String why;
  const _EnhancedQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.why,
  });
}

class _Dimension {
  final String name;
  final String baseline;
  final String enhanced;
  const _Dimension({
    required this.name,
    required this.baseline,
    required this.enhanced,
  });
}

// ─── UiQuestion builders (for use in SurveyPage enhanced mode) ───────────────

/// Builds the list of UiQuestion objects for the enhanced Mental Health path.
/// Called by SurveyPage when SurveyMode.enhanced is active.
List<UiQuestion> buildEnhancedMentalHealthQuestions() {
  final scale0to3 = ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'];
  final scale0to4 = ['Never', 'Rarely', 'Sometimes', 'Often', 'Always'];
  final trendScale = ['Getting better', 'About the same', 'Getting worse'];
  final yesNo = ['No', 'Yes'];

  return [
    UiQuestion(
      questionId: 18,
      title: 'Over the past month, have you continued to experience feelings like '
          'low mood, worry, or restlessness? Last month you reported this '
          'happening on several days.',
      help: 'Enhanced: references your Month 1 report.',
      options: scale0to3,
      answerKind: 'SCALE',
      required: true,
      domain: 'MENTAL HEALTH',
      periodQuestion: true,
    ),
    UiQuestion(
      questionId: 19,
      title: 'In the past month, has it felt harder than usual to stay on top '
          'of your studies, daily responsibilities, or relationships?',
      help: 'Enhanced: adapted for student context.',
      options: scale0to4,
      answerKind: 'SCALE',
      required: true,
      domain: 'MENTAL HEALTH',
      periodQuestion: true,
    ),
    UiQuestion(
      questionId: -1, // mock trend question — not in DB yet
      title: 'Since you\'ve reported similar feelings for two months in a row, '
          'how would you describe the change over the past month?',
      help: 'Enhanced: triggered by two-month persistent pattern.',
      options: trendScale,
      answerKind: 'SCALE',
      required: true,
      domain: 'MENTAL HEALTH',
      periodQuestion: true,
    ),
    UiQuestion(
      questionId: 39,
      title: 'Have these feelings made it harder for you to manage your daily life — '
          'for example, attending classes, completing work, or maintaining relationships?',
      help: 'Enhanced: unlocked early due to two-month pattern (normally hidden until Moderate risk).',
      options: yesNo,
      answerKind: 'SCALE',
      required: true,
      domain: 'MENTAL HEALTH',
      periodQuestion: true,
    ),
    // Q20 deliberately excluded — low stable score in Month 1, no new info expected.
  ];
}
