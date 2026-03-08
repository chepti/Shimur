import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

/// קונפטי חמוד מהצדדים – שני מקורות משמאל ומימין
class CelebrationConfetti extends StatelessWidget {
  const CelebrationConfetti({
    super.key,
    required this.controller,
    this.child,
  });

  final ConfettiController controller;
  final Widget? child;

  static const _colors = [
    Color(0xFF40AE49),
    Color(0xFF11a0db),
    Color(0xFFFAA41A),
    Color(0xFFED1C24),
    Color(0xFFB2D234),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final stripWidth = 100.0;
    final canvasSize = Size(stripWidth, size.height);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    // ב-RTL: שמאל וימין מתהפכים – מתאימים את כיוון הפיצוץ
    final leftDir = isRtl ? math.pi : 0.0;
    final rightDir = isRtl ? 0.0 : math.pi;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (child != null) child!,
        IgnorePointer(
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: stripWidth,
              height: size.height,
              child: ConfettiWidget(
                confettiController: controller,
                blastDirection: leftDir,
                blastDirectionality: BlastDirectionality.directional,
                emissionFrequency: 0.05,
                numberOfParticles: 12,
                gravity: 0.15,
                colors: _colors,
                canvas: canvasSize,
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: stripWidth,
              height: size.height,
              child: ConfettiWidget(
                confettiController: controller,
                blastDirection: rightDir,
                blastDirectionality: BlastDirectionality.directional,
                emissionFrequency: 0.05,
                numberOfParticles: 12,
                gravity: 0.15,
                colors: _colors,
                canvas: canvasSize,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
