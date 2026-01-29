import 'package:flutter/material.dart';
import '../models/teacher.dart';
import '../services/firestore_service.dart';

class AddTeacherScreen extends StatefulWidget {
  final Teacher? teacher;

  const AddTeacherScreen({Key? key, this.teacher}) : super(key: key);

  bool get isEditMode => teacher != null;

  @override
  State<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _notesController = TextEditingController();
  final _firestoreService = FirestoreService();
  // סטטוס רמזור ישן (סיכון/מעקב/יציב) – נשמר לסטטיסטיקות
  String _selectedStatus = 'green';
  // סטטוס רגשי חדש עם 5 רמות (פורח/זורם/מתוח/מנותק/שחוק)
  String _selectedMoodStatus = 'flow';
  bool _isLoading = false;
  // זמני עומס
  final Set<String> _busyWeekdays = {}; // ימים עמוסים בשבוע
  DateTimeRange? _busySeasonRange; // תקופת עומס בשנה
  final TextEditingController _busyReasonController = TextEditingController();
  String? _initialBusySeasonText;
  // סגנון מוטיבציה – ניתן לבחור יותר מאחד
  final Set<String> _selectedMotivationStyles = {};
  // תובנות/סימני מעורבות (לפי גאלופ)
  final Set<String> _selectedEngagementSignals = {};

