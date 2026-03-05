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
    final stripWidth = 80.0;
    final canvasSize = Size(stripWidth, size.height);

    return Stack(
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
                blastDirection: 0,
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
                blastDirection: math.pi,
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
