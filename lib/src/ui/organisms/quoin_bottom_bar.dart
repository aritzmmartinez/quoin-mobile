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

class QuoinBottomBar extends StatelessWidget {
  const QuoinBottomBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
    required this.addIcon,
    required this.addLabel,
    required this.onAdd,
  }) : assert(items.length == 4);

  final List<QuoinBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;
  final QuoinIconData addIcon;
  final String addLabel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
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
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: QuoinBarSurface(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: LayoutBuilder(
              builder: (context, box) => Stack(
                children: [
                  _SlidingPill(
                    index: currentIndex,
                    tabWidth: (box.maxWidth - _AddButton.size) / 4,
                  ),
                  Row(
                    children: [
                      item(0),
                      item(1),
                      _AddButton(icon: addIcon, label: addLabel, onTap: onAdd),
                      item(2),
                      item(3),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlidingPill extends StatefulWidget {
  const _SlidingPill({required this.index, required this.tabWidth});

  final int index;
  final double tabWidth;

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
            t * widget.tabWidth + _AddButton.size * clampDouble(t - 1, 0, 1);
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

class _AddButton extends StatelessWidget {
  const _AddButton({
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
