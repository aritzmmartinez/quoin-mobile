import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/atoms/pressable.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';
import 'package:quoin/src/ui/organisms/quoin_bar_surface.dart';

class QuoinBarItem {
  const QuoinBarItem({required this.icon, required this.label});

  final QuoinIconData icon;
  final String label;
}

/// Where the add button sits: inside the pill between the second and third
/// tab ([center]), as its own glass circle beside the pill ([leading],
/// [trailing]), or above the pill's end ([above]).
enum QuoinBarActionPlacement { center, leading, trailing, above }

class QuoinBottomBar extends StatelessWidget {
  const QuoinBottomBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
    required this.addIcon,
    required this.addLabel,
    required this.onAdd,
    this.placement = QuoinBarActionPlacement.trailing,
  }) : assert(items.length == 4);

  /// Between the pill and a detached button.
  static const double gap = 10;

  final List<QuoinBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;
  final QuoinIconData addIcon;
  final String addLabel;
  final VoidCallback onAdd;
  final QuoinBarActionPlacement placement;

  @override
  Widget build(BuildContext context) {
    final inline = placement == QuoinBarActionPlacement.center;
    Widget item(int i) => Expanded(
      child: _BarButton(
        item: items[i],
        selected: i == currentIndex,
        onTap: () {
          HapticFeedback.selectionClick();
          onSelected(i);
        },
      ),
    );

    final pill = QuoinBarSurface(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: LayoutBuilder(
          builder: (context, box) {
            final inlineWidth = inline ? _InlineAddButton.size : 0.0;
            return Stack(
              children: [
                _SlidingPill(
                  index: currentIndex,
                  tabWidth: (box.maxWidth - inlineWidth) / 4,
                  inlineWidth: inlineWidth,
                ),
                Row(
                  children: [
                    item(0),
                    item(1),
                    if (inline)
                      _InlineAddButton(
                        icon: addIcon,
                        label: addLabel,
                        onTap: onAdd,
                      ),
                    item(2),
                    item(3),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
    final detached = _DetachedAddButton(
      icon: addIcon,
      label: addLabel,
      onTap: onAdd,
    );

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      // The bar keeps its height: text inside it scales only to 1.3.
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: QuoinGlassLayer(
          child: switch (placement) {
            QuoinBarActionPlacement.center => pill,
            QuoinBarActionPlacement.leading => Row(
              spacing: gap,
              children: [
                detached,
                Expanded(child: pill),
              ],
            ),
            QuoinBarActionPlacement.trailing => Row(
              spacing: gap,
              children: [
                Expanded(child: pill),
                detached,
              ],
            ),
            QuoinBarActionPlacement.above => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: gap,
              children: [detached, pill],
            ),
          },
        ),
      ),
    );
  }
}

class _SlidingPill extends StatefulWidget {
  const _SlidingPill({
    required this.index,
    required this.tabWidth,
    required this.inlineWidth,
  });

  final int index;
  final double tabWidth;

  /// The add button's width when it sits between the second and third tab.
  final double inlineWidth;

  @override
  State<_SlidingPill> createState() => _SlidingPillState();
}

class _SlidingPillState extends State<_SlidingPill>
    with SingleTickerProviderStateMixin {
  static final _spring = SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 400),
    bounce: 0.2,
  );

  late final _position = AnimationController.unbounded(
    vsync: this,
    value: widget.index.toDouble(),
  );

  @override
  void didUpdateWidget(_SlidingPill old) {
    super.didUpdateWidget(old);
    if (widget.index == old.index) return;
    final target = widget.index.toDouble();
    if (MediaQuery.disableAnimationsOf(context)) {
      _position.value = target;
    } else {
      _position.animateWith(
        SpringSimulation(_spring, _position.value, target, _position.velocity),
      );
    }
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    return AnimatedBuilder(
      animation: _position,
      builder: (context, pill) {
        final t = _position.value;
        final start =
            t * widget.tabWidth + widget.inlineWidth * clampDouble(t - 1, 0, 1);
        return PositionedDirectional(
          start: start,
          top: 0,
          bottom: 0,
          width: widget.tabWidth,
          child: pill!,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: c.text.withValues(alpha: 0.08),
            shape: const StadiumBorder(),
          ),
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final QuoinBarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final color = selected ? c.accent : c.muted;
    return Semantics(
      button: true,
      selected: selected,
      child: Pressable(
        onTap: onTap,
        child: SizedBox(
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 4,
            children: [
              QuoinIcon(item.icon, size: 22, color: color),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: QuoinType.of(context).small.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineAddButton extends StatelessWidget {
  const _InlineAddButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  static const size = 44.0;

  final QuoinIconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        child: Pressable(
          onTap: onTap,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: c.accent,
              shape: const CircleBorder(),
            ),
            child: SizedBox.square(
              dimension: size,
              child: Center(
                child: QuoinIcon(icon, size: 20, color: c.onAccent),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The add button as a glass circle of its own, as high as the pill.
class _DetachedAddButton extends StatelessWidget {
  const _DetachedAddButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final QuoinIconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        child: Pressable(
          onTap: onTap,
          child: QuoinBarSurface.circle(
            child: Center(
              child: QuoinIcon(
                icon,
                size: 24,
                color: QuoinColors.of(context).text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
