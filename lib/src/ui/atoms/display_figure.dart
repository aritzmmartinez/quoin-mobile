import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_type.dart';

class DisplayFigure extends StatelessWidget {
  const DisplayFigure(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        style: QuoinType.of(context).display.copyWith(color: color),
      ),
    );
  }
}
