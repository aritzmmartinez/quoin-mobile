import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quoin/src/app/app.dart';
import 'package:quoin/src/app/dependencies.dart';
import 'package:quoin/src/app/licenses.dart';
import 'package:quoin/src/features/portfolio/data/database/prices_database.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';
import 'package:quoin/src/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:quoin/src/features/sync/data/datasources/device_identity_datasource.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerLicenses();
  final prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: preferenceKeys,
    ),
  );
  final database = QuoinDatabase.open();
  final support = await getApplicationSupportDirectory();
  try {
    await DeviceIdentityDataSource(database, support).claim();
  } on Exception {
    // The app opens all the same; the next start tries again.
  }
  await LiquidGlassWidgets.initialize();
  runApp(
    ProviderScope(
      overrides: dependencies(prefs, database, PricesDatabase.open(), support),
      child: LiquidGlassWidgets.wrap(
        brightnessResolver: Theme.maybeBrightnessOf,
        child: const QuoinApp(),
      ),
    ),
  );
}
