import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';

class DonutSlice {
  const DonutSlice({
    required this.label,
    required this.fraction,
    required this.percent,
  });

  final String label;

  /// Share of the ring, 0 to 1. A chart coordinate: the figure shown is
  /// [percent], formatted from the decimal.
  final double fraction;
  final String percent;
}

/// A ring split by share, largest first, with its legend beside it. The
/// colours are the neutral donut scale: categories never take green or red.
class AllocationDonut extends StatelessWidget {
  const AllocationDonut({super.key, required this.slices});

  static const double size = 112;

  final List<DonutSlice> slices;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    // One tone per slice, spread from dn1 to dn4: never repeated, and never
    // dn5, which is the card's border and vanishes against it.
    final ramp = [c.dn1, c.dn2, c.dn3, c.dn4];
    Color colorOf(int i) {
      if (slices.length < 2) return ramp.first;
      final t = i / (slices.length - 1) * (ramp.length - 1);
      final from = t.floor().clamp(0, ramp.length - 2);
      return Color.lerp(ramp[from], ramp[from + 1], t - from)!;
    }

    return Row(
      spacing: 20,
      children: [
        ExcludeSemantics(
          child: SizedBox.square(
            dimension: size,
            child: CustomPaint(
              painter: _RingPainter(
                fractions: [for (final s in slices) s.fraction],
                colors: [for (var i = 0; i < slices.length; i++) colorOf(i)],
                track: c.surface2,
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              for (final (i, slice) in slices.indexed)
                Row(
                  spacing: 8,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorOf(i),
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: c.border),
                      ),
                      child: const SizedBox.square(dimension: 8),
                    ),
                    Expanded(
                      child: Text(
                        slice.label,
                        style: type.secondary.copyWith(color: c.body),
                      ),
                    ),
                    Text(
                      slice.percent,
                      style: type.secondary.mono.copyWith(color: c.text),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fractions,
    required this.colors,
    required this.track,
  });

  static const double stroke = 14;
  static const double gap = 3;

  final List<double> fractions;
  final List<Color> colors;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: radius,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(rect.center, radius, paint..color = track);

    final gapAngle = fractions.length > 1 ? gap / radius : 0.0;
    var start = -math.pi / 2;
    for (final (i, fraction) in fractions.indexed) {
      final sweep = fraction * 2 * math.pi;
      if (sweep > gapAngle) {
        canvas.drawArc(
          rect,
          start,
          sweep - gapAngle,
          false,
          paint..color = colors[i],
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fractions != fractions || old.colors != colors || old.track != track;
}
