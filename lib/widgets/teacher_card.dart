import 'package:flutter/material.dart';
import '../models/teacher.dart';
import 'status_indicator.dart';
import 'hebrew_gregorian_date.dart';

class TeacherCard extends StatelessWidget {
  final Teacher teacher;
  final VoidCallback onTap;
  final int actionsCount;

  const TeacherCard({
    super.key,
    required this.teacher,
    required this.onTap,
    this.actionsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final last = teacher.lastInteractionDate;
    final int? daysSinceLast =
        last == null ? null : now.difference(last).inDays;
    final String daysNumberText =
        daysSinceLast != null ? daysSinceLast.toString() : '—';
    final String daysLabelText = daysSinceLast == null
        ? 'עדיין לא נוצר יחס'
        : (daysSinceLast == 1 ? 'יום מהיחס האחרון' : 'ימים מהיחס האחרון');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teacher.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (teacher.roles.isNotEmpty)
                          Row(
                            children: _buildRoleIcons(teacher.roles),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      StatusIndicator(
                        status: teacher.moodStatus ?? teacher.status,
                        size: 20,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        daysNumberText,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        daysLabelText,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_parseNextActionDate(teacher.nextActionDate) != null) ...[
                const SizedBox(height: 6),
                _buildDateChip(
                  _parseNextActionDate(teacher.nextActionDate!)!,
                  Icons.event,
                  color: const Color(0xFF11a0db),
                ),
              ],
              if (actionsCount > 0) ...[
                const SizedBox(height: 6),
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

  List<Widget> _buildRoleIcons(List<String> roles) {
    final displayed = roles.take(4).toList();
    return displayed
        .map(
          (role) => Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              _iconForRole(role),
              size: 16,
              color: Colors.grey[600],
            ),
          ),
        )
        .toList();
  }

  IconData _iconForRole(String role) {
    final r = role.toLowerCase();
    if (r.contains('מחנ')) {
      return Icons.groups;
    }
    if (r.contains('רכז')) {
      return Icons.hub_outlined;
    }
    if (r.contains('סגן') || r.contains('מנה')) {
      return Icons.school;
    }
    if (r.contains('יועץ') || r.contains('יועצ')) {
      return Icons.psychology_alt_outlined;
    }
    return Icons.person_outline;
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
