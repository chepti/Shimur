class Action {
  final String id;
  final String type;
  /// תאריך ביצוע – null = "ללא תאריך" (גמיש).
  final DateTime? date;
  final String? notes;
  final bool completed;
  final DateTime createdAt;
  /// מזהה היגד מסיכום שבוע – לקישור משימה להיגד (להעלמה/הופעה מחדש)
  final String? insightId;

  Action({
    required this.id,
    required this.type,
    this.date,
    this.notes,
    required this.completed,
    required this.createdAt,
    this.insightId,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'type': type,
      'date': date?.toIso8601String(), // null = "ללא תאריך", נשמר כדי ש־orderBy יעבוד
      'notes': notes,
      'completed': completed,
      'createdAt': createdAt.toIso8601String(),
    };
    if (insightId != null && insightId!.isNotEmpty) {
      map['insightId'] = insightId;
    }
    return map;
  }

  factory Action.fromMap(String id, Map<String, dynamic> map) {
    return Action(
      id: id,
      type: map['type'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : null,
      notes: map['notes'],
      completed: map['completed'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      insightId: map['insightId'] as String?,
    );
  }

  Action copyWith({
    String? type,
    DateTime? date,
    String? notes,
    bool? completed,
    String? insightId,
  }) {
    return Action(
      id: id,
      type: type ?? this.type,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      completed: completed ?? this.completed,
      createdAt: createdAt,
      insightId: insightId ?? this.insightId,
    );
  }
}

