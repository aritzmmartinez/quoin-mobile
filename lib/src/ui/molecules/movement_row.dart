import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';

class MovementRow extends StatelessWidget {
  const MovementRow({
    super.key,
    required this.title,
    required this.detail,
    required this.amount,
    this.leading,
    this.quiet = false,
    this.onTap,
  });

  final String title;
  final String detail;
  final String amount;
  final Widget? leading;
  final bool quiet;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final leading = this.leading;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: QuoinSpace.row),
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            spacing: QuoinSpace.m,
            children: [
              ?leading,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: QuoinSpace.xxs,
                  children: [
                    Text(title, style: type.row),
                    Text(
                      detail,
                      style: type.secondary.tabular.copyWith(color: c.muted),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.5,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(
                    amount,
                    style: type.row.mono.copyWith(
                      color: quiet ? c.muted : c.text,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Semantics(
      container: true,
      button: onTap != null,
      onTap: onTap,
      excludeSemantics: true,
      label: '$title, $detail, $amount',
      child: onTap == null ? row : InkWell(onTap: onTap, child: row),
    );
  }
}
