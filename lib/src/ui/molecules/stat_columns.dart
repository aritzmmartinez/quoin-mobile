import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';

typedef Stat = ({String label, String value, int sign});

class StatColumns extends StatelessWidget {
  const StatColumns({super.key, required this.stats});

  final List<Stat> stats;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, stat) in stats.indexed)
            Expanded(
              child: Semantics(
                container: true,
                label: '${stat.label}, ${stat.value}',
                excludeSemantics: true,
                child: Container(
                  padding: EdgeInsetsDirectional.only(
                    start: i == 0 ? 0 : QuoinSpace.m,
                    end: QuoinSpace.xs,
                  ),
                  decoration: i == 0
                      ? null
                      : BoxDecoration(
                          border: BorderDirectional(
                            start: BorderSide(color: c.borderSubtle),
                          ),
                        ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: QuoinSpace.xs,
                    children: [
                      Text(
                        stat.label,
                        style: type.secondary.copyWith(color: c.muted),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          stat.value,
                          maxLines: 1,
                          style: type.row.mono.copyWith(
                            color: switch (stat.sign) {
                              > 0 => c.positive,
                              < 0 => c.negative,
                              _ => c.text,
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
