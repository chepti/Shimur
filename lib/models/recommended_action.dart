/// פעולה מומלצת במאגר המשותף – מנהלים יכולים לבחור, לדרג, להגיב.
class RecommendedAction {
  final String id;
  final String type;
  final String? addedByUserId;
  final bool isAnonymous;
  final DateTime createdAt;
  final int ratingSum;
  final int ratingCount;
  /// מפתח: userId, ערך: דירוג 1-5
  final Map<String, int> ratingByUserId;

  RecommendedAction({
    required this.id,
    required this.type,
    this.addedByUserId,
    required this.isAnonymous,
    required this.createdAt,
    this.ratingSum = 0,
    this.ratingCount = 0,
    Map<String, int>? ratingByUserId,
  }) : ratingByUserId = ratingByUserId ?? {};

  double get averageRating =>
      ratingCount > 0 ? ratingSum / ratingCount : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'addedByUserId': addedByUserId,
      'isAnonymous': isAnonymous,
      'createdAt': createdAt.toIso8601String(),
      'ratingSum': ratingSum,
      'ratingCount': ratingCount,
      'ratingByUserId': ratingByUserId,
    };
  }

  factory RecommendedAction.fromMap(String id, Map<String, dynamic> map) {
    final raw = map['ratingByUserId'];
    Map<String, int> byUser = {};
    if (raw is Map) {
      for (final e in raw.entries) {
        if (e.value is int) byUser[e.key.toString()] = e.value;
      }
    }
    return RecommendedAction(
      id: id,
      type: map['type'] ?? '',
      addedByUserId: map['addedByUserId'] as String?,
      isAnonymous: map['isAnonymous'] ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      ratingSum: map['ratingSum'] is int ? map['ratingSum'] as int : 0,
      ratingCount: map['ratingCount'] is int ? map['ratingCount'] as int : 0,
      ratingByUserId: byUser,
    );
  }
}
