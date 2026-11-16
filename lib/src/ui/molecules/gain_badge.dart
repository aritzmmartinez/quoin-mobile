import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';

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
        color: c.fillOf(color),
        shape: StadiumBorder(side: BorderSide(color: c.edgeOf(color))),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: QuoinSpace.s,
          vertical: 3,
        ),
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
