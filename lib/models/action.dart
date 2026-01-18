class Action {
  final String id;
  final String type;
  final DateTime date;
  final String? notes;
  final bool completed;
  final DateTime createdAt;

  Action({
    required this.id,
    required this.type,
    required this.date,
    this.notes,
    required this.completed,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'date': date.toIso8601String(),
      'notes': notes,
      'completed': completed,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Action.fromMap(String id, Map<String, dynamic> map) {
    return Action(
      id: id,
      type: map['type'] ?? '',
      date: map['date'] != null
          ? DateTime.parse(map['date'])
          : DateTime.now(),
      notes: map['notes'],
      completed: map['completed'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Action copyWith({
    String? type,
    DateTime? date,
    String? notes,
    bool? completed,
  }) {
    return Action(
      id: id,
      type: type ?? this.type,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      completed: completed ?? this.completed,
      createdAt: createdAt,
    );
  }
}

