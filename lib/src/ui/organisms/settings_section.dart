import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/ui/atoms/quoin_card.dart';
import 'package:quoin/src/ui/atoms/quoin_section_label.dart';
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
          QuoinSectionLabel(
            title,
            padding: const EdgeInsets.fromLTRB(
              QuoinSpace.card,
              QuoinSpace.m,
              QuoinSpace.card,
              QuoinSpace.s,
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
