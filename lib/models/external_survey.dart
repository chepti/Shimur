/// מודל לשאלון חיצוני שהמנהל יוצר
class ExternalSurvey {
  final String id;
  final String title; // כותרת השאלון (למשל "שאלון אקלים - חנוכה 2024")
  final String? description; // תיאור קצר (אופציונלי)
  final List<ExternalSurveyQuestion> questions; // רשימת השאלות
  final DateTime createdAt;
  final DateTime? expiresAt; // תאריך תפוגה (אופציונלי)
  final bool isActive; // האם השאלון פעיל (ניתן למלא)
  final String? token; // טוקן אבטחה לקישור
  /// האם לכלול את שאלון המעורבות (Q12, מוטיבציה, תפקידים) באותו טופס
  final bool includeEngagementSurvey;
  /// לוגו מותאם לשאלון (מחליף את לוגו בית הספר בטופס)
  final String? logoUrl;

  ExternalSurvey({
    required this.id,
    required this.title,
    this.description,
    required this.questions,
    required this.createdAt,
    this.expiresAt,
    this.isActive = true,
    this.token,
    this.includeEngagementSurvey = true,
    this.logoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'isActive': isActive,
      'token': token,
      'includeEngagementSurvey': includeEngagementSurvey,
      'logoUrl': logoUrl,
    };
  }

  factory ExternalSurvey.fromMap(String id, Map<String, dynamic> map) {
    final questionsList = (map['questions'] as List<dynamic>?)
            ?.map((q) => ExternalSurveyQuestion.fromMap(q as Map<String, dynamic>))
            .toList() ??
        [];

    return ExternalSurvey(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] as String?,
      questions: questionsList,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      expiresAt: map['expiresAt'] != null
          ? DateTime.parse(map['expiresAt'])
          : null,
      isActive: map['isActive'] ?? true,
      token: map['token'] as String?,
      includeEngagementSurvey: map['includeEngagementSurvey'] ?? true,
      logoUrl: map['logoUrl'] as String?,
    );
  }

  ExternalSurvey copyWith({
    String? id,
    String? title,
    String? description,
    List<ExternalSurveyQuestion>? questions,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isActive,
    String? token,
    bool? includeEngagementSurvey,
    String? logoUrl,
  }) {
    return ExternalSurvey(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      questions: questions ?? this.questions,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      token: token ?? this.token,
      includeEngagementSurvey: includeEngagementSurvey ?? this.includeEngagementSurvey,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }
}

/// שאלה בשאלון חיצוני
class ExternalSurveyQuestion {
  final String id; // מזהה ייחודי לשאלה (למשל "q1", "q2")
  final String text; // טקסט השאלה
  final ExternalSurveyQuestionType type; // סוג השאלה
  final List<String>? options; // אופציות (רק אם type הוא multipleChoice)
  final bool required; // האם השאלה חובה

  ExternalSurveyQuestion({
    required this.id,
    required this.text,
    required this.type,
    this.options,
    this.required = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'type': type.toString().split('.').last, // 'scale', 'multipleChoice', 'text'
      'options': options,
      'required': required,
    };
  }

  factory ExternalSurveyQuestion.fromMap(Map<String, dynamic> map) {
    final typeStr = map['type'] as String? ?? 'text';
    ExternalSurveyQuestionType type;
    switch (typeStr) {
      case 'scale':
        type = ExternalSurveyQuestionType.scale;
        break;
      case 'multipleChoice':
        type = ExternalSurveyQuestionType.multipleChoice;
        break;
      default:
        type = ExternalSurveyQuestionType.text;
    }

    return ExternalSurveyQuestion(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      type: type,
      options: map['options'] != null
          ? List<String>.from(map['options'])
          : null,
      required: map['required'] ?? true,
    );
  }
}

enum ExternalSurveyQuestionType {
  scale, // סולם 1-6 (כמו Q12)
  multipleChoice, // בחירה מרובה
  text, // טקסט חופשי
}
