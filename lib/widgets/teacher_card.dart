import 'package:flutter/material.dart';
import '../models/teacher.dart';
import 'status_indicator.dart';
import 'hebrew_gregorian_date.dart';

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
    final now = DateTime.now();
    String lastInteractionText;
    if (teacher.lastInteractionDate == null) {
      lastInteractionText = 'עדיין לא נוצר יחס';
    } else {
      final diffDays = now.difference(teacher.lastInteractionDate!).inDays;
      if (diffDays == 0) {
        lastInteractionText = 'היום היתה אינטראקציה אחרונה';
      } else if (diffDays == 1) {
        lastInteractionText = 'אתמול היתה אינטראקציה אחרונה';
      } else {
        lastInteractionText = '$diffDays ימים מהיחס האחרון';
      }
    }

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
                  StatusIndicator(
                    status: teacher.moodStatus ?? teacher.status,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (teacher.roles.isNotEmpty)
                    _buildInfoChip(
                      teacher.roles.join(', '),
                      Icons.badge_outlined,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _buildInfoChip(
                lastInteractionText,
                Icons.access_time,
              ),
              if (_parseNextActionDate(teacher.nextActionDate) != null) ...[
                const SizedBox(height: 8),
                _buildDateChip(
                  _parseNextActionDate(teacher.nextActionDate!)!,
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

  Widget _buildDateChip(DateTime date, IconData icon, {Color? color}) {
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
          HebrewGregorianDateText(
            date: date,
            hebrewStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            gregorianStyle: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _parseNextActionDate(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // נסיון ראשון: ISO-8601
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return iso;

    // פורמט ישן: יום/חודש/שנה
    final parts = trimmed.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }
}
