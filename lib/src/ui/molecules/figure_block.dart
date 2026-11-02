import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';

class FigureBlock extends StatelessWidget {
  const FigureBlock({
    super.key,
    required this.label,
    required this.value,
    this.sign = 0,
    this.muted = false,
    this.caption,
  });

  final String label;
  final String value;
  final int sign;
  final bool muted;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final color = muted
        ? c.muted
        : sign > 0
        ? c.positive
        : sign < 0
        ? c.negative
        : c.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(label, style: type.small.copyWith(color: c.muted)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            maxLines: 1,
            softWrap: false,
            style: (muted ? type.row : type.row.mono).copyWith(color: color),
          ),
        ),
        if (caption case final caption?)
          Text(caption, style: type.small.copyWith(color: c.muted)),
      ],
    );
  }
}
