import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';

class SaleRow extends StatefulWidget {
  const SaleRow({
    super.key,
    required this.name,
    required this.when,
    required this.result,
    required this.sign,
    this.returnPct,
    this.badge,
    this.notes = const [],
    this.details = const [],
    this.more = const [],
  });

  final String name;
  final String when;
  final String result;
  final int sign;
  final String? returnPct;
  final String? badge;
  final List<String> notes;
  final List<(String, String)> details;
  final List<Widget> more;

  @override
  State<SaleRow> createState() => _SaleRowState();
}

class _SaleRowState extends State<SaleRow> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final color = widget.sign > 0
        ? c.positive
        : widget.sign < 0
        ? c.negative
        : c.muted;
    final badge = widget.badge;
    final expandable = widget.details.isNotEmpty || widget.more.isNotEmpty;

    final summary = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: QuoinSpace.card,
        vertical: QuoinSpace.m,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          spacing: QuoinSpace.m,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: QuoinSpace.xs,
                children: [
                  Wrap(
                    spacing: QuoinSpace.s,
                    runSpacing: QuoinSpace.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(widget.name, style: type.row),
                      if (badge != null)
                        DecoratedBox(
                          decoration: ShapeDecoration(
                            color: c.fillOf(c.negative),
                            shape: StadiumBorder(
                              side: BorderSide(color: c.edgeOf(c.negative)),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: QuoinSpace.s,
                              vertical: QuoinSpace.xxs,
                            ),
                            child: Text(
                              badge,
                              style: type.small.copyWith(color: c.negative),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    widget.when,
                    style: type.secondary.mono.copyWith(color: c.muted),
                  ),
                  for (final note in widget.notes)
                    Text(note, style: type.small.copyWith(color: c.body)),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * 0.55,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: QuoinSpace.xs,
                  children: [
                    Text(
                      widget.result,
                      style: type.row.mono.copyWith(color: color),
                    ),
                    if (widget.returnPct case final pct?)
                      Text(pct, style: type.small.mono.copyWith(color: color)),
                  ],
                ),
              ),
            ),
            if (expandable)
              AnimatedRotation(
                turns: _open ? 0.5 : 0,
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                child: QuoinIcon(
                  QuoinIcons.chevronDown,
                  size: QuoinIconSize.small,
                  color: c.faint,
                ),
              ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (expandable)
          Semantics(
            button: true,
            expanded: _open,
            child: InkWell(
              onTap: () => setState(() => _open = !_open),
              child: summary,
            ),
          )
        else
          summary,
        if (_open)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              QuoinSpace.card,
              0,
              QuoinSpace.card,
              14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: QuoinSpace.tight,
              children: [
                for (final (label, value) in widget.details)
                  DetailLine(label: label, value: value),
                ...widget.more,
              ],
            ),
          ),
      ],
    );
  }
}

/// A label and its figure on one line; the label wraps, the figure does not.
class DetailLine extends StatelessWidget {
  const DetailLine({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: QuoinSpace.m,
      children: [
        Expanded(
          child: Text(label, style: type.secondary.copyWith(color: c.muted)),
        ),
        Text(
          value,
          style: type.secondary.mono.copyWith(color: color ?? c.body),
        ),
      ],
    );
  }
}
