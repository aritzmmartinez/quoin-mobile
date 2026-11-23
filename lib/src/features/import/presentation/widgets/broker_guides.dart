import 'package:flutter/material.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/atoms/marked_span.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';
import 'package:quoin/src/ui/molecules/icon_tile.dart';
import 'package:quoin/src/ui/organisms/quoin_sheet.dart';

enum ExportPlace { app, web }

typedef Localized = String Function(AppLocalizations l10n);

final class BrokerGuide {
  const BrokerGuide({
    required this.broker,
    required this.name,
    required this.place,
    required this.steps,
  });

  final Broker broker;
  final Localized name;
  final ExportPlace place;
  final List<Localized> steps;

  QuoinIconData get icon => switch (place) {
    ExportPlace.app => QuoinIcons.exportInApp,
    ExportPlace.web => QuoinIcons.exportOnWeb,
  };

  String subtitle(AppLocalizations l10n) => switch (place) {
    ExportPlace.app => l10n.importFromApp(steps.length),
    ExportPlace.web => l10n.importFromWeb(steps.length),
  };

  String whereFrom(AppLocalizations l10n) => switch (place) {
    ExportPlace.app => l10n.importExportedInApp,
    ExportPlace.web => l10n.importExportedOnWeb,
  };
}

final brokerGuides = <BrokerGuide>[
  BrokerGuide(
    broker: Broker.tradeRepublic,
    name: (l10n) => l10n.brokerTradeRepublic,
    place: ExportPlace.app,
    steps: [
      (l10n) => l10n.importTradeRepublicStep1,
      (l10n) => l10n.importTradeRepublicStep2,
      (l10n) => l10n.importTradeRepublicStep3,
      (l10n) => l10n.importTradeRepublicStep4,
    ],
  ),
  BrokerGuide(
    broker: Broker.kraken,
    name: (l10n) => l10n.brokerKraken,
    place: ExportPlace.web,
    steps: [
      (l10n) => l10n.importKrakenStep1,
      (l10n) => l10n.importKrakenStep2,
      (l10n) => l10n.importKrakenStep3,
      (l10n) => l10n.importKrakenStep4,
    ],
  ),
];

BrokerGuide guideOf(Broker broker) =>
    brokerGuides.firstWhere((g) => g.broker == broker);

class BrokerGuideRow extends StatelessWidget {
  const BrokerGuideRow({super.key, required this.guide});

  final BrokerGuide guide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final name = guide.name(l10n);
    final subtitle = guide.subtitle(l10n);
    void open() => showBrokerGuide(context, guide);
    return Semantics(
      container: true,
      button: true,
      label: '$name, $subtitle',
      onTap: open,
      excludeSemantics: true,
      child: InkWell(
        onTap: open,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: QuoinSpace.s),
            child: Row(
              spacing: QuoinSpace.m,
              children: [
                IconTile(icon: guide.icon),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: QuoinSpace.xxs,
                    children: [
                      Text(name, style: type.row),
                      Text(
                        subtitle,
                        style: type.secondary.copyWith(color: c.muted),
                      ),
                    ],
                  ),
                ),
                QuoinIcon(
                  QuoinIcons.chevronRight,
                  size: QuoinIconSize.small,
                  color: c.faint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showBrokerGuide(BuildContext context, BrokerGuide guide) {
  final l10n = AppLocalizations.of(context);
  return showQuoinSheet<void>(
    context,
    title: guide.name(l10n),
    subtitle: guide.whereFrom(l10n),
    leading: IconTile(icon: guide.icon),
    body: (sheet) =>
        BrokerGuideSheet(guide: guide, onDone: () => Navigator.of(sheet).pop()),
  );
}

class BrokerGuideSheet extends StatelessWidget {
  const BrokerGuideSheet({
    super.key,
    required this.guide,
    required this.onDone,
  });

  final BrokerGuide guide;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final rule = BorderSide(color: c.borderSubtle);
    final total = guide.steps.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: QuoinSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, step) in guide.steps.indexed)
            Semantics(
              container: true,
              label:
                  '${l10n.quoinStepOf(i + 1, total)}, '
                  '${step(l10n).replaceAll('*', '')}',
              excludeSemantics: true,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: QuoinSpace.m),
                decoration: BoxDecoration(border: Border(top: rule)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: QuoinSpace.m,
                  children: [
                    Container(
                      constraints: const BoxConstraints(
                        minWidth: 26,
                        minHeight: 26,
                      ),
                      alignment: Alignment.center,
                      decoration: ShapeDecoration(
                        color: c.iconTile,
                        shape: const CircleBorder(),
                      ),
                      child: Text('${i + 1}', style: type.secondary.mono),
                    ),
                    Expanded(
                      child: Text.rich(
                        starredSpan(
                          step(l10n),
                          type.row.copyWith(color: c.text),
                        ),
                        style: type.row.copyWith(
                          color: c.body,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.only(top: QuoinSpace.m),
            decoration: BoxDecoration(border: Border(top: rule)),
            child: Text(
              l10n.importGuideNote,
              style: type.secondary.copyWith(color: c.muted),
            ),
          ),
          const SizedBox(height: QuoinSpace.gutter),
          OutlinedButton(onPressed: onDone, child: Text(l10n.importGotIt)),
        ],
      ),
    );
  }
}
