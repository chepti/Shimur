import 'package:flutter/material.dart' hide Action;
import '../models/action.dart';
import '../models/teacher.dart';
import '../services/firestore_service.dart';
import '../services/gemini_service.dart';
import '../widgets/hebrew_gregorian_date.dart';

class AddActionScreen extends StatefulWidget {
  final String teacherId;
  /// אופציונלי: סוג פעולה מוצע (למשל מסיכום שבוע)
  final String? suggestedType;
  /// אופציונלי: מורה – לשימוש ב-AI (הצע ניסוח)
  final Teacher? teacher;

  const AddActionScreen({
    super.key,
    required this.teacherId,
    this.suggestedType,
    this.teacher,
  });

  @override
  State<AddActionScreen> createState() => _AddActionScreenState();
}

class _AddActionScreenState extends State<AddActionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _firestoreService = FirestoreService();
  late String _selectedType;
  DateTime? _selectedDate;
  bool _isCompleted = false;
  bool _isLoading = false;
  bool _suggestingDraft = false;

  bool get _canSuggestDraft =>
      _selectedType.contains('הוקרה') || _selectedType.contains('מילה');

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

  Future<void> _showAiActionSuggestions() async {
    Teacher? teacher = widget.teacher;
    teacher ??= await _firestoreService.getTeacher(widget.teacherId);
    if (teacher == null) return;

    final (canUse, errorMsg) = await _firestoreService.canUseGemini();
    if (!canUse) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg ?? 'לא ניתן להשתמש ב-AI')),
        );
      }
      return;
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AiActionSuggestionsSheet(
        teacher: teacher!,
        firestoreService: _firestoreService,
        onSelect: (suggestion) {
          Navigator.pop(ctx);
          if (_actionTypes.contains(suggestion)) {
            setState(() => _selectedType = suggestion);
          } else {
            setState(() {
              _selectedType = 'אחר';
              _notesController.text = suggestion;
            });
          }
        },
      ),
    );
  }

  Future<void> _suggestDraft() async {
    Teacher? teacher = widget.teacher;
    teacher ??= await _firestoreService.getTeacher(widget.teacherId);
    if (teacher == null) return;

    final (canUse, errorMsg) = await _firestoreService.canUseGemini();
    if (!canUse) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg ?? 'לא ניתן להשתמש ב-AI')),
        );
      }
      return;
    }

    setState(() => _suggestingDraft = true);
    try {
      final drafts = await GeminiService.generateMessageDrafts(
        teacher: teacher,
      );
      await _firestoreService.recordGeminiUsage();
      if (mounted && drafts != null && drafts.isNotEmpty) {
        _notesController.text = drafts.first;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('נוסח הודעת הוקרה הוכנס')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _suggestingDraft = false);
    }
  }

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
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('נא לבחור תאריך')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final action = Action(
        id: '', // יווצר אוטומטית
        type: _selectedType,
        date: _selectedDate!,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        completed: _isCompleted,
        createdAt: DateTime.now(),
      );

      await _firestoreService.addAction(widget.teacherId, action);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('הפעולה נשמרה בהצלחה!')),
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
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'סוג פעולה *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _isLoading || _suggestingDraft
                          ? null
                          : _showAiActionSuggestions,
                      icon: const Icon(Icons.auto_awesome, size: 20),
                      label: const Text('המלצות לפי AI'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
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
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365),
                      ),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 12),
                        if (_selectedDate == null)
                          Text(
                            'בחר תאריך',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
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
                    suffixIcon: _canSuggestDraft
                        ? IconButton(
                            icon: _suggestingDraft
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.auto_awesome),
                            tooltip: 'הצע ניסוח מותאם',
                            onPressed:
                                (_isLoading || _suggestingDraft)
                                    ? null
                                    : _suggestDraft,
                          )
                        : null,
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

/// גיליון המלצות פעולות לפי AI
class _AiActionSuggestionsSheet extends StatefulWidget {
  final Teacher teacher;
  final FirestoreService firestoreService;
  final void Function(String) onSelect;

  const _AiActionSuggestionsSheet({
    required this.teacher,
    required this.firestoreService,
    required this.onSelect,
  });

  @override
  State<_AiActionSuggestionsSheet> createState() =>
      _AiActionSuggestionsSheetState();
}

class _AiActionSuggestionsSheetState extends State<_AiActionSuggestionsSheet> {
  List<String>? _suggestions;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final suggestions = await GeminiService.generateActionSuggestions(
        teacher: widget.teacher,
      );
      await widget.firestoreService.recordGeminiUsage();
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'שגיאה: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: 16),
              Text(
                'המלצות פעולות ל־${widget.teacher.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                Text(_error!, style: TextStyle(color: Colors.red[700]))
              else if (_suggestions != null && _suggestions!.isNotEmpty)
                ..._suggestions!.map((text) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.lightbulb_outline),
                        title: Text(text),
                        onTap: () => widget.onSelect(text),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor: Colors.grey[100],
                      ),
                    ))
              else
                const Text('לא נוצרו המלצות. נסי שוב.'),
            ],
          ),
        ),
      ),
    );
  }
}

