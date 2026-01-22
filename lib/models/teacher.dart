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
    };
  }

  factory Teacher.fromMap(String id, Map<String, dynamic> map) {
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
    );
  }
}

