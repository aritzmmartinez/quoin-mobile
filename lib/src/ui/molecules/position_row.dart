import 'dart:math' as math;

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
    this.valueSuffix,
    this.valueMuted = false,
    required this.change,
    this.onTap,
  });

  final String name;
  final String detail;
  final String value;
  final String? valueSuffix;
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
                maxWidth: _figuresWidth(context, constraints.maxWidth),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: QuoinSpace.xs,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: value, style: type.row.mono),
                          if (valueSuffix case final suffix?)
                            TextSpan(text: ' $suffix'),
                        ],
                      ),
                      style: type.row.copyWith(
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

  double _figuresWidth(BuildContext context, double row) {
    final style = DefaultTextStyle.of(context).style
        .merge(QuoinType.of(context).row);
    var longestWord = 0.0;
    for (final word in name.split(RegExp(r'\s+'))) {
      final painter = TextPainter(
        text: TextSpan(text: word, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      longestWord = math.max(longestWord, painter.width.ceilToDouble());
      painter.dispose();
    }
    final left = row - QuoinAvatar.size - 2 * QuoinSpace.m - longestWord;
    return math.max(0, math.min(row * 0.55, left));
  }
}
