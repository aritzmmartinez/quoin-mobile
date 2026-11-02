import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:quoin/src/app/router.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/portfolio/domain/entities/holding_order.dart';
import 'package:quoin/src/features/portfolio/domain/entities/movement.dart';
import 'package:quoin/src/features/portfolio/presentation/providers/portfolio_providers.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/ledger_tiles.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/result_view.dart';
import 'package:quoin/src/ui/atoms/quoin_chip.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';
import 'package:quoin/src/ui/molecules/empty_state.dart';
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
        body: EmptyState(message: l10n.homeEmpty),
      );
    }

    final names = <String, String>{
      for (final m in all)
        if ((m.instrumentId, m.instrumentName) case (final id?, final name?))
          id: name,
    };
    final instrument = names.containsKey(_instrument) ? _instrument : null;
    final types = {for (final m in all) m.type};
    final shown = [
      for (final m in all)
        if ((_type == null || m.type == _type) &&
            (instrument == null || m.instrumentId == instrument))
          m,
    ];

    return QuoinPage.lazy(
      title: l10n.movementsTitle,
      header: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: [
              QuoinChip.text(
                label: instrument == null
                    ? l10n.movementsAllInstruments
                    : names[instrument]!,
                selected: instrument != null,
                onTap: () => _pickInstrument(context, names),
              ),
              QuoinChip.text(
                label: l10n.movementsFilterAll,
                selected: _type == null,
                onTap: () => setState(() => _type = null),
              ),
              for (final t in _typeOrder.where(types.contains))
                QuoinChip.text(
                  label: l10n.movementType(t),
                  selected: t == _type,
                  onTap: () => setState(() => _type = t),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.movementsCount(shown.length),
          style: type.secondary.copyWith(color: c.muted),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.movementsAmountHint,
          style: type.small.copyWith(color: c.muted),
        ),
        const SizedBox(height: 8),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: QuoinSpace.section),
            child: Text(
              l10n.movementsNoneMatch,
              style: type.secondary.copyWith(color: c.muted),
            ),
          ),
      ],
      itemCount: shown.length,
      itemBuilder: (context, i) {
        final m = shown[i];
        final id = m.instrumentId;
        return DecoratedBox(
          decoration: BoxDecoration(
            border: i == 0
                ? null
                : Border(top: BorderSide(color: c.borderSubtle)),
          ),
          child: movementTile(
            context,
            m,
            zone,
            onTap: id == null || id == widget.instrumentId
                ? null
                : () => context.push(Routes.instrument(id)),
          ),
        );
      },
    );
  }

  Future<void> _pickInstrument(
    BuildContext context,
    Map<String, String> names,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ids = names.keys.toList()
      ..sort((a, b) => compareNamesEs(names[a]!, names[b]!));
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final (id, label) in [
              ('', l10n.movementsAllInstruments),
              for (final id in ids) (id, names[id]!),
            ])
              ListTile(
                title: Text(label),
                trailing: (id.isEmpty ? null : id) == _instrument
                    ? const QuoinIcon(QuoinIcons.check)
                    : null,
                onTap: () => Navigator.of(context).pop(id),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _instrument = picked.isEmpty ? null : picked);
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
