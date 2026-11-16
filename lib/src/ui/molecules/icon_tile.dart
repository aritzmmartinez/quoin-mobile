import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';

class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, this.signal});

  static const double size = 40;

  final QuoinIconData icon;
  final Color? signal;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: switch (signal) {
          final signal? => c.fillOf(signal),
          null => c.accentTint,
        },
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(QuoinRadius.tile),
        ),
      ),
      child: QuoinIcon(
        icon,
        size: QuoinIconSize.tile,
        color: signal ?? c.accent,
      ),
    );
  }
}
