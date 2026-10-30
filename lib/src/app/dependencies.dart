import 'package:flutter_riverpod/misc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quoin/src/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:quoin/src/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:quoin/src/features/settings/presentation/providers/settings_providers.dart';

List<Override> dependencies(SharedPreferencesWithCache prefs) => [
  sharedPreferencesProvider.overrideWithValue(prefs),
  settingsRepositoryProvider.overrideWith(
    (ref) => SettingsRepositoryImpl(ref.watch(settingsLocalDataSourceProvider)),
  ),
];
