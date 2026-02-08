import 'package:flutter/material.dart' hide Action;
import '../models/teacher.dart';
import '../models/action.dart';
import '../services/firestore_service.dart';
import '../widgets/status_indicator.dart';
import '../widgets/hebrew_gregorian_date.dart';
import 'add_action_screen.dart';
import 'add_teacher_screen.dart';
import 'engagement_survey_screen.dart';
import 'recommended_actions_screen.dart';

class TeacherDetailsScreen extends StatefulWidget {
  final String teacherId;

  const TeacherDetailsScreen({
    Key? key,
    required this.teacherId,
  }) : super(key: key);

  @override
  State<TeacherDetailsScreen> createState() => _TeacherDetailsScreenState();
}

class _TeacherDetailsScreenState extends State<TeacherDetailsScreen> {
  final _firestoreService = FirestoreService();
  final _nextActionDateController = TextEditingController();
  final _nextActionTypeController = TextEditingController();
  bool _controllersInitialized = false;
  int _refreshKey = 0;

  @override
  void dispose() {
    _nextActionDateController.dispose();
    _nextActionTypeController.dispose();
    super.dispose();
  }
  
  void _initializeControllers(Teacher teacher) {
    if (!_controllersInitialized) {
      if (teacher.nextActionDate != null) {
        _nextActionDateController.text = teacher.nextActionDate!;
      }
      if (teacher.nextActionType != null) {
        _nextActionTypeController.text = teacher.nextActionType!;
      }
      _controllersInitialized = true;
    }
  }

