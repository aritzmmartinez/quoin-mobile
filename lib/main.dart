import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quoin/src/app/app.dart';
import 'package:quoin/src/app/dependencies.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';
import 'package:quoin/src/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:quoin/src/features/sync/data/datasources/device_identity_datasource.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'Geist',
      'Geist Mono',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  final prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: preferenceKeys,
    ),
  );
  final database = QuoinDatabase.open();
  try {
    await DeviceIdentityDataSource(
      database,
      await getApplicationSupportDirectory(),
    ).claim();
  } on Exception {
    // The app opens all the same; the next start tries again.
  }
  await LiquidGlassWidgets.initialize();
  runApp(
    ProviderScope(
      overrides: dependencies(prefs, database),
      child: LiquidGlassWidgets.wrap(
        brightnessResolver: Theme.maybeBrightnessOf,
        child: const QuoinApp(),
      ),
    ),
  );
}
