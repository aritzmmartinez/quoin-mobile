import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/app/app.dart';
import 'package:quoin/src/app/dependencies.dart';
import 'package:quoin/src/features/portfolio/data/database/prices_database.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';
import 'package:quoin/src/features/portfolio/data/datasources/portfolio_local_datasource.dart';
import 'package:quoin/src/features/portfolio/presentation/providers/portfolio_providers.dart';
import 'package:quoin/src/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:quoin/src/features/settings/presentation/providers/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Future<SharedPreferencesWithCache> pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  SharedPreferencesAsyncPlatform? store,
  QuoinDatabase? database,
  PricesDatabase? prices,
  bool sample = false,
  List<Override> overrides = const [],
}) async {
  if (sample) (:database, :prices) = await sampleStores();
  SharedPreferencesAsyncPlatform.instance =
      store ?? InMemorySharedPreferencesAsync.withData(prefs);
  final cache = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: preferenceKeys,
    ),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...dependencies(
          cache,
          database ?? memoryDatabase(),
          prices ?? memoryPrices(),
          Directory.systemTemp.createTempSync('quoin-test-'),
        ),
        appVersionProvider.overrideWith((ref) => '0.0.0-test'),
        nowProvider.overrideWithValue(() => testNow),
        ...overrides,
      ],
      child: const QuoinApp(),
    ),
  );
  await tester.pumpAndSettle();
  return cache;
}

final testNow = DateTime.utc(2026, 10, 30, 10);

QuoinDatabase memoryDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return QuoinDatabase(NativeDatabase.memory());
}

PricesDatabase memoryPrices() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return PricesDatabase(NativeDatabase.memory());
}

Future<({QuoinDatabase database, PricesDatabase prices})> sampleStores() async {
  final stores = (database: memoryDatabase(), prices: memoryPrices());
  await PortfolioLocalDataSource(
    stores.database,
    stores.prices,
  ).replaceWithSample(testNow);
  return stores;
}
