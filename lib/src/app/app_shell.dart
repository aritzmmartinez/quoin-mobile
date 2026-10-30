import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:quoin/src/app/router.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/ui/organisms/quoin_bottom_bar.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: QuoinBottomBar(
        items: [
          QuoinBarItem(icon: QuoinIcons.home, label: l10n.tabHome),
          QuoinBarItem(icon: QuoinIcons.portfolio, label: l10n.tabPortfolio),
          QuoinBarItem(icon: QuoinIcons.analysis, label: l10n.tabAnalysis),
          QuoinBarItem(icon: QuoinIcons.settings, label: l10n.tabSettings),
        ],
        currentIndex: shell.currentIndex,
        onSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        addIcon: QuoinIcons.add,
        addLabel: l10n.importCsv,
        onAdd: () => context.push(Routes.import),
      ),
    );
  }
}
