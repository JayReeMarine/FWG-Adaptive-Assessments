# FWG-Adaptive-Assessments
FWG  Adaptive Assessments

FIT4701

Team's folder -> https://drive.google.com/drive/u/1/folders/1g20YC3A-IQ8-JM6LBUzlJKDUFKCSX0sM



/********************************************************
 * Database Relationships
 ********************************************************/
Ref: profile.user_id > user.id
Ref: consent.user_id > user.id
Ref: question.questionnaire_id > questionnaire.id
Ref: question_version.question_id > question.id
Ref: option.question_version_id > question_version.id
Ref: question_schedule.schedule_id > schedule.id
Ref: question_schedule.question_id > question.id
Ref: rule.trigger_question_version_id > question_version.id
Ref: session.user_id > user.id
Ref: response.session_id > session.id
Ref: response.question_version_id > question_version.id
Ref: flag.user_id > user.id
Ref: flag.session_id > session.id