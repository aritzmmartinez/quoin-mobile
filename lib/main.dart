import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quoin/src/app/app.dart';
import 'package:quoin/src/app/dependencies.dart';
import 'package:quoin/src/features/settings/data/datasources/settings_local_datasource.dart';

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
  await LiquidGlassWidgets.initialize();
  runApp(
    ProviderScope(
      overrides: dependencies(prefs),
      child: LiquidGlassWidgets.wrap(
        brightnessResolver: Theme.maybeBrightnessOf,
        child: const QuoinApp(),
      ),
    ),
  );
}
