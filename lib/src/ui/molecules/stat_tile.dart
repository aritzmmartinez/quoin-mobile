import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.sign = 0,
    required this.onTap,
  });

  final String label;
  final String value;
  final int sign;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    return Semantics(
      container: true,
      button: true,
      onTap: onTap,
      label: '$label, $value',
      excludeSemantics: true,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(QuoinRadius.compact),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(QuoinSpace.card),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: QuoinSpace.xs,
              children: [
                Text(label, style: type.secondary.copyWith(color: c.muted)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: type.rowStrong.mono.copyWith(
                      color: switch (sign) {
                        > 0 => c.positive,
                        < 0 => c.negative,
                        _ => c.text,
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
