import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';

class QuoinBarFade extends StatelessWidget {
  const QuoinBarFade({super.key, required this.height});

  static const double reach = QuoinSpace.hero;

  final double height;

  @override
  Widget build(BuildContext context) {
    final bg = QuoinColors.of(context).bg;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bg.withValues(alpha: 0), bg],
                stops: const [0, 0.55],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
