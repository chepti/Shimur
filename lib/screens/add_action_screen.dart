import 'package:flutter/material.dart' hide Action;
import 'package:material_hebrew_date_picker/material_hebrew_date_picker.dart';
import '../models/action.dart';
import '../services/firestore_service.dart';
import '../widgets/hebrew_gregorian_date.dart';

class AddActionScreen extends StatefulWidget {
  final String teacherId;
  /// אופציונלי: סוג פעולה מוצע (למשל מסיכום שבוע)
  final String? suggestedType;

  const AddActionScreen({
    Key? key,
    required this.teacherId,
    this.suggestedType,
  }) : super(key: key);

  @override
  State<AddActionScreen> createState() => _AddActionScreenState();
}

/// בחירת תאריך: צ'יפ או תאריך ספציפי
enum _DateChoice { none, thisWeek, thisMonth, specific }

class _AddActionScreenState extends State<AddActionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _firestoreService = FirestoreService();
  late String _selectedType;
  DateTime? _selectedDate;
  _DateChoice _dateChoice = _DateChoice.specific;
  bool _isCompleted = false;
  bool _isLoading = false;
  bool _addToRecommended = false;
  bool _shareAnonymously = true;

  /// סוף השבוע הנוכחי (שבת)
  static DateTime _endOfThisWeek() {
    final now = DateTime.now();
    final daysToSaturday = (6 - now.weekday + 7) % 7;
    final saturday = now.add(Duration(days: daysToSaturday));
    return DateTime(saturday.year, saturday.month, saturday.day);
  }

  /// סוף החודש הנוכחי
  static DateTime _endOfThisMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0);
  }

  Widget _buildDateChip(String label, _DateChoice choice) {
    final selected = _dateChoice == choice;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) {
        setState(() {
          _dateChoice = choice;
          if (choice == _DateChoice.thisWeek) {
            _selectedDate = _endOfThisWeek();
          } else if (choice == _DateChoice.thisMonth) {
            _selectedDate = _endOfThisMonth();
          } else if (choice == _DateChoice.none) {
            _selectedDate = null;
          }
        });
      },
      selectedColor: const Color(0xFF11a0db).withValues(alpha: 0.3),
      checkmarkColor: const Color(0xFF11a0db),
    );
  }

  /// פותח בורר תאריך עברי (לוח עברי בתוך החלונית).
  static Future<DateTime?> _showHebrewAwareDatePicker({
    required BuildContext context,
    required DateTime initialDate,
  }) {
    return showMaterialHebrewDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      hebrewFormat: true,
    );
  }

  final List<String> _actionTypes = [
    'שיחה אישית - הקשבה ותמיכה',
    'פגישת משוב מעצים',
    'הודעת הוקרה (וואטסאפ/טלפון)',
    'מכתב הערכה רשמי',
    'הצעת תפקיד חדש/אחריות',
    'המלצה להשתלמות/פיתוח מקצועי',
    'ביקור בשיעור (למידת עמיתים)',
    'מתנה קטנה/סימן תשומת לב',
    'עזרה בבעיה אישית/מקצועית',
    'שיתוף בקבלת החלטות',
    'ציון יום הולדת/אירוע אישי',
    'אחר',
  ];

  @override
  void initState() {
    super.initState();
    final suggested = widget.suggestedType?.trim();
    if (suggested != null && suggested.isNotEmpty) {
      if (_actionTypes.contains(suggested)) {
        _selectedType = suggested;
      } else {
        _selectedType = 'אחר';
        _notesController.text = suggested;
      }
    } else {
      _selectedType = 'שיחה אישית - הקשבה ותמיכה';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveAction() async {
    final effectiveDate = _dateChoice == _DateChoice.none ? null : _selectedDate;
    if (effectiveDate == null && _dateChoice != _DateChoice.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('נא לבחור תאריך או לסמן "ללא תאריך"')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final action = Action(
        id: '', // יווצר אוטומטית
        type: _selectedType,
        date: effectiveDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        completed: _isCompleted,
        createdAt: DateTime.now(),
      );

      await _firestoreService.addAction(widget.teacherId, action);

      if (_addToRecommended && _selectedType.trim().isNotEmpty) {
        try {
          await _firestoreService.addRecommendedAction(
            type: _selectedType.trim(),
            isAnonymous: _shareAnonymously,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('הפעולה נשמרה וגם נוספה למאגר המומלצות')),
            );
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('הפעולה נשמרה; הוספה למאגר נכשלה')),
            );
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('הפעולה נשמרה בהצלחה!')),
        );
      }
      if (mounted) Navigator.pop(context);
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
          title: const Text('הוספת פעולה'),
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
                const Text(
                  'סוג פעולה *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _actionTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'תאריך ביצוע *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildDateChip('בשבוע הקרוב', _DateChoice.thisWeek),
                    _buildDateChip('בחודש הקרוב', _DateChoice.thisMonth),
                    _buildDateChip('ללא תאריך', _DateChoice.none),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final date = await _showHebrewAwareDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _dateChoice = _DateChoice.specific;
                        _selectedDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _dateChoice == _DateChoice.specific && _selectedDate != null
                            ? const Color(0xFF11a0db)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 12),
                        if (_dateChoice == _DateChoice.none)
                          Text(
                            'ללא תאריך',
                            style: TextStyle(color: Colors.grey[600]),
                          )
                        else if (_selectedDate == null)
                          Text(
                            'בחר תאריך ספציפי',
                            style: TextStyle(color: Colors.grey[600]),
                          )
                        else
                          HebrewGregorianDateText(
                            date: _selectedDate!,
                          ),
                      ],
                    ),
                  ),
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
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('האם בוצעה?'),
                  value: _isCompleted,
                  onChanged: (value) {
                    setState(() => _isCompleted = value ?? false);
                  },
                  activeColor: const Color(0xFF11a0db),
                ),
                const SizedBox(height: 8),
                const Divider(),
                const Text(
                  'למידה הדדית – שתף עם מנהלים אחרים',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                CheckboxListTile(
                  title: const Text('הוסף גם למאגר פעולות מומלצות'),
                  subtitle: const Text(
                    'מנהלים אחרים יוכלו לראות, לדרג ולהתנסות בפעולה',
                  ),
                  value: _addToRecommended,
                  onChanged: (value) {
                    setState(() => _addToRecommended = value ?? false);
                  },
                  activeColor: const Color(0xFF11a0db),
                ),
                if (_addToRecommended)
                  CheckboxListTile(
                    title: const Text('שתף באנונימיות'),
                    value: _shareAnonymously,
                    onChanged: (value) {
                      setState(() => _shareAnonymously = value ?? true);
                    },
                    activeColor: const Color(0xFF11a0db),
                  ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveAction,
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
}

