import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/atoms/quoin_avatar.dart';

class PositionRow extends StatelessWidget {
  const PositionRow({
    super.key,
    required this.name,
    required this.detail,
    required this.value,
    this.valueMuted = false,
    required this.change,
    this.onTap,
  });

  final String name;
  final String detail;
  final String value;
  final bool valueMuted;
  final Widget change;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: QuoinSpace.card,
        vertical: QuoinSpace.m,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          spacing: QuoinSpace.m,
          children: [
            QuoinAvatar(name),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: QuoinSpace.xs,
                children: [
                  Text(name, style: type.row),
                  Text(
                    detail,
                    style: type.secondary.mono.copyWith(color: c.muted),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * 0.55,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: QuoinSpace.xs,
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
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}
