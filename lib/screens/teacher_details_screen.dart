import 'package:flutter/material.dart' hide Action;
import '../models/teacher.dart';
import '../models/action.dart';
import '../services/firestore_service.dart';
import '../widgets/status_indicator.dart';
import 'add_action_screen.dart';
import 'add_teacher_screen.dart';

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
      child: Scaffold(
        appBar: AppBar(
          title: const Text('פרטי מורה'),
          backgroundColor: const Color(0xFF11a0db),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // TODO: מסך עריכה
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('פונקציונליות עריכה בקרוב')),
                );
              },
            ),
          ],
        ),
        body: FutureBuilder<Teacher?>(
          future: _firestoreService.getTeacher(widget.teacherId),
          builder: (context, teacherSnapshot) {
            if (teacherSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final teacher = teacherSnapshot.data;
            if (teacher == null) {
              return const Center(child: Text('מורה לא נמצא'));
            }
            
            _initializeControllers(teacher);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // כרטיס מידע בסיסי
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
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.work,
                            'וותק כללי: ${teacher.totalSeniorityYears} שנים',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.schedule,
                            'היקף משרה: ${teacher.workloadPercent}%',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.sentiment_satisfied_alt,
                            'שביעות רצון: ${teacher.satisfactionRating}/5',
                          ),
                          const SizedBox(height: 4),
                          _buildInfoRow(
                            Icons.group,
                            'תחושת שייכות: ${teacher.belongingRating}/5',
                          ),
                          const SizedBox(height: 4),
                          _buildInfoRow(
                            Icons.speed,
                            'עומס: ${teacher.workloadRating}/5',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.event_busy,
                            'היעדרויות השנה: ${teacher.absencesThisYear}',
                          ),
                          if (teacher.specialActivities.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            const Text(
                              'פעילויות מיוחדות:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
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
                                  Text(
                                    '${action.date.day}/${action.date.month}/${action.date.year}',
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
                  const SizedBox(height: 16),
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
            );
          },
        ),
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
}

