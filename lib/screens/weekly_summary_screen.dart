import 'package:flutter/material.dart';
import '../models/teacher.dart';
import '../services/firestore_service.dart';
import 'add_action_screen.dart';
import 'teacher_details_screen.dart';

/// מסך סיכום שבוע – התראה ליום שישי.
/// החלק ימינה = התייחסתי השבוע, שמאלה = לא התייחסתי.
/// עדכון סטטוס רגשי (פורח/זורם/מתוח/מנותק/שחוק), היגדים מהשאלון להעברת לפעולה.
class WeeklySummaryScreen extends StatefulWidget {
  const WeeklySummaryScreen({Key? key}) : super(key: key);

  @override
  State<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends State<WeeklySummaryScreen> {
  final _firestoreService = FirestoreService();

  /// היגדי גאלופ Q12 (q1..q12) + כותרות קצרות לבעיה
  static const List<({String key, String question, String problemLabel})>
      _q12WithLabels = [
    (key: 'q1', question: 'אני יודע/ת מה מצפים ממני בעבודה', problemLabel: 'ציפיות ובהירות'),
    (key: 'q2', question: 'יש לי את החומרים והציוד שאני צריך/ה', problemLabel: 'משאבים וציוד'),
    (key: 'q3', question: 'הזדמנות לעשות מה שאני הכי טוב/ה בו', problemLabel: 'עשייה מהחוזקות'),
    (key: 'q4', question: 'קיבלתי הכרה או שבח על עבודה טובה', problemLabel: 'הכרה ושבח'),
    (key: 'q5', question: 'אכפת למנהל/מישהו בעבודה ממני כאדם', problemLabel: 'אכפתיות'),
    (key: 'q6', question: 'מישהו בעבודה מעודד את ההתפתחות שלי', problemLabel: 'עידוד התפתחות'),
    (key: 'q7', question: 'הדעות שלי נחשבות בעבודה', problemLabel: 'דעות נחשבות'),
    (key: 'q8', question: 'המשימה של ביה"ס גורמת להרגיש שהעבודה חשובה', problemLabel: 'משמעות'),
    (key: 'q9', question: 'חברי הצוות מחויבים לעבודה איכותית', problemLabel: 'מחויבות צוות'),
    (key: 'q10', question: 'יש לי חבר/ה טוב/ה בעבודה', problemLabel: 'חבר בעבודה'),
    (key: 'q11', question: 'דיברו איתי על ההתקדמות שלי', problemLabel: 'שיחת התקדמות'),
    (key: 'q12', question: 'הזדמנויות ללמוד ולצמוח', problemLabel: 'למידה וצמיחה'),
  ];

  /// 5 מדרגות סטטוס בעברית + צבע רמזור
  static const List<({String id, String label, Color color})> _moodLevels = [
    (id: 'פורח', label: 'פורח', color: Color(0xFF2E7D32)),
    (id: 'זורם', label: 'זורם', color: Color(0xFF00897B)),
    (id: 'מתוח', label: 'מתוח', color: Color(0xFFFF8F00)),
    (id: 'מנותק', label: 'מנותק', color: Color(0xFFE65100)),
    (id: 'שחוק', label: 'שחוק', color: Color(0xFFC62828)),
  ];

  /// מיפוי ערך שמור (אנגלית/עברית) לתצוגה בעברית – מונע גלישה לאנגלית
  static String _moodDisplay(String? raw) {
    if (raw == null || raw.isEmpty) return 'לא עודכן';
    final lower = raw.toLowerCase();
    if (lower == 'bloom' || lower == 'פורח') return 'פורח';
    if (lower == 'flow' || lower == 'זורם') return 'זורם';
    if (lower == 'tense' || lower == 'מתוח') return 'מתוח';
    if (lower == 'disconnected' || lower == 'מנותק') return 'מנותק';
    if (lower == 'burned_out' || lower == 'שחוק') return 'שחוק';
    return raw;
  }

  static Color _moodColor(String? raw) {
    final display = _moodDisplay(raw);
    for (final e in _moodLevels) {
      if (e.label == display) return e.color;
    }
    return Colors.grey;
  }

  /// פעולות מוצעות לפי סוג בעיה (לפי problemLabel)
  static const Map<String, List<String>> _suggestedActionsByProblem = {
    'ציפיות ובהירות': ['שיחה ברורה על ציפיות', 'הגדרת יעדים משותפים', 'מעקב שבועי קצר'],
    'משאבים וציוד': ['בדיקת ציוד וכיתה', 'שיחה עם רכז מקצועי', 'בקשת תקציב אם חסר'],
    'עשייה מהחוזקות': ['התאמת תפקיד/שיעורים לחוזקות', 'שיחה על תחומי חוזקה'],
    'הכרה ושבח': ['מילה טובה פומבית', 'הכרה בפגישה', 'מכתב הערכה'],
    'אכפתיות': ['שיחה אישית קצרה', 'בדיקת רווחה', 'הפנייה לליווי אם נדרש'],
    'עידוד התפתחות': ['הצעה להשתלמות', 'ליווי פדגוגי', 'שיחת קריירה'],
    'דעות נחשבות': ['שיתוף בהחלטות רלוונטיות', 'ייעוץ לפני שינוי', 'פורום צוות'],
    'משמעות': ['שיחת חזון ויעדים', 'חיבור למטרת ביה"ס'],
    'מחויבות צוות': ['פעילות צוותית', 'שיח צוות', 'העלאת נושא בישיבה'],
    'חבר בעבודה': ['חיבור בין עמיתים', 'פעילות חברתית', 'בדיקה עם רכז שכבה'],
    'שיחת התקדמות': ['שיחת משוב מתוכננת', 'העלאת הנושא בישיבה'],
    'למידה וצמיחה': ['השתלמות מתאימה', 'אתגר/פרויקט חדש', 'ליווי מקצועי'],
  };

  List<Teacher> _teachers = [];
  final Set<String> _addressedIds = {};
  final Set<String> _notAddressedIds = {};
  /// מורים שהייתה להם התייחסות מתועדת השבוע (פעולה) – מוצגים בסוף בצבע התייחסתי
  final Set<String> _documentedThisWeekIds = {};
  final Map<String, String> _moodUpdates = {}; // teacherId -> mood (פורח/...)
  final Map<String, String> _moodTrendUpdates = {}; // teacherId -> 'up'|'down'
  final Map<String, String> _moodNoteUpdates = {}; // teacherId -> note
  final Set<String> _selectedInsightIds = {}; // "teacherId_q2" etc.
  bool _isLoading = true;
  bool _moodSaving = false;

  List<Teacher> get _toClassify =>
      _teachers.where((t) => !_addressedIds.contains(t.id) && !_notAddressedIds.contains(t.id)).toList();
  List<Teacher> get _documentedThisWeek =>
      _teachers.where((t) => _documentedThisWeekIds.contains(t.id)).toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final teachers = await _firestoreService.getTeachersStream().first;
    if (!mounted) return;
    final documentedIds = await _firestoreService.getTeacherIdsWithActionsInCurrentWeek();
    if (!mounted) return;
    setState(() {
      _teachers = teachers;
      _documentedThisWeekIds.clear();
      _documentedThisWeekIds.addAll(documentedIds);
      for (final id in documentedIds) {
        _addressedIds.add(id);
        _notAddressedIds.remove(id);
      }
      _isLoading = false;
    });
  }

