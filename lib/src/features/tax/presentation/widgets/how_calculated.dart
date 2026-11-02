import 'package:flutter/material.dart';

import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';

class HowCalculated extends StatefulWidget {
  const HowCalculated({super.key, required this.paragraphs});

  final List<String> paragraphs;

  @override
  State<HowCalculated> createState() => _HowCalculatedState();
}

class _HowCalculatedState extends State<HowCalculated> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: kMinInteractiveDimension,
              ),
              child: Row(
                spacing: 8,
                children: [
                  QuoinIcon(QuoinIcons.info, size: 18, color: c.accent),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).realizedHow,
                      style: type.secondary.copyWith(color: c.accent),
                    ),
                  ),
                  QuoinIcon(
                    _open ? QuoinIcons.close : QuoinIcons.chevronDown,
                    size: 16,
                    color: c.faint,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_open)
          for (final paragraph in widget.paragraphs)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                paragraph,
                style: type.secondary.copyWith(color: c.body),
              ),
            ),
      ],
    );
  }
}
