import 'package:flutter/material.dart' hide Action;
import '../models/action.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({Key? key}) : super(key: key);

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _firestoreService = FirestoreService();
  bool _thisWeekOnly = false;
  List<Map<String, dynamic>> _allActions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActions();
  }

  Future<void> _loadActions() async {
    setState(() => _isLoading = true);
    try {
      final actions = await _firestoreService.getAllUpcomingActions(
        thisWeekOnly: _thisWeekOnly,
      );
      setState(() {
        _allActions = actions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e')),
        );
      }
    }
  }

  Future<void> _toggleActionCompleted(
      String teacherId, Action action) async {
    try {
      final updatedAction = action.copyWith(completed: !action.completed);
      await _firestoreService.updateAction(teacherId, updatedAction);
      await _loadActions();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action.completed
                  ? 'הפעולה סומנה כלא בוצעה'
                  : 'הפעולה סומנה כבוצעה!',
            ),
          ),
        );
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
          title: const Text('המשימות שלי'),
          backgroundColor: const Color(0xFF11a0db),
          foregroundColor: Colors.white,
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FilterChip(
                label: Text(_thisWeekOnly ? 'השבוע בלבד' : 'הכל'),
                selected: _thisWeekOnly,
                onSelected: (selected) {
                  setState(() => _thisWeekOnly = selected);
                  _loadActions();
                },
                selectedColor: const Color(0xFF11a0db),
                checkmarkColor: Colors.white,
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _allActions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'אין משימות',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadActions,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _allActions.length,
                      itemBuilder: (context, index) {
                        final item = _allActions[index];
                        final action = item['action'] as Action;
                        final teacherId = item['teacherId'] as String;
                        final teacherName = item['teacherName'] as String;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Checkbox(
                              value: action.completed,
                              onChanged: (value) {
                                _toggleActionCompleted(teacherId, action);
                              },
                              activeColor: const Color(0xFF40ae49),
                              shape: const CircleBorder(),
                            ),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  action.type,
                                  style: TextStyle(
                                    decoration: action.completed
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: action.completed
                                        ? Colors.grey
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  teacherName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: const Color(0xFF11a0db),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  '${action.date.day}/${action.date.month}/${action.date.year}',
                                ),
                                if (action.notes != null &&
                                    action.notes!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      action.notes!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: action.completed
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF40ae49),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}

