import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/teacher.dart';
import '../services/firestore_service.dart';
import 'teacher_details_screen.dart';

/// מסך דוגמא: התראה לתחילת שבוע – פגישות מומלצות, מילים טובות, העתקה למזכירה, תובנות.
class WeeklyStartNotificationScreen extends StatefulWidget {
  const WeeklyStartNotificationScreen({Key? key}) : super(key: key);

  @override
  State<WeeklyStartNotificationScreen> createState() =>
      _WeeklyStartNotificationScreenState();
}

class _WeeklyStartNotificationScreenState
    extends State<WeeklyStartNotificationScreen> {
  final _firestoreService = FirestoreService();
  final _random = Random();

  // דוגמאות לסיבות פגישה
  static const List<String> _meetReasons = [
    'תקופת עומס מתקרבת – כדאי לתאם ציפיות',
    'סיים/ה פרויקט – הזדמנות לשיחה',
    'לפי תדירות שהוגדרה בתחילת השנה',
  ];

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
  List<String> _randomInsights = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAndBuildSuggestions();
  }

  Future<void> _loadAndBuildSuggestions() async {
    setState(() => _isLoading = true);
    final teachers = await _firestoreService.getTeachersStream().first;
    if (!mounted) return;

    // דוגמא: אם יש מורים – בוחרים מהם; אחרת דוגמאות סטטיות
    final meetCount = 3;
    final kindWordCount = 7;

    List<_MeetSuggestion> meets = [];
    List<Teacher> kindWords = [];

    if (teachers.length >= meetCount + kindWordCount) {
      final shuffled = List<Teacher>.from(teachers)..shuffle(_random);
      for (int i = 0; i < meetCount && i < shuffled.length; i++) {
        meets.add(_MeetSuggestion(
          teacher: shuffled[i],
          reason: _meetReasons[i % _meetReasons.length],
        ));
      }
      final rest = shuffled.skip(meetCount).toList();
      for (int i = 0; i < kindWordCount && i < rest.length; i++) {
        kindWords.add(rest[i]);
      }
    } else {
      // דוגמאות סטטיות כשאין מספיק מורים
      final demoNamesMeet = ['רחל לוי', 'דוד כהן', 'מיכל אברהם'];
      final demoNamesKind = [
        'שרה גולדמן',
        'יוסי רוזן',
        'נעמי ברק',
        'אלי שמעון',
        'רונית דוד',
        'אבי מלכה',
        'תמר נחום',
      ];
      for (int i = 0; i < meetCount; i++) {
        meets.add(_MeetSuggestion(
          teacher: _demoTeacher(demoNamesMeet[i], 'demo-meet-$i'),
          reason: _meetReasons[i % _meetReasons.length],
        ));
      }
      for (int i = 0; i < kindWordCount; i++) {
        kindWords.add(_demoTeacher(demoNamesKind[i], 'demo-kind-$i'));
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

    setState(() {
      _meetSuggestions = meets;
      _kindWordSuggestions = kindWords;
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
    buffer.writeln('');
    buffer.writeln('מילים טובות מומלצות השבוע:');
    for (var t in _kindWordSuggestions) {
      buffer.writeln('• ${t.name}');
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
                      const SizedBox(height: 20),
                      _buildKindWordSection(),
                      const SizedBox(height: 20),
                      _buildCopyButton(),
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
              '3 מורים שכדאי לתאם איתם פגישה',
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
              '7 מורים שכדאי לתת להם מילה טובה',
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
      label: const Text('העתק למזכירה – פגישות ומילים טובות'),
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
