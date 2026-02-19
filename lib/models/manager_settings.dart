/// הגדרות מנהל – יעדים, כללים, נוטיפיקציות, דורשים טיפול.
class ManagerSettings {
  /// יעד מילים טובות ביום
  final int goalsGoodWordsPerDay;
  /// יעד מילים טובות בשבוע
  final int goalsGoodWordsPerWeek;

  /// כל כמה חודשים לפגוש מחנכים (למשל 2 = פעם בחודשיים)
  final int ruleMeetEducatorsMonths;
  /// כל כמה חודשים לפגוש בעלי תפקידים (למשל 1 = פעם בחודש)
  final int ruleMeetRoleHoldersMonths;

  /// יום שבוע להתראה לתחילת שבוע (1=שני … 7=ראשון). מחדל 7 (ראשון)
  final int notificationStartWeekWeekday;
  final int notificationStartWeekHour;
  final int notificationStartWeekMinute;

  /// יום שבוע להתראה לסוף שבוע (1=שני … 7=ראשון). מחדל 4 = חמישי
  final int notificationEndWeekWeekday;
  final int notificationEndWeekHour;
  final int notificationEndWeekMinute;

  /// כמה מורים להציג ב"דורשים טיפול": 'all' | '5' | '10'
  final String needAttentionLimit;

  /// טוקן למילוי טופס שאלון חיצוני – קישור אחיד לכל הצוות
  final String? schoolFormToken;

  /// מפתח API של Gemini (מ־aistudio.google.com) – לניסוח הודעות והמלצות
  final String? geminiApiKey;
  /// הגבלת בקשות AI לחודש (מחדל 50) – למניעת חריגת תקציב
  final int geminiUsageLimitPerMonth;
  /// ספירת בקשות AI בחודש הנוכחי (מפתח: yyyy-MM)
  final String? geminiUsageMonth;
  final int geminiUsageCount;

  const ManagerSettings({
    this.goalsGoodWordsPerDay = 10,
    this.goalsGoodWordsPerWeek = 40,
    this.ruleMeetEducatorsMonths = 2,
    this.ruleMeetRoleHoldersMonths = 1,
    this.notificationStartWeekWeekday = 7,
    this.notificationStartWeekHour = 7,
    this.notificationStartWeekMinute = 40,
    this.notificationEndWeekWeekday = 4,
    this.notificationEndWeekHour = 16,
    this.notificationEndWeekMinute = 0,
    this.needAttentionLimit = '5',
    this.schoolFormToken,
    this.geminiApiKey,
    this.geminiUsageLimitPerMonth = 50,
    this.geminiUsageMonth,
    this.geminiUsageCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'goalsGoodWordsPerDay': goalsGoodWordsPerDay,
      'goalsGoodWordsPerWeek': goalsGoodWordsPerWeek,
      'ruleMeetEducatorsMonths': ruleMeetEducatorsMonths,
      'ruleMeetRoleHoldersMonths': ruleMeetRoleHoldersMonths,
      'notificationStartWeekWeekday': notificationStartWeekWeekday,
      'notificationStartWeekHour': notificationStartWeekHour,
      'notificationStartWeekMinute': notificationStartWeekMinute,
      'notificationEndWeekWeekday': notificationEndWeekWeekday,
      'notificationEndWeekHour': notificationEndWeekHour,
      'notificationEndWeekMinute': notificationEndWeekMinute,
      'needAttentionLimit': needAttentionLimit,
      'schoolFormToken': schoolFormToken,
      'geminiApiKey': geminiApiKey,
      'geminiUsageLimitPerMonth': geminiUsageLimitPerMonth,
      'geminiUsageMonth': geminiUsageMonth,
      'geminiUsageCount': geminiUsageCount,
    };
  }

  static int _toInt(dynamic v, int def) {
    if (v == null) return def;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return def;
  }

  static String _toString(dynamic v, String def) {
    if (v == null) return def;
    if (v is String) return v;
    return v.toString();
  }

