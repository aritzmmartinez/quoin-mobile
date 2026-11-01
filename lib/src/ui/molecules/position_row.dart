import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';

/// One position: an initial in a circle, its name and a detail line, and its
/// value with a [change] (a `GainBadge`, or a note when there is no figure).
class PositionRow extends StatelessWidget {
  const PositionRow({
    super.key,
    required this.name,
    required this.detail,
    required this.value,
    this.valueMuted = false,
    required this.change,
  });

  final String name;
  final String detail;
  final String value;

  /// For a figure that is not a value, such as the cost of an unpriced one.
  final bool valueMuted;
  final Widget change;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          spacing: 12,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: c.accent.withValues(alpha: 0.12),
              // A fixed circle: the initial shrinks rather than overflow it.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                  style: type.row.copyWith(
                    color: c.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(name, style: type.row),
                  Text(
                    detail,
                    style: type.secondary.mono.copyWith(color: c.muted),
                  ),
                ],
              ),
            ),
            // Figures don't wrap: past 55 % of the row (a large system font)
            // they shrink to one line instead.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * 0.55,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: 4,
                  children: [
                    Text(
                      value,
                      style: type.row.mono.copyWith(
                        color: valueMuted ? c.muted : c.text,
                      ),
                    ),
                    change,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
