import 'package:flutter/material.dart' hide Action;
import '../models/action.dart';
import '../services/firestore_service.dart';
import '../widgets/hebrew_gregorian_date.dart';
import 'add_action_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _firestoreService = FirestoreService();
  bool _thisWeekOnly = false;
  List<Map<String, dynamic>> _allActions = [];
  bool _isLoading = true;
  int _visibleCount = 6;

  @override
  void initState() {
    super.initState();
    _loadActions();
  }

  Future<void> _loadActions() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final actions = await _firestoreService.getAllUpcomingActions(
        thisWeekOnly: _thisWeekOnly,
      );
      if (mounted) {
        setState(() {
          _allActions = actions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e')),
        );
      }
    }
  }

  Future<void> _openAddAction() async {
    final teachers = await _firestoreService.getTeachersStream().first;
    if (!mounted) return;

    if (teachers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('נא להוסיף מורים קודם')),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'בחר מורה להוספת פעולה',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: teachers.length,
                  itemBuilder: (context, index) {
                    final teacher = teachers[index];
                    return ListTile(
                      leading:
                          const Icon(Icons.person, color: Color(0xFF11a0db)),
                      title: Text(teacher.name),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddActionScreen(
                              teacherId: teacher.id,
                            ),
                          ),
                        );
                        await _loadActions();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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

  Future<void> _postponeActionByWeek(String teacherId, Action action) async {
    try {
      final baseDate = action.date ?? DateTime.now();
      final updatedAction = action.copyWith(date: baseDate.add(const Duration(days: 7)));
      await _firestoreService.updateAction(teacherId, updatedAction);
      await _loadActions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('המשימה נדחתה בשבוע.'),
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
                : Column(
                    children: [
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _loadActions,
                          child: _buildReorderableTasksList(),
                        ),
                      ),
                      if (_allActions.length > _visibleCount)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _visibleCount =
                                      (_visibleCount + 5).clamp(0, _allActions.length);
                                });
                              },
                              child: const Text('הצג עוד'),
                            ),
                          ),
                        ),
                    ],
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openAddAction,
          backgroundColor: const Color(0xFF11a0db),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildReorderableTasksList() {
    final itemCount = _allActions.isEmpty
        ? 0
        : (_visibleCount.clamp(0, _allActions.length));

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          if (oldIndex < 0 ||
              oldIndex >= itemCount ||
              newIndex < 0 ||
              newIndex >= itemCount) {
            return;
          }
          final item = _allActions.removeAt(oldIndex);
          _allActions.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        final item = _allActions[index];
        final action = item['action'] as Action;
        final teacherId = item['teacherId'] as String;
        final teacherName = item['teacherName'] as String;

        return Dismissible(
          key: ValueKey('${teacherId}_${action.id}'),
          direction: DismissDirection.horizontal,
          background: Container(
            alignment: Alignment.centerRight,
            color: Colors.orange,
            padding: const EdgeInsets.only(right: 20),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'דחיה בשבוע',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.schedule, color: Colors.white, size: 28),
              ],
            ),
          ),
          secondaryBackground: Container(
            alignment: Alignment.centerLeft,
            color: const Color(0xFF4CAF50),
            padding: const EdgeInsets.only(left: 20),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.check, color: Colors.white, size: 28),
                SizedBox(width: 8),
                Text(
                  'בוצע',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              await _postponeActionByWeek(teacherId, action);
            } else {
              await _toggleActionCompleted(teacherId, action);
            }
            return false;
          },
          child: Card(
            key: ValueKey('card_${teacherId}_${action.id}'),
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              leading: Checkbox(
                value: action.completed,
                onChanged: (_) {
                  _toggleActionCompleted(teacherId, action);
                },
                activeColor: const Color(0xFF40ae49),
                shape: const CircleBorder(),
              ),
              title: _buildTaskTitleRow(action, teacherName),
              subtitle: _buildTaskSubtitleRow(action),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (action.completed)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF40ae49),
                    ),
                  const SizedBox(width: 4),
                  ReorderableDragStartListener(
                    index: index,
                    child: const Icon(
                      Icons.drag_handle,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// כותרת קומפקטית: תאריך למעלה, סוג + ״אחר״ עם פירוט באותה שורה.
  Widget _buildTaskTitleRow(Action action, String teacherName) {
    final isOther = action.type.trim() == 'אחר';
    final hasNotes = action.notes != null && action.notes!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // שורה עליונה – תאריך + שם מורה באותה שורה (פחות שורות).
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (action.date != null)
              Expanded(
                child: DefaultTextStyle(
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  child: HebrewGregorianDateText(
                    date: action.date!,
                  ),
                ),
              )
            else
              const Expanded(
                child: Text(
                  'ללא תאריך',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Text(
              teacherName,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF11a0db),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // שורה שנייה – סוג + פירוט ״אחר״ באותה שורה.
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: action.type,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: action.completed ? Colors.grey : Colors.black,
                  decoration: action.completed
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
              if (isOther && hasNotes) ...[
                const TextSpan(
                  text: ' – ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: action.notes!.trim(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w400,
                    decoration: action.completed
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// שורת משנה – הערות נוספות רק כשזה לא ״אחר״ (כדי לא לפצל לשתי שורות).
  Widget _buildTaskSubtitleRow(Action action) {
    final isOther = action.type.trim() == 'אחר';
    final hasNotes = action.notes != null && action.notes!.trim().isNotEmpty;

    if (!hasNotes || isOther) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        action.notes!.trim(),
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}
