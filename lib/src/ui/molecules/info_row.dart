import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    return Semantics(
      container: true,
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: kMinInteractiveDimension,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: QuoinSpace.s),
            child: Row(
              spacing: QuoinSpace.row,
              children: [
                QuoinIcon(
                  QuoinIcons.info,
                  size: QuoinIconSize.row,
                  color: c.text,
                ),
                Expanded(child: Text(label, style: type.row)),
                QuoinIcon(
                  QuoinIcons.chevronRight,
                  size: QuoinIconSize.small,
                  color: c.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
