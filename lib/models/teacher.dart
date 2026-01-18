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
    );
  }
}

