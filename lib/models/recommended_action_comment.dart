/// תגובה על פעולה מומלצת (למשל "עזר לי מאוד עם מורים מתמחים").
class RecommendedActionComment {
  final String id;
  final String recommendedActionId;
  final String? userId;
  final bool isAnonymous;
  final String text;
  final DateTime createdAt;

  RecommendedActionComment({
    required this.id,
    required this.recommendedActionId,
    this.userId,
    required this.isAnonymous,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'recommendedActionId': recommendedActionId,
      'userId': userId,
      'isAnonymous': isAnonymous,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RecommendedActionComment.fromMap(String id, Map<String, dynamic> map) {
    return RecommendedActionComment(
      id: id,
      recommendedActionId: map['recommendedActionId'] ?? '',
      userId: map['userId'] as String?,
      isAnonymous: map['isAnonymous'] ?? true,
      text: map['text'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
