import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/atoms/instrument_icon.dart';

class PositionRow extends StatelessWidget {
  const PositionRow({
    super.key,
    required this.leading,
    required this.name,
    required this.detail,
    required this.value,
    this.valueIsFigure = true,
    this.change,
    this.changePrefix,
    this.changeColor,
    this.onTap,
  });

  static const _nameLines = 2;

  final Widget leading;
  final String name;
  final String detail;
  final String value;
  final bool valueIsFigure;
  final String? change;
  final String? changePrefix;
  final Color? changeColor;
  final VoidCallback? onTap;

  ({TextStyle name, TextStyle detail, Text value, TextSpan? change}) _parts(
    BuildContext context,
  ) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final change = this.change;
    final prefix = changePrefix;
    return (
      name: type.row,
      detail: type.secondary.tabular.copyWith(color: c.muted),
      value: Text(
        value,
        style: valueIsFigure
            ? type.row.mono.copyWith(color: c.text)
            : type.secondary.copyWith(color: c.body),
      ),
      change: change == null
          ? null
          : TextSpan(
              children: [
                if (prefix != null) TextSpan(text: '$prefix '),
                TextSpan(text: change, style: type.secondary.mono),
              ],
              style: type.secondary.copyWith(color: changeColor ?? c.muted),
            ),
    );
  }

  bool stacksIn(BuildContext context, double width) {
    if (QuoinType.largeText(context)) return true;
    final parts = _parts(context);
    final figures = math.max(
      _width(context, TextSpan(text: value, style: parts.value.style)),
      parts.change == null ? 0.0 : _width(context, parts.change!),
    );
    final beside = width - InstrumentIcon.size - 2 * QuoinSpace.m - figures;
    return !(_fits(context, name, parts.name, beside, _nameLines) &&
        _fits(context, detail, parts.detail, beside, 1));
  }

  @override
  Widget build(BuildContext context) {
    final change = this.change;
    final prefix = changePrefix;
    final parts = _parts(context);
    final nameStyle = parts.name;
    final detailStyle = parts.detail;
    final valueText = parts.value;
    final changeSpan = parts.change;

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: QuoinSpace.row),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sideBySide =
              !(PositionList.stackedOf(context) ??
                  stacksIn(context, constraints.maxWidth));

          final names = [
            Text(name, style: nameStyle),
            Text(detail, style: detailStyle),
          ];
          if (sideBySide) {
            return Row(
              spacing: QuoinSpace.m,
              children: [
                leading,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: QuoinSpace.xxs,
                    children: names,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: QuoinSpace.xxs,
                  children: [valueText, ?_rich(changeSpan)],
                ),
              ],
            );
          }
          return Row(
            spacing: QuoinSpace.m,
            children: [
              leading,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: QuoinSpace.xxs,
                  children: [
                    ...names,
                    const SizedBox(height: QuoinSpace.xxs),
                    valueText,
                    ?_rich(changeSpan),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    return Semantics(
      container: true,
      button: onTap != null,
      onTap: onTap,
      label: [
        name,
        detail,
        value,
        if (change != null) prefix == null ? change : '$prefix $change',
      ].join(', '),
      excludeSemantics: true,
      child: onTap == null ? row : InkWell(onTap: onTap, child: row),
    );
  }

  static Widget? _rich(TextSpan? span) => span == null ? null : Text.rich(span);

  TextPainter _painter(BuildContext context, InlineSpan span) => TextPainter(
    text: TextSpan(style: DefaultTextStyle.of(context).style, children: [span]),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  );

  double _width(BuildContext context, InlineSpan span) {
    final painter = _painter(context, span)..layout();
    final width = painter.width.ceilToDouble();
    painter.dispose();
    return width;
  }

  bool _fits(
    BuildContext context,
    String text,
    TextStyle style,
    double width,
    int lines,
  ) {
    if (width <= 0) return false;
    for (final word in text.split(RegExp(r'\s+'))) {
      if (_width(context, TextSpan(text: word, style: style)) > width) {
        return false;
      }
    }
    final painter = _painter(context, TextSpan(text: text, style: style))
      ..layout(maxWidth: width);
    final fits = painter.computeLineMetrics().length <= lines;
    painter.dispose();
    return fits;
  }
}

class PositionList extends StatelessWidget {
  const PositionList({super.key, required this.children});

  final List<Widget> children;

  static bool? stackedOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Stacked>()?.stacked;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _Stacked(
        stacked: children.whereType<PositionRow>().any(
          (row) => row.stacksIn(context, constraints.maxWidth),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _Stacked extends InheritedWidget {
  const _Stacked({required this.stacked, required super.child});

  final bool stacked;

  @override
  bool updateShouldNotify(_Stacked old) => old.stacked != stacked;
}
