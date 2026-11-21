import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/portfolio/domain/usecases/set_instrument_category.dart';
import 'package:quoin/src/features/portfolio/presentation/providers/portfolio_providers.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/portfolio_view.dart';
import 'package:quoin/src/ui/organisms/quoin_sheet.dart';
import 'package:quoin/src/ui/organisms/quoin_toast.dart';

String categoryOf(AppLocalizations l10n, Instrument i) {
  final kind = effectiveExposure(i.type, i.exposureKind).kind;
  if (kind == null) return l10n.categoryOther;
  final label = categoryLabel(l10n, kind.code);
  return switch (i.exposureLeafId) {
    final leaf? when i.exposureKind != null => '$label · $leaf',
    _ => label,
  };
}

Future<void> classifyInstruments(
  BuildContext context,
  List<Instrument> instruments,
) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final classify = container.read(setInstrumentCategoryProvider);
  final pass = instruments.length > 1;
  var wrote = false;
  for (final (index, instrument) in instruments.indexed) {
    if (!context.mounted) break;
    final outcome = await _ask(
      context,
      instrument,
      progress: pass ? (index + 1, instruments.length) : null,
    );
    if (outcome case _Chosen(:final choice)) {
      final saved = switch (await classify(instrument.id, choice)) {
        Ok() => true,
        Err() => false,
      };
      if (!saved) {
        if (context.mounted) {
          final l10n = AppLocalizations.of(context);
          showQuoinToast(
            context,
            tone: QuoinToastTone.negative,
            title: l10n.categorySaveFailed,
            body: l10n.categorySaveFailedBody,
          );
        }
        break;
      }
      wrote = true;
    } else if (outcome == null) {
      break;
    }
  }
  if (wrote) container.invalidate(ledgerProvider);
}

sealed class _Outcome {
  const _Outcome();
}

final class _Chosen extends _Outcome {
  const _Chosen(this.choice);

  final CategoryChoice choice;
}

final class _Skipped extends _Outcome {
  const _Skipped();
}

Future<_Outcome?> _ask(
  BuildContext context,
  Instrument i, {
  (int, int)? progress,
}) {
  final l10n = AppLocalizations.of(context);
  final chosen = i.exposureKind;
  final derived = effectiveExposure(i.type, null).kind;
  final subtitle = [
    if (progress case (final at, final of)) l10n.categoryProgress(at, of),
    if (i.type != 'CRYPTO') i.id,
  ];
  return showQuoinSheet<_Outcome>(
    context,
    title: i.name,
    subtitle: subtitle.isEmpty ? null : subtitle.join(' · '),
    leading: instrumentMark(type: i.type, name: i.name, kind: chosen),
    body: (sheet) {
      final c = QuoinColors.of(sheet);
      final type = QuoinType.of(sheet);
      void pick(CategoryChoice choice) =>
          Navigator.of(sheet)
              .pop(choice.kind == chosen ? const _Skipped() : _Chosen(choice));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final choice in [
            CategoryChoice.equityFund,
            CategoryChoice.bondFund,
          ])
            QuoinChoiceRow(
              label: categoryLabel(l10n, choice.kind!.code),
              selected: choice.kind == chosen,
              onTap: () => pick(choice),
            ),
          if (chosen != null &&
              !CategoryChoice.values.any((c) => c.kind == chosen))
            QuoinChoiceRow(
              label: categoryOf(l10n, i),
              selected: true,
              onTap: () => Navigator.of(sheet).pop(const _Skipped()),
            ),
          QuoinChoiceRow(
            label: derived == null
                ? l10n.categoryOther
                : l10n.categoryAutomatic(categoryLabel(l10n, derived.code)),
            selected: chosen == null,
            onTap: () => pick(CategoryChoice.automatic),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              QuoinSpace.gutter,
              QuoinSpace.m,
              QuoinSpace.gutter,
              0,
            ),
            child: Text(
              l10n.categoryPcOnly,
              style: type.secondary.copyWith(color: c.muted),
            ),
          ),
          if (progress != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                QuoinSpace.gutter,
                QuoinSpace.m,
                QuoinSpace.gutter,
                0,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => Navigator.of(sheet).pop(const _Skipped()),
                  child: Text(l10n.categorySkip),
                ),
              ),
            ),
        ],
      );
    },
  );
}
