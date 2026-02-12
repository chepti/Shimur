class Teacher {
  final String id;
  final String name;
  final int seniorityYears; // וותק בבית הספר
  final int totalSeniorityYears; // וותק בכלל
  final String status; // 'green', 'yellow', 'red'
  final String? notes;
  final DateTime createdAt;
  final String? nextActionDate;
  final String? nextActionType;

  // שדות חדשים
  final int workloadPercent; // היקף משרה באחוזים (3–116)
  final int satisfactionRating; // שביעות רצון 1–5
  final int belongingRating; // תחושת שייכות 1–5
  final int workloadRating; // עומס 1–5
  final int absencesThisYear; // היעדרויות השנה
  final List<String> specialActivities; // פעילויות מיוחדות שסומנו
  // זמני עומס ופרופיל מוטיבציה
  final List<String> busyWeekdays; // ימים עמוסים בשבוע (א,ב,ג...)
  final String? busySeason; // תיאור תקופת עומס בשנה (טקסט חופשי/טווח תאריכים)
  final String? busyReason; // כותרת/סיבת העומס (למשל "תקופת בגרויות")
  final List<String> motivationStyles; // סגנונות מוטיבציה דומיננטיים (לאבו‑וי)
  final List<String> engagementSignals; // תובנות/סימני מעורבות (תחומים מרכזיים)
  // מדד מעורבות גאלופ Q12
  final Map<String, int> engagementDomainScores; // ציון לכל תחום (1–6)
  final Map<String, int> engagementItemScores; // ציון לכל אחד מ-12 ההיגדים (q1..q12)
  final Map<String, String> engagementItemNotes; // הערה קטנה ליד כל שאלה (q1..q12)
  final String? engagementNote; // הערה מילולית כללית מהשאלון/המורה
  // סטטוס רגשי שבועי לפי תחושת מנהל (פורח/זורם/מתוח/מנותק/שחוק)
  final String? moodStatus;
  /// סימון השבוע: עליה/ירידה בסטטוס ('up'|'down')
  final String? moodTrend;
  /// הערה קצרה לשבוע (מנהל)
  final String? moodWeekNote;
  // תפקידים במערכת (מחנכת, רכזת, סגנית וכו') – רשימה
  final List<String> roles;
  // תאריך האינטראקציה האחרונה (מילה טובה/פעולה)
  final DateTime? lastInteractionDate;
  /// טוקן למילוי טופס חיצוני – הקישור שמנהל שולח למורה
  final String? formToken;

  Teacher({
    required this.id,
    required this.name,
    required this.seniorityYears,
    required this.totalSeniorityYears,
    required this.status,
    this.notes,
    required this.createdAt,
    this.nextActionDate,
    this.nextActionType,
    this.workloadPercent = 86,
    this.satisfactionRating = 3,
    this.belongingRating = 3,
    this.workloadRating = 3,
    this.absencesThisYear = 0,
    this.specialActivities = const [],
    this.busyWeekdays = const [],
    this.busySeason,
    this.motivationStyles = const [],
    this.engagementSignals = const [],
    this.busyReason,
    this.engagementDomainScores = const {},
    this.engagementItemScores = const {},
    this.engagementItemNotes = const {},
    this.engagementNote,
    this.moodStatus,
    this.moodTrend,
    this.moodWeekNote,
    this.roles = const [],
    this.lastInteractionDate,
    this.formToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'seniorityYears': seniorityYears,
      'totalSeniorityYears': totalSeniorityYears,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'nextActionDate': nextActionDate,
      'nextActionType': nextActionType,
      'workloadPercent': workloadPercent,
      'satisfactionRating': satisfactionRating,
      'belongingRating': belongingRating,
      'workloadRating': workloadRating,
      'absencesThisYear': absencesThisYear,
      'specialActivities': specialActivities,
      'busyWeekdays': busyWeekdays,
      'busySeason': busySeason,
      'busyReason': busyReason,
      'motivationStyles': motivationStyles,
      'engagementSignals': engagementSignals,
      'engagementDomainScores': engagementDomainScores,
      'engagementItemScores': engagementItemScores,
      'engagementItemNotes': engagementItemNotes,
      'engagementNote': engagementNote,
      'moodStatus': moodStatus,
      'moodTrend': moodTrend,
      'moodWeekNote': moodWeekNote,
      'roles': roles,
      'lastInteractionDate':
          lastInteractionDate?.toIso8601String(),
      'formToken': formToken,
    };
  }

  factory Teacher.fromMap(String id, Map<String, dynamic> map) {
    // תמיכה אחורה בגרסה שבה נשמר מפתח יחיד motivationStyle
    final dynamic rawStyles = map['motivationStyles'] ?? map['motivationStyle'];
    final List<String> parsedStyles;
    if (rawStyles is List) {
      parsedStyles = List<String>.from(rawStyles);
    } else if (rawStyles is String && rawStyles.isNotEmpty) {
      parsedStyles = [rawStyles];
    } else {
      parsedStyles = const [];
    }

    return Teacher(
      id: id,
      name: map['name'] ?? '',
      seniorityYears: map['seniorityYears'] ?? 0,
      totalSeniorityYears: map['totalSeniorityYears'] ?? 0,
      status: map['status'] ?? 'green',
      notes: map['notes'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      nextActionDate: map['nextActionDate'],
      nextActionType: map['nextActionType'],
      workloadPercent: (map['workloadPercent'] ?? 86).toInt(),
      satisfactionRating: (map['satisfactionRating'] ?? 3).toInt(),
      belongingRating: (map['belongingRating'] ?? 3).toInt(),
      workloadRating: (map['workloadRating'] ?? 3).toInt(),
      absencesThisYear: (map['absencesThisYear'] ?? 0).toInt(),
      specialActivities: List<String>.from(map['specialActivities'] ?? const []),
      busyWeekdays: List<String>.from(map['busyWeekdays'] ?? const []),
      busySeason: map['busySeason'],
      motivationStyles: parsedStyles,
      engagementSignals:
          List<String>.from(map['engagementSignals'] ?? const []),
      busyReason: map['busyReason'],
      engagementDomainScores: Map<String, int>.from(
          (map['engagementDomainScores'] ?? const <String, int>{})),
      engagementItemScores: Map<String, int>.from(
          (map['engagementItemScores'] ?? const <String, int>{})),
      engagementItemNotes: Map<String, String>.from(
          (map['engagementItemNotes'] ?? const <String, String>{})),
      engagementNote: map['engagementNote'],
      moodStatus: map['moodStatus'],
      moodTrend: map['moodTrend'],
      moodWeekNote: map['moodWeekNote'],
      // תמיכה אחורה במצב שבו נשמר מחרוזת יחידה בשם 'role'
      roles: map['roles'] != null
          ? List<String>.from(map['roles'])
          : (map['role'] != null
              ? map['role'].toString().split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
              : const []),
      lastInteractionDate: map['lastInteractionDate'] != null
          ? DateTime.parse(map['lastInteractionDate'])
          : null,
      formToken: map['formToken'] as String?,
    );
  }

  Teacher copyWith({
    String? name,
    int? seniorityYears,
    int? totalSeniorityYears,
    String? status,
    String? notes,
    String? nextActionDate,
    String? nextActionType,
    int? workloadPercent,
    int? satisfactionRating,
    int? belongingRating,
    int? workloadRating,
    int? absencesThisYear,
    List<String>? specialActivities,
    List<String>? busyWeekdays,
    String? busySeason,
    List<String>? motivationStyles,
    List<String>? engagementSignals,
    String? busyReason,
    Map<String, int>? engagementDomainScores,
    Map<String, int>? engagementItemScores,
    Map<String, String>? engagementItemNotes,
    String? engagementNote,
    String? moodStatus,
    String? moodTrend,
    String? moodWeekNote,
    List<String>? roles,
    DateTime? lastInteractionDate,
    String? formToken,
  }) {
    return Teacher(
      id: id,
      name: name ?? this.name,
      seniorityYears: seniorityYears ?? this.seniorityYears,
      totalSeniorityYears: totalSeniorityYears ?? this.totalSeniorityYears,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      nextActionDate: nextActionDate ?? this.nextActionDate,
      nextActionType: nextActionType ?? this.nextActionType,
      workloadPercent: workloadPercent ?? this.workloadPercent,
      satisfactionRating: satisfactionRating ?? this.satisfactionRating,
      belongingRating: belongingRating ?? this.belongingRating,
      workloadRating: workloadRating ?? this.workloadRating,
      absencesThisYear: absencesThisYear ?? this.absencesThisYear,
      specialActivities: specialActivities ?? this.specialActivities,
      busyWeekdays: busyWeekdays ?? this.busyWeekdays,
      busySeason: busySeason ?? this.busySeason,
      motivationStyles: motivationStyles ?? this.motivationStyles,
      engagementSignals: engagementSignals ?? this.engagementSignals,
      busyReason: busyReason ?? this.busyReason,
      engagementDomainScores:
          engagementDomainScores ?? this.engagementDomainScores,
      engagementItemScores:
          engagementItemScores ?? this.engagementItemScores,
      engagementItemNotes:
          engagementItemNotes ?? this.engagementItemNotes,
      engagementNote: engagementNote ?? this.engagementNote,
      moodStatus: moodStatus ?? this.moodStatus,
      moodTrend: moodTrend ?? this.moodTrend,
      moodWeekNote: moodWeekNote ?? this.moodWeekNote,
      roles: roles ?? this.roles,
      lastInteractionDate: lastInteractionDate ?? this.lastInteractionDate,
      formToken: formToken ?? this.formToken,
    );
  }
}

