import 'package:flutter/material.dart';

import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.comingSoon = false,
    this.valueIsFigure = false,
  }) : assert(!comingSoon || onTap == null);

  final QuoinIconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool comingSoon;

  final bool valueIsFigure;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final rowSize = type.row.fontSize!;
    final stacked =
        MediaQuery.textScalerOf(context).scale(rowSize) >= rowSize * 1.5;
    final valueText = value == null
        ? null
        : Text(
            value!,
            textAlign: stacked ? TextAlign.start : TextAlign.end,
            style: (valueIsFigure ? type.secondary.mono : type.secondary)
                .copyWith(color: c.muted),
          );
    final labelText = Text(label, style: type.row);

    final row = InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          spacing: 12,
          children: [
            QuoinIcon(icon, size: 18, color: c.muted),
            if (stacked)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    labelText,
                    ?valueText,
                    if (comingSoon) _ComingSoonBadge(),
                  ],
                ),
              )
            else ...[
              Expanded(child: labelText),
              // Short values (a language, a version): their own width.
              ?valueText,
              if (comingSoon) _ComingSoonBadge(),
            ],
            if (onTap != null)
              QuoinIcon(QuoinIcons.chevronRight, size: 16, color: c.faint),
          ],
        ),
      ),
    );
    return comingSoon ? Opacity(opacity: 0.3, child: row) : row;
  }
}

class _ComingSoonBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
