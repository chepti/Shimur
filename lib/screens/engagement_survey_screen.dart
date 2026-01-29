import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

/// מסך שאלון מעורבות גאלופ Q12 + סגנונות מוטיבציה + תפקידים
class EngagementSurveyScreen extends StatefulWidget {
  final String teacherId;

  const EngagementSurveyScreen({
    Key? key,
    required this.teacherId,
  }) : super(key: key);

  @override
  State<EngagementSurveyScreen> createState() => _EngagementSurveyScreenState();
}

class _EngagementSurveyScreenState extends State<EngagementSurveyScreen> {
  final _firestoreService = FirestoreService();
  final _rolesController = TextEditingController();
  bool _isLoading = false;

  // Q1..Q12 ציון 1–6
  final Map<String, int> _itemScores = {};
  // Q1..Q12 הערה קטנה
  final Map<String, TextEditingController> _itemNoteControllers = {};
  // מוטיבציה – סט של מפתחות (gregariousness, autonomy, ...)
  final Set<String> _selectedMotivationKeys = {};
  // רשימת ההיגדים במוטיבציה בסדר מעורבב (בלי כותרת קטגוריה)
  static const List<({String text, String key})> _motivationStatements = [
    (text: 'אני נהנה לעבוד בצוות ולשתף פעולה עם עמיתים', key: 'gregariousness'),
    (text: 'אני אוהב ללמוד דברים חדשים ולהתפתח מקצועית', key: 'inquisitiveness'),
    (text: 'חשוב לי לקבל חופש להחליט איך אני מלמד', key: 'autonomy'),
    (text: 'חשוב לי קשר אישי וחם עם המנהל', key: 'affiliation'),
    (text: 'הכרה פומבית והערכה חשובות לי', key: 'status'),
    (text: 'אני רוצה להוביל שינויים ולהשפיע על החלטות', key: 'power'),
    (text: 'אני מרגיש טוב כשאני חלק מקהילה מקצועית', key: 'gregariousness'),
    (text: 'השתלמויות וחידושים פדגוגיים מעוררים אותי', key: 'inquisitiveness'),
    (text: 'אני מעדיף לעבוד באופן עצמאי ולהוביל תהליכים בעצמי', key: 'autonomy'),
    (text: 'אני זקוק לעידוד אישי ותמיכה רגשית', key: 'affiliation'),
    (text: 'אני נהנה כשההצלחות שלי מוזכרות ומפורסמות', key: 'status'),
    (text: 'חשוב לי לקבל אחריות ותפקידי הובלה', key: 'power'),
  ];

  static const List<String> _q12Questions = [
    'אני יודע/ת מה מצפים ממני בעבודה',
    'יש לי את החומרים והציוד שאני צריך/ה כדי לעשות את עבודתי כמו שצריך',
    'בעבודה, יש לי הזדמנות לעשות את מה שאני הכי טוב/ה בו כל יום',
    'בשבוע האחרון, קיבלתי הכרה או שבח על עבודה טובה',
    'נראה שאכפת למנהל שלי, או מישהו בעבודה, ממני כאדם',
    'יש מישהו בעבודה שמעודד את ההתפתחות שלי',
    'בעבודה, נראה שהדעות שלי נחשבות',
    'המשימה או המטרה של בית הספר גורמת לי להרגיש שהעבודה שלי חשובה',
    'חברי הצוות שלי מחויבים לעשות עבודה איכותית',
    'יש לי חבר/ה טוב/ה בעבודה',
    'בחצי השנה האחרונה, מישהו בעבודה דיבר איתי על ההתקדמות שלי',
    'השנה האחרונה, היו לי הזדמנויות בעבודה ללמוד ולצמוח',
  ];

  @override
  void initState() {
    super.initState();
    for (int i = 1; i <= 12; i++) {
      _itemScores['q$i'] = 3;
      _itemNoteControllers['q$i'] = TextEditingController();
    }
    _loadTeacher();
  }

  Future<void> _loadTeacher() async {
    final teacher = await _firestoreService.getTeacher(widget.teacherId);
    if (teacher != null && mounted) {
      setState(() {
        for (int i = 1; i <= 12; i++) {
          final key = 'q$i';
          final score = teacher.engagementItemScores[key];
          if (score != null) _itemScores[key] = score;
          final note = teacher.engagementItemNotes[key];
          if (note != null && note.isNotEmpty) {
            _itemNoteControllers[key]!.text = note;
          }
        }
        _selectedMotivationKeys.addAll(teacher.motivationStyles);
        if (teacher.roles.isNotEmpty) {
          _rolesController.text = teacher.roles.join(', ');
        }
      });
    }
  }

