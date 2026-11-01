import 'package:flutter_riverpod/misc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';
import 'package:quoin/src/features/portfolio/data/datasources/portfolio_local_datasource.dart';
import 'package:quoin/src/features/portfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:quoin/src/features/portfolio/presentation/providers/portfolio_providers.dart';
import 'package:quoin/src/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:quoin/src/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:quoin/src/features/settings/presentation/providers/settings_providers.dart';

List<Override> dependencies(
  SharedPreferencesWithCache prefs,
  QuoinDatabase database,
) => [
  sharedPreferencesProvider.overrideWithValue(prefs),
  settingsRepositoryProvider.overrideWith(
    (ref) => SettingsRepositoryImpl(ref.watch(settingsLocalDataSourceProvider)),
  ),
  quoinDatabaseProvider.overrideWithValue(database),
  portfolioRepositoryProvider.overrideWith(
    (ref) =>
        PortfolioRepositoryImpl(ref.watch(portfolioLocalDataSourceProvider)),
  ),
];
