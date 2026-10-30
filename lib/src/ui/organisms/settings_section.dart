import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/atoms/quoin_card.dart';
import 'package:quoin/src/ui/molecules/settings_row.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.title, required this.rows});

  final String title;
  final List<SettingsRow> rows;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    return QuoinCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Semantics(
              header: true,
              child: Text(
                title.toUpperCase(),
                style: QuoinType.of(context).section.copyWith(color: c.muted),
              ),
            ),
          ),
          for (final row in rows) ...[
            Divider(height: 1, color: c.borderSubtle),
            row,
          ],
        ],
      ),
    );
  }
}