  @override
  void dispose() {
    _rolesController.dispose();
    for (final c in _itemNoteControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// חישוב ציוני תחומים מגאלופ (ממוצע לפי תחום)
  static Map<String, int> _computeDomainScores(Map<String, int> itemScores) {
    const domainItems = {
      'basic_needs': ['q1', 'q2'],
      'individual_contribution': ['q3', 'q4'],
      'team_belonging': ['q5', 'q6', 'q7', 'q8', 'q9', 'q10'],
      'personal_growth': ['q11', 'q12'],
    };
    final domainScores = <String, int>{};
    for (final e in domainItems.entries) {
      var sum = 0;
      var count = 0;
      for (final key in e.value) {
        final s = itemScores[key];
        if (s != null) {
          sum += s;
          count++;
        }
      }
      if (count > 0) {
        domainScores[e.key] = (sum / count).round().clamp(1, 6);
      }
    }
    return domainScores;
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final teacher = await _firestoreService.getTeacher(widget.teacherId);
      if (teacher == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('מורה לא נמצא')),
          );
        }
        return;
      }

      final itemScores = Map<String, int>.from(_itemScores);
      final itemNotes = <String, String>{};
      for (final e in _itemNoteControllers.entries) {
        final t = e.value.text.trim();
        if (t.isNotEmpty) itemNotes[e.key] = t;
      }
      final domainScores = _computeDomainScores(itemScores);
      final motivationStyles = _selectedMotivationKeys.toList();
      final rolesText = _rolesController.text.trim();
      final roles = rolesText.isEmpty
          ? <String>[]
          : rolesText
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();

      final updated = teacher.copyWith(
        engagementItemScores: itemScores,
        engagementItemNotes: itemNotes,
        engagementDomainScores: domainScores,
        motivationStyles: motivationStyles,
        roles: roles,
      );
      await _firestoreService.updateTeacher(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('השאלון נשמר בהצלחה')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('שאלון מעורבות ומוטיבציה'),
          backgroundColor: const Color(0xFF11a0db),
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('מדד מעורבות (גאלופ Q12)', Icons.psychology_outlined),
              const SizedBox(height: 8),
              const Text(
                'בחר/י ציון 1–6 לכל היגד. ניתן להוסיף הערה קטנה ליד כל שאלה.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ...List.generate(12, (i) {
                final key = 'q${i + 1}';
                return _buildQ12Item(
                  key: key,
                  number: i + 1,
                  question: _q12Questions[i],
                  score: _itemScores[key] ?? 3,
                  noteController: _itemNoteControllers[key]!,
                  onScoreChanged: (v) =>
                      setState(() => _itemScores[key] = v.round()),
                );
              }),
              const SizedBox(height: 32),
              _buildSectionTitle('סגנון מוטיבציה', Icons.auto_awesome),
              const SizedBox(height: 8),
              const Text(
                'סמן/י את המשפטים שמתאימים לך (הקטגוריות מחושבות במערכת).',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ..._motivationStatements.map((s) => _buildMotivationChip(s)),
              const SizedBox(height: 32),
              _buildSectionTitle('תפקידים', Icons.badge_outlined),
              const SizedBox(height: 8),
              TextField(
                controller: _rolesController,
                decoration: InputDecoration(
                  labelText: 'תפקידים (מופרדים בפסיק, למשל: מחנכת, רכזת שכבה)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF11a0db),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('שמור שאלון', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF11a0db)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQ12Item({
    required String key,
    required int number,
    required String question,
    required int score,
    required TextEditingController noteController,
    required ValueChanged<double> onScoreChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Q$number. $question',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('1', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Expanded(
                  child: Slider(
                    value: score.toDouble(),
                    min: 1,
                    max: 6,
                    divisions: 5,
                    onChanged: onScoreChanged,
                    activeColor: const Color(0xFF11a0db),
                  ),
                ),
                Text('6', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(width: 8),
                Container(
                  width: 28,
                  alignment: Alignment.center,
                  child: Text(
                    '$score',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            TextField(
              controller: noteController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'הערה (אופציונלי)',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationChip(({String text, String key}) s) {
    final isSelected = _selectedMotivationKeys.contains(s.key);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedMotivationKeys.remove(s.key);
            } else {
              _selectedMotivationKeys.add(s.key);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF3EB) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFF36F21)
                  : (Colors.grey[300] ?? Colors.grey),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 22,
                color: isSelected ? const Color(0xFFF36F21) : Colors.grey,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.text,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
