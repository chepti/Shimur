import 'package:flutter/material.dart';

class StatusIndicator extends StatelessWidget {
  /// יכול לקבל גם ערכי רמזור ישנים (green/yellow/red)
  /// וגם סטטוס רגשי חדש (bloom/flow/tense/disconnected/burned_out)
  final String status;
  final double size;

  const StatusIndicator({
    super.key,
    required this.status,
    this.size = 16.0,
  });

  Color get _color {
    switch (status) {
      // סטטוס רגשי – 5 רמות
      case 'bloom':
      case 'פורח':
        return const Color(0xFF40AE49); // ירוק חי
      case 'flow':
      case 'זורם':
        return const Color(0xFFB2D234); // ירקרק-צהוב
      case 'tense':
      case 'מתוח':
        return const Color(0xFFFAA41A); // כתום
      case 'disconnected':
      case 'מנותק':
        return const Color(0xFFED1C24); // אדום
      case 'burned_out':
      case 'שחוק':
        return const Color(0xFFAC2B31); // בורדו

      // תמיכה אחורה ברמזור הישן
      case 'green':
        return const Color(0xFF4CAF50);
      case 'yellow':
        return const Color(0xFFFFC107);
      case 'red':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _color,
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

