import 'package:flutter/material.dart';
import '../models/teacher.dart';
import 'status_indicator.dart';

class TeacherCard extends StatelessWidget {
  final Teacher teacher;
  final VoidCallback onTap;
  final int actionsCount;

  const TeacherCard({
    Key? key,
    required this.teacher,
    required this.onTap,
    this.actionsCount = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      teacher.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  StatusIndicator(status: teacher.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    'וותק בבית הספר: ${teacher.seniorityYears} שנים',
                    Icons.calendar_today,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    'וותק כללי: ${teacher.totalSeniorityYears} שנים',
                    Icons.work,
                  ),
                ],
              ),
              if (teacher.nextActionDate != null) ...[
                const SizedBox(height: 8),
                _buildInfoChip(
                  'פעולה הבאה: ${teacher.nextActionDate}',
                  Icons.event,
                  color: const Color(0xFF11a0db),
                ),
              ],
              if (actionsCount > 0) ...[
                const SizedBox(height: 8),
                _buildInfoChip(
                  '$actionsCount פעולות',
                  Icons.check_circle,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, {Color? color}) {
    // צבעים עדינים יותר - פחות צבעוני
    final chipColor = color ?? Colors.grey[400]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: chipColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

