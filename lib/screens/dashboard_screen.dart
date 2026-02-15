import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/teacher.dart';
import '../services/firestore_service.dart';
import '../widgets/status_indicator.dart';
import 'teacher_details_screen.dart';
import 'weekly_start_notification_screen.dart';
import 'weekly_summary_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _firestoreService = FirestoreService();
  late Future<List<DailyInteractions>> _interactionsFuture;

  @override
  void initState() {
    super.initState();
    _interactionsFuture =
        _firestoreService.getRecentInteractionsStats(days: 14);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('דשבורד'),
        backgroundColor: const Color(0xFF11a0db),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Teacher>>(
          stream: _firestoreService.getTeachersStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final teachers = snapshot.data ?? [];
            if (teachers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'אין מורים עדיין',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            final stats = _calculateStats(teachers);
            final needAttention = _teachersNeedingAttention(teachers);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // כרטיסי KPI עליונים
                  _buildKpiRow(teachers, stats),
                  const SizedBox(height: 24),

                  // תרשים עמודות – סטטוסים רגשיים
                  _buildSectionTitle('התפלגות סטטוסים רגשיים'),
                  const SizedBox(height: 12),
                  _buildMoodStatusDistribution(context, teachers, stats.moodStatusCount),
                  const SizedBox(height: 24),

                  // גרף קווי – התייחסויות בימים האחרונים
                  _buildSectionTitle('התייחסויות בימים האחרונים'),
                  const SizedBox(height: 12),
                  _buildInteractionsSection(),
                  const SizedBox(height: 24),

                  // מי דורש תשומת לב עכשיו
                  if (needAttention.isNotEmpty) ...[
                    _buildSectionTitle('מי דורש תשומת לב עכשיו'),
                    const SizedBox(height: 12),
                    _buildNeedAttentionCard(context, needAttention),
                    const SizedBox(height: 24),
                  ],

                  // קיצורי דרך למסכי עומק
                  _buildWeeklyNotificationCard(context),
                  const SizedBox(height: 12),
                  _buildWeeklySummaryCard(context),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
    );
  }

  Widget _buildWeeklyNotificationCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WeeklyStartNotificationScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(32),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF11a0db).withOpacity(0.2),
                child: const Icon(
                  Icons.notifications_active,
                  color: Color(0xFF11a0db),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'התראה לתחילת השבוע',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'פגישות מומלצות, מילים טובות והעתקה למזכירה',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklySummaryCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WeeklySummaryScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(32),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.amber.withOpacity(0.3),
                child: Icon(Icons.weekend, color: Colors.amber[800], size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'סיכום שבוע',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'סיווג התייחסות, עדכון סטטוס רגשי והיגדים לפעולה',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildKpiRow(List<Teacher> teachers, DashboardStats stats) {
    final needAttention = _teachersNeedingAttention(teachers);
    final totalTeachers = teachers.length;
    final atRiskCount = teachers.where((t) {
      final moodKey = _mapLegacyStatusToMood(t.moodStatus ?? t.status);
      return moodKey == 'disconnected' || moodKey == 'burned_out';
    }).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildKpiCard(
            title: 'סה״כ מורים',
            value: '$totalTeachers',
            subtitle: 'במערכת כעת',
            icon: Icons.people,
            color: const Color(0xFF11a0db),
          ),
          const SizedBox(width: 12),
          _buildKpiCard(
            title: 'דורשים תשומת לב',
            value: '${math.min(needAttention.length, 99)}',
            subtitle: 'לפי סטטוס וזמן יחס',
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFED1C24),
          ),
          const SizedBox(width: 12),
          _buildKpiCard(
            title: 'במצב סיכון',
            value: '$atRiskCount',
            subtitle: 'מנותקים / שחוקים',
            icon: Icons.local_fire_department_outlined,
            color: const Color(0xFFAC2B31),
          ),
          const SizedBox(width: 12),
          _buildKpiCard(
            title: 'ממוצע שביעות רצון',
            value: stats.avgSatisfaction.toStringAsFixed(1),
            subtitle: 'מתוך 5',
            icon: Icons.sentiment_satisfied_alt,
            color: const Color(0xFF40AE49),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodStatusDistribution(
    BuildContext context,
    List<Teacher> teachers,
    Map<String, int> moodStatusCount,
  ) {
    final total = moodStatusCount.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final statuses = ['bloom', 'flow', 'tense', 'disconnected', 'burned_out'];
    final labels = {
      'bloom': 'פורחים',
      'flow': 'זורמים',
      'tense': 'מתוחים',
      'disconnected': 'מנותקים',
      'burned_out': 'שחוקים',
    };

    final maxCount = moodStatusCount.values.isEmpty
        ? 1
        : moodStatusCount.values.reduce(math.max).clamp(1, 999);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: (maxCount + 1).toDouble(),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipBorderRadius: BorderRadius.circular(12),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final key = statuses[group.x.toInt()];
                        final label = labels[key] ?? key;
                        final count = moodStatusCount[key] ?? 0;
                        return BarTooltipItem(
                          '$label\n$count מורים',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                    // פתיחת רשימת המורים רק בלחיצה, לא בריחוף
                    touchCallback: (event, response) {
                      if (event is! FlTapUpEvent ||
                          response == null ||
                          response.spot == null) {
                        return;
                      }
                      final index = response.spot!.touchedBarGroupIndex;
                      if (index < 0 || index >= statuses.length) return;
                      final statusKey = statuses[index];
                      _showTeachersByMoodStatus(
                        context,
                        teachers,
                        statusKey,
                        labels[statusKey] ?? statusKey,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 != 0) return const SizedBox.shrink();
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= statuses.length) {
                            return const SizedBox.shrink();
                          }
                          final key = statuses[index];
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              labels[key] ?? key,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(statuses.length, (index) {
                    final key = statuses[index];
                    final count = (moodStatusCount[key] ?? 0).toDouble();
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: count,
                          width: 20,
                          borderRadius: BorderRadius.circular(16),
                          color: _moodStatusColor(key),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxCount.toDouble(),
                            color: Colors.grey.withOpacity(0.08),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: statuses.map((key) {
                final count = moodStatusCount[key] ?? 0;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusIndicator(status: key, size: 10),
                    const SizedBox(width: 4),
                    Text(
                      '${labels[key]} · $count',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: FutureBuilder<List<DailyInteractions>>(
          future: _interactionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final data = snapshot.data ?? [];
            if (data.isEmpty) {
              return const SizedBox(
                height: 80,
                child: Center(
                  child: Text(
                    'אין עדיין התייחסויות מתועדות בטווח הזמן שנבחר',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              );
            }

            final dateFormat = DateFormat('d.M');
            final days = data.length;

            // בניית סדרות לפי סוג
            final typeKeys = ['good_word', 'short_talk', 'meeting', 'other'];
            final typeColors = {
              'good_word': const Color(0xFF40AE49),
              'short_talk': const Color(0xFFFAA41A),
              'meeting': const Color(0xFF11A0DB),
              'other': Colors.grey,
            };

            double maxY = 1;
            final Map<String, List<FlSpot>> series = {
              for (final key in typeKeys) key: <FlSpot>[],
            };

            for (var i = 0; i < days; i++) {
              final dayStats = data[i];
              for (final key in typeKeys) {
                final value = (dayStats.typeCounts[key] ?? 0).toDouble();
                series[key]!.add(FlSpot(i.toDouble(), value));
                if (value > maxY) maxY = value;
              }
            }

            maxY = (maxY + 1).clamp(1, 20);

            return SizedBox(
              height: 240,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 180,
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: (days - 1).toDouble(),
                        minY: 0,
                        maxY: maxY,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.grey.withOpacity(0.15),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            tooltipBorderRadius: BorderRadius.circular(12),
                            tooltipPadding: const EdgeInsets.all(8),
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final dayIndex = spot.x.toInt();
                                final dayStats = data[dayIndex];
                                final dayLabel =
                                    dateFormat.format(dayStats.day);

                                final typeKey = typeKeys[spot.barIndex];
                                final label = _interactionTypeLabel(typeKey);
                                final value =
                                    (dayStats.typeCounts[typeKey] ?? 0);

                                return LineTooltipItem(
                                  '$dayLabel\n$label: $value',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              getTitlesWidget: (value, meta) {
                                if (value % 1 != 0) {
                                  return const SizedBox.shrink();
                                }
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= days) {
                                  return const SizedBox.shrink();
                                }
                                final date = data[index].day;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    dateFormat.format(date),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        lineBarsData: typeKeys.map((key) {
                          final spots = series[key]!;
                          return LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            barWidth: 3,
                            color: typeColors[key],
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: typeColors[key]!.withOpacity(0.15),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: typeKeys.map((key) {
                      final color = typeColors[key]!;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _interactionTypeLabel(key),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _interactionTypeLabel(String key) {
    switch (key) {
      case 'good_word':
        return 'מילה טובה';
      case 'short_talk':
        return 'דיבור קצר';
      case 'meeting':
        return 'פגישה / נפגשתי';
      default:
        return 'אחר';
    }
  }

  List<Teacher> _teachersNeedingAttention(List<Teacher> teachers) {
    final now = DateTime.now();
    final list = List<Teacher>.from(teachers);
    list.sort((a, b) {
      final scoreA = _needAttentionScore(a, now);
      final scoreB = _needAttentionScore(b, now);
      return scoreB.compareTo(scoreA);
    });
    return list;
  }

  int _needAttentionScore(Teacher t, DateTime now) {
    int score = 0;
    final mood = _mapLegacyStatusToMood(t.moodStatus ?? t.status);
    if (mood == 'burned_out') {
      score += 140;
    } else if (mood == 'disconnected') {
      score += 120;
    } else if (mood == 'tense') {
      score += 70;
    }

    final last = t.lastInteractionDate;
    if (last == null) {
      score += 40;
    } else {
      final days = now.difference(last).inDays;
      if (days > 30) {
        score += 30;
      } else if (days > 14) {
        score += 20;
      } else if (days > 7) {
        score += 10;
      }
    }
    return score;
  }

  Widget _buildNeedAttentionCard(
    BuildContext context,
    List<Teacher> teachers,
  ) {
    final displayed = teachers.take(4).toList();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...displayed.map(
              (t) => ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                leading: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF11a0db),
                ),
                title: Text(
                  t.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: _buildNeedAttentionSubtitle(t),
                trailing: StatusIndicator(
                  status:
                      _mapLegacyStatusToMood(t.moodStatus ?? t.status) ?? t.status,
                  size: 14,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TeacherDetailsScreen(teacherId: t.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeedAttentionSubtitle(Teacher t) {
    final last = t.lastInteractionDate;
    String daysText;
    if (last == null) {
      daysText = 'עדיין לא נוצר יחס';
    } else {
      final days = DateTime.now().difference(last).inDays;
      if (days == 0) {
        daysText = 'היום היתה אינטראקציה אחרונה';
      } else if (days == 1) {
        daysText = 'אתמול היתה אינטראקציה אחרונה';
      } else {
        daysText = '$days ימים מהיחס האחרון';
      }
    }

    final moodKey = _mapLegacyStatusToMood(t.moodStatus ?? t.status);
    final moodText = _moodStatusLabel(moodKey ?? 'unknown');

    return Text(
      '$moodText · $daysText',
      style: const TextStyle(fontSize: 12),
    );
  }

  void _showTeachersByMoodStatus(
    BuildContext context,
    List<Teacher> teachers,
    String statusKey,
    String label,
  ) {
    final filtered = teachers.where((t) {
      final moodKey = _mapLegacyStatusToMood(t.moodStatus ?? t.status);
      return moodKey == statusKey;
    }).toList();

    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('אין מורים בסטטוס $label כרגע')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusIndicator(status: statusKey, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'מורים בסטטוס $label',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemBuilder: (_, index) {
                      final t = filtered[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.person_outline,
                          color: Color(0xFF11a0db),
                        ),
                        title: Text(t.name),
                        subtitle: _buildNeedAttentionSubtitle(t),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TeacherDetailsScreen(teacherId: t.id),
                            ),
                          );
                        },
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemCount: filtered.length,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _moodStatusColor(String status) {
    switch (status) {
      case 'bloom':
        return const Color(0xFF40AE49);
      case 'flow':
        return const Color(0xFFB2D234);
      case 'tense':
        return const Color(0xFFFAA41A);
      case 'disconnected':
        return const Color(0xFFED1C24);
      case 'burned_out':
        return const Color(0xFFAC2B31);
      default:
        return Colors.grey;
    }
  }

  String _moodStatusLabel(String status) {
    switch (status) {
      case 'bloom':
        return 'פורח/ת';
      case 'flow':
        return 'זורם/ת';
      case 'tense':
        return 'מתוח/ה';
      case 'disconnected':
        return 'מנותק/ת';
      case 'burned_out':
        return 'שחוק/ה';
      default:
        return 'לא ידוע';
    }
  }

  DashboardStats _calculateStats(List<Teacher> teachers) {
    if (teachers.isEmpty) {
      return DashboardStats.empty();
    }

    // סטטוסים
    final statusCount = <String, int>{'green': 0, 'yellow': 0, 'red': 0};
    final moodStatusCount = <String, int>{
      'bloom': 0,
      'flow': 0,
      'tense': 0,
      'disconnected': 0,
      'burned_out': 0,
    };
    for (var teacher in teachers) {
      statusCount[teacher.status] = (statusCount[teacher.status] ?? 0) + 1;

      final moodKey =
          _mapLegacyStatusToMood(teacher.moodStatus ?? teacher.status);
      if (moodKey != null && moodStatusCount.containsKey(moodKey)) {
        moodStatusCount[moodKey] = (moodStatusCount[moodKey] ?? 0) + 1;
      }
    }

    // ממוצעים
    final avgTotalSeniority = teachers
        .map((t) => t.totalSeniorityYears.toDouble())
        .reduce((a, b) => a + b) /
        teachers.length;
    final avgSchoolSeniority = teachers
        .map((t) => t.seniorityYears.toDouble())
        .reduce((a, b) => a + b) /
        teachers.length;
    final avgSatisfaction = teachers
        .map((t) => t.satisfactionRating.toDouble())
        .reduce((a, b) => a + b) /
        teachers.length;
    final avgBelonging = teachers
        .map((t) => t.belongingRating.toDouble())
        .reduce((a, b) => a + b) /
        teachers.length;
    final avgWorkloadRating = teachers
        .map((t) => t.workloadRating.toDouble())
        .reduce((a, b) => a + b) /
        teachers.length;
    final avgWorkload = teachers
        .map((t) => t.workloadPercent.toDouble())
        .reduce((a, b) => a + b) /
        teachers.length;

    // התפלגות ותק כולל
    final totalSeniorityDistribution = <String, int>{};
    for (var teacher in teachers) {
      final range = _getSeniorityRange(teacher.totalSeniorityYears);
      totalSeniorityDistribution[range] =
          (totalSeniorityDistribution[range] ?? 0) + 1;
    }

    // התפלגות ותק בבית הספר
    final schoolSeniorityDistribution = <String, int>{};
    for (var teacher in teachers) {
      final range = _getSeniorityRange(teacher.seniorityYears);
      schoolSeniorityDistribution[range] =
          (schoolSeniorityDistribution[range] ?? 0) + 1;
    }

    return DashboardStats(
      statusCount: statusCount,
      moodStatusCount: moodStatusCount,
      avgTotalSeniority: avgTotalSeniority,
      avgSchoolSeniority: avgSchoolSeniority,
      avgSatisfaction: avgSatisfaction,
      avgBelonging: avgBelonging,
      avgWorkloadRating: avgWorkloadRating,
      avgWorkload: avgWorkload,
      totalSeniorityDistribution: totalSeniorityDistribution,
      schoolSeniorityDistribution: schoolSeniorityDistribution,
    );
  }

  String _getSeniorityRange(int years) {
    if (years < 1) return '0 שנים';
    if (years < 3) return '1-2 שנים';
    if (years < 5) return '3-4 שנים';
    if (years < 10) return '5-9 שנים';
    if (years < 15) return '10-14 שנים';
    if (years < 20) return '15-19 שנים';
    return '20+ שנים';
  }
}

class DashboardStats {
  final Map<String, int> statusCount;
  final Map<String, int> moodStatusCount;
  final double avgTotalSeniority;
  final double avgSchoolSeniority;
  final double avgSatisfaction;
  final double avgBelonging;
  final double avgWorkloadRating;
  final double avgWorkload;
  final Map<String, int> totalSeniorityDistribution;
  final Map<String, int> schoolSeniorityDistribution;

  DashboardStats({
    required this.statusCount,
    required this.moodStatusCount,
    required this.avgTotalSeniority,
    required this.avgSchoolSeniority,
    required this.avgSatisfaction,
    required this.avgBelonging,
    required this.avgWorkloadRating,
    required this.avgWorkload,
    required this.totalSeniorityDistribution,
    required this.schoolSeniorityDistribution,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      statusCount: {},
      moodStatusCount: {},
      avgTotalSeniority: 0,
      avgSchoolSeniority: 0,
      avgSatisfaction: 0,
      avgBelonging: 0,
      avgWorkloadRating: 0,
      avgWorkload: 0,
      totalSeniorityDistribution: {},
      schoolSeniorityDistribution: {},
    );
  }
}

String? _mapLegacyStatusToMood(String? raw) {
  if (raw == null) return null;
  final lower = raw.toLowerCase();
  switch (lower) {
    // ערכי סטטוס רגשי (אנגלית/עברית)
    case 'bloom':
    case 'פורח':
      return 'bloom';
    case 'flow':
    case 'זורם':
      return 'flow';
    case 'tense':
    case 'מתוח':
      return 'tense';
    case 'disconnected':
    case 'מנותק':
      return 'disconnected';
    case 'burned_out':
    case 'שחוק':
      return 'burned_out';

    // מיפוי מרמזור ישן
    case 'green':
      return 'bloom';
    case 'yellow':
      return 'flow';
    case 'red':
      return 'disconnected';
    default:
      return null;
  }
}
