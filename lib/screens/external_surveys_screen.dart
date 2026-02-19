import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/external_survey.dart';
import '../services/firestore_service.dart';
import 'external_survey_results_screen.dart';

/// מסך לניהול שאלונים חיצוניים שהמנהל יוצר
class ExternalSurveysScreen extends StatefulWidget {
  const ExternalSurveysScreen({super.key});

  @override
  State<ExternalSurveysScreen> createState() => _ExternalSurveysScreenState();
}

class _ExternalSurveysScreenState extends State<ExternalSurveysScreen> {
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('שאלונים חיצוניים'),
        backgroundColor: const Color(0xFF11a0db),
      ),
      body: StreamBuilder<List<ExternalSurvey>>(
        stream: _firestoreService.getExternalSurveysStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('שגיאה: ${snapshot.error}'),
            );
          }

          final surveys = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.add_circle, color: Color(0xFF11a0db)),
                  title: const Text('צור שאלון חדש'),
                  onTap: () => _showCreateSurveyDialog(context),
                ),
              ),
              const SizedBox(height: 16),
              if (surveys.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'אין שאלונים חיצוניים.\nצור שאלון חדש כדי להתחיל.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...surveys.map((survey) => _buildSurveyCard(survey)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSurveyCard(ExternalSurvey survey) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        survey.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (survey.description != null && survey.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            survey.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!survey.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'לא פעיל',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${survey.questions.length} שאלות',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  survey.includeEngagementSurvey
                      ? 'כולל שאלון מעורבות'
                      : 'רק שאלון בית הספר',
                  style: TextStyle(
                    fontSize: 13,
                    color: survey.includeEngagementSurvey
                        ? Colors.green[700]
                        : Colors.orange[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _viewResults(survey),
                  icon: const Icon(Icons.bar_chart, size: 18),
                  label: const Text('תוצאות'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _copySurveyLink(survey),
                  icon: const Icon(Icons.link, size: 18),
                  label: const Text('העתק קישור'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _editSurvey(survey),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('ערוך'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _deleteSurvey(survey),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'מחק',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _viewResults(ExternalSurvey survey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExternalSurveyResultsScreen(surveyId: survey.id),
      ),
    );
  }

  Future<void> _copySurveyLink(ExternalSurvey survey) async {
    try {
      final link = await _firestoreService.getExternalSurveyLink(survey.id);
      await Clipboard.setData(ClipboardData(text: link));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('הקישור הועתק ללוח. שלחי לקבוצת הצוות.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editSurvey(ExternalSurvey survey) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEditExternalSurveyScreen(survey: survey),
      ),
    );
    if (result == true && mounted) {
      setState(() {}); // רענון הרשימה
    }
  }

  Future<void> _deleteSurvey(ExternalSurvey survey) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת שאלון'),
        content: Text('האם את בטוחה שברצונך למחוק את השאלון "${survey.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('מחק'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteExternalSurvey(survey.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('השאלון נמחק בהצלחה')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('שגיאה במחיקה: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showCreateSurveyDialog(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateEditExternalSurveyScreen(),
      ),
    );
    if (result == true && mounted) {
      setState(() {}); // רענון הרשימה
    }
  }
}

/// מסך ליצירה/עריכה של שאלון חיצוני
class CreateEditExternalSurveyScreen extends StatefulWidget {
  final ExternalSurvey? survey;

  const CreateEditExternalSurveyScreen({super.key, this.survey});

  @override
  State<CreateEditExternalSurveyScreen> createState() =>
      _CreateEditExternalSurveyScreenState();
}

class _CreateEditExternalSurveyScreenState
    extends State<CreateEditExternalSurveyScreen> {
  final _firestoreService = FirestoreService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<ExternalSurveyQuestion> _questions = [];
  bool _isLoading = false;
  bool _includeEngagementSurvey = true;

  @override
  void initState() {
    super.initState();
    if (widget.survey != null) {
      _titleController.text = widget.survey!.title;
      _descriptionController.text = widget.survey!.description ?? '';
      _questions.addAll(widget.survey!.questions);
      _includeEngagementSurvey = widget.survey!.includeEngagementSurvey;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.survey == null ? 'צור שאלון חדש' : 'ערוך שאלון'),
        backgroundColor: const Color(0xFF11a0db),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'כותרת השאלון',
              hintText: 'למשל: שאלון אקלים - חנוכה 2024',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'תיאור (אופציונלי)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: CheckboxListTile(
                title: const Text(
                  'כולל שאלון מעורבות (Q12, מוטיבציה, תפקידים)',
                  style: TextStyle(fontSize: 15),
                ),
                subtitle: const Text(
                  'אם תבטלי – המורים ימלאו רק את שאלות בית הספר (מתאים להמשך השנה כשכבר יש מידע מעורבות)',
                  style: TextStyle(fontSize: 12),
                ),
                value: _includeEngagementSurvey,
                onChanged: (value) =>
                    setState(() => _includeEngagementSurvey = value ?? true),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'שאלות',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _addQuestion,
                icon: const Icon(Icons.add),
                label: const Text('הוסף שאלה'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_questions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'אין שאלות.\nהוסיפי שאלות כדי ליצור את השאלון.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...List.generate(
              _questions.length,
              (index) => _buildQuestionCard(index),
            ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveSurvey,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF11a0db),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'שמור שאלון',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
    final question = _questions[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${index + 1}. ${question.text}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeQuestion(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _getQuestionTypeLabel(question.type),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (question.type == ExternalSurveyQuestionType.multipleChoice &&
                question.options != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  children: question.options!
                      .map((opt) => Chip(label: Text(opt)))
                      .toList(),
                ),
              ),
            TextButton(
              onPressed: () => _editQuestion(index),
              child: const Text('ערוך שאלה'),
            ),
          ],
        ),
      ),
    );
  }

  String _getQuestionTypeLabel(ExternalSurveyQuestionType type) {
    switch (type) {
      case ExternalSurveyQuestionType.scale:
        return 'סולם 1-6';
      case ExternalSurveyQuestionType.multipleChoice:
        return 'בחירה מרובה';
      case ExternalSurveyQuestionType.text:
        return 'טקסט חופשי';
    }
  }

  Future<void> _addQuestion() async {
    final result = await Navigator.push<ExternalSurveyQuestion>(
      context,
      MaterialPageRoute(
        builder: (context) => const EditQuestionScreen(),
      ),
    );
    if (result != null) {
      setState(() {
        _questions.add(result);
      });
    }
  }

  Future<void> _editQuestion(int index) async {
    final result = await Navigator.push<ExternalSurveyQuestion>(
      context,
      MaterialPageRoute(
        builder: (context) => EditQuestionScreen(question: _questions[index]),
      ),
    );
    if (result != null) {
      setState(() {
        _questions[index] = result;
      });
    }
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  Future<void> _saveSurvey() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('נא להזין כותרת לשאלון'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('נא להוסיף לפחות שאלה אחת'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final survey = ExternalSurvey(
        id: widget.survey?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        questions: _questions,
        createdAt: widget.survey?.createdAt ?? DateTime.now(),
        isActive: widget.survey?.isActive ?? true,
        token: widget.survey?.token,
        includeEngagementSurvey: _includeEngagementSurvey,
      );

      if (widget.survey == null) {
        await _firestoreService.createExternalSurvey(survey);
      } else {
        await _firestoreService.updateExternalSurvey(survey);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('השאלון נשמר בהצלחה')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בשמירה: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

/// מסך לעריכת שאלה בודדת
class EditQuestionScreen extends StatefulWidget {
  final ExternalSurveyQuestion? question;

  const EditQuestionScreen({super.key, this.question});

  @override
  State<EditQuestionScreen> createState() => _EditQuestionScreenState();
}

class _EditQuestionScreenState extends State<EditQuestionScreen> {
  final _textController = TextEditingController();
  ExternalSurveyQuestionType _type = ExternalSurveyQuestionType.scale;
  final List<TextEditingController> _optionControllers = [];
  bool _required = true;

  @override
  void initState() {
    super.initState();
    if (widget.question != null) {
      _textController.text = widget.question!.text;
      _type = widget.question!.type;
      _required = widget.question!.required;
      if (widget.question!.options != null) {
        _optionControllers.addAll(
          widget.question!.options!.map((opt) => TextEditingController(text: opt)),
        );
      }
    } else {
      _optionControllers.add(TextEditingController());
      _optionControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    for (var ctrl in _optionControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ערוך שאלה'),
        backgroundColor: const Color(0xFF11a0db),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'טקסט השאלה',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ExternalSurveyQuestionType>(
            initialValue: _type,
            decoration: const InputDecoration(
              labelText: 'סוג השאלה',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: ExternalSurveyQuestionType.scale,
                child: Text('סולם 1-6'),
              ),
              DropdownMenuItem(
                value: ExternalSurveyQuestionType.multipleChoice,
                child: Text('בחירה מרובה'),
              ),
              DropdownMenuItem(
                value: ExternalSurveyQuestionType.text,
                child: Text('טקסט חופשי'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _type = value);
                if (value == ExternalSurveyQuestionType.multipleChoice &&
                    _optionControllers.isEmpty) {
                  _optionControllers.add(TextEditingController());
                  _optionControllers.add(TextEditingController());
                }
              }
            },
          ),
          if (_type == ExternalSurveyQuestionType.multipleChoice) ...[
            const SizedBox(height: 16),
            const Text(
              'אופציות:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...List.generate(
              _optionControllers.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _optionControllers[index],
                        decoration: InputDecoration(
                          labelText: 'אופציה ${index + 1}',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    if (_optionControllers.length > 2)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _optionControllers[index].dispose();
                            _optionControllers.removeAt(index);
                          });
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                  ],
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _optionControllers.add(TextEditingController());
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('הוסף אופציה'),
            ),
          ],
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('שאלה חובה'),
            value: _required,
            onChanged: (value) => setState(() => _required = value ?? true),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF11a0db),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('שמור שאלה', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  void _saveQuestion() {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('נא להזין טקסט לשאלה'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_type == ExternalSurveyQuestionType.multipleChoice) {
      final options = _optionControllers
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (options.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('נא להוסיף לפחות 2 אופציות'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final question = ExternalSurveyQuestion(
        id: widget.question?.id ?? 'q${DateTime.now().millisecondsSinceEpoch}',
        text: _textController.text.trim(),
        type: _type,
        options: options,
        required: _required,
      );
      Navigator.pop(context, question);
    } else {
      final question = ExternalSurveyQuestion(
        id: widget.question?.id ?? 'q${DateTime.now().millisecondsSinceEpoch}',
        text: _textController.text.trim(),
        type: _type,
        required: _required,
      );
      Navigator.pop(context, question);
    }
  }
}
