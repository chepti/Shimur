import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher.dart';
import '../models/action.dart';
import '../models/manager_settings.dart';
import '../models/recommended_action.dart';
import '../models/recommended_action_comment.dart';
import '../services/auth_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  String? get _currentUserId => _authService.currentUserId;

  // ========== Schools ==========
  Future<void> createSchool(String schoolSymbol, String schoolName) async {
    if (_currentUserId == null) throw Exception('לא מחובר');
    
    await _firestore.collection('schools').doc(_currentUserId).set({
      'name': schoolName,
      'managerId': _currentUserId!,
      'symbol': schoolSymbol,
    });
  }

  Future<Map<String, dynamic>?> getSchool() async {
    if (_currentUserId == null) return null;
    
    final doc = await _firestore.collection('schools').doc(_currentUserId).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  // ========== Teachers ==========
  Stream<List<Teacher>> getTeachersStream() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('schools')
        .doc(_currentUserId)
        .collection('teachers')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Teacher.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> addTeacher(Teacher teacher) async {
    if (_currentUserId == null) throw Exception('לא מחובר');
    
    await _firestore
        .collection('schools')
        .doc(_currentUserId)
        .collection('teachers')
        .add(teacher.toMap());
  }

  Future<void> updateTeacher(Teacher teacher) async {
    if (_currentUserId == null) throw Exception('לא מחובר');
    
    await _firestore
        .collection('schools')
        .doc(_currentUserId)
        .collection('teachers')
        .doc(teacher.id)
        .update(teacher.toMap());
  }

  Future<void> deleteTeacher(String teacherId) async {
    if (_currentUserId == null) throw Exception('לא מחובר');
    
    // מחק גם את כל הפעולות
    final actionsSnapshot = await _firestore
        .collection('schools')
        .doc(_currentUserId)
        .collection('teachers')
        .doc(teacherId)
        .collection('actions')
        .get();
    
    for (var doc in actionsSnapshot.docs) {
      await doc.reference.delete();
    }
    
    await _firestore
        .collection('schools')
        .doc(_currentUserId)
        .collection('teachers')
        .doc(teacherId)
        .delete();
  }

  // ========== Actions ==========
  Stream<List<Action>> getActionsStream(String teacherId) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('schools')
        .doc(_currentUserId)
        .collection('teachers')
        .doc(teacherId)
        .collection('actions')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Action.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// ספירת כל הפעולות שהושלמו היום (למדד היומי במסך הבית).
  /// כרגע נספרות כל הפעולות שסומנו כ-completed בתאריך של היום,
  /// ללא סינון לפי סוג – כדי לתת תחושת התקדמות כללית.
  Future<int> getTodayCompletedActionsCount() async {
    if (_currentUserId == null) return 0;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final startIso = startOfDay.toIso8601String();
    final endIso = endOfDay.toIso8601String();

    int totalCount = 0;

    final teachersSnapshot = await _firestore
        .collection('schools')
        .doc(_currentUserId)
        .collection('teachers')
        .get();

    for (var teacherDoc in teachersSnapshot.docs) {
      final actionsSnapshot = await teacherDoc.reference
          .collection('actions')
          .where('completed', isEqualTo: true)
          .where('date', isGreaterThanOrEqualTo: startIso)
          .where('date', isLessThan: endIso)
          .get();

      totalCount += actionsSnapshot.size;
    }

    return totalCount;
  }

  /// מחזיר מזהי מורים שהייתה להם לפחות פעולה אחת (התייחסות מתועדת) השבוע הנוכחי (ראשון–שבת).
  Future<Set<String>> getTeacherIdsWithActionsInCurrentWeek() async {
    if (_currentUserId == null) return {};

    final now = DateTime.now();
    final daysSinceSunday = now.weekday == 7 ? 0 : now.weekday;
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysSinceSunday));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    final startIso = startOfWeek.toIso8601String();
    final endIso = endOfWeek.toIso8601String();

    final teachersSnapshot = await _firestore
        .collection('schools')
        .doc(_currentUserId)
        .collection('teachers')
        .get();

    final ids = <String>{};
    for (var teacherDoc in teachersSnapshot.docs) {
      final actionsSnapshot = await teacherDoc.reference
          .collection('actions')
          .where('date', isGreaterThanOrEqualTo: startIso)
          .where('date', isLessThan: endIso)
          .limit(1)
          .get();
      if (actionsSnapshot.docs.isNotEmpty) {
        ids.add(teacherDoc.id);
      }
    }
    return ids;
  }

  Future<List<Map<String, dynamic>>> getAllUpcomingActions({bool thisWeekOnly = false}) async {
    if (_currentUserId == null) return [];
    
    final teachersSnapshot = await _firestore
        .collection('schools')
        .doc(_currentUserId)
        .collection('teachers')
        .get();
    
    List<Map<String, dynamic>> allActions = [];
    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));
    
    for (var teacherDoc in teachersSnapshot.docs) {
      final teacher = Teacher.fromMap(teacherDoc.id, teacherDoc.data());
      final actionsSnapshot = await teacherDoc.reference
          .collection('actions')
          .where('completed', isEqualTo: false)
          .orderBy('date')
          .get();
      
      for (var actionDoc in actionsSnapshot.docs) {
        final action = Action.fromMap(actionDoc.id, actionDoc.data());
        final d = action.date;
        if (!thisWeekOnly || (d != null && d.isAfter(now) && d.isBefore(weekFromNow))) {
          allActions.add({
            'action': action,
            'teacherId': teacherDoc.id,
            'teacherName': teacher.name,
          });
        }
      }
    }
    
    allActions.sort((a, b) {
      final da = (a['action'] as Action).date;
      final db = (b['action'] as Action).date;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
    return allActions;
  }

  Future<void> addAction(String teacherId, Action action) async {
    if (_currentUserId == null) throw Exception('לא מחובר');

    final teacherRef = _firestore
        .collection('schools')
        .doc(_currentUserId)
        .collection('teachers')
        .doc(teacherId);

    // הוספת הפעולה עצמה
    await teacherRef.collection('actions').add(action.toMap());

    // עדכון תאריך אינטראקציה אחרונה למורה (רק אם נבחר תאריך)
    if (action.date != null) {
      await teacherRef.update({
        'lastInteractionDate': action.date!.toIso8601String(),
      });
    }
  }

  Future<void> updateAction(String teacherId, Action action) async {
    if (_currentUserId == null) throw Exception('לא מחובר');
    
    await _firestore
        .collection('schools')
        .doc(_currentUserId)
        .collection('teachers')
        .doc(teacherId)
        .collection('actions')
        .doc(action.id)
        .update(action.toMap());
  }

  Future<Teacher?> getTeacher(String teacherId) async {
    if (_currentUserId == null) return null;

    final doc = await _firestore
        .collection('schools')
        .doc(_currentUserId)
        .collection('teachers')
        .doc(teacherId)
        .get();

    if (doc.exists) {
      return Teacher.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  // ========== הגדרות מנהל ==========
  static const String _managerSettingsDocId = 'manager';

  Future<ManagerSettings> getManagerSettings() async {
    if (_currentUserId == null) return const ManagerSettings();

    final doc = await _firestore
        .collection('schools')
        .doc(_currentUserId)
        .collection('settings')
        .doc(_managerSettingsDocId)
        .get();

    if (doc.exists && doc.data() != null) {
      return ManagerSettings.fromMap(doc.data());
    }
    return const ManagerSettings();
  }

  Future<void> updateManagerSettings(ManagerSettings settings) async {
    if (_currentUserId == null) throw Exception('לא מחובר');

    await _firestore
        .collection('schools')
        .doc(_currentUserId)
        .collection('settings')
        .doc(_managerSettingsDocId)
        .set(settings.toMap());
  }

  // ========== מאגר פעולות מומלצות (למידה הדדית) ==========
  static const String _recommendedActionsCollection = 'recommended_actions';

  Stream<List<RecommendedAction>> getRecommendedActionsStream() {
    return _firestore
        .collection(_recommendedActionsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RecommendedAction.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> addRecommendedAction({
    required String type,
    required bool isAnonymous,
  }) async {
    if (_currentUserId == null) throw Exception('לא מחובר');

    await _firestore.collection(_recommendedActionsCollection).add({
      'type': type,
      'addedByUserId': isAnonymous ? null : _currentUserId,
      'isAnonymous': isAnonymous,
      'createdAt': DateTime.now().toIso8601String(),
      'ratingSum': 0,
      'ratingCount': 0,
      'ratingByUserId': <String, int>{},
    });
  }

  /// מעדכן דירוג של המשתמש הנוכחי (1–5). אם כבר דירג – מעדכן.
  Future<void> setRecommendedActionRating(String recommendedActionId, int rating) async {
    if (_currentUserId == null) throw Exception('לא מחובר');
    if (rating < 1 || rating > 5) return;

    final ref = _firestore
        .collection(_recommendedActionsCollection)
        .doc(recommendedActionId);
    await _firestore.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists) return;

      final data = doc.data()!;
      final prevByUser = Map<String, int>.from(
        (data['ratingByUserId'] as Map<dynamic, dynamic>?)?.map(
          (k, v) => MapEntry(k.toString(), v as int),
        ) ?? {},
      );
      final prevSum = data['ratingSum'] as int? ?? 0;
      final prevCount = data['ratingCount'] as int? ?? 0;
      final oldRating = prevByUser[_currentUserId];

      int newSum = prevSum;
      int newCount = prevCount;
      if (oldRating != null) {
        newSum -= oldRating;
        newCount -= 1;
      }
      newSum += rating;
      newCount += 1;
      prevByUser[_currentUserId!] = rating;

      tx.update(ref, {
        'ratingSum': newSum,
        'ratingCount': newCount,
        'ratingByUserId': prevByUser,
      });
    });
  }

  Stream<List<RecommendedActionComment>> getRecommendedActionCommentsStream(
    String recommendedActionId,
  ) {
    return _firestore
        .collection(_recommendedActionsCollection)
        .doc(recommendedActionId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RecommendedActionComment.fromMap(
                doc.id,
                doc.data(),
              ))
          .toList();
    });
  }

  Future<void> addRecommendedActionComment({
    required String recommendedActionId,
    required String text,
    required bool isAnonymous,
  }) async {
    if (_currentUserId == null) throw Exception('לא מחובר');
    if (text.trim().isEmpty) return;

    await _firestore
        .collection(_recommendedActionsCollection)
        .doc(recommendedActionId)
        .collection('comments')
        .add({
      'recommendedActionId': recommendedActionId,
      'userId': isAnonymous ? null : _currentUserId,
      'isAnonymous': isAnonymous,
      'text': text.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}

