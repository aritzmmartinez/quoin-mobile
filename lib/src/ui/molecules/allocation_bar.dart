import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';

class AllocationSegment {
  const AllocationSegment({
    required this.label,
    required this.fraction,
    required this.percent,
    this.unclassified = false,
  });

  final String label;
  final double fraction;
  final String percent;
  final bool unclassified;
}

class AllocationBar extends StatelessWidget {
  const AllocationBar({super.key, required this.segments});

  static const double height = 10;
  static const _round = Radius.circular(height / 2);
  static const _square = Radius.circular(QuoinSpace.xxs);

  final List<AllocationSegment> segments;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final ramp = [c.dn1, c.dn2, c.dn3, c.dn4, c.dn5];
    var rank = 0;
    final fills = [
      for (final s in segments)
        s.unclassified ? null : ramp[(rank++).clamp(0, ramp.length - 1)],
    ];
    BoxDecoration paint(int i, BorderRadius radius) => BoxDecoration(
      color: fills[i],
      border: fills[i] == null ? Border.all(color: c.border) : null,
      borderRadius: radius,
    );

    Widget legendItem(int i) => Row(
      spacing: QuoinSpace.s,
      children: [
        DecoratedBox(
          decoration: paint(i, BorderRadius.circular(QuoinSpace.xxs)),
          child: const SizedBox.square(dimension: QuoinSpace.s),
        ),
        Expanded(
          child: Text(
            segments[i].label,
            style: type.secondary.copyWith(color: c.body),
          ),
        ),
        Text(
          segments[i].percent,
          style: type.secondary.mono.copyWith(color: c.text),
        ),
      ],
    );

    return Semantics(
      container: true,
      label: [for (final s in segments) '${s.label} ${s.percent}'].join(', '),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: QuoinSpace.m,
        children: [
          SizedBox(
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: QuoinSpace.xxs,
              children: [
                for (final (i, s) in segments.indexed)
                  Expanded(
                    flex: math.max(1, (s.fraction * 1000).round()),
                    child: DecoratedBox(
                      decoration: paint(
                        i,
                        BorderRadiusDirectional.horizontal(
                          start: i == 0 ? _round : _square,
                          end: i == segments.length - 1 ? _round : _square,
                        ).resolve(Directionality.of(context)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, box) {
              final half = (box.maxWidth - QuoinSpace.card) / 2;
              final columns = segments.every((s) => _fitsLine(context, s, half))
                  ? 2
                  : 1;
              final width = columns == 2 ? half : box.maxWidth;
              return Wrap(
                spacing: QuoinSpace.card,
                runSpacing: QuoinSpace.s,
                children: [
                  for (var i = 0; i < segments.length; i++)
                    SizedBox(width: width, child: legendItem(i)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  bool _fitsLine(BuildContext context, AllocationSegment s, double width) {
    final type = QuoinType.of(context);
    final painter = TextPainter(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          TextSpan(text: s.label, style: type.secondary),
          TextSpan(text: s.percent, style: type.secondary.mono),
        ],
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final room = width - QuoinSpace.s * 3;
    final fits = painter.width <= room;
    painter.dispose();
    return fits;
  }
}
