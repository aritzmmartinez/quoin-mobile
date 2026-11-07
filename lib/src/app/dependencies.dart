import 'package:flutter_riverpod/misc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/import/data/datasources/ecb_remote_datasource.dart';
import 'package:quoin/src/features/import/data/datasources/fx_local_datasource.dart';
import 'package:quoin/src/features/import/data/datasources/import_file_datasource.dart';
import 'package:quoin/src/features/import/data/datasources/import_local_datasource.dart';
import 'package:quoin/src/features/import/data/repositories/fx_repository_impl.dart';
import 'package:quoin/src/features/import/data/repositories/import_repository_impl.dart';
import 'package:quoin/src/features/import/domain/usecases/ensure_rates.dart';
import 'package:quoin/src/features/import/presentation/providers/import_providers.dart';
import 'package:quoin/src/features/portfolio/data/database/prices_database.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';
import 'package:quoin/src/features/portfolio/data/datasources/portfolio_local_datasource.dart';
import 'package:quoin/src/features/portfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:quoin/src/features/portfolio/presentation/providers/portfolio_providers.dart';
import 'package:quoin/src/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:quoin/src/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:quoin/src/features/settings/presentation/providers/settings_providers.dart';
import 'package:quoin/src/features/sync/domain/usecases/run_effects.dart';

List<Override> dependencies(
  SharedPreferencesWithCache prefs,
  QuoinDatabase database,
  PricesDatabase prices,
) => [
  sharedPreferencesProvider.overrideWithValue(prefs),
  settingsRepositoryProvider.overrideWith(
    (ref) => SettingsRepositoryImpl(ref.watch(settingsLocalDataSourceProvider)),
  ),
  quoinDatabaseProvider.overrideWithValue(database),
  pricesDatabaseProvider.overrideWithValue(prices),
  portfolioRepositoryProvider.overrideWith(
    (ref) =>
        PortfolioRepositoryImpl(ref.watch(portfolioLocalDataSourceProvider)),
  ),
  importRepositoryProvider.overrideWith(
    (ref) => ImportRepositoryImpl(
      ref.watch(importFileDataSourceProvider),
      ref.watch(importLocalDataSourceProvider),
      ref.watch(fxLocalDataSourceProvider),
    ),
  ),
  fxRepositoryProvider.overrideWith(
    (ref) => FxRepositoryImpl(
      ref.watch(ecbRemoteDataSourceProvider),
      ref.watch(fxLocalDataSourceProvider),
    ),
  ),
];

EnsureRatesFrom ratesForSync(EnsureRates ensure, {DateTime Function()? now}) =>
    (needs, {required zone}) async =>
        switch (await ensure(needs, now: (now ?? DateTime.now)(), zone: zone)) {
          Ok(:final value) => Ok(value.unavailable),
          Err(:final failure) => Err(failure),
        };
