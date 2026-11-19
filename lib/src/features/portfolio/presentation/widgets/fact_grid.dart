import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';

typedef Fact = ({String label, InlineSpan value});

class FactGrid extends StatelessWidget {
  const FactGrid({super.key, required this.facts});

  final List<Fact> facts;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final rule = BorderSide(color: c.borderSubtle);
    Widget cell(Fact fact, {required bool first}) => Semantics(
      container: true,
      label: '${fact.label}, ${fact.value.toPlainText()}',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsetsDirectional.only(
          start: first ? 0 : QuoinSpace.card,
          end: QuoinSpace.xs,
          top: QuoinSpace.m,
          bottom: QuoinSpace.m,
        ),
        decoration: first
            ? null
            : BoxDecoration(border: BorderDirectional(start: rule)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: QuoinSpace.xxs,
          children: [
            Text(fact.label, style: type.small.copyWith(color: c.muted)),
            Text.rich(fact.value, style: type.row.copyWith(color: c.text)),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < facts.length; i += 2)
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: i == 0 ? BorderSide.none : rule),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: cell(facts[i], first: true)),
                  Expanded(
                    child: i + 1 < facts.length
                        ? cell(facts[i + 1], first: false)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
