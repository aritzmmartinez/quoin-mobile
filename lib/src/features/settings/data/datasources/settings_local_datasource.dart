import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/features/settings/data/models/preferences_model.dart';

const _themeModeKey = 'themeMode';
const _localeKey = 'locale';

const preferenceKeys = {_themeModeKey, _localeKey};

final sharedPreferencesProvider = Provider<SharedPreferencesWithCache>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

final settingsLocalDataSourceProvider = Provider<SettingsLocalDataSource>(
  (ref) => SettingsLocalDataSource(ref.watch(sharedPreferencesProvider)),
);

class SettingsLocalDataSource {
  const SettingsLocalDataSource(this._prefs);

  final SharedPreferencesWithCache _prefs;

  PreferencesModel read() {
    try {
      return PreferencesModel(
        theme: _prefs.getString(_themeModeKey),
        language: _prefs.getString(_localeKey),
      );
    } on Exception catch (e) {
      throw StorageException(e);
    }
  }

  Future<void> writeTheme(String name) =>
      _write(() => _prefs.setString(_themeModeKey, name));

  Future<void> writeLanguage(String? code) => _write(
    () => code == null
        ? _prefs.remove(_localeKey)
        : _prefs.setString(_localeKey, code),
  );

  Future<void> _write(Future<void> Function() body) async {
    try {
      await body();
    } on Exception catch (e) {
      throw StorageException(e);
    }
  }
}
