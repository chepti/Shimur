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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  StatusIndicator(
                    status: teacher.moodStatus ?? teacher.status,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (teacher.roles.isNotEmpty)
                          Row(
                            children: _buildRoleIcons(teacher.roles),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RichText(
                    text: TextSpan(
                      text: daysNumberText,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      children: [
                        const TextSpan(text: ' '),
                        TextSpan(
                          text: daysLabelText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (actionsCount > 0)
                    _buildInfoChip(
                      '$actionsCount פעולות',
                      Icons.check_circle,
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

    // תפקידים כלליים
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

    // מקצועות לימוד – התאמת אייקון לפי תחום
    if (r.contains('ספורט') ||
        r.contains('חנ\"ג') ||
        r.contains('חנג') ||
        r.contains('חינוך גופ')) {
      return Icons.sports_soccer;
    }
    if (r.contains('תנ\"ך') || r.contains('תנך') || r.contains('מקרא')) {
      return Icons.menu_book;
    }
    if (r.contains('היסט') || r.contains('אזרחות')) {
      return Icons.account_balance;
    }
    if (r.contains('מתמט') || r.contains('חשבון') || r.contains('אלגבר')) {
      return Icons.calculate;
    }
    if (r.contains('אנגלית') ||
        r.contains('שפה') ||
        r.contains('עברית') ||
        r.contains('לשון')) {
      return Icons.language;
    }
    if (r.contains('מדע') ||
        r.contains('פיזיקה') ||
        r.contains('כימיה') ||
        r.contains('ביולוג')) {
      return Icons.science;
    }
    if (r.contains('מוזיקה') || r.contains('מוסיקה')) {
      return Icons.music_note;
    }
    if (r.contains('אמנות') || r.contains('אומנות') || r.contains('אמנות')) {
      return Icons.brush;
    }
    if (r.contains('תיאטרון') || r.contains('דרמה')) {
      return Icons.theater_comedy;
    }
    if (r.contains('חינוך מיוחד') ||
        r.contains('שילוב') ||
        r.contains('משלבת') ||
        r.contains('משלב')) {
      return Icons.diversity_3;
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
