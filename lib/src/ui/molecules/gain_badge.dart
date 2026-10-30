import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';

/// A gain or a loss, already formatted: green when [sign] is positive, red
/// when negative, muted at zero. The sign is in the text too, so the colour is
/// never the only signal.
class GainBadge extends StatelessWidget {
  const GainBadge({super.key, required this.text, required this.sign});

  final String text;
  final int sign;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final color = sign > 0
        ? c.positive
        : sign < 0
        ? c.negative
        : c.muted;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.08),
        shape: StadiumBorder(
          side: BorderSide(color: color.withValues(alpha: 0.25)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: QuoinType.of(context).small.mono.copyWith(color: color),
        ),
      ),
    );
  }
}