  Future<void> _saveNextAction() async {
    if (_nextActionDateController.text.isEmpty ||
        _nextActionTypeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('נא למלא את כל השדות')),
      );
      return;
    }

    try {
      final teacher = await _firestoreService.getTeacher(widget.teacherId);
      if (teacher != null) {
        final updatedTeacher = teacher.copyWith(
          nextActionDate: _nextActionDateController.text,
          nextActionType: _nextActionTypeController.text,
        );
        await _firestoreService.updateTeacher(updatedTeacher);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('תזכורת נשמרה!')),
          );
          _nextActionDateController.clear();
          _nextActionTypeController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FutureBuilder<Teacher?>(
        key: ValueKey(_refreshKey),
        future: _firestoreService.getTeacher(widget.teacherId),
        builder: (context, teacherSnapshot) {
          if (teacherSnapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('פרטי מורה'),
                backgroundColor: const Color(0xFF11a0db),
                foregroundColor: Colors.white,
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          final teacher = teacherSnapshot.data;
          if (teacher == null) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('פרטי מורה'),
                backgroundColor: const Color(0xFF11a0db),
                foregroundColor: Colors.white,
              ),
              body: const Center(child: Text('מורה לא נמצא')),
            );
          }

          _initializeControllers(teacher);

          return Scaffold(
            appBar: AppBar(
              title: const Text('פרטי מורה'),
              backgroundColor: const Color(0xFF11a0db),
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final updated = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddTeacherScreen(teacher: teacher),
                      ),
                    );
                    if (updated == true && mounted) {
                      setState(() {
                        _controllersInitialized = false;
                        _refreshKey++;
                      });
                    }
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // כרטיס מידע בסיסי + פרופיל מורה
                  Card(
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
                              Expanded(
                                child: Text(
                                  teacher.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              StatusIndicator(status: teacher.status, size: 24),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.calendar_today,
                            'וותק בבית הספר: ${teacher.seniorityYears} שנים',
                          ),
                          const SizedBox(height: 4),
                          _buildInfoRow(
                            Icons.work,
                            'וותק כללי: ${teacher.totalSeniorityYears} שנים',
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text(
                            'זמני עומס',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (teacher.busyWeekdays.isNotEmpty)
                            _buildInfoRow(
                              Icons.calendar_view_week,
                              'ימים עמוסים בשבוע: ${teacher.busyWeekdays.join(", ")}',
                            )
                          else
                            _buildInfoRow(
                              Icons.calendar_view_week,
                              'ימים עמוסים בשבוע: טרם סומן',
                            ),
                          const SizedBox(height: 4),
                          _buildInfoRow(
                            Icons.event,
                            teacher.busySeason != null
                                ? 'תקופת עומס בשנה: ${teacher.busySeason}'
                                : 'תקופת עומס בשנה: טרם סומנה',
                          ),
                          if (teacher.busyReason != null &&
                              teacher.busyReason!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            _buildInfoRow(
                              Icons.label_outline,
                              'סיבת עומס: ${teacher.busyReason}',
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text(
                            'סטטוס רגשי לפי תחושתך',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildMoodStatusChips(teacher),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text(
                            'סגנון מוטיבציה ותובנות מעורבות',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.psychology_alt_outlined,
                            teacher.motivationStyles.isNotEmpty
                                ? 'סגנונות בולטים: ${teacher.motivationStyles.map(_mapMotivationLabel).join(", ")}'
                                : 'סגנונות בולטים: טרם סומנו',
                          ),
                          const SizedBox(height: 8),
                          if (teacher.engagementSignals.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: teacher.engagementSignals
                                  .map(
                                    (signal) => Chip(
                                      label: Text(signal),
                                      backgroundColor:
                                          const Color(0xFFFFF3EB),
                                    ),
                                  )
                                  .toList(),
                            )
                          else
                            Text(
                              'עוד לא הוגדרו תובנות מעורבות מהמנהל או מהשאלון.',
                              style: TextStyle(
                                color: Colors.grey[700],
                              ),
                            ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'מדד מעורבות (Q12)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  final updated = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EngagementSurveyScreen(
                                        teacherId: widget.teacherId,
                                      ),
                                    ),
                                  );
                                  if (updated == true && mounted) {
                                    setState(() {
                                      _controllersInitialized = false;
                                      _refreshKey++;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.edit_note, size: 20),
                                label: const Text('מילוי / עריכת שאלון'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (teacher.engagementDomainScores.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: teacher
                                      .engagementDomainScores.entries
                                      .map(
                                        (e) => Chip(
                                          label: Text(
                                            '${_mapDomainLabel(e.key)}: ${e.value}/6',
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: () =>
                                        _showEngagementDetails(context, teacher),
                                    icon: const Icon(Icons.list_alt_outlined),
                                    label: const Text('פירוט 12 היגדים'),
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              'שאלון המעורבות טרם מולא.',
                              style: TextStyle(
                                color: Colors.grey[700],
                              ),
                            ),
                          if (teacher.absencesThisYear > 0 ||
                              teacher.specialActivities.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            const Text(
                              'נתונים משלימים',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (teacher.absencesThisYear > 0)
                              _buildInfoRow(
                                Icons.event_busy,
                                'היעדרויות השנה: ${teacher.absencesThisYear}',
                              ),
                            if (teacher.specialActivities.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: teacher.specialActivities
                                    .map(
                                      (activity) => Chip(
                                        label: Text(activity),
                                        backgroundColor:
                                            const Color(0xFFE3F2FD),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ],
                          if (teacher.notes != null &&
                              teacher.notes!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            const Text(
                              'הערות:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(teacher.notes!),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // פעולות שבוצעו
                  const Text(
                    'פעולות שבוצעו',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<Action>>(
                    stream: _firestoreService.getActionsStream(widget.teacherId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final actions = snapshot.data ?? [];
                      if (actions.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                'אין פעולות עדיין',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: actions.map((action) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: action.completed
                                    ? const Color(0xFF40ae49)
                                    : Colors.grey[300],
                                child: Icon(
                                  action.completed
                                      ? Icons.check
                                      : Icons.pending,
                                  color: action.completed
                                      ? Colors.white
                                      : Colors.grey[700],
                                ),
                              ),
                              title: Text(action.type),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  action.date == null
                                      ? const Text('ללא תאריך')
                                      : HebrewGregorianDateText(
                                          date: action.date!,
                                        ),
                                  if (action.notes != null &&
                                      action.notes!.isNotEmpty)
                                    Text(action.notes!),
                                ],
                              ),
                              trailing: action.completed
                                  ? const Icon(Icons.check_circle,
                                      color: Color(0xFF40ae49))
                                  : null,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // בחר ממאגר פעולות מומלצות (למידה הדדית)
                  OutlinedButton.icon(
                    onPressed: () async {
                      final type = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecommendedActionsScreen(
                            pickerMode: true,
                          ),
                        ),
                      );
                      if (type != null && type.isNotEmpty && mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddActionScreen(
                              teacherId: widget.teacherId,
                              suggestedType: type,
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.lightbulb_outline, size: 20),
                    label: const Text('בחר ממאגר פעולות מומלצות'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF11a0db),
                      side: const BorderSide(color: Color(0xFF11a0db)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddActionScreen(
                            teacherId: widget.teacherId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('הוסף פעולה'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF11a0db),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // פעולה מתוכננת
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'פעולה מתוכננת',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _nextActionDateController,
                            decoration: InputDecoration(
                              labelText: 'הפעולה הבאה מתוכננת ל...',
                              prefixIcon: const Icon(Icons.calendar_today),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (date != null) {
                                _nextActionDateController.text =
                                    '${date.day}/${date.month}/${date.year}';
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _nextActionTypeController,
                            decoration: InputDecoration(
                              labelText: 'סוג הפעולה',
                              prefixIcon: const Icon(Icons.event_note),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveNextAction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF11a0db),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('שמור תזכורת'),
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
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: Colors.grey[700])),
      ],
    );
  }

  static String _mapMotivationLabel(String key) {
    switch (key) {
      case 'gregariousness':
        return 'חברותיות';
      case 'autonomy':
        return 'אוטונומיה';
      case 'status':
        return 'סטטוס';
      case 'inquisitiveness':
        return 'סקרנות';
      case 'power':
        return 'כוח';
      case 'affiliation':
        return 'שייכות אישית';
      default:
        return key;
    }
  }

  Widget _buildMoodStatusChips(Teacher teacher) {
    const options = {
      'bloom': 'מורה פורח',
      'flow': 'מורה זורם',
      'tense': 'מורה מתוח',
      'disconnected': 'מורה מנותק',
      'burned_out': 'מורה שחוק',
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((entry) {
        final isSelected = teacher.moodStatus == entry.key;
        final isAlert = entry.key == 'tense' ||
            entry.key == 'disconnected' ||
            entry.key == 'burned_out';

        return ChoiceChip(
          label: Text(entry.value),
          selected: isSelected,
          selectedColor:
              isAlert ? const Color(0xFFFFE0E0) : const Color(0xFFE3F2FD),
          labelStyle: TextStyle(
            color: isAlert
                ? (isSelected ? const Color(0xFFB71C1C) : Colors.red[700])
                : (isSelected ? const Color(0xFF0D47A1) : Colors.black87),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
          onSelected: (selected) async {
            try {
              final updated = teacher.copyWith(
                moodStatus: selected ? entry.key : null,
              );
              await _firestoreService.updateTeacher(updated);

              // רישום פעולה קטנה כדי לסמן שהמנהל שם לב
              if (selected) {
                // לא מכניסים כאן Action כי אין לנו teacherId, רק ה-Teacher עצמו
                // את לוג הסטטוס המלא נוסיף בטקסי סוף השבוע.
              }

              if (mounted) {
                setState(() {});
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('שגיאה בעדכון סטטוס: $e')),
                );
              }
            }
          },
        );
      }).toList(),
    );
  }

  static String _mapDomainLabel(String key) {
    switch (key) {
      case 'basic_needs':
        return 'צרכים בסיסיים';
      case 'individual_contribution':
        return 'תרומה אישית';
      case 'team_belonging':
        return 'שייכות לצוות';
      case 'personal_growth':
        return 'צמיחה אישית';
      default:
        return key;
    }
  }

  void _showEngagementDetails(BuildContext context, Teacher teacher) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final scores = teacher.engagementItemScores;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'פירוט 12 היגדי המעורבות',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'הציון בכל היגד הוא בסולם 1–6 כפי שסימן/ה המורה בטופס החיצוני.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final key = 'q${index + 1}';
                        final value = scores[key];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('היגד ${index + 1}'),
                          trailing: Text(
                            value != null ? '$value / 6' : '-',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (teacher.engagementNote != null &&
                      teacher.engagementNote!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'הערה מילולית מהשאלון:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(teacher.engagementNote!),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

