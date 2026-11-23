import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';

class FoldSection extends StatefulWidget {
  const FoldSection({
    super.key,
    required this.title,
    required this.children,
    this.summary,
    this.initiallyOpen = false,
    this.rule = true,
  });

  final String title;
  final String? summary;
  final List<Widget> children;
  final bool initiallyOpen;
  final bool rule;

  @override
  State<FoldSection> createState() => _FoldSectionState();
}

class _FoldSectionState extends State<FoldSection> {
  late var _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final summary = widget.summary;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: widget.rule
              ? BorderSide(color: c.borderSubtle)
              : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _open,
            label: [widget.title, ?summary].join(', '),
            excludeSemantics: true,
            onTap: _toggle,
            child: InkWell(
              onTap: _toggle,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: kMinInteractiveDimension,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: QuoinSpace.m),
                  child: Row(
                    spacing: QuoinSpace.m,
                    children: [
                      Expanded(
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: QuoinSpace.m,
                          runSpacing: QuoinSpace.xxs,
                          children: [
                            Text(widget.title, style: type.row),
                            if (summary != null)
                              Text(
                                summary,
                                style: type.secondary.tabular.copyWith(
                                  color: c.muted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: _open ? 0.5 : 0,
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 150),
                        child: QuoinIcon(
                          QuoinIcons.chevronDown,
                          size: QuoinIconSize.small,
                          color: c.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.only(bottom: QuoinSpace.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.children,
              ),
            ),
        ],
      ),
    );
  }

  void _toggle() => setState(() => _open = !_open);
}
