import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';

class QuoinSectionLabel extends StatelessWidget {
  const QuoinSectionLabel(
    this.text, {
    super.key,
    this.action,
    this.padding = const EdgeInsets.only(
      top: QuoinSpace.section,
      bottom: QuoinSpace.row,
    ),
  });

  final String text;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                text.toUpperCase(),
                style: QuoinType.of(context).section
                    .copyWith(color: QuoinColors.of(context).muted),
              ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
