import 'package:flutter/material.dart';
import '../models/external_survey.dart';
import '../models/teacher.dart';
import '../services/firestore_service.dart';

/// מסך להצגת תוצאות שאלונים חיצוניים
class ExternalSurveyResultsScreen extends StatefulWidget {
  final String surveyId;

  const ExternalSurveyResultsScreen({
    super.key,
    required this.surveyId,
  });

  @override
  State<ExternalSurveyResultsScreen> createState() =>
      _ExternalSurveyResultsScreenState();
}

class _ExternalSurveyResultsScreenState
    extends State<ExternalSurveyResultsScreen> {
  final _firestoreService = FirestoreService();
  ExternalSurvey? _survey;

  @override
  void initState() {
    super.initState();
    _loadSurvey();
  }

  Future<void> _loadSurvey() async {
    final survey = await _firestoreService.getExternalSurvey(widget.surveyId);
    if (mounted) {
      setState(() {
        _survey = survey;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_survey?.title ?? 'תוצאות שאלון'),
        backgroundColor: const Color(0xFF11a0db),
      ),
      body: _survey == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Teacher>>(
              stream: _firestoreService.getTeachersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('שגיאה: ${snapshot.error}'),
                  );
                }

                final teachers = snapshot.data ?? [];
                final teachersWithResponses = teachers.where((teacher) {
                  return teacher.externalSurveys.containsKey(widget.surveyId);
                }).toList();

                if (teachersWithResponses.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'אין תשובות לשאלון זה עדיין.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_survey!.description != null &&
                        _survey!.description!.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _survey!.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      '${teachersWithResponses.length} מורים מילאו את השאלון',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...teachersWithResponses.map((teacher) =>
                        _buildTeacherResponseCard(teacher)),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildTeacherResponseCard(Teacher teacher) {
    final responses = teacher.externalSurveys[widget.surveyId] ?? {};
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          teacher.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${responses.length} תשובות'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _survey!.questions.map((question) {
                final response = responses[question.id];
                if (response == null) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.text,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildResponseDisplay(question, response),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseDisplay(
      ExternalSurveyQuestion question, dynamic response) {
    if (question.type == ExternalSurveyQuestionType.scale) {
      final score = response is int ? response : int.tryParse(response.toString());
      if (score != null) {
        return Row(
          children: [
            Text(
              '$score',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _getScoreColor(score),
              ),
            ),
            const Text(' / 6', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: LinearProgressIndicator(
                value: score / 6,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(score)),
              ),
            ),
          ],
        );
      }
    } else if (question.type == ExternalSurveyQuestionType.multipleChoice) {
      if (response is List) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: response
              .map((opt) => Chip(
                    label: Text(opt.toString()),
                    backgroundColor: const Color(0xFFE3F2FD),
                  ))
              .toList(),
        );
      } else {
        return Chip(
          label: Text(response.toString()),
          backgroundColor: const Color(0xFFE3F2FD),
        );
      }
    }

    // טקסט חופשי
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        response.toString(),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 5) return Colors.green;
    if (score >= 4) return Colors.lightGreen;
    if (score >= 3) return Colors.orange;
    return Colors.red;
  }
}
