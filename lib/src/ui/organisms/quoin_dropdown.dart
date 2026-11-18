import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';
import 'package:quoin/src/ui/organisms/quoin_sheet.dart';

class QuoinDropdown<T> extends StatelessWidget {
  const QuoinDropdown({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<QuoinChoice<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final shown = options.firstWhere((o) => o.value == value).label;
    return Semantics(
      button: true,
      label: label,
      value: shown,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
        child: Center(
          widthFactor: 1,
          child: Material(
            color: c.surface,
            shape: StadiumBorder(side: BorderSide(color: c.border)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () async {
                final picked = await showQuoinChoice(
                  context,
                  title: label,
                  options: options,
                  selected: value,
                );
                if (picked != null) onChanged(picked.value);
              },
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  QuoinSpace.card,
                  QuoinSpace.s,
                  QuoinSpace.m,
                  QuoinSpace.s,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: QuoinSpace.xs,
                  children: [
                    Flexible(
                      child: Text(
                        shown,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: QuoinType.of(context).control
                            .copyWith(color: c.text),
                      ),
                    ),
                    QuoinIcon(
                      QuoinIcons.chevronDown,
                      size: QuoinIconSize.small,
                      color: c.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
