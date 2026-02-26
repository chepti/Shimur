import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/external_survey.dart';
import '../models/teacher.dart';
import '../services/external_survey_export_service.dart';
import '../services/firestore_service.dart';
import '../utils/download_helper.dart';

/// מסך להצגת תוצאות שאלונים חיצוניים – דשבורד, פירוט והורדת אקסל
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
    extends State<ExternalSurveyResultsScreen>
    with SingleTickerProviderStateMixin {
  final _firestoreService = FirestoreService();
  ExternalSurvey? _survey;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadSurvey();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSurvey() async {
    final survey = await _firestoreService.getExternalSurvey(widget.surveyId);
    if (mounted) {
      setState(() {
        _survey = survey;
      });
    }
  }

  Future<void> _exportToExcel(
    ExternalSurvey survey,
    List<Teacher> teachersWithResponses,
  ) async {
    try {
      final bytes = ExternalSurveyExportService.exportToExcel(
        survey: survey,
        teachersWithResponses: teachersWithResponses,
      );
      final fileName = ExternalSurveyExportService.suggestedFileName(survey);
      downloadBytes(bytes, fileName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('הקובץ הורד בהצלחה')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בייצוא: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerRight,
          child: Text(_survey?.title ?? 'תוצאות שאלון'),
        ),
        backgroundColor: const Color(0xFF11a0db),
        bottom: _survey != null
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.dashboard), text: 'סיכום'),
                  Tab(icon: Icon(Icons.list), text: 'פירוט'),
                ],
              )
            : null,
        actions: [
          Builder(
            builder: (context) {
              return StreamBuilder<List<Teacher>>(
                stream: _firestoreService.getTeachersStream(),
                builder: (context, snapshot) {
                  final teachers = snapshot.data ?? [];
                  final teachersWithResponses = teachers
                      .where((t) => t.externalSurveys.containsKey(widget.surveyId))
                      .toList();
                  if (teachersWithResponses.isEmpty || _survey == null) {
                    return const SizedBox.shrink();
                  }
                  return IconButton(
                    icon: const Icon(Icons.download),
                    tooltip: 'הורד לאקסל',
                    onPressed: () => _exportToExcel(_survey!, teachersWithResponses),
                  );
                },
              );
            },
          ),
        ],
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
                  return Center(child: Text('שגיאה: ${snapshot.error}'));
                }

                final teachers = snapshot.data ?? [];
                final teachersWithResponses = teachers
                    .where((t) => t.externalSurveys.containsKey(widget.surveyId))
                    .toList();

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

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _SurveyDashboardTab(
                      survey: _survey!,
                      teachersWithResponses: teachersWithResponses,
                    ),
                    _SurveyDetailTab(
                      survey: _survey!,
                      surveyId: widget.surveyId,
                      teachersWithResponses: teachersWithResponses,
                    ),
                  ],
                );
              },
            ),
    );
  }
}

/// טאב דשבורד – גרפים והתפלגויות
class _SurveyDashboardTab extends StatelessWidget {
  final ExternalSurvey survey;
  final List<Teacher> teachersWithResponses;

