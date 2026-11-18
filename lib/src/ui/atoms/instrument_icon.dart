import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';

class InstrumentIcon extends StatelessWidget {
  const InstrumentIcon.tile(QuoinIconData this.glyph, {super.key})
    : mark = null,
      _round = false;

  const InstrumentIcon.circle(String this.mark, {super.key})
    : glyph = null,
      _round = true;

  const InstrumentIcon.coin(QuoinIconData this.glyph, {super.key})
    : mark = null,
      _round = true;

  static const double size = 40;

  final QuoinIconData? glyph;
  final String? mark;
  final bool _round;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final mark = this.mark;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(QuoinSpace.xs),
        decoration: ShapeDecoration(
          color: c.iconTile,
          shape: _round
              ? const CircleBorder()
              : RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(QuoinRadius.tile),
                ),
        ),
        child: mark == null
            ? QuoinIcon(glyph!, size: QuoinIconSize.tile, color: c.accent)
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  mark,
                  maxLines: 1,
                  style: type.rowStrong.copyWith(
                    color: c.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ),
    );
  }
}
