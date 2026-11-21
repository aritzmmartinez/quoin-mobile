import 'package:flutter/material.dart';

import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    this.icon,
    required this.label,
    this.subtitle,
    this.value,
    this.onTap,
    this.comingSoon = false,
    this.valueIsFigure = false,
    this.inset = true,
  }) : assert(!comingSoon || onTap == null);

  final QuoinIconData? icon;
  final String label;
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;
  final bool comingSoon;
  final bool valueIsFigure;
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final stacked = QuoinType.largeText(context);
    final valueText = value == null
        ? null
        : Text(
            value!,
            textAlign: stacked ? TextAlign.start : TextAlign.end,
            maxLines: stacked ? null : 1,
            overflow: stacked ? null : TextOverflow.ellipsis,
            style: (valueIsFigure ? type.secondary.mono : type.secondary)
                .copyWith(color: c.muted),
          );
    final label = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: QuoinSpace.xxs,
      children: [
        Text(
          this.label,
          style: type.row.copyWith(color: comingSoon ? c.faint : c.text),
        ),
        if (subtitle case final subtitle?)
          Text(subtitle, style: type.secondary.copyWith(color: c.muted)),
      ],
    );

    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        enabled: !comingSoon,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: inset ? QuoinSpace.card : 0,
              vertical: QuoinSpace.m,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: QuoinSpace.section),
              child: Row(
                spacing: QuoinSpace.m,
                children: [
                  if (icon case final icon?)
                    QuoinIcon(
                      icon,
                      size: QuoinIconSize.row,
                      color: comingSoon ? c.faint : c.muted,
                    ),
                  if (stacked)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: QuoinSpace.tight,
                        children: [
                          label,
                          ?valueText,
                          if (comingSoon) const _ComingSoonBadge(),
                        ],
                      ),
                    )
                  else ...[
                    Expanded(child: label),
                    if (valueText != null)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.4,
                        ),
                        child: valueText,
                      ),
                    if (comingSoon) const _ComingSoonBadge(),
                  ],
                  if (onTap != null)
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

class _ComingSoonBadge extends StatelessWidget {
  const _ComingSoonBadge();

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: QuoinSpace.row,
        vertical: QuoinSpace.xs,
      ),
      decoration: ShapeDecoration(
        color: c.bg,
        shape: StadiumBorder(side: BorderSide(color: c.border)),
      ),
      child: Text(
        AppLocalizations.of(context).comingSoon,
        softWrap: false,
        style: QuoinType.of(context).small.copyWith(color: c.muted),
      ),
    );
  }
}
