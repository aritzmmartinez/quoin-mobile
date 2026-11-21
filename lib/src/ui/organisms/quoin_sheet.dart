import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';

Future<T?> showQuoinSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder body,
  String? subtitle,
  Widget? leading,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheet) {
      final c = QuoinColors.of(sheet);
      final type = QuoinType.of(sheet);
      return Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: title,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: QuoinSpace.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  QuoinSpace.gutter,
                  0,
                  QuoinSpace.gutter,
                  QuoinSpace.m,
                ),
                child: Row(
                  spacing: QuoinSpace.m,
                  children: [
                    if (leading != null) ExcludeSemantics(child: leading),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: QuoinSpace.xs,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(title, style: type.title),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle,
                              style: type.secondary.tabular.copyWith(
                                color: c.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              body(sheet),
            ],
          ),
        ),
      );
    },
  );
}

typedef QuoinChoice<T> = ({T value, String label});

Future<QuoinChoice<T>?> showQuoinChoice<T>(
  BuildContext context, {
  required String title,
  required List<QuoinChoice<T>> options,
  required T selected,
}) {
  return showQuoinSheet<QuoinChoice<T>>(
    context,
    title: title,
    body: (sheet) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in options)
          QuoinChoiceRow(
            label: option.label,
            selected: option.value == selected,
            onTap: () => Navigator.of(sheet).pop(option),
          ),
      ],
    ),
  );
}

class QuoinChoiceRow extends StatelessWidget {
  const QuoinChoiceRow({
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
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: kMinInteractiveDimension,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: QuoinSpace.gutter,
                vertical: QuoinSpace.m,
              ),
              child: Row(
                spacing: QuoinSpace.m,
                children: [
                  Expanded(
                    child: Text(label, style: QuoinType.of(context).row),
                  ),
                  if (selected)
                    ExcludeSemantics(
                      child: QuoinIcon(
                        QuoinIcons.check,
                        size: QuoinIconSize.row,
                        color: c.accent,
                      ),
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