  @override
  void initState() {
    super.initState();
    final teacher = widget.teacher;
    if (teacher != null) {
      _nameController.text = teacher.name;
      _roleController.text = teacher.roles.join(', ');
      _notesController.text = teacher.notes ?? '';
      _selectedStatus = teacher.status;
      _selectedMoodStatus = teacher.moodStatus ?? _selectedMoodStatus;
      _busyWeekdays.addAll(teacher.busyWeekdays);
      _initialBusySeasonText = teacher.busySeason;
      if (teacher.busyReason != null) {
        _busyReasonController.text = teacher.busyReason!;
      }
      _selectedMotivationStyles.addAll(teacher.motivationStyles);
      _selectedEngagementSignals.addAll(teacher.engagementSignals);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _notesController.dispose();
    _busyReasonController.dispose();
    super.dispose();
  }

  Future<void> _saveTeacher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final roleText = _roleController.text.trim();
      final roles = roleText.isEmpty
          ? <String>[]
          : roleText
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
      final notesText = _notesController.text.trim();
      final busyReasonText = _busyReasonController.text.trim();
      final busySeasonText = _busySeasonRange == null
          ? _initialBusySeasonText
          : _formatBusySeason(_busySeasonRange!);

      if (widget.teacher == null) {
        final teacher = Teacher(
          id: '', // יווצר אוטומטית ב-Firestore
          name: name,
          seniorityYears: 0, // יגיעו בעתיד ממערכות משרד החינוך
          totalSeniorityYears: 0,
          roles: roles,
          status: _selectedStatus,
          notes: notesText.isEmpty ? null : notesText,
          createdAt: DateTime.now(),
          busyWeekdays: _busyWeekdays.toList(),
          busySeason: busySeasonText,
          busyReason: busyReasonText.isEmpty ? null : busyReasonText,
          motivationStyles: _selectedMotivationStyles.toList(),
          engagementSignals: _selectedEngagementSignals.toList(),
        );

        await _firestoreService.addTeacher(teacher);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('המורה נוסף בהצלחה!')),
          );
          Navigator.pop(context, true);
        }
      } else {
        final updatedTeacher = widget.teacher!.copyWith(
          name: name,
          roles: roles,
          status: _selectedStatus,
          notes: notesText.isEmpty ? null : notesText,
          busyWeekdays: _busyWeekdays.toList(),
          busySeason: busySeasonText,
          busyReason: busyReasonText.isEmpty ? null : busyReasonText,
          motivationStyles: _selectedMotivationStyles.toList(),
          engagementSignals: _selectedEngagementSignals.toList(),
        );

        await _firestoreService.updateTeacher(updatedTeacher);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('פרטי המורה עודכנו בהצלחה!')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditMode ? 'עריכת מורה' : 'הוספת מורה'),
          backgroundColor: const Color(0xFF11a0db),
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'בואי נכיר את המורים שלך',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  'כמה פרטים שיעזרו לנו לתמוך בהם בזמן הנכון ובדרך הנכונה.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'שם מלא *',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'נא להזין שם';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _roleController,
                  decoration: InputDecoration(
                    labelText: 'תפקיד (למשל מחנכת, רכזת שכבה)',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'מתי הם בלחץ? *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _buildWeekdayChips(),
                ),
                const SizedBox(height: 12),
                const Text(
                  'תקופות עמוסות בשנה',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(now.year - 1),
                      lastDate: DateTime(now.year + 1),
                      initialDateRange: _busySeasonRange ??
                          DateTimeRange(
                            start: now,
                            end: now.add(const Duration(days: 14)),
                          ),
                    );
                    if (range != null) {
                      setState(() => _busySeasonRange = range);
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _busySeasonRange == null
                        ? (_initialBusySeasonText ??
                            'בחרי תקופה עמוסה (למשל לפני בגרויות)')
                        : _formatBusySeason(_busySeasonRange!),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _busyReasonController,
                  decoration: InputDecoration(
                    labelText: 'כותרת/סיבת העומס (למשל "בחינות בגרות")',
                    prefixIcon: const Icon(Icons.label_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'סגנון מוטיבציה',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.help_outline, size: 20),
                      color: Colors.grey[600],
                      padding: EdgeInsets.zero,
                      onPressed: _showMotivationHelp,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildMotivationGrid(),
                const SizedBox(height: 8),
                const Text(
                  'מדד מעורבות',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _buildEngagementChips(),
                ),
                const SizedBox(height: 24),
                const Text(
                  'סטטוס *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _buildMoodStatusChips(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'הערות',
                    prefixIcon: const Icon(Icons.note),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveTeacher,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF11a0db),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'שמור',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ביטול'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMoodStatusChips() {
    const options = {
      'bloom': 'פורח',
      'flow': 'זורם',
      'tense': 'מתוח',
      'disconnected': 'מנותק',
      'burned_out': 'שחוק',
    };

    Color colorForMood(String key) {
      switch (key) {
        case 'bloom':
          return const Color(0xFF40AE49);
        case 'flow':
          return const Color(0xFFB2D234);
        case 'tense':
          return const Color(0xFFFAA41A);
        case 'disconnected':
          return const Color(0xFFED1C24);
        case 'burned_out':
          return const Color(0xFFAC2B31);
        default:
          return Colors.grey;
      }
    }

    return options.entries.map((entry) {
      final isSelected = _selectedMoodStatus == entry.key;
      final color = colorForMood(entry.key);
      return ChoiceChip(
        label: Text(entry.value),
        selected: isSelected,
        selectedColor: color.withOpacity(0.15),
        labelStyle: TextStyle(
          color: isSelected ? color : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
        onSelected: (selected) {
          setState(() {
            _selectedMoodStatus = selected ? entry.key : _selectedMoodStatus;
            _selectedStatus = _mapMoodToTrafficLight(_selectedMoodStatus);
          });
        },
      );
    }).toList();
  }

  String _mapMoodToTrafficLight(String mood) {
    switch (mood) {
      case 'bloom':
      case 'flow':
        return 'green';
      case 'tense':
        return 'yellow';
      case 'disconnected':
      case 'burned_out':
        return 'red';
      default:
        return 'green';
    }
  }

  List<Widget> _buildWeekdayChips() {
    const days = ['א', 'ב', 'ג', 'ד', 'ה', 'ו'];
    return days
        .map(
          (day) => FilterChip(
            label: Text(day),
            selected: _busyWeekdays.contains(day),
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _busyWeekdays.add(day);
                } else {
                  _busyWeekdays.remove(day);
                }
              });
            },
          ),
        )
        .toList();
  }

  String _formatBusySeason(DateTimeRange range) {
    final start = range.start;
    final end = range.end;
    return '${start.day}.${start.month}–${end.day}.${end.month}';
  }

  Widget _buildMotivationTile({
    required String keyValue,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _selectedMotivationStyles.contains(keyValue);
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedMotivationStyles.remove(keyValue);
          } else {
            _selectedMotivationStyles.add(keyValue);
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF3EB) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF36F21)
                : Colors.grey[300] ?? Colors.grey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFFF36F21)
                  : const Color(0xFF11a0db),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.2,
      children: [
        _buildMotivationTile(
          keyValue: 'gregariousness',
          title: 'חברותיות',
          icon: Icons.chat_bubble_outline,
        ),
        _buildMotivationTile(
          keyValue: 'autonomy',
          title: 'אוטונומיה',
          icon: Icons.flight_takeoff,
        ),
        _buildMotivationTile(
          keyValue: 'status',
          title: 'סטטוס',
          icon: Icons.star_border,
        ),
        _buildMotivationTile(
          keyValue: 'inquisitiveness',
          title: 'סקרנות',
          icon: Icons.lightbulb_outline,
        ),
        _buildMotivationTile(
          keyValue: 'power',
          title: 'כוח',
          icon: Icons.bolt,
        ),
        _buildMotivationTile(
          keyValue: 'affiliation',
          title: 'שייכות אישית',
          icon: Icons.card_giftcard,
        ),
      ],
    );
  }

  List<Widget> _buildEngagementChips() {
    const options = [
      'צרכים בסיסיים',
      'תרומה אישית',
      'שייכות לצוות',
      'צמיחה אישית',
    ];
    return options
        .map(
          (label) => FilterChip(
            label: Text(label),
            selected: _selectedEngagementSignals.contains(label),
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedEngagementSignals.add(label);
                } else {
                  _selectedEngagementSignals.remove(label);
                }
              });
            },
          ),
        )
        .toList();
  }

  void _showMotivationHelp() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('6 סוגי המוטיבציה (ריק לאבוי)'),
            content: const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• חברותיות – הצורך להשתייך לקבוצה, ליהנות מעבודה בצוות ומאינטראקציה חברתית.',
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• אוטונומיה – הצורך בעצמאות, שליטה על תהליכי העבודה וחופש פעולה.',
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• סטטוס – הצורך בהכרה ציבורית, מעמד, פרסים והערכה פומבית על הישגים.',
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• סקרנות – הצורך ברכישת ידע חדש, חקירה, גילוי וצמיחה אינטלקטואלית.',
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• כוח – הצורך בהשפעה, סמכות, מנהיגות ונטילת חלק בקבלת החלטות.',
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• שייכות אישית – הצורך בקשר אישי חם, תמיכה רגשית, אמפתיה ועידוד מהמנהל.',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('סגור'),
              ),
            ],
          ),
        );
      },
    );
  }
}

