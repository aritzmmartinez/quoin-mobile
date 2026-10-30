import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';

class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon});

  final QuoinIconData icon;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: c.accent.withValues(alpha: 0.15),
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(QuoinRadius.tile),
        ),
      ),
      child: QuoinIcon(icon, size: 20, color: c.accent),
    );
  }
}
