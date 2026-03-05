import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/teacher.dart';
import '../models/action.dart';
import '../models/manager_settings.dart';
import '../models/recommended_action.dart';
import '../models/recommended_action_comment.dart';
import '../models/external_survey.dart';
import '../services/auth_service.dart';
import '../config/auth_state.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  String? get _currentUserId => _authService.currentUserId;

  /// מחזיר את ה-UID אחרי המתנה ל-auth (פתרון ל-custom token login).
  /// משתמש ב-AuthState.verifiedUid כ-fallback כש-Firebase Auth מחזיר null ב-Web.
  Future<String> _requireUserId() async {
    var uid = await _authService.ensureUserIdReady();
    uid ??= AuthState.verifiedUid;
    if (uid == null) throw Exception('לא מחובר');
    return uid;
  }

  // ========== Schools ==========
  Future<void> createSchool(
    String schoolSymbol,
    String schoolName, {
    String? managerName,
  }) async {
    final uid = await _requireUserId();
    final data = <String, dynamic>{
      'name': schoolName,
      'managerId': uid,
      'symbol': schoolSymbol,
    };
    if (managerName != null && managerName.isNotEmpty) {
      data['managerName'] = managerName;
    }
    await _firestore.collection('schools').doc(uid).set(data);
  }

  /// מעדכן את שם המנהל במסמך בית הספר.
  Future<void> updateSchoolManagerName(String managerName) async {
    final uid = await _requireUserId();
    await _firestore.collection('schools').doc(uid).set(
      {'managerName': managerName},
      SetOptions(merge: true),
    );
  }

  Future<Map<String, dynamic>?> getSchool() async {
    var uid = _currentUserId;
    uid ??= await _authService.ensureUserIdReady();
    uid ??= AuthState.verifiedUid;
    if (uid == null) return null;

    final doc = await _firestore.collection('schools').doc(uid).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  /// סטרים לעדכונים חיים על מסמך בית הספר (למשל שם מנהל).
  Stream<Map<String, dynamic>?> getSchoolStream() async* {
    var uid = _currentUserId;
    uid ??= await _authService.ensureUserIdReady();
    uid ??= AuthState.verifiedUid;
    if (uid == null) {
      yield null;
      return;
    }
    await for (final snapshot
        in _firestore.collection('schools').doc(uid).snapshots()) {
      yield snapshot.data();
    }
  }

  /// מעלה לוגו ל-Storage ומעדכן את מסמך בית הספר ב־logoUrl. מחזיר את ה-URL.
  Future<String> uploadSchoolLogo(Uint8List bytes, String contentType) async {
    final uid = await _requireUserId();
    final ext = contentType == 'image/png' ? 'png' : 'jpg';
    final ref = FirebaseStorage.instance
        .ref()
        .child('school_logos')
        .child(uid)
        .child('logo.$ext');

    await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );
    final url = await ref.getDownloadURL();

    await _firestore.collection('schools').doc(uid).set(
      {'logoUrl': url},
      SetOptions(merge: true),
    );
    return url;
  }

  /// מסיר את לוגו בית הספר (מעדכן ל-null ב-Firestore; הקובץ ב-Storage נשאר).
  Future<void> clearSchoolLogo() async {
    final uid = await _requireUserId();
    await _firestore.collection('schools').doc(uid).update({
      'logoUrl': FieldValue.delete(),
    });
  }

  /// מעלה לוגו לשאלון חיצוני. מחזיר את ה-URL.
  Future<String> uploadExternalSurveyLogo(
    String surveyId,
    Uint8List bytes,
    String contentType,
  ) async {
    final uid = await _requireUserId();
    final ext = contentType == 'image/png' ? 'png' : 'jpg';
    final ref = FirebaseStorage.instance
        .ref()
        .child('external_survey_logos')
        .child(uid)
        .child(surveyId)
        .child('logo.$ext');

    await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );
    return ref.getDownloadURL();
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
    final uid = await _requireUserId();
    await _firestore
        .collection('schools')
        .doc(uid)
        .collection('teachers')
        .add(teacher.toMap());
  }

  Future<void> updateTeacher(Teacher teacher) async {
    final uid = await _requireUserId();
    await _firestore
        .collection('schools')
        .doc(uid)
        .collection('teachers')
        .doc(teacher.id)
        .update(teacher.toMap());
  }

  Future<void> deleteTeacher(String teacherId) async {
    final uid = await _requireUserId();
    // מחק גם את כל הפעולות
    final actionsSnapshot = await _firestore
        .collection('schools')
        .doc(uid)
        .collection('teachers')
        .doc(teacherId)
        .collection('actions')
        .get();
    
    for (var doc in actionsSnapshot.docs) {
      await doc.reference.delete();
    }
    
    await _firestore
        .collection('schools')
        .doc(uid)
        .collection('teachers')
        .doc(teacherId)
        .delete();
  }

  /// מאחד שני מורים: מעביר פעולות מהמורה המקור (from) למורה היעד (to),
  /// וממזג שדות מידע כך שהמורה היעד שומר את שמו אבל מקבל מידע חסר מהמורה המקור.
  Future<void> mergeTeachers({
    required String fromTeacherId,
    required String toTeacherId,
  }) async {
    final uid = await _requireUserId();
    if (fromTeacherId == toTeacherId) return;

    final schoolRef = _firestore.collection('schools').doc(uid);
    final fromRef = schoolRef.collection('teachers').doc(fromTeacherId);
    final toRef = schoolRef.collection('teachers').doc(toTeacherId);

    final fromSnap = await fromRef.get();
    final toSnap = await toRef.get();
    if (!fromSnap.exists || !toSnap.exists) {
      throw Exception('אחד המורים לא נמצא למיזוג');
    }

    final fromTeacher = Teacher.fromMap(fromSnap.id, fromSnap.data()!);
    final toTeacher = Teacher.fromMap(toSnap.id, toSnap.data()!);

    // העברת פעולות
    final fromActions = await fromRef.collection('actions').get();
    for (final actionDoc in fromActions.docs) {
      await toRef.collection('actions').add(actionDoc.data());
      await actionDoc.reference.delete();
    }

    // מיזוג מידע: שומרים את המורה היעד כ"קאנוני",
    // וממלאים רק שדות שחסרים/ריקים אצלו מתוך מורה המקור.
    bool isEmptyMap(Map m) => m.isEmpty;
    bool isEmptyList(List l) => l.isEmpty;

    final merged = toTeacher.copyWith(
      notes: toTeacher.notes ?? fromTeacher.notes,
      motivationStyles: !isEmptyList(toTeacher.motivationStyles)
          ? toTeacher.motivationStyles
          : fromTeacher.motivationStyles,
      engagementSignals: !isEmptyList(toTeacher.engagementSignals)
          ? toTeacher.engagementSignals
          : fromTeacher.engagementSignals,
      engagementDomainScores: !isEmptyMap(toTeacher.engagementDomainScores)
          ? toTeacher.engagementDomainScores
          : fromTeacher.engagementDomainScores,
      engagementItemScores: !isEmptyMap(toTeacher.engagementItemScores)
          ? toTeacher.engagementItemScores
          : fromTeacher.engagementItemScores,
      engagementItemNotes: !isEmptyMap(toTeacher.engagementItemNotes)
          ? toTeacher.engagementItemNotes
          : fromTeacher.engagementItemNotes,
      engagementNote: toTeacher.engagementNote ?? fromTeacher.engagementNote,
      roles: !isEmptyList(toTeacher.roles) ? toTeacher.roles : fromTeacher.roles,
      lastInteractionDate:
          toTeacher.lastInteractionDate ?? fromTeacher.lastInteractionDate,
      mobilePhone: (toTeacher.mobilePhone != null && toTeacher.mobilePhone!.isNotEmpty)
          ? toTeacher.mobilePhone
          : fromTeacher.mobilePhone,
    );

    await toRef.update(merged.toMap());
    await fromRef.delete();
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

  /// מחזיר סטטיסטיקות של התייחסויות בימים האחרונים, מחולקות לפי סוג.
  ///
  /// [days] – כמה ימים אחורה לספור (ברירת מחדל: 14).
  /// התוצאה ממוינת מכרונולוגית (מהיום הישן לחדש).
  Future<List<DailyInteractions>> getRecentInteractionsStats({int days = 14}) async {
    if (_currentUserId == null) return const [];
    if (days <= 0) return const [];

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfRange = startOfToday.subtract(Duration(days: days - 1));
    final startIso = startOfRange.toIso8601String();
    final endIso = startOfToday.add(const Duration(days: 1)).toIso8601String();

    final teachersSnapshot = await _firestore
        .collection('schools')
        .doc(_currentUserId)
        .collection('teachers')
        .get();

    // מפתח: yyyy-MM-dd  ->  (מפתח פנימי: קטגוריית סוג -> כמות)
    final Map<String, Map<String, int>> buckets = {};

    for (var teacherDoc in teachersSnapshot.docs) {
      final actionsSnapshot = await teacherDoc.reference
          .collection('actions')
          .where('completed', isEqualTo: true)
          .where('date', isGreaterThanOrEqualTo: startIso)
          .where('date', isLessThan: endIso)
          .get();

      for (var actionDoc in actionsSnapshot.docs) {
        final action = Action.fromMap(actionDoc.id, actionDoc.data());
        final date = action.date;
        if (date == null) continue;

        final day = DateTime(date.year, date.month, date.day);
        if (day.isBefore(startOfRange) || day.isAfter(startOfToday)) continue;

        final dayKey =
            '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        final typeKey = _categorizeInteractionType(action.type);

        final dayBucket = buckets.putIfAbsent(dayKey, () => <String, int>{});
        dayBucket[typeKey] = (dayBucket[typeKey] ?? 0) + 1;
      }
    }

    final result = <DailyInteractions>[];
    buckets.forEach((dayKey, typeCounts) {
      final day = DateTime.parse(dayKey);
      result.add(DailyInteractions(day: day, typeCounts: typeCounts));
    });

    result.sort((a, b) => a.day.compareTo(b.day));
    return result;
  }

  /// מיפוי טקסט חופשי של סוג פעולה לקטגוריה ויזואלית קבועה.
  String _categorizeInteractionType(String rawType) {
    final t = rawType.toLowerCase();
    if (t.contains('מילה') || t.contains('טובה')) {
      return 'good_word';
    }
    if (t.contains('דיבור') || t.contains('שיחה קצר') || t.contains('קצר')) {
      return 'short_talk';
    }
    if (t.contains('נפגש') || t.contains('פגישה') || t.contains('meeting')) {
      return 'meeting';
    }
    return 'other';
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

  /// ספירת מילים טובות בלבד היום (למדד היומי המדויק).
  Future<int> getTodayGoodWordsCount() async {
    if (_currentUserId == null) return 0;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final startIso = startOfDay.toIso8601String();
    final endIso = endOfDay.toIso8601String();

    int count = 0;
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

      for (var doc in actionsSnapshot.docs) {
        final action = Action.fromMap(doc.id, doc.data());
        if (_categorizeInteractionType(action.type) == 'good_word') {
          count++;
        }
      }
    }
    return count;
  }

  /// רצף ימי פעילות (ראשון–חמישי) עם לפחות התייחסות אחת – נספר אחורה מהיום.
  /// שישי ושבת אינם נספרים ברצף.
  Future<int> getReferralStreakDays() async {
    if (_currentUserId == null) return 0;

    final now = DateTime.now();
    var checkDate = DateTime(now.year, now.month, now.day);
    int streak = 0;

    final teachersSnapshot = await _firestore
        .collection('schools')
        .doc(_currentUserId)
        .collection('teachers')
        .get();

    while (true) {
      // דילוג על שישי (5) ושבת (6) – DateTime.weekday: 1=Mon … 7=Sun
      final w = checkDate.weekday;
      if (w == 5 || w == 6) {
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      }

      final startIso = checkDate.toIso8601String();
      final endIso = checkDate.add(const Duration(days: 1)).toIso8601String();
      bool hasAction = false;

      for (var teacherDoc in teachersSnapshot.docs) {
        final actionsSnapshot = await teacherDoc.reference
            .collection('actions')
            .where('completed', isEqualTo: true)
            .where('date', isGreaterThanOrEqualTo: startIso)
            .where('date', isLessThan: endIso)
            .limit(1)
            .get();
        if (actionsSnapshot.docs.isNotEmpty) {
          hasAction = true;
          break;
        }
      }

      if (!hasAction) break;
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
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

  Future<List<Map<String, dynamic>>> getAllUpcomingActions({
    bool thisWeekOnly = false,
  }) async {
    if (_currentUserId == null) return [];

    final teachersSnapshot = await _firestore
        .collection('schools')
        .doc(_currentUserId)
        .collection('teachers')
        .get();

    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));

    // אוספים את כל הפיוצ׳רים לקריאה מקבילית – במקום לולאת await סדרתית על כל מורה
    final futures = <Future<List<Map<String, dynamic>>>>[];

    for (var teacherDoc in teachersSnapshot.docs) {
      futures.add(_loadTeacherUpcomingActions(
        teacherDoc: teacherDoc,
        thisWeekOnly: thisWeekOnly,
        now: now,
        weekFromNow: weekFromNow,
      ));
    }

    final results = await Future.wait(futures);
    final allActions = results.expand((x) => x).toList();

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

  /// קריאת פעולות עתידיות למורה יחיד – לשימוש פנימי, מאפשר ריצה מקבילית.
  Future<List<Map<String, dynamic>>> _loadTeacherUpcomingActions({
    required QueryDocumentSnapshot<Map<String, dynamic>> teacherDoc,
    required bool thisWeekOnly,
    required DateTime now,
    required DateTime weekFromNow,
  }) async {
    final teacher = Teacher.fromMap(teacherDoc.id, teacherDoc.data());

    final actionsSnapshot = await teacherDoc.reference
        .collection('actions')
        .where('completed', isEqualTo: false)
        .orderBy('date')
        .get();

    final List<Map<String, dynamic>> teacherActions = [];

    for (var actionDoc in actionsSnapshot.docs) {
      final action = Action.fromMap(actionDoc.id, actionDoc.data());
      final d = action.date;
      if (!thisWeekOnly || (d != null && d.isAfter(now) && d.isBefore(weekFromNow))) {
        teacherActions.add({
          'action': action,
          'teacherId': teacherDoc.id,
          'teacherName': teacher.name,
        });
      }
    }

    return teacherActions;
  }

  Future<void> addAction(String teacherId, Action action) async {
    final uid = await _requireUserId();
    final teacherRef = _firestore
        .collection('schools')
        .doc(uid)
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

  /// מחזיר מפה של insightId -> Action לכל הפעולות שיש להן insightId.
  /// משמש לסינון היגדים: היגד מוסתר אם יש משימה מקושרת (בוצעה או פחות מחודש עבר).
  /// היגד מופיע מחדש אם עבר חודש והמשימה לא בוצעה.
  Future<Map<String, Action>> getActionsLinkedToInsights() async {
    if (_currentUserId == null) return {};

    final teachersSnapshot = await _firestore
        .collection('schools')
        .doc(_currentUserId)
        .collection('teachers')
        .get();

    final result = <String, Action>{};
    for (final teacherDoc in teachersSnapshot.docs) {
      final actionsSnapshot = await teacherDoc.reference
          .collection('actions')
          .get();

      for (final actionDoc in actionsSnapshot.docs) {
        final data = actionDoc.data();
        final insightId = data['insightId'] as String?;
        if (insightId != null && insightId.isNotEmpty) {
          result[insightId] = Action.fromMap(actionDoc.id, data);
        }
      }
    }
    return result;
  }

  Future<void> updateAction(String teacherId, Action action) async {
    final uid = await _requireUserId();
    await _firestore
        .collection('schools')
        .doc(uid)
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

  /// קישור כללי לטופס החיצוני של בית הספר.
  /// המנהל מעתיק את הקישור מעמוד ההגדרות, שולח לקבוצת הצוות,
  /// וכל מורה נכנס, כותב את שמו המלא וממלא את השאלון.
  Future<String> getOrCreateSchoolFormLink() async {
    final uid = await _requireUserId();
    var settings = await getManagerSettings();
    String token = settings.schoolFormToken ?? '';
    if (token.isEmpty) {
      final random = Random.secure();
      final bytes = List<int>.generate(24, (_) => random.nextInt(256));
      token = base64Url.encode(bytes).replaceAll('=', '');
      settings = settings.copyWith(schoolFormToken: token);
      await updateManagerSettings(settings);
    }

    const baseUrl = 'https://shimur.web.app';
    // s = schoolId (uid של המנהל), t = טוקן אבטחה לטופס הכללי
    return '$baseUrl/form.html?s=$uid&t=$token';
  }

  // ========== הגדרות מנהל ==========
  static const String _managerSettingsDocId = 'manager';

  Future<ManagerSettings> getManagerSettings() async {
    var uid = _currentUserId;
    uid ??= await _authService.ensureUserIdReady();
    uid ??= AuthState.verifiedUid;
    if (uid == null) return const ManagerSettings();

    final doc = await _firestore
        .collection('schools')
        .doc(uid)
        .collection('settings')
        .doc(_managerSettingsDocId)
        .get();

    if (doc.exists && doc.data() != null) {
      return ManagerSettings.fromMap(doc.data());
    }
    return const ManagerSettings();
  }

  Future<void> updateManagerSettings(ManagerSettings settings) async {
    final uid = await _requireUserId();
    await _firestore
        .collection('schools')
        .doc(uid)
        .collection('settings')
        .doc(_managerSettingsDocId)
        .set(settings.toMap());
  }

  /// מוודא שקיים schoolFormToken – נדרש כדי שטופס השאלון החיצוני יעבוד.
  /// קוראים פעם אחת בטעינת האפליקציה.
  Future<void> ensureManagerSettingsWithFormToken() async {
    try {
      var settings = await getManagerSettings();
      if ((settings.schoolFormToken ?? '').isEmpty) {
        final random = Random.secure();
        final bytes = List<int>.generate(24, (_) => random.nextInt(256));
        final token = base64Url.encode(bytes).replaceAll('=', '');
        settings = settings.copyWith(schoolFormToken: token);
        await updateManagerSettings(settings);
      }
    } catch (_) {
      // שקט – לא קריטי
    }
  }

  /// בודק אם ניתן להשתמש ב-AI (לא חרגנו מהמכסה החודשית).
  /// מחזיר (יכול להשתמש, הודעת שגיאה אם לא).
  Future<(bool canUse, String? errorMessage)> canUseGemini() async {
    final settings = await getManagerSettings();
    final monthKey =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
    final count = settings.geminiUsageMonth == monthKey
        ? settings.geminiUsageCount
        : 0;
    if (count >= settings.geminiUsageLimitPerMonth) {
      return (false, 'הגעת למכסת השימוש החודשית (${settings.geminiUsageLimitPerMonth})');
    }
    return (true, null);
  }

  /// רושם שימוש ב-AI ומעדכן את הספירה.
  Future<void> recordGeminiUsage() async {
    final settings = await getManagerSettings();
    final monthKey =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
    final count = settings.geminiUsageMonth == monthKey
        ? settings.geminiUsageCount + 1
        : 1;
    await updateManagerSettings(settings.copyWith(
      geminiUsageMonth: monthKey,
      geminiUsageCount: count,
    ));
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
    final uid = await _requireUserId();
    await _firestore.collection(_recommendedActionsCollection).add({
      'type': type,
      'addedByUserId': isAnonymous ? null : uid,
      'isAnonymous': isAnonymous,
      'createdAt': DateTime.now().toIso8601String(),
      'ratingSum': 0,
      'ratingCount': 0,
      'ratingByUserId': <String, int>{},
    });
  }

  /// מעדכן דירוג של המשתמש הנוכחי (1–5). אם כבר דירג – מעדכן.
  Future<void> setRecommendedActionRating(String recommendedActionId, int rating) async {
    final uid = await _requireUserId();
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
      final oldRating = prevByUser[uid];

      int newSum = prevSum;
      int newCount = prevCount;
      if (oldRating != null) {
        newSum -= oldRating;
        newCount -= 1;
      }
      newSum += rating;
      newCount += 1;
      prevByUser[uid] = rating;

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
    final uid = await _requireUserId();
    if (text.trim().isEmpty) return;

    await _firestore
        .collection(_recommendedActionsCollection)
        .doc(recommendedActionId)
        .collection('comments')
        .add({
      'recommendedActionId': recommendedActionId,
      'userId': isAnonymous ? null : uid,
      'isAnonymous': isAnonymous,
      'text': text.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // ========== שאלונים חיצוניים ==========
  static const String _externalSurveysCollection = 'external_surveys';

  /// יצירת שאלון חיצוני חדש
  Future<String> createExternalSurvey(ExternalSurvey survey) async {
    final uid = await _requireUserId();
    final docRef = await _firestore
        .collection('schools')
        .doc(uid)
        .collection(_externalSurveysCollection)
        .add(survey.toMap());

    return docRef.id;
  }

  /// עדכון שאלון חיצוני קיים
  Future<void> updateExternalSurvey(ExternalSurvey survey) async {
    final uid = await _requireUserId();
    final map = Map<String, dynamic>.from(survey.toMap());
    if (survey.logoUrl == null) map['logoUrl'] = FieldValue.delete();
    await _firestore
        .collection('schools')
        .doc(uid)
        .collection(_externalSurveysCollection)
        .doc(survey.id)
        .update(map);
  }

  /// מחיקת שאלון חיצוני
  Future<void> deleteExternalSurvey(String surveyId) async {
    final uid = await _requireUserId();
    await _firestore
        .collection('schools')
        .doc(uid)
        .collection(_externalSurveysCollection)
        .doc(surveyId)
        .delete();
  }

  /// קבלת רשימת כל השאלונים החיצוניים של בית הספר
  Stream<List<ExternalSurvey>> getExternalSurveysStream() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('schools')
        .doc(_currentUserId)
        .collection(_externalSurveysCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ExternalSurvey.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// קבלת שאלון חיצוני ספציפי
  Future<ExternalSurvey?> getExternalSurvey(String surveyId) async {
    if (_currentUserId == null) return null;

    final doc = await _firestore
        .collection('schools')
        .doc(_currentUserId)
        .collection(_externalSurveysCollection)
        .doc(surveyId)
        .get();

    if (doc.exists && doc.data() != null) {
      return ExternalSurvey.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  /// יצירת או קבלת קישור לשאלון חיצוני
  /// משתמש ב-schoolFormToken (כמו טופס רגיל) כדי שהכללים ב-Firestore יאפשרו יצירה/עדכון מורים
  Future<String> getExternalSurveyLink(String surveyId) async {
    final uid = await _requireUserId();
    final survey = await getExternalSurvey(surveyId);
    if (survey == null) throw Exception('שאלון לא נמצא');

    var settings = await getManagerSettings();
    String token = settings.schoolFormToken ?? '';
    if (token.isEmpty) {
      final random = Random.secure();
      final bytes = List<int>.generate(24, (_) => random.nextInt(256));
      token = base64Url.encode(bytes).replaceAll('=', '');
      settings = settings.copyWith(schoolFormToken: token);
      await updateManagerSettings(settings);
    }

    const baseUrl = 'https://shimur.web.app';
    // s = schoolId, surveyId = מזהה השאלון, t = טוקן (schoolFormToken)
    return '$baseUrl/form.html?s=$uid&surveyId=$surveyId&t=$token';
  }

  /// עדכון תשובות של מורה לשאלון חיצוני
  Future<void> updateTeacherExternalSurveyResponse({
    required String teacherId,
    required String surveyInstanceId,
    required Map<String, dynamic> responses,
  }) async {
    final uid = await _requireUserId();
    final teacherRef = _firestore
        .collection('schools')
        .doc(uid)
        .collection('teachers')
        .doc(teacherId);

    final teacherDoc = await teacherRef.get();
    if (!teacherDoc.exists) {
      throw Exception('מורה לא נמצא');
    }

    final teacher = Teacher.fromMap(teacherDoc.id, teacherDoc.data()!);
    final updatedExternalSurveys = Map<String, Map<String, dynamic>>.from(
        teacher.externalSurveys);
    updatedExternalSurveys[surveyInstanceId] = responses;

    await teacherRef.update({
      'externalSurveys': updatedExternalSurveys,
    });
  }

  /// חיפוש מורה לפי שם (לשימוש בטופס הווב)
  Future<Teacher?> findTeacherByName(String name) async {
    if (_currentUserId == null) return null;

    // נרמול שם לחיפוש (הסרת רווחים מיותרים, טרימינג)
    final normalizedName = name.trim().replaceAll(RegExp(r'\s+'), ' ');

    final teachersSnapshot = await _firestore
        .collection('schools')
        .doc(_currentUserId)
        .collection('teachers')
        .get();

    for (var doc in teachersSnapshot.docs) {
      final teacher = Teacher.fromMap(doc.id, doc.data());
      final teacherNormalizedName =
          teacher.name.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (teacherNormalizedName == normalizedName) {
        return teacher;
      }
    }

    return null;
  }
}

/// מודל עזר לסטטיסטיקות התייחסויות יומיות לדשבורד.
class DailyInteractions {
  final DateTime day;
  final Map<String, int> typeCounts;

  const DailyInteractions({
    required this.day,
    required this.typeCounts,
  });

  int get totalCount =>
      typeCounts.values.fold(0, (previous, element) => previous + element);
}

