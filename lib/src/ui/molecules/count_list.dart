import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';

class CountEntry {
  const CountEntry(
    this.label,
    this.value, {
    this.note,
    this.icon,
    this.muted = false,
  });

  final String label;
  final String value;
  final String? note;
  final QuoinIconData? icon;
  final bool muted;
}

class CountList extends StatelessWidget {
  const CountList({super.key, required this.entries, this.closed = true});

  final List<CountEntry> entries;
  final bool closed;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final rule = BorderSide(color: c.borderSubtle);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, entry) in entries.indexed)
          Semantics(
            container: true,
            label: [entry.label, entry.value, ?entry.note].join(', '),
            excludeSemantics: true,
            child: Container(
              constraints: const BoxConstraints(
                minHeight: kMinInteractiveDimension,
              ),
              padding: const EdgeInsets.symmetric(vertical: QuoinSpace.m),
              decoration: BoxDecoration(
                border: Border(
                  top: rule,
                  bottom: closed && i == entries.length - 1
                      ? rule
                      : BorderSide.none,
                ),
              ),
              child: Row(
                spacing: QuoinSpace.s,
                children: [
                  if (entry.icon case final icon?)
                    QuoinIcon(icon, size: QuoinIconSize.small, color: c.muted),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: QuoinSpace.xxs,
                      children: [
                        Text(
                          entry.label,
                          style: type.row.copyWith(
                            color: entry.muted ? c.body : c.text,
                          ),
                        ),
                        if (entry.note case final note?)
                          Text(
                            note,
                            style: type.secondary.copyWith(color: c.muted),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    entry.value,
                    style: type.row.mono.copyWith(
                      color: entry.muted ? c.body : c.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
