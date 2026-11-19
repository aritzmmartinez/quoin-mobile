import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';

class QuoinPillButton extends StatelessWidget {
  const QuoinPillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final QuoinIconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: kMinInteractiveDimension,
          ),
          child: Center(
            widthFactor: 1,
            child: Material(
              type: MaterialType.transparency,
              shape: StadiumBorder(side: BorderSide(color: c.border)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    QuoinSpace.m,
                    QuoinSpace.s,
                    QuoinSpace.card,
                    QuoinSpace.s,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: QuoinSpace.tight,
                    children: [
                      QuoinIcon(icon, size: QuoinIconSize.small, color: c.body),
                      Text(
                        label,
                        style: QuoinType.of(context).secondary
                            .copyWith(color: c.body),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