  factory ManagerSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return const ManagerSettings();
    return ManagerSettings(
      goalsGoodWordsPerDay: _toInt(map['goalsGoodWordsPerDay'], 10),
      goalsGoodWordsPerWeek: _toInt(map['goalsGoodWordsPerWeek'], 40),
      ruleMeetEducatorsMonths: _toInt(map['ruleMeetEducatorsMonths'], 2),
      ruleMeetRoleHoldersMonths: _toInt(map['ruleMeetRoleHoldersMonths'], 1),
      notificationStartWeekWeekday: _toInt(map['notificationStartWeekWeekday'], 7),
      notificationStartWeekHour: _toInt(map['notificationStartWeekHour'], 7),
      notificationStartWeekMinute: _toInt(map['notificationStartWeekMinute'], 40),
      notificationEndWeekWeekday: _toInt(map['notificationEndWeekWeekday'], 4),
      notificationEndWeekHour: _toInt(map['notificationEndWeekHour'], 16),
      notificationEndWeekMinute: _toInt(map['notificationEndWeekMinute'], 0),
      needAttentionLimit: _toString(map['needAttentionLimit'], '5'),
      schoolFormToken: map['schoolFormToken'] as String?,
      geminiApiKey: map['geminiApiKey'] as String?,
      geminiUsageLimitPerMonth: _toInt(map['geminiUsageLimitPerMonth'], 50),
      geminiUsageMonth: map['geminiUsageMonth'] as String?,
      geminiUsageCount: _toInt(map['geminiUsageCount'], 0),
    );
  }

  ManagerSettings copyWith({
    int? goalsGoodWordsPerDay,
    int? goalsGoodWordsPerWeek,
    int? ruleMeetEducatorsMonths,
    int? ruleMeetRoleHoldersMonths,
    int? notificationStartWeekWeekday,
    int? notificationStartWeekHour,
    int? notificationStartWeekMinute,
    int? notificationEndWeekWeekday,
    int? notificationEndWeekHour,
    int? notificationEndWeekMinute,
    String? needAttentionLimit,
    String? schoolFormToken,
    String? geminiApiKey,
    int? geminiUsageLimitPerMonth,
    String? geminiUsageMonth,
    int? geminiUsageCount,
  }) {
    return ManagerSettings(
      goalsGoodWordsPerDay: goalsGoodWordsPerDay ?? this.goalsGoodWordsPerDay,
      goalsGoodWordsPerWeek: goalsGoodWordsPerWeek ?? this.goalsGoodWordsPerWeek,
      ruleMeetEducatorsMonths: ruleMeetEducatorsMonths ?? this.ruleMeetEducatorsMonths,
      ruleMeetRoleHoldersMonths: ruleMeetRoleHoldersMonths ?? this.ruleMeetRoleHoldersMonths,
      notificationStartWeekWeekday: notificationStartWeekWeekday ?? this.notificationStartWeekWeekday,
      notificationStartWeekHour: notificationStartWeekHour ?? this.notificationStartWeekHour,
      notificationStartWeekMinute: notificationStartWeekMinute ?? this.notificationStartWeekMinute,
      notificationEndWeekWeekday: notificationEndWeekWeekday ?? this.notificationEndWeekWeekday,
      notificationEndWeekHour: notificationEndWeekHour ?? this.notificationEndWeekHour,
      notificationEndWeekMinute: notificationEndWeekMinute ?? this.notificationEndWeekMinute,
      needAttentionLimit: needAttentionLimit ?? this.needAttentionLimit,
      schoolFormToken: schoolFormToken ?? this.schoolFormToken,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      geminiUsageLimitPerMonth:
          geminiUsageLimitPerMonth ?? this.geminiUsageLimitPerMonth,
      geminiUsageMonth: geminiUsageMonth ?? this.geminiUsageMonth,
      geminiUsageCount: geminiUsageCount ?? this.geminiUsageCount,
    );
  }

  /// מחזיר את מספר המורים להצגה ב"דורשים טיפול" – null = כולם
  int? get needAttentionCount {
    if (needAttentionLimit == 'all') return null;
    final n = int.tryParse(needAttentionLimit);
    return n;
  }
}
