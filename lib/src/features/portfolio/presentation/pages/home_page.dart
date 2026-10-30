import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:quoin/src/app/router.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/ui/molecules/empty_state.dart';
import 'package:quoin/src/ui/templates/quoin_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return QuoinPage(
      title: l10n.tabHome,
      body: EmptyState(
        message: l10n.homeEmpty,
        actionLabel: l10n.importCsv,
        onAction: () => context.push(Routes.import),
      ),
    );
  }
}
