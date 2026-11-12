import 'dart:io';

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
import 'package:quoin/src/features/sync/data/datasources/device_identity_datasource.dart';
import 'package:quoin/src/features/sync/data/datasources/pairing_local_datasource.dart';
import 'package:quoin/src/features/sync/data/datasources/pc_finder_datasource.dart';
import 'package:quoin/src/features/sync/data/datasources/prices_local_datasource.dart';
import 'package:quoin/src/features/sync/data/datasources/sync_local_datasource.dart';
import 'package:quoin/src/features/sync/data/datasources/sync_remote_datasource.dart';
import 'package:quoin/src/features/sync/data/repositories/sync_repository_impl.dart';
import 'package:quoin/src/features/sync/domain/usecases/run_effects.dart';
import 'package:quoin/src/features/sync/presentation/providers/sync_providers.dart';

List<Override> dependencies(
  SharedPreferencesWithCache prefs,
  QuoinDatabase database,
  PricesDatabase prices,
  Directory support,
) => [
  sharedPreferencesProvider.overrideWithValue(prefs),
  settingsRepositoryProvider.overrideWith(
    (ref) => SettingsRepositoryImpl(ref.watch(settingsLocalDataSourceProvider)),
  ),
  quoinDatabaseProvider.overrideWithValue(database),
  pricesDatabaseProvider.overrideWithValue(prices),
  supportDirectoryProvider.overrideWithValue(support),
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
  syncRepositoryProvider.overrideWith(
    (ref) => SyncRepositoryImpl(
      pairings: ref.watch(pairingLocalDataSourceProvider),
      remote: ref.watch(syncRemoteDataSourceProvider),
      local: ref.watch(syncLocalDataSourceProvider),
      identity: ref.watch(deviceIdentityDataSourceProvider),
      prices: ref.watch(pricesLocalDataSourceProvider),
      finder: ref.watch(pcFinderDataSourceProvider),
    ),
  ),
  ensureRatesFromProvider.overrideWith(
    (ref) => ratesForSync(ref.watch(ensureRatesProvider)),
  ),
];

EnsureRatesFrom ratesForSync(EnsureRates ensure, {DateTime Function()? now}) =>
    (needs, {required zone}) async => switch (await ensure(
      needs,
      now: (now ?? DateTime.now)(),
      zone: zone,
      withBook: false,
    )) {
      Ok(:final value) => Ok(value.unavailable),
      Err(:final failure) => Err(failure),
    };
