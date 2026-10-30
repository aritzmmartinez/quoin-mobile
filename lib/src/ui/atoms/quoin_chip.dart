import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';

class QuoinChip extends StatelessWidget {
  const QuoinChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

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
                style: QuoinType.of(context).control.mono
                    .copyWith(color: selected ? c.onAccent : c.muted),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
