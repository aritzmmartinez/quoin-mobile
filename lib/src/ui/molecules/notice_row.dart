import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';

class NoticeRow extends StatelessWidget {
  const NoticeRow({
    super.key,
    required this.text,
    required this.action,
    required this.onTap,
  });

  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    return Semantics(
      container: true,
      button: true,
      onTap: onTap,
      label: '$text, $action',
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(QuoinRadius.compact),
          side: BorderSide(color: c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: kMinInteractiveDimension,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: QuoinSpace.card,
                vertical: QuoinSpace.m,
              ),
              child: Row(
                spacing: QuoinSpace.row,
                children: [
                  QuoinIcon(
                    QuoinIcons.info,
                    size: QuoinIconSize.row,
                    color: c.body,
                  ),
                  Expanded(child: Text(text, style: type.row)),
                  Text(action, style: type.secondary.copyWith(color: c.muted)),
                  QuoinIcon(
                    QuoinIcons.chevronRight,
                    size: QuoinIconSize.small,
                    color: c.faint,
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
