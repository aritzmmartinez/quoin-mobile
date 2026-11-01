import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';

/// A selectable pill. [QuoinChip.code] sets its label in Geist Mono, for
/// ranges and codes («1M», «EUR»); [QuoinChip.text] in Geist, for filters
/// that are words (a category).
class QuoinChip extends StatelessWidget {
  const QuoinChip.code({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  }) : mono = true;

  const QuoinChip.text({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  }) : mono = false;

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? c.accent : Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? c.accent : c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 32),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style:
                    (mono
                            ? QuoinType.of(context).control.mono
                            : QuoinType.of(context).control)
                        .copyWith(color: selected ? c.onAccent : c.muted),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
