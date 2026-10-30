import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:quoin/src/app/app_shell.dart';
import 'package:quoin/src/features/analysis/presentation/pages/analysis_page.dart';
import 'package:quoin/src/features/import/presentation/pages/import_page.dart';
import 'package:quoin/src/features/portfolio/presentation/pages/home_page.dart';
import 'package:quoin/src/features/portfolio/presentation/pages/portfolio_page.dart';
import 'package:quoin/src/features/settings/presentation/pages/component_gallery_page.dart';
import 'package:quoin/src/features/settings/presentation/pages/settings_page.dart';

abstract final class Routes {
  static const home = '/';
  static const portfolio = '/portfolio';
  static const analysis = '/analysis';
  static const settings = '/settings';
  static const import = '/import';
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
      GoRoute(
        path: Routes.import,
        pageBuilder: (context, state) =>
            const MaterialPage(fullscreenDialog: true, child: ImportPage()),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (context, state) => screen)],
);
