import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';

class QuoinSegmented<T> extends StatelessWidget {
  const QuoinSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.position,
  }) : assert(segments.length >= 2);

  final List<(T, String)> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  final ValueListenable<double>? position;

  static const _minHeight = 40.0;
  static const _inset = 3.0;

  @override
  Widget build(BuildContext context) => switch (position) {
    final position? => ValueListenableBuilder(
      valueListenable: position,
      builder: (context, t, _) => _build(context, t),
    ),
    null => _build(context, null),
  };

  Widget _build(BuildContext context, double? t) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final index = segments.indexWhere((s) => s.$1 == selected);
    final duration = MediaQuery.disableAnimationsOf(context) || t != null
        ? Duration.zero
        : const Duration(milliseconds: 240);
    final at = t ?? index.toDouble();
    Color labelColor(int i) =>
        Color.lerp(c.muted, c.onAccent, (1 - (at - i).abs()).clamp(0.0, 1.0))!;

    return Container(
      constraints: const BoxConstraints(minHeight: _minHeight),
      padding: const EdgeInsets.all(_inset),
      decoration: ShapeDecoration(
        color: c.surface,
        shape: StadiumBorder(side: BorderSide(color: c.border)),
      ),
      child: Stack(
        children: [
          if (index >= 0)
            Positioned.fill(
              child: AnimatedAlign(
                duration: duration,
                curve: Curves.easeOutCubic,
                alignment: Alignment(-1 + 2 * at / (segments.length - 1), 0),
                child: FractionallySizedBox(
                  widthFactor: 1 / segments.length,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: c.accent,
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ),
            ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, (value, label)) in segments.indexed)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: i == index,
                      inMutuallyExclusiveGroup: true,
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: () => onChanged(value),
                        child: Container(
                          constraints: const BoxConstraints(
                            minHeight: _minHeight - 2 * _inset,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: QuoinSpace.s,
                            vertical: QuoinSpace.tight,
                          ),
                          alignment: Alignment.center,
                          child: AnimatedDefaultTextStyle(
                            duration: duration,
                            style: type.control.copyWith(
                              color: t == null
                                  ? (i == index ? c.onAccent : c.muted)
                                  : labelColor(i),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(label, softWrap: false),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
