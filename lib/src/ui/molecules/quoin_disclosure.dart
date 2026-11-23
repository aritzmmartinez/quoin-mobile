import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';

class QuoinDisclosure extends StatefulWidget {
  const QuoinDisclosure({
    super.key,
    required this.title,
    required this.paragraphs,
  });

  final String title;
  final List<String> paragraphs;

  @override
  State<QuoinDisclosure> createState() => _QuoinDisclosureState();
}

class _QuoinDisclosureState extends State<QuoinDisclosure> {
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
                spacing: QuoinSpace.s,
                children: [
                  QuoinIcon(
                    QuoinIcons.info,
                    size: QuoinIconSize.row,
                    color: c.accent,
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: type.secondary.copyWith(color: c.accent),
                    ),
                  ),
                  QuoinIcon(
                    _open ? QuoinIcons.close : QuoinIcons.chevronDown,
                    size: QuoinIconSize.small,
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
              padding: const EdgeInsets.only(top: QuoinSpace.s),
              child: Text(
                paragraph,
                style: type.secondary.copyWith(color: c.body),
              ),
            ),
      ],
    );
  }
}
