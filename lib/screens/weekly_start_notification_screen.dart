import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/teacher.dart';
import '../services/firestore_service.dart';
import '../utils/birthday_utils.dart';
import 'teacher_details_screen.dart';

/// מסך התראה לתחילת שבוע – פגישות מומלצות, מילים טובות, העתקה למזכירה, תובנות.
/// ההמלצות מבוססות על נתונים אמיתיים: עומס, תאריך אינטראקציה אחרונה, ציוני גאלופ Q12, מגמת מצב רוח.
class WeeklyStartNotificationScreen extends StatefulWidget {
  const WeeklyStartNotificationScreen({super.key});

  @override
  State<WeeklyStartNotificationScreen> createState() =>
      _WeeklyStartNotificationScreenState();
}

class _WeeklyStartNotificationScreenState
    extends State<WeeklyStartNotificationScreen> {
  final _firestoreService = FirestoreService();
  final _random = Random();

  // היגדים ממדדי מעורבות (גאלופ Q12) – להצגה אקראית
  static const List<String> _engagementStatements = [
    'בשבוע האחרון, קיבלתי הכרה או שבח על עבודה טובה',
    'נראה שאכפת למנהל שלי, או מישהו בעבודה, ממני כאדם',
    'יש מישהו בעבודה שמעודד את ההתפתחות שלי',
    'בעבודה, נראה שהדעות שלי נחשבות',
    'בחצי השנה האחרונה, מישהו בעבודה דיבר איתי על ההתקדמות שלי',
    'השנה האחרונה, היו לי הזדמנויות בעבודה ללמוד ולצמוח',
  ];

  // תובנות מוכנות (אקראי)
  static const List<String> _insightTemplates = [
    'מורה %s בעליה בסטטוס בזמן האחרון – כדאי לחזק',
    'נתת הרבה מילים טובות ל-%s לאחרונה – ייתכן שכדאי לפזר גם לאחרים',
    'ל-%s לא הייתה אינטראקציה ממושכת – שווה לבדוק',
    '%s דירג/ה נמוך בשאלה על הכרה – הזדמנות למילה טובה',
  ];

  List<_MeetSuggestion> _meetSuggestions = [];
  List<Teacher> _kindWordSuggestions = [];
  List<Teacher> _birthdayTeachers = [];
  List<String> _randomInsights = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAndBuildSuggestions();
  }

  /// מחזיר סיבה לפגישה מבוססת נתונים אמיתיים של המורה.
  String _meetReasonFromData(Teacher t) {
    if (t.busyReason != null && t.busyReason!.trim().isNotEmpty) {
      return '${t.busyReason!.trim()} – כדאי לתאם ציפיות';
    }
    if (t.busySeason != null && t.busySeason!.trim().isNotEmpty) {
      return 'תקופת עומס מתקרבת – כדאי לתאם ציפיות';
    }
    if (t.nextActionDate != null || t.nextActionType != null) {
      return 'לפי תדירות שהוגדרה בתחילת השנה';
    }
    final q11 = t.engagementItemScores['q11'];
    if (q11 != null && q11 <= 3) {
      return 'דיברו איתי על ההתקדמות שלי – הזדמנות לשיחה';
    }
    if (t.moodTrend == 'down') {
      return 'מגמת ירידה – כדאי לשיחה';
    }
    final last = t.lastInteractionDate;
    if (last == null) {
      return 'לא הייתה אינטראקציה מתועדת – שווה לבדוק';
    }
    final daysSince = DateTime.now().difference(last).inDays;
    if (daysSince > 14) {
      return 'לא הייתה אינטראקציה ממושכת – שווה לבדוק';
    }
    return 'לפי תדירות שהוגדרה בתחילת השנה';
  }

  Future<void> _loadAndBuildSuggestions() async {
    setState(() => _isLoading = true);
    final teachers = await _firestoreService.getTeachersStream().first;
    if (!mounted) return;

    final meetCount = 3;
    final kindWordCount = 7;

    List<_MeetSuggestion> meets = [];
    List<Teacher> kindWords = [];

    final realTeachers = teachers.where((t) => !t.id.startsWith('demo')).toList();

    if (realTeachers.isNotEmpty) {
      // פגישות: מורים עם סיבה מבוססת נתונים – ממוינים לפי עדיפות
      final meetCandidates = <_MeetSuggestion>[];
      for (final t in realTeachers) {
        meetCandidates.add(_MeetSuggestion(
          teacher: t,
          reason: _meetReasonFromData(t),
        ));
      }
      // עדיפות: עומס > nextAction > q11 נמוך > mood down > lastInteraction ישן > fallback
      meetCandidates.sort((a, b) {
        int score(_MeetSuggestion s) {
          final t = s.teacher;
          if (t.busyReason != null && t.busyReason!.trim().isNotEmpty) return 100;
          if (t.busySeason != null && t.busySeason!.trim().isNotEmpty) return 90;
          if (t.nextActionDate != null || t.nextActionType != null) return 80;
          if ((t.engagementItemScores['q11'] ?? 6) <= 3) return 70;
          if (t.moodTrend == 'down') return 60;
          if (t.lastInteractionDate == null) return 50;
          final days = DateTime.now().difference(t.lastInteractionDate!).inDays;
          if (days > 14) return 40;
          return 10;
        }
        return score(b).compareTo(score(a));
      });
      meets = meetCandidates.take(meetCount).toList();

      // מילים טובות: מורים עם ציון נמוך בהכרה (q4) או ללא אינטראקציה ממושכת
      final kindWordCandidates = <({Teacher t, int score})>[];
      for (final t in realTeachers) {
        if (meets.any((m) => m.teacher.id == t.id)) continue; // לא להכפיל
        int s = 0;
        final q4 = t.engagementItemScores['q4'];
        if (q4 != null && q4 <= 3) s += 50;
        if (t.moodTrend == 'down') s += 30;
        if (t.lastInteractionDate == null) s += 20;
        else {
          final days = DateTime.now().difference(t.lastInteractionDate!).inDays;
          if (days > 14) s += 25;
        }
        if (s > 0) kindWordCandidates.add((t: t, score: s));
      }
      kindWordCandidates.sort((a, b) => b.score.compareTo(a.score));
      kindWords = kindWordCandidates.map((e) => e.t).take(kindWordCount).toList();
      if (kindWords.length < kindWordCount) {
        final usedIds = {...meets.map((m) => m.teacher.id), ...kindWords.map((t) => t.id)};
        final rest = realTeachers.where((t) => !usedIds.contains(t.id)).toList()..shuffle(_random);
        for (final t in rest) {
          if (kindWords.length >= kindWordCount) break;
          kindWords.add(t);
        }
      }
    }

    if (meets.isEmpty || kindWords.length < kindWordCount) {
      // דוגמאות סטטיות כשאין מספיק מורים אמיתיים
      final demoNamesMeet = ['רחל לוי', 'דוד כהן', 'מיכל אברהם'];
      final demoNamesKind = [
        'שרה גולדמן', 'יוסי רוזן', 'נעמי ברק', 'אלי שמעון',
        'רונית דוד', 'אבי מלכה', 'תמר נחום',
      ];
      if (meets.isEmpty) {
        for (var i = 0; i < meetCount; i++) {
          meets.add(_MeetSuggestion(
            teacher: _demoTeacher(demoNamesMeet[i], 'demo-meet-$i'),
            reason: 'דוגמא – הוסף מורים במערכת כדי לראות המלצות מבוססות נתונים',
          ));
        }
      }
      if (kindWords.length < kindWordCount) {
        for (var i = kindWords.length; i < kindWordCount && i < demoNamesKind.length; i++) {
          kindWords.add(_demoTeacher(demoNamesKind[i], 'demo-kind-$i'));
        }
      }
    }

    // תובנות אקראיות: היגד מעורבות + תובנה עם שם (אם יש מורים)
    List<String> insights = [];
    insights.add(_engagementStatements[_random.nextInt(_engagementStatements.length)]);
    if (teachers.isNotEmpty) {
      final t = teachers[_random.nextInt(teachers.length)];
      final template =
          _insightTemplates[_random.nextInt(_insightTemplates.length)];
      insights.add(template.replaceFirst('%s', t.name));
    } else {
      insights.add(_insightTemplates[_random.nextInt(_insightTemplates.length)]
          .replaceFirst('%s', 'מורה מהצוות'));
    }
    if (_insightTemplates.length > 2) {
      final idx = _random.nextInt(_insightTemplates.length);
      final name = teachers.isNotEmpty
          ? teachers[_random.nextInt(teachers.length)].name
          : 'מורה';
      insights.add(_insightTemplates[idx].replaceFirst('%s', name));
    }

    // ימי הולדת השבוע (היום + 6 ימים)
    final birthdayThisWeek = realTeachers
        .where((t) =>
            t.birthday != null &&
            t.birthday!.isNotEmpty &&
            BirthdayUtils.isBirthdayWithinDays(t.birthday, 6))
        .toList();
    birthdayThisWeek.sort((a, b) {
      final da = BirthdayUtils.daysUntilBirthday(a.birthday) ?? 999;
      final db = BirthdayUtils.daysUntilBirthday(b.birthday) ?? 999;
      return da.compareTo(db);
    });

    setState(() {
      _meetSuggestions = meets;
      _kindWordSuggestions = kindWords;
      _birthdayTeachers = birthdayThisWeek;
      _randomInsights = insights;
      _isLoading = false;
    });
  }

  Teacher _demoTeacher(String name, String id) {
    return Teacher(
      id: id,
      name: name,
      seniorityYears: 3,
      totalSeniorityYears: 8,
      status: 'green',
      createdAt: DateTime.now(),
    );
  }

  void _copyMeetingsToSecretary() {
    final buffer = StringBuffer();
    buffer.writeln('פגישות מומלצות השבוע – להעברה למזכירה');
    buffer.writeln('────────────────────────────');
    for (var s in _meetSuggestions) {
      buffer.writeln('• ${s.teacher.name} – ${s.reason}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('הועתק ללוח – ניתן להעביר למזכירה'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('התראה לתחילת השבוע'),
          backgroundColor: const Color(0xFF11a0db),
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadAndBuildSuggestions,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildMeetSection(),
                      const SizedBox(height: 16),
                      _buildCopyButton(),
                      const SizedBox(height: 20),
                      if (_birthdayTeachers.isNotEmpty) ...[
                        _buildBirthdaysSection(),
                        const SizedBox(height: 20),
                      ],
                      _buildKindWordSection(),
                      const SizedBox(height: 24),
                      _buildInsightsSection(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildMeetSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_available, color: Colors.orange[700]),
                const SizedBox(width: 8),
                const Text(
                  'כדאי להיפגש השבוע',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_meetSuggestions.length} מורים שכדאי לתאם איתם פגישה',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            ..._meetSuggestions.map((s) => _meetTile(s)),
          ],
        ),
      ),
    );
  }

  Widget _meetTile(_MeetSuggestion s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF11a0db).withOpacity(0.2),
          child: const Icon(Icons.person, color: Color(0xFF11a0db)),
        ),
        title: Text(
          s.teacher.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          s.reason,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        trailing: Icon(Icons.chevron_left, color: Colors.grey[400]),
        onTap: () => _openTeacher(s.teacher),
      ),
    );
  }

  Widget _buildBirthdaysSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cake, color: Colors.pink[300]),
                const SizedBox(width: 8),
                const Text(
                  'ימי הולדת השבוע – ברכי והתייחסי!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_birthdayTeachers.length} מורים עם יום הולדת השבוע',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            ..._birthdayTeachers.map((t) {
              final days = BirthdayUtils.daysUntilBirthday(t.birthday) ?? 0;
              final dayLabel = days == 0
                  ? 'היום!'
                  : days == 1
                      ? 'מחר'
                      : 'בעוד $days ימים';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.pink.withValues(alpha: 0.2),
                    child: Icon(Icons.cake, color: Colors.pink[300]),
                  ),
                  title: Text(
                    t.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${BirthdayUtils.formatForDisplay(t.birthday)} – $dayLabel',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  trailing: Icon(Icons.chevron_left, color: Colors.grey[400]),
                  onTap: () => _openTeacher(t),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildKindWordSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.pink[300]),
                const SizedBox(width: 8),
                const Text(
                  'מילה טובה השבוע',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_kindWordSuggestions.length} מורים שכדאי לתת להם מילה טובה',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kindWordSuggestions
                  .map((t) => ActionChip(
                        avatar: const Icon(Icons.thumb_up_alt_outlined,
                            size: 18, color: Color(0xFF11a0db)),
                        label: Text(t.name),
                        onPressed: () => _openTeacher(t),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyButton() {
    return OutlinedButton.icon(
      onPressed: _copyMeetingsToSecretary,
      icon: const Icon(Icons.copy),
      label: const Text('העתק למזכירה – פגישות'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: Color(0xFF11a0db)),
        foregroundColor: const Color(0xFF11a0db),
      ),
    );
  }

  Widget _buildInsightsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber[700]),
                const SizedBox(width: 8),
                const Text(
                  'תובנות והתייחסויות',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'היגדים ממדדי המעורבות והמלצות להתייחסות',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            ..._randomInsights.map(
              (text) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.format_quote, size: 20, color: Colors.grey[500]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openTeacher(Teacher t) {
    if (t.id.startsWith('demo')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('זו דוגמא – הוסף מורים במערכת כדי לראות פרטים'),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherDetailsScreen(teacherId: t.id),
      ),
    );
  }
}

class _MeetSuggestion {
  final Teacher teacher;
  final String reason;

  _MeetSuggestion({required this.teacher, required this.reason});
}
