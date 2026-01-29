import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher.dart';
import '../models/action.dart';
import '../models/manager_settings.dart';
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
        if (!thisWeekOnly || (action.date.isAfter(now) && action.date.isBefore(weekFromNow))) {
          allActions.add({
            'action': action,
            'teacherId': teacherDoc.id,
            'teacherName': teacher.name,
          });
        }
      }
    }
    
    allActions.sort((a, b) => 
        (a['action'] as Action).date.compareTo((b['action'] as Action).date));
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

    // עדכון תאריך אינטראקציה אחרונה למורה
    await teacherRef.update({
      'lastInteractionDate': action.date.toIso8601String(),
    });
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
}

