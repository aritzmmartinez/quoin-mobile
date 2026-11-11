import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:quoin/src/app/app_shell.dart';
import 'package:quoin/src/features/analysis/presentation/pages/analysis_page.dart';
import 'package:quoin/src/features/import/presentation/pages/import_page.dart';
import 'package:quoin/src/features/portfolio/presentation/pages/home_page.dart';
import 'package:quoin/src/features/portfolio/presentation/pages/instrument_page.dart';
import 'package:quoin/src/features/portfolio/presentation/pages/movements_page.dart';
import 'package:quoin/src/features/portfolio/presentation/pages/portfolio_page.dart';
import 'package:quoin/src/features/settings/presentation/pages/component_gallery_page.dart';
import 'package:quoin/src/features/settings/presentation/pages/settings_page.dart';
import 'package:quoin/src/features/sync/presentation/pages/pair_page.dart';
import 'package:quoin/src/features/sync/presentation/pages/sync_page.dart';
import 'package:quoin/src/features/tax/presentation/pages/realized_page.dart';

abstract final class Routes {
  static const home = '/';
  static const portfolio = '/portfolio';
  static const analysis = '/analysis';
  static const settings = '/settings';
  static const import = '/import';
  static const realized = '/realized';
  static const movements = '/movements';
  static const pair = '/pair';
  static const repair = '/pair?repair=1';
  static const sync = '/sync';

  static String instrument(String id) =>
      '/instrument/${Uri.encodeComponent(id)}';

  static String movementsOf(String id) =>
      Uri(path: movements, queryParameters: {'instrument': id}).toString();

  /// Debug builds only: the wizard over an invented batch.
  static const importSample = '/import?sample=1';
  static const gallery = '/settings/gallery';
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: Routes.home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          _branch(Routes.home, const HomePage()),
          _branch(Routes.portfolio, const PortfolioPage()),
          _branch(Routes.analysis, const AnalysisPage()),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (context, state) => const SettingsPage(),
                routes: [
                  if (kDebugMode)
                    GoRoute(
                      path: 'gallery',
                      builder: (context, state) => const ComponentGalleryPage(),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
      // Detail screens open over the shell, without the bar, as in the design.
      GoRoute(
        path: '/instrument/:id',
        builder: (context, state) =>
            Scaffold(body: InstrumentPage(id: state.pathParameters['id']!)),
      ),
      GoRoute(
        path: Routes.movements,
        builder: (context, state) => Scaffold(
          body: MovementsPage(
            instrumentId: state.uri.queryParameters['instrument'],
          ),
        ),
      ),
      GoRoute(
        path: Routes.realized,
        builder: (context, state) => const Scaffold(body: RealizedPage()),
      ),
      GoRoute(
        path: Routes.pair,
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: Scaffold(
            body: PairPage(repair: state.uri.queryParameters['repair'] == '1'),
          ),
        ),
      ),
      GoRoute(
        path: Routes.sync,
        builder: (context, state) => const Scaffold(body: SyncPage()),
      ),
      GoRoute(
        path: Routes.import,
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: ImportPage(
            sample: kDebugMode && state.uri.queryParameters['sample'] == '1',
          ),
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (context, state) => screen)],
);
