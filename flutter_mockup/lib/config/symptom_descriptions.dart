// ─────────────────────────────────────────────────────────────────────────────
// symptom_descriptions.dart
//
// Centralised, per-domain symptom descriptions keyed by RiskLevel.
// Used on the CompletionPage result cards to give users a human-readable
// interpretation of their score.
//
// To add a new domain: insert a new entry in [_descriptions].
// To tweak wording: edit the string for the relevant domain + level.
// ─────────────────────────────────────────────────────────────────────────────

import '../services/scoring_service.dart';

/// Provides a user-facing description for a given health domain and risk level.
class SymptomDescriptions {
  SymptomDescriptions._(); // not instantiable

  /// Returns a description for the given [domain] and [level].
  /// Returns an empty string if the domain is not mapped.
  static String get(String domain, RiskLevel level) {
    return _descriptions[domain.toUpperCase()]?[level] ?? '';
  }

  static const _descriptions = <String, Map<RiskLevel, String>>{
    // ── Mental Health ──────────────────────────────────────────────────────
    'MENTAL HEALTH': {
      RiskLevel.none:
          'No significant mental health concerns were detected based on your '
          'responses. You appear to be managing your emotional wellbeing well. '
          'Continue maintaining your current routines, social connections, and '
          'self-care practices.',
      RiskLevel.mild:
          'Your responses suggest you may be experiencing occasional low mood '
          'or mild stress. This is common and does not appear to significantly '
          'affect your daily life at this stage. Consider keeping an eye on '
          'your mood patterns and practising regular self-care such as '
          'exercise, adequate sleep, and staying connected with others.',
      RiskLevel.moderate:
          'Your responses indicate you may be experiencing persistent low mood '
          'or anxiety that is starting to affect daily activities such as '
          'studying, working, or socialising. It may be helpful to talk to '
          'someone you trust or explore support services available to you. '
          'Small steps like maintaining a routine and setting achievable goals '
          'can also make a difference.',
      RiskLevel.high:
          'Your responses suggest you may be experiencing significant '
          'emotional distress that is impacting most areas of your daily life. '
          'Please consider reaching out to a mental health professional or a '
          'trusted person in your life. Support is available \u2014 Lifeline '
          '(13\u00a011\u00a014), Beyond Blue (1300\u00a022\u00a04636), or '
          'Headspace (headspace.org.au) are here to help.',
    },

    // ── Dietary ────────────────────────────────────────────────────────────
    'DIETARY': {
      RiskLevel.none:
          'Your dietary habits appear to be well-balanced based on your '
          'responses. You seem to be maintaining a healthy relationship with '
          'food and nutrition. Keep up these positive habits.',
      RiskLevel.mild:
          'Your responses suggest some minor inconsistencies in your eating '
          'habits, such as occasionally skipping meals or limited variety in '
          'your diet. These are common and manageable \u2014 small adjustments '
          'like planning meals ahead or including more fruit and vegetables '
          'can help.',
      RiskLevel.moderate:
          'Your responses indicate notable concerns with your dietary patterns. '
          'You may be frequently skipping meals, relying heavily on processed '
          'foods, or experiencing irregular eating habits. Consider consulting '
          'a nutritionist or using meal-planning resources to improve your '
          'dietary balance.',
      RiskLevel.high:
          'Your responses suggest significant dietary concerns that may be '
          'affecting your overall health and energy levels. Poor nutrition can '
          'impact mood, concentration, and physical wellbeing. It is '
          'recommended that you seek guidance from a healthcare professional '
          'or dietitian to develop a sustainable eating plan.',
    },

    // ── Physical Activity ──────────────────────────────────────────────────
    'PHYSICAL ACTIVITY': {
      RiskLevel.none:
          'You appear to be maintaining an active lifestyle based on your '
          'responses. Regular physical activity supports both physical and '
          'mental health. Keep up the great work.',
      RiskLevel.mild:
          'Your responses suggest you could benefit from a bit more physical '
          'activity in your routine. You may be active occasionally but not '
          'consistently. Even small increases \u2014 such as a daily walk or '
          'stretching breaks \u2014 can have positive effects on your energy '
          'and mood.',
      RiskLevel.moderate:
          'Your responses indicate a largely sedentary lifestyle that may be '
          'affecting your physical and mental wellbeing. Prolonged inactivity '
          'can contribute to fatigue, low mood, and health issues over time. '
          'Consider setting small, achievable activity goals and building up '
          'gradually.',
      RiskLevel.high:
          'Your responses suggest very low levels of physical activity, which '
          'can significantly impact your overall health. A sedentary lifestyle '
          'is associated with increased risks of chronic conditions and mental '
          'health difficulties. Consider speaking with a healthcare provider '
          'about safe ways to become more active.',
    },

    // ── Alcohol ────────────────────────────────────────────────────────────
    'ALCOHOL': {
      RiskLevel.none:
          'Your responses indicate low or no alcohol consumption. This is a '
          'positive indicator for your overall health and wellbeing.',
      RiskLevel.mild:
          'Your responses suggest occasional alcohol use that is within '
          'generally accepted guidelines. Be mindful of how alcohol affects '
          'your sleep, mood, and productivity, and consider keeping track of '
          'your intake over time.',
      RiskLevel.moderate:
          'Your responses indicate regular alcohol consumption that may be '
          'approaching risky levels. Frequent drinking can affect sleep '
          'quality, mental health, and academic or work performance. Consider '
          'setting limits for yourself and exploring alcohol-free alternatives '
          'in social settings.',
      RiskLevel.high:
          'Your responses suggest high levels of alcohol consumption that may '
          'be having a significant impact on your health and daily life. Heavy '
          'drinking is associated with a range of physical and mental health '
          'risks. Please consider reaching out to a healthcare professional or '
          'support service for guidance.',
    },

    // ── Smoking / Vaping ───────────────────────────────────────────────────
    'SMOKING/VAPING': {
      RiskLevel.none:
          'Your responses indicate no current smoking or vaping activity. '
          'This is beneficial for your respiratory and overall health.',
      RiskLevel.mild:
          'Your responses suggest occasional smoking or vaping. Even '
          'infrequent use can develop into a habit over time. Being aware of '
          'triggers and considering cessation resources early can help prevent '
          'escalation.',
      RiskLevel.moderate:
          'Your responses indicate regular smoking or vaping that may be '
          'becoming a habitual part of your routine. Nicotine dependence can '
          'develop gradually and affect both physical health and finances. '
          'Consider exploring cessation programs or speaking with a healthcare '
          'provider about options.',
      RiskLevel.high:
          'Your responses suggest heavy smoking or vaping that is likely '
          'impacting your respiratory health and overall wellbeing. Quitting '
          'can be challenging but support is available \u2014 talk to your '
          'doctor or contact Quitline (13\u00a078\u00a048) for free, '
          'confidential advice and support.',
    },

    // ── Women's Health ─────────────────────────────────────────────────────
    'WOMEN HEALTH': {
      RiskLevel.none:
          'No significant concerns were detected regarding your reproductive '
          'or hormonal health based on your responses. Continue with your '
          'current health practices and routine check-ups.',
      RiskLevel.mild:
          'Your responses suggest some minor concerns related to your '
          'reproductive or hormonal health, such as occasional irregularities '
          'or mild discomfort. These are often manageable but worth monitoring '
          'over time.',
      RiskLevel.moderate:
          'Your responses indicate notable concerns with your reproductive or '
          'hormonal health that may be affecting your daily comfort or '
          'wellbeing. Consider scheduling a check-up with your GP or a '
          'women\u2019s health specialist to discuss your symptoms.',
      RiskLevel.high:
          'Your responses suggest significant concerns related to your '
          'reproductive or hormonal health. It is recommended that you consult '
          'a healthcare professional to explore these symptoms further and '
          'discuss appropriate support or treatment options.',
    },
  };
}
