import 'package:flutter/material.dart';
import '../models/teacher.dart';
import '../services/firestore_service.dart';

class AddTeacherScreen extends StatefulWidget {
  const AddTeacherScreen({Key? key}) : super(key: key);

  @override
  State<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _seniorityController = TextEditingController();
  final _totalSeniorityController = TextEditingController();
  final _notesController = TextEditingController();
  final _absencesController = TextEditingController();
  final _firestoreService = FirestoreService();
  String _selectedStatus = 'green';
  bool _isLoading = false;
  double _workloadPercent = 86; // ברירת מחדל 86%
  double _satisfactionRating = 3;
  double _belongingRating = 3;
  double _workloadRating = 3;
  final Set<String> _selectedActivities = {};
  final TextEditingController _newActivityController = TextEditingController();

  static const List<String> _baseActivities = [
    'רכז',
    'ליווי טיול',
    'טקס',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _seniorityController.dispose();
    _totalSeniorityController.dispose();
    _notesController.dispose();
    _absencesController.dispose();
    _newActivityController.dispose();
    super.dispose();
  }

  Future<void> _saveTeacher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final teacher = Teacher(
        id: '', // יווצר אוטומטית ב-Firestore
        name: _nameController.text.trim(),
        seniorityYears: int.parse(_seniorityController.text),
        totalSeniorityYears: int.parse(_totalSeniorityController.text),
        status: _selectedStatus,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: DateTime.now(),
        workloadPercent: _workloadPercent.toInt(),
        satisfactionRating: _satisfactionRating.toInt(),
        belongingRating: _belongingRating.toInt(),
        workloadRating: _workloadRating.toInt(),
        absencesThisYear: int.tryParse(_absencesController.text.trim()) ?? 0,
        specialActivities: _selectedActivities.toList(),
      );

      await _firestoreService.addTeacher(teacher);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('המורה נוסף בהצלחה!')),
        );
        Navigator.pop(context);
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
          title: const Text('הוספת מורה'),
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
                  controller: _seniorityController,
                  decoration: InputDecoration(
                    labelText: 'וותק בבית הספר (שנים) *',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'נא להזין וותק';
                    }
                    if (int.tryParse(value) == null) {
                      return 'נא להזין מספר תקין';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _totalSeniorityController,
                  decoration: InputDecoration(
                    labelText: 'וותק כללי (שנים) *',
                    prefixIcon: const Icon(Icons.work),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'נא להזין וותק כללי';
                    }
                    if (int.tryParse(value) == null) {
                      return 'נא להזין מספר תקין';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'היקף משרה',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _workloadPercent,
                        min: 3,
                        max: 116,
                        divisions: 113,
                        label: '${_workloadPercent.toInt()}%',
                        onChanged: (value) {
                          setState(() => _workloadPercent = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: Text(
                        '${_workloadPercent.toInt()}%',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'דירוגים (1–5)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildRatingRow('שביעות רצון', _satisfactionRating,
                    (v) => setState(() => _satisfactionRating = v)),
                _buildRatingRow('תחושת שייכות', _belongingRating,
                    (v) => setState(() => _belongingRating = v)),
                _buildRatingRow('עומס', _workloadRating,
                    (v) => setState(() => _workloadRating = v)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _absencesController,
                  decoration: InputDecoration(
                    labelText: 'היעדרויות השנה',
                    prefixIcon: const Icon(Icons.event_busy),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return null; // אופציונלי
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'נא להזין מספר תקין';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'פעילויות מיוחדות',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    ...{..._baseActivities, ..._selectedActivities}.map(
                      (activity) => FilterChip(
                        label: Text(activity),
                        selected: _selectedActivities.contains(activity),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedActivities.add(activity);
                            } else {
                              _selectedActivities.remove(activity);
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newActivityController,
                        decoration: InputDecoration(
                          labelText: 'הוסף פעילות מיוחדת',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle,
                          color: Color(0xFF11a0db)),
                      onPressed: () {
                        final text = _newActivityController.text.trim();
                        if (text.isEmpty) return;
                        setState(() {
                          _selectedActivities.add(text);
                          _newActivityController.clear();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'סטטוס *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusOption('green', '🟢 יציב'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatusOption('yellow', '🟡 מעקב'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatusOption('red', '🔴 סיכון'),
                    ),
                  ],
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

  Widget _buildStatusOption(String status, String label) {
    final isSelected = _selectedStatus == status;
    return InkWell(
      onTap: () => setState(() => _selectedStatus = status),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? _getStatusColor(status).withOpacity(0.15)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? _getStatusColor(status).withOpacity(0.6)
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? _getStatusColor(status)
                  : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'green':
        return const Color(0xFF4CAF50);
      case 'yellow':
        return const Color(0xFFFFC107);
      case 'red':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  Widget _buildRatingRow(
      String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: 1,
                max: 5,
                divisions: 4,
                label: value.toInt().toString(),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 24,
              child: Text(
                value.toInt().toString(),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

