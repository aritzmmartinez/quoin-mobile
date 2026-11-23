import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';

class GroupHeader extends StatelessWidget {
  const GroupHeader({super.key, required this.label, this.total, this.action});

  final String label;
  final String? total;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final style = QuoinType.of(context).secondary
        .copyWith(color: c.muted, fontWeight: FontWeight.w500);
    final total = this.total;
    final heading = Semantics(
      header: true,
      label: total == null ? label : '$label, $total',
      excludeSemantics: true,
      child: Row(
        spacing: QuoinSpace.s,
        children: [
          Expanded(child: Text(label, style: style)),
          if (total != null) Text(total, style: style.mono),
        ],
      ),
    );
    final action = this.action;
    return Padding(
      padding: const EdgeInsets.only(
        top: QuoinSpace.gutter,
        bottom: QuoinSpace.xs,
      ),
      child: switch (action) {
        null => heading,
        _ when QuoinType.largeText(context) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [heading, action],
        ),
        _ => Row(
          spacing: QuoinSpace.s,
          children: [
            Expanded(child: heading),
            action,
          ],
        ),
      },
    );
  }
}
