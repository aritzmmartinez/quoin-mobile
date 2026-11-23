import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/molecules/icon_tile.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.negative = false,
  }) : assert((actionLabel == null) == (onAction == null));

  final QuoinIconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    final type = QuoinType.of(context);
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: QuoinSpace.section,
        vertical: QuoinSpace.hero,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: QuoinSpace.card,
        children: [
          IconTile(
            icon: icon,
            signal: negative ? QuoinColors.of(context).negative : null,
          ),
          Column(
            spacing: QuoinSpace.s,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: type.rowStrong,
                ),
              ),
              Text(
                body,
                textAlign: TextAlign.center,
                style: type.secondary.copyWith(
                  color: QuoinColors.of(context).muted,
                ),
              ),
            ],
          ),
          if (actionLabel case final label?)
            FilledButton(onPressed: onAction, child: Text(label)),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, box) => Center(
        child: box.hasBoundedHeight
            ? SingleChildScrollView(child: content)
            : content,
      ),
    );
  }
}
