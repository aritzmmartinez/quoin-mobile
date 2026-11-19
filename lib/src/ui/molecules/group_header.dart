import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';

class GroupHeader extends StatelessWidget {
  const GroupHeader({super.key, required this.label, this.total});

  final String label;
  final String? total;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final style = QuoinType.of(context).secondary
        .copyWith(color: c.muted, fontWeight: FontWeight.w500);
    final total = this.total;
    return Semantics(
      header: true,
      label: total == null ? label : '$label, $total',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(
          top: QuoinSpace.gutter,
          bottom: QuoinSpace.xs,
        ),
        child: Row(
          spacing: QuoinSpace.s,
          children: [
            Expanded(child: Text(label, style: style)),
            if (total != null) Text(total, style: style.mono),
          ],
        ),
      ),
    );
  }
}