  void _onSwiped(Teacher teacher, bool addressed) {
    setState(() {
      if (addressed) {
        _addressedIds.add(teacher.id);
        _notAddressedIds.remove(teacher.id);
      } else {
        _notAddressedIds.add(teacher.id);
        _addressedIds.remove(teacher.id);
      }
    });
  }

  List<_EngagementInsight> _buildEngagementInsights() {
    final list = <_EngagementInsight>[];
    for (final t in _teachers) {
      if (t.id.startsWith('demo')) continue;
      final scores = t.engagementItemScores;
      final notes = t.engagementItemNotes;
      for (final item in _q12WithLabels) {
        final score = scores[item.key];
        final note = notes[item.key]?.trim() ?? '';
        final lowScore = score != null && score <= 3;
        final hasNote = note.isNotEmpty;
        if (!lowScore && !hasNote) continue;
        String description = '';
        if (lowScore && hasNote) {
          description = 'מורה ${t.name}: ציון נמוך (${score}/6) + הערה: $note';
        } else if (lowScore) {
          description = 'מורה ${t.name}: ציון נמוך בשאלה על ${item.problemLabel} (${score}/6)';
        } else {
          description = 'מורה ${t.name}: הערה – $note';
        }
        list.add(_EngagementInsight(
          id: '${t.id}_${item.key}',
          teacherId: t.id,
          teacherName: t.name,
          questionKey: item.key,
          problemLabel: item.problemLabel,
          description: description,
          suggestedActions: _suggestedActionsByProblem[item.problemLabel] ?? [],
        ));
      }
      if (t.engagementNote != null && t.engagementNote!.trim().isNotEmpty) {
        list.add(_EngagementInsight(
          id: '${t.id}_note',
          teacherId: t.id,
          teacherName: t.name,
          questionKey: '',
          problemLabel: 'הערה כללית',
          description: 'מורה ${t.name}: ${t.engagementNote!.trim()}',
          suggestedActions: ['שיחה אישית', 'מעקב', 'הפנייה לליווי'],
        ));
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('סיכום שבוע'),
          backgroundColor: const Color(0xFF11a0db),
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _teachers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'אין מורים במערכת',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSwipeSection(),
                          const SizedBox(height: 24),
                          _buildMoodSection(),
                          const SizedBox(height: 24),
                          _buildEngagementSection(),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildSwipeSection() {
    final toClassify = _toClassify;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.swipe, color: Colors.teal[700]),
                const SizedBox(width: 8),
                const Text(
                  'סיווג השבוע',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'החלק שמאלה = התייחסתי • החלק ימינה = לא התייחסתי',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            if (_addressedIds.isNotEmpty || _notAddressedIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildCountChip(
                    'לא התייחסתי',
                    _notAddressedIds.length,
                    Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  _buildCountChip(
                    'התייחסתי',
                    _addressedIds.length,
                    const Color(0xFF4CAF50),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            if (toClassify.isEmpty && _documentedThisWeekIds.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'אין מורים לסיווג.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            else ...[
              ...toClassify.map((t) => _buildDismissibleTeacher(t)),
              if (_documentedThisWeekIds.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildDocumentedThisWeekHeader(),
                ..._documentedThisWeek.map((t) => _buildDocumentedTeacherTile(t)),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentedThisWeekHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.assignment_turned_in, color: const Color(0xFF4CAF50), size: 20),
          const SizedBox(width: 8),
          Text(
            'התייחסות מתועדת השבוע (ללא צורך לסווג)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentedTeacherTile(Teacher teacher) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.4)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF4CAF50).withOpacity(0.3),
          child: const Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
        ),
        title: Text(
          teacher.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: const Text('הייתה פעולה מתועדת השבוע'),
        trailing: const Icon(Icons.chevron_left, color: Colors.grey),
        onTap: () {
          if (!teacher.id.startsWith('demo')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TeacherDetailsScreen(teacherId: teacher.id),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildCountChip(String label, int count, Color color) {
    return Chip(
      avatar: CircleAvatar(backgroundColor: color, child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 12))),
      label: Text(label),
    );
  }

  Widget _buildDismissibleTeacher(Teacher teacher) {
    return Dismissible(
      key: ValueKey(teacher.id),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerRight,
        color: Colors.orange,
        child: const Padding(
          padding: EdgeInsets.only(right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('לא התייחסתי', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(width: 8),
              Icon(Icons.close, color: Colors.white, size: 28),
            ],
          ),
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerLeft,
        color: const Color(0xFF4CAF50),
        child: const Padding(
          padding: EdgeInsets.only(left: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.check, color: Colors.white, size: 28),
              SizedBox(width: 8),
              Text('התייחסתי', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
      confirmDismiss: (direction) async {
        final addressed = direction == DismissDirection.startToEnd;
        _onSwiped(teacher, addressed);
        return true;
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF11a0db).withOpacity(0.2),
          child: const Icon(Icons.person, color: Color(0xFF11a0db)),
        ),
        title: Text(teacher.name),
        trailing: const Icon(Icons.chevron_left),
        onTap: () {
          if (!teacher.id.startsWith('demo')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TeacherDetailsScreen(teacherId: teacher.id),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildMoodSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mood, color: Colors.amber[700]),
                const SizedBox(width: 8),
                const Text(
                  'מיפוי סטטוס מורים',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'האם הבחנת בשינוי אצל אחד המורים?',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            if (_moodSaving)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
            const SizedBox(height: 12),
            ..._teachers.map((t) => _buildMoodRow(t)),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodRow(Teacher teacher) {
    if (teacher.id.startsWith('demo')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(child: Text(teacher.name, overflow: TextOverflow.ellipsis)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
              child: const Text('לא עודכן', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      );
    }
    final currentStatus = _moodUpdates[teacher.id] ?? teacher.moodStatus;
    final displayStatus = _moodDisplay(currentStatus);
    final isNotUpdated = displayStatus == 'לא עודכן' ||
        (currentStatus == null || currentStatus.isEmpty);
    final trend = _moodTrendUpdates[teacher.id] ?? teacher.moodTrend;
    final note = _moodNoteUpdates[teacher.id] ?? teacher.moodWeekNote;
    final hasNote = note != null && note.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // SingleChildScrollView אופקי מונע overflow (למשל 70px) במסכים צרים
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true, // RTL: גלילה מתחילה מהצד הנכון
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    teacher.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                const SizedBox(width: 8),
                if (isNotUpdated) ...[
                  Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  textDirection: TextDirection.rtl,
                  children: _moodLevels.map((e) {
                    return ActionChip(
                      label: Text(e.label, style: const TextStyle(fontSize: 12)),
                      backgroundColor: e.color.withOpacity(0.15),
                      side: BorderSide(color: e.color.withOpacity(0.5)),
                      onPressed: () => _setMoodStatus(teacher, e.id),
                    );
                  }).toList(),
                ),
              ] else ...[
                // רוחב מינימלי + IconButton כדי שבגרסת Web החיצים תמיד יוצגו (ללא overflow/קריסה)
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 200),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _moodColor(currentStatus).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _moodColor(currentStatus)),
                        ),
                        child: Text(
                          displayStatus,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _moodColor(currentStatus)),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () => _setMoodTrend(teacher, 'up'),
                        icon: Icon(
                          Icons.keyboard_arrow_up,
                          size: 32,
                          color: trend == 'up' ? Colors.green[700] : Colors.grey,
                        ),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        style: IconButton.styleFrom(
                          foregroundColor: trend == 'up' ? Colors.green[700] : Colors.grey,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _setMoodTrend(teacher, 'down'),
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          size: 32,
                          color: trend == 'down' ? Colors.red[700] : Colors.grey,
                        ),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        style: IconButton.styleFrom(
                          foregroundColor: trend == 'down' ? Colors.red[700] : Colors.grey,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.note_add_outlined, size: 22, color: hasNote ? Colors.blue : Colors.grey),
                        onPressed: () => _showNoteOnlyOverlay(teacher),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        ],
      ),
    );
  }

  Future<void> _setMoodStatus(Teacher teacher, String status) async {
    setState(() => _moodUpdates[teacher.id] = status);
    await _saveMoodFull(
      teacher,
      status,
      _moodTrendUpdates[teacher.id] ?? teacher.moodTrend,
      _moodNoteUpdates[teacher.id] ?? teacher.moodWeekNote,
    );
  }

  /// חיצי שיפור/החמרה – משנים את הסטטוס בפועל (דרגה אחת למעלה/למטה) ולא רק את ה-trend.
  Future<void> _setMoodTrend(Teacher teacher, String trend) async {
    final currentRaw = _moodUpdates[teacher.id] ?? teacher.moodStatus;
    final display = _moodDisplay(currentRaw);
    if (display == 'לא עודכן') return;
    final idx = _moodLevels.indexWhere((e) => e.label == display);
    if (idx < 0) return;
    int newIdx = trend == 'up' ? idx - 1 : idx + 1;
    if (newIdx < 0 || newIdx >= _moodLevels.length) return;
    final newStatus = _moodLevels[newIdx].id;
    setState(() {
      _moodUpdates[teacher.id] = newStatus;
      _moodTrendUpdates[teacher.id] = trend;
    });
    await _saveMoodFull(
      teacher,
      newStatus,
      trend,
      _moodNoteUpdates[teacher.id] ?? teacher.moodWeekNote,
    );
  }

  void _showNoteOnlyOverlay(Teacher teacher) {
    final noteController = TextEditingController(
      text: _moodNoteUpdates[teacher.id] ?? teacher.moodWeekNote ?? '',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(
            right: 20,
            left: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                teacher.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 8),
              Text(
                'הערה (אופציונלי)',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 6),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  hintText: 'משפט קצר...',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                maxLines: 1,
                maxLength: 120,
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('ביטול'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final newNote = noteController.text.trim().isEmpty ? null : noteController.text.trim();
                      if (newNote != null) _moodNoteUpdates[teacher.id] = newNote;
                      else _moodNoteUpdates.remove(teacher.id);
                      Navigator.pop(ctx);
                      await _saveMoodFull(
                        teacher,
                        _moodUpdates[teacher.id] ?? teacher.moodStatus,
                        _moodTrendUpdates[teacher.id] ?? teacher.moodTrend,
                        newNote,
                      );
                      setState(() {});
                    },
                    child: const Text('שמירה'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveMoodFull(Teacher teacher, String? mood, String? trend, String? note) async {
    if (teacher.id.startsWith('demo')) return;
    setState(() => _moodSaving = true);
    try {
      await _firestoreService.updateTeacher(teacher.copyWith(
        moodStatus: mood ?? teacher.moodStatus,
        moodTrend: trend,
        moodWeekNote: note,
      ));
    } catch (_) {}
    if (mounted) setState(() => _moodSaving = false);
  }

  Widget _buildEngagementSection() {
    final insights = _buildEngagementInsights();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.format_quote, color: Colors.purple[700]),
                const SizedBox(width: 8),
                const Text(
                  'היגדים מהשאלון – להעברת לפעולה',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'מידע מהשאלון והערות המורים. סמן היגדים שאתה רוצה להפוך לפעולה – יוצגו פעולות מוצעות.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            if (insights.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'אין כרגע היגדים או הערות שדורשים התייחסות (ציונים נמוכים או הערות מהמורים).',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            else ...[
              ...insights.map((insight) => _buildInsightTile(insight)),
              if (_selectedInsightIds.isNotEmpty) ...[
                const Divider(height: 24),
                const Text('פעולות מוצעות לפריטים שנבחרו:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...insights.where((i) => _selectedInsightIds.contains(i.id)).map((i) => _buildSuggestedActions(i)),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInsightTile(_EngagementInsight insight) {
    final selected = _selectedInsightIds.contains(insight.id);
    return CheckboxListTile(
      value: selected,
      onChanged: (v) {
        setState(() {
          if (v == true) {
            _selectedInsightIds.add(insight.id);
          } else {
            _selectedInsightIds.remove(insight.id);
          }
        });
      },
      title: Text(
        insight.description,
        style: const TextStyle(fontSize: 14),
      ),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildSuggestedActions(_EngagementInsight insight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${insight.teacherName} – ${insight.problemLabel}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...insight.suggestedActions.map((action) => ActionChip(
                    label: Text(action),
                    onPressed: () => _openAddAction(insight.teacherId, action),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  void _openAddAction(String teacherId, String suggestedAction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddActionScreen(
          teacherId: teacherId,
          suggestedType: suggestedAction,
        ),
      ),
    );
  }
}

class _EngagementInsight {
  final String id;
  final String teacherId;
  final String teacherName;
  final String questionKey;
  final String problemLabel;
  final String description;
  final List<String> suggestedActions;

  _EngagementInsight({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.questionKey,
    required this.problemLabel,
    required this.description,
    required this.suggestedActions,
  });
}
