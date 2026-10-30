import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/app/app.dart';
import 'package:quoin/src/app/dependencies.dart';
import 'package:quoin/src/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:quoin/src/features/settings/presentation/providers/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Future<SharedPreferencesWithCache> pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  SharedPreferencesAsyncPlatform? store,
}) async {
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
        ...dependencies(cache),
        appVersionProvider.overrideWith((ref) => '0.0.0-test'),
      ],
      child: const QuoinApp(),
    ),
  );
  await tester.pumpAndSettle();
  return cache;
}
