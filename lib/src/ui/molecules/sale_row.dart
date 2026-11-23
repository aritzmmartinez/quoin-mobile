import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';

class SaleRow extends StatelessWidget {
  const SaleRow({
    super.key,
    required this.name,
    required this.when,
    required this.result,
    required this.sign,
    this.leading,
    this.tag,
    this.note,
    this.onTap,
  });

  final String name;
  final String when;
  final String result;
  final int sign;
  final Widget? leading;
  final String? tag;
  final ({String label, String value})? note;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final color = sign > 0
        ? c.positive
        : sign < 0
        ? c.negative
        : c.muted;
    final tag = this.tag;
    final note = this.note;
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
                    Text(name, style: type.row),
                    Text.rich(
                      TextSpan(
                        text: when,
                        children: [
                          if (tag != null) ...[
                            const TextSpan(text: ' · '),
                            TextSpan(
                              text: tag,
                              style: TextStyle(color: c.body),
                            ),
                          ],
                        ],
                      ),
                      style: type.secondary.tabular.copyWith(color: c.muted),
                    ),
                  ],
                ),
              ),
              // Row figures shrink to one line rather than wrap.
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.5,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    spacing: QuoinSpace.xxs,
                    children: [
                      Text(result, style: type.row.mono.copyWith(color: color)),
                      if (note != null)
                        Text.rich(
                          TextSpan(
                            text: '${note.label} ',
                            children: [
                              TextSpan(
                                text: note.value,
                                style: type.small.mono,
                              ),
                            ],
                          ),
                          style: type.small.copyWith(color: c.muted),
                        ),
                    ],
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
      label: [
        name,
        when,
        ?tag,
        result,
        if (note != null) '${note.label} ${note.value}',
      ].join(', '),
      child: onTap == null ? row : InkWell(onTap: onTap, child: row),
    );
  }
}
