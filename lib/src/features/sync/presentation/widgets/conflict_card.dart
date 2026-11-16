import 'package:flutter/material.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/l10n/quoin_format.dart';
import 'package:quoin/src/core/l10n/residence_name.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/sync/presentation/widgets/sync_detail_view.dart';
import 'package:quoin/src/ui/atoms/quoin_card.dart';
import 'package:quoin/src/ui/molecules/quoin_segmented.dart';

class ConflictCard extends StatelessWidget {
  const ConflictCard({
    super.key,
    required this.conflict,
    required this.names,
    required this.choice,
    required this.onChanged,
  });

  final Conflict conflict;
  final Map<String, String> names;
  final Resolution? choice;
  final ValueChanged<Resolution> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = QuoinType.of(context);
    final c = QuoinColors.of(context);
    String shown(Object? value) => value == null || value == ''
        ? l10n.syncEmptyValue
        : value is bool
        ? (value ? l10n.syncYes : l10n.syncNo)
        : '$value';
    String residence(Object? value) => value is String && value.isNotEmpty
        ? residenceName(l10n, value)
        : shown(value);
    final (title, subject, phone, pc) = switch (conflict) {
      FieldConflict(entity: 'settings', :final local, :final incoming) => (
        l10n.syncFieldResidence,
        null,
        residence(local),
        residence(incoming),
      ),
      FieldConflict(:final key, :final field, :final local, :final incoming) =>
        (_field(l10n, field), names[key], shown(local), shown(incoming)),
      TargetConflict() => (l10n.syncConflictTarget, null, null, null),
      TargetDayConflict(:final day) => (
        l10n.syncConflictTargetDay(
          QuoinFormat.of(context).day(CalendarDate.parse(day)),
        ),
        null,
        null,
        null,
      ),
      HoldingsConflict(:final instrumentId) => (
        l10n.syncConflictHoldings(names[instrumentId] ?? ''),
        null,
        null,
        null,
      ),
    };
    return QuoinCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: QuoinSpace.s,
        children: [
          Text(title, style: type.rowStrong),
          if (subject != null)
            Text(subject, style: type.secondary.copyWith(color: c.muted)),
          if (phone != null && pc != null) ...[
            Text(
              '${l10n.syncKeepPhone}: $phone',
              style: type.secondary.copyWith(color: c.body),
            ),
            Text(
              '${l10n.syncTakePc}: $pc',
              style: type.secondary.copyWith(color: c.body),
            ),
          ],
          QuoinSegmented<Resolution?>(
            segments: [
              (Resolution.keep, l10n.syncKeepPhone),
              (Resolution.take, l10n.syncTakePc),
            ],
            selected: choice,
            onChanged: (value) => onChanged(value!),
          ),
        ],
      ),
    );
  }

  static String _field(AppLocalizations l10n, String field) =>
      switch (DetailField.values.asNameMap()[field]) {
        final known? => detailFieldLabel(l10n, known),
        null => field,
      };
}