  const _SurveyDashboardTab({
    required this.survey,
    required this.teachersWithResponses,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard(context),
        const SizedBox(height: 24),
        ...survey.questions.map((q) => _buildQuestionChart(context, q)),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF11a0db).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.people,
                color: Color(0xFF11a0db),
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${teachersWithResponses.length} מורים מילאו את השאלון',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${survey.questions.length} שאלות',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionChart(BuildContext context, ExternalSurveyQuestion question) {
    if (question.type == ExternalSurveyQuestionType.scale) {
      return _buildScaleChart(context, question);
    }
    if (question.type == ExternalSurveyQuestionType.multipleChoice) {
      return _buildPieChart(question);
    }
    return _buildWordCloud(context, question);
  }

  Widget _buildScaleChart(BuildContext context, ExternalSurveyQuestion question) {
    final distribution = <int, int>{};
    final teachersByScore = <int, List<Teacher>>{};
    for (var i = 1; i <= 6; i++) {
      distribution[i] = 0;
      teachersByScore[i] = [];
    }
    for (final teacher in teachersWithResponses) {
      final responses = teacher.externalSurveys[survey.id] ?? {};
      final val = responses[question.id];
      final score = val is int ? val : int.tryParse(val?.toString() ?? '');
      if (score != null && score >= 1 && score <= 6) {
        distribution[score] = (distribution[score] ?? 0) + 1;
        teachersByScore[score]!.add(teacher);
      }
    }

    final maxCount = distribution.values.isEmpty
        ? 1
        : distribution.values.reduce(math.max).clamp(1, 999);
    final total = distribution.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              question.text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (maxCount + 1).toDouble(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (_, __, ___, ____) => null,
                    ),
                    touchCallback: (event, response) {
                      if (event is FlTapUpEvent &&
                          response != null &&
                          response.spot != null) {
                        final score = response.spot!.touchedBarGroupIndex + 1;
                        final teachers = teachersByScore[score] ?? [];
                        if (teachers.isNotEmpty) {
                          _showTeachersBottomSheet(
                            context,
                            'ציון $score',
                            teachers.map((t) => t.name).toList(),
                          );
                        }
                      }
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (v, meta) => Text(
                          v.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          if (i >= 0 && i < 6) {
                            final score = i + 1;
                            final count = distribution[score] ?? 0;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _getScoreColor(score),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(6, (i) {
                    final score = i + 1;
                    final count = distribution[score] ?? 0;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: count.toDouble(),
                          color: _getScoreColor(score),
                          width: 24,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                      showingTooltipIndicators: [],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTeachersBottomSheet(
    BuildContext context,
    String title,
    List<String> names,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.7,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: names.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(names[i], textAlign: TextAlign.right),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(ExternalSurveyQuestion question) {
    final counts = <String, int>{};
    for (final teacher in teachersWithResponses) {
      final responses = teacher.externalSurveys[survey.id] ?? {};
      final val = responses[question.id];
      if (val is List) {
        for (final opt in val) {
          final s = opt.toString();
          counts[s] = (counts[s] ?? 0) + 1;
        }
      } else if (val != null && val.toString().isNotEmpty) {
        final s = val.toString();
        counts[s] = (counts[s] ?? 0) + 1;
      }
    }

    if (counts.isEmpty) return const SizedBox.shrink();

    final colors = [
      const Color(0xFF11a0db),
      const Color(0xFF40AE49),
      const Color(0xFFFAA41A),
      const Color(0xFFAC2B31),
      const Color(0xFF9C27B0),
      Colors.teal,
      Colors.orange,
    ];

    final sections = counts.entries.toList().asMap().entries.map((e) {
      final i = e.key;
      final entry = e.value;
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${entry.key} (${entry.value})',
        color: colors[i % colors.length],
        radius: 80,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      );
    }).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              question.text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {},
                        ),
                      ),
                      duration: const Duration(milliseconds: 300),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: counts.entries.toList().asMap().entries.map((e) {
                        final i = e.key;
                        final entry = e.value;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colors[i % colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                entry.key,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordCloud(BuildContext context, ExternalSurveyQuestion question) {
    final wordCounts = <String, int>{};
    final responsesWithTeachers = <String, List<Teacher>>{};
    final stopWords = {'את', 'על', 'ב', 'ל', 'של', 'ה', 'ו', 'או', 'כ', 'מ', 'א', 'לא', 'כן'};

    for (final teacher in teachersWithResponses) {
      final responses = teacher.externalSurveys[survey.id] ?? {};
      final val = responses[question.id];
      if (val == null || val.toString().trim().isEmpty) continue;

      final text = val.toString().trim();
      responsesWithTeachers[text] = [...(responsesWithTeachers[text] ?? []), teacher];

      final words = text.split(RegExp(r'\s+'));
      for (final w in words) {
        final clean = w.replaceAll(RegExp(r'[^\u0590-\u05FF\w]'), '').trim();
        if (clean.length >= 2 && !stopWords.contains(clean)) {
          wordCounts[clean] = (wordCounts[clean] ?? 0) + 1;
        }
      }
    }

    if (wordCounts.isEmpty) return const SizedBox.shrink();

    final sorted = wordCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topWords = sorted.take(40).toList();
    final maxCount = topWords.isEmpty ? 1 : topWords.first.value;
    final minCount = topWords.isEmpty ? 1 : topWords.last.value;

    final cloudColors = [
      const Color(0xFF11a0db),
      const Color(0xFF6B4E9C),
      const Color(0xFFAC2B31),
      const Color(0xFFFAA41A),
      Colors.indigo,
      Colors.deepPurple,
    ];

    final sentences = responsesWithTeachers.entries
        .map((e) => MapEntry(e.key, e.value.map((t) => t.name).toList()))
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              question.text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 8),
            Text(
              'ענן מילים – מילים חוזרות בתשובות (לחיצה להצגת משפטים)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _showSentencesBottomSheet(context, question.text, sentences),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: topWords.map((e) {
                  final ratio = maxCount > minCount
                      ? (e.value - minCount) / (maxCount - minCount)
                      : 1.0;
                  final size = 10.0 + ratio * 14;
                  final color = cloudColors[e.value % cloudColors.length];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      e.key,
                      style: TextStyle(
                        fontSize: size,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSentencesBottomSheet(
    BuildContext context,
    String questionText,
    List<MapEntry<String, List<String>>> sentencesWithTeachers,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                questionText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 8),
              const Text(
                'משפטים מהתשובות',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: sentencesWithTeachers.length,
                  itemBuilder: (_, i) {
                    final entry = sentencesWithTeachers[i];
                    final names = entry.value.join(', ');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        textDirection: TextDirection.rtl,
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                entry.key,
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 100,
                            child: Text(
                              names,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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

/// טאב פירוט – רשימת מורים ותשובות
class _SurveyDetailTab extends StatelessWidget {
  final ExternalSurvey survey;
  final String surveyId;
  final List<Teacher> teachersWithResponses;

  const _SurveyDetailTab({
    required this.survey,
    required this.surveyId,
    required this.teachersWithResponses,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (survey.description != null && survey.description!.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                survey.description!,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        if (survey.description != null && survey.description!.isNotEmpty)
          const SizedBox(height: 16),
        ...teachersWithResponses.map((t) => _TeacherResponseCard(
              teacher: t,
              survey: survey,
              surveyId: surveyId,
            )),
      ],
    );
  }
}

class _TeacherResponseCard extends StatelessWidget {
  final Teacher teacher;
  final ExternalSurvey survey;
  final String surveyId;

  const _TeacherResponseCard({
    required this.teacher,
    required this.survey,
    required this.surveyId,
  });

  @override
  Widget build(BuildContext context) {
    final responses = teacher.externalSurveys[surveyId] ?? {};

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(teacher.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${responses.length} תשובות'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: survey.questions.map((question) {
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(response.toString(), style: const TextStyle(fontSize: 14)),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 5) return Colors.green;
    if (score >= 4) return Colors.lightGreen;
    if (score >= 3) return Colors.orange;
    return Colors.red;
  }
}
