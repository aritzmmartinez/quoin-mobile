import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/l10n/below_cent.dart';
import 'package:quoin/src/app/router.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/l10n/quoin_format.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/portfolio/domain/entities/holding_order.dart';
import 'package:quoin/src/features/portfolio/domain/entities/movement.dart';
import 'package:quoin/src/features/portfolio/presentation/providers/portfolio_providers.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/ledger_tiles.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/result_view.dart';
import 'package:quoin/src/ui/molecules/empty_state.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';
import 'package:quoin/src/ui/molecules/group_header.dart';
import 'package:quoin/src/ui/organisms/explain_sheet.dart';
import 'package:quoin/src/ui/organisms/quoin_dropdown.dart';
import 'package:quoin/src/ui/templates/quoin_page.dart';

class MovementsPage extends ConsumerStatefulWidget {
  const MovementsPage({super.key, this.instrumentId});

  final String? instrumentId;

  @override
  ConsumerState<MovementsPage> createState() => _MovementsPageState();
}

class _MovementsPageState extends ConsumerState<MovementsPage> {
  String? _type;
  late String? _instrument = widget.instrumentId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ResultView(
      title: l10n.movementsTitle,
      value: ref.watch(movementsProvider),
      builder: (movements) => _content(context, movements.zone, movements.rows),
    );
  }

  Widget _content(BuildContext context, String zone, List<Movement> all) {
    final l10n = AppLocalizations.of(context);
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    if (all.isEmpty) {
      return QuoinPage(
        title: l10n.movementsTitle,
        body: EmptyState(
          icon: QuoinIcons.movements,
          title: l10n.emptyMovementsTitle,
          body: l10n.emptyMovementsBody,
          actionLabel: l10n.importCsv,
          onAction: () => context.push(Routes.import),
        ),
      );
    }

    final names = <String, String>{
      for (final m in all)
        if ((m.instrumentId, m.instrumentName) case (final id?, final name?))
          id: name,
    };
    final instrument = names.containsKey(_instrument) ? _instrument : null;
    final ids = names.keys.toList()
      ..sort((a, b) => compareNamesEs(names[a]!, names[b]!));
    final types = {for (final m in all) m.type};
    final shown = [
      for (final m in all)
        if ((_type == null || m.type == _type) &&
            (instrument == null || m.instrumentId == instrument))
          m,
    ];

    final months = byMonth(shown, zone);
    final format = QuoinFormat.of(context);
    final items = <Widget Function(BuildContext)>[
      for (final month in months) ...[
        (_) => GroupHeader(
          label: format.month(month.month),
          total: isBelowCent(month.net)
              ? belowCentText(l10n, format)
              : format.signedMoney(month.net).text,
        ),
        for (final m in month.rows)
          (context) => movementTile(
            context,
            m,
            zone,
            onTap: switch (m.instrumentId) {
              final id? when id != widget.instrumentId => () => context.push(
                Routes.instrument(id),
              ),
              _ => null,
            },
          ),
      ],
    ];

    return QuoinPage.lazy(
      title: l10n.movementsTitle,
      trailing: IconButton(
        icon: const QuoinIcon(QuoinIcons.info),
        tooltip: l10n.movementsAmountTitle,
        onPressed: () => _explain(context),
      ),
      card: false,
      header: [
        Wrap(
          spacing: QuoinSpace.s,
          runSpacing: QuoinSpace.s,
          children: [
            QuoinDropdown<String?>(
              label: l10n.movementsFilterInstrument,
              value: instrument,
              options: [
                (value: null, label: l10n.movementsAllInstruments),
                for (final id in ids) (value: id, label: names[id]!),
              ],
              onChanged: (id) => setState(() => _instrument = id),
            ),
            QuoinDropdown<String?>(
              label: l10n.movementsFilterType,
              value: _type,
              options: [
                (value: null, label: l10n.movementsAllTypes),
                for (final t in _typeOrder.where(types.contains))
                  (value: t, label: l10n.movementType(t)),
              ],
              onChanged: (t) => setState(() => _type = t),
            ),
          ],
        ),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: QuoinSpace.section),
            child: Text(
              l10n.movementsNoneMatch,
              style: type.secondary.copyWith(color: c.muted),
            ),
          ),
      ],
      itemCount: items.length,
      itemBuilder: (context, i) => items[i](context),
    );
  }

  Future<void> _explain(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return showExplainSheet(
      context,
      title: l10n.movementsAmountTitle,
      points: [
        (
          icon: QuoinIcons.cashFlow,
          title: l10n.movementsCashTitle,
          body: l10n.movementsCashBody,
          source: null,
        ),
        (
          icon: QuoinIcons.swap,
          title: l10n.movementsSwapTitle,
          body: l10n.movementsSwapBody,
          source: null,
        ),
      ],
      detailTitle: l10n.realizedHowDetail,
      detail: [l10n.movementsAmountHint],
    );
  }
}

const _typeOrder = [
  'BUY',
  'SELL',
  'DIVIDEND',
  'DEPOSIT',
  'WITHDRAWAL',
  'INTEREST',
];
