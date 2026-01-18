import 'package:flutter/material.dart';

class StatusIndicator extends StatelessWidget {
  final String status;
  final double size;

  const StatusIndicator({
    Key? key,
    required this.status,
    this.size = 16.0,
  }) : super(key: key);

  Color get _color {
    switch (status) {
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

  String get _emoji {
    switch (status) {
      case 'green':
        return '🟢';
      case 'yellow':
        return '🟡';
      case 'red':
        return '🔴';
      default:
        return '⚪';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_emoji, style: TextStyle(fontSize: size)),
        const SizedBox(width: 4),
      ],
    );
  }
}

