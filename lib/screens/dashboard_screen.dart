import 'package:flutter/material.dart';
import '../models/teacher.dart';
import '../services/firestore_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
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

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // כרטיסי סיכום
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'סה"כ מורים',
                          '${teachers.length}',
                          Icons.people,
                          const Color(0xFF11a0db),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'ממוצע ותק כולל',
                          '${stats.avgTotalSeniority.toStringAsFixed(1)} שנים',
                          Icons.work,
                          const Color(0xFF40ae49),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'ממוצע ותק בביה"ס',
                          '${stats.avgSchoolSeniority.toStringAsFixed(1)} שנים',
                          Icons.school,
                          const Color(0xFFFFC107),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'ממוצע שביעות רצון',
                          '${stats.avgSatisfaction.toStringAsFixed(1)}/5',
                          Icons.sentiment_satisfied_alt,
                          const Color(0xFF9C27B0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // התפלגות סטטוסים
                  _buildSectionTitle('התפלגות סטטוסים'),
                  const SizedBox(height: 12),
                  _buildStatusDistribution(stats.statusCount),
                  const SizedBox(height: 24),
                  // התפלגות ותק כולל
                  _buildSectionTitle('התפלגות ותק כולל'),
                  const SizedBox(height: 12),
                  _buildSeniorityChart(
                    'ותק כולל',
                    stats.totalSeniorityDistribution,
                    Icons.work,
                  ),
                  const SizedBox(height: 24),
                  // התפלגות ותק בבית הספר
                  _buildSectionTitle('התפלגות ותק בבית הספר'),
                  const SizedBox(height: 12),
                  _buildSeniorityChart(
                    'ותק בבית הספר',
                    stats.schoolSeniorityDistribution,
                    Icons.school,
                  ),
                  const SizedBox(height: 24),
                  // ממוצע דירוגים
                  _buildSectionTitle('ממוצע דירוגים'),
                  const SizedBox(height: 12),
                  _buildRatingsCard(stats),
                  const SizedBox(height: 24),
                  // היקף משרה ממוצע
                  _buildSectionTitle('היקף משרה'),
                  const SizedBox(height: 12),
                  _buildWorkloadCard(stats.avgWorkload),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
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

  Widget _buildStatusDistribution(Map<String, int> statusCount) {
    final total = statusCount.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatusBar(
              'יציב',
              statusCount['green'] ?? 0,
              total,
              const Color(0xFF4CAF50),
            ),
            const SizedBox(height: 12),
            _buildStatusBar(
              'מעקב',
              statusCount['yellow'] ?? 0,
              total,
              const Color(0xFFFFC107),
            ),
            const SizedBox(height: 12),
            _buildStatusBar(
              'סיכון',
              statusCount['red'] ?? 0,
              total,
              const Color(0xFFF44336),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('$count (${percentage.toStringAsFixed(1)}%)'),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total > 0 ? count / total : 0,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildSeniorityChart(String title, Map<String, int> distribution, IconData icon) {
    final total = distribution.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF11a0db)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...distribution.entries.map((entry) {
              final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key),
                        Text('${entry.value} (${percentage.toStringAsFixed(1)}%)'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: total > 0 ? entry.value / total : 0,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF11a0db)),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingsCard(DashboardStats stats) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildRatingRow('שביעות רצון', stats.avgSatisfaction, Icons.sentiment_satisfied_alt),
            const SizedBox(height: 16),
            _buildRatingRow('תחושת שייכות', stats.avgBelonging, Icons.group),
            const SizedBox(height: 16),
            _buildRatingRow('עומס', stats.avgWorkloadRating, Icons.speed),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(String label, double value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF11a0db)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        Text(
          value.toStringAsFixed(1),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 4),
        const Text('/5', style: TextStyle(color: Colors.grey)),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: LinearProgressIndicator(
            value: value / 5,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF11a0db)),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkloadCard(double avgWorkload) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Color(0xFF11a0db)),
                const SizedBox(width: 8),
                const Text(
                  'ממוצע היקף משרה',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${avgWorkload.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF11a0db),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: LinearProgressIndicator(
                    value: avgWorkload / 116,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF11a0db)),
                    minHeight: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  DashboardStats _calculateStats(List<Teacher> teachers) {
    if (teachers.isEmpty) {
      return DashboardStats.empty();
    }

    // סטטוסים
    final statusCount = <String, int>{'green': 0, 'yellow': 0, 'red': 0};
    for (var teacher in teachers) {
      statusCount[teacher.status] = (statusCount[teacher.status] ?? 0) + 1;
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
