import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';

class QuoinAvatar extends StatelessWidget {
  const QuoinAvatar(this.name, {super.key});

  static const double size = 36;

  final String name;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: c.accentTint,
          shape: const CircleBorder(),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            name.isEmpty ? '?' : name.characters.first.toUpperCase(),
            style: QuoinType.of(context).rowStrong.copyWith(color: c.accent),
          ),
        ),
      ),
    );
  }
}
