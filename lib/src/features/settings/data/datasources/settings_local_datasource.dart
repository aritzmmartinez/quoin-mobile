import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/features/settings/data/models/preferences_model.dart';

const _themeModeKey = 'themeMode';
const _localeKey = 'locale';
const _krakenPricesKey = 'krakenPrices';

const preferenceKeys = {_themeModeKey, _localeKey, _krakenPricesKey};

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
        krakenPrices: _prefs.getBool(_krakenPricesKey),
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

  Future<void> writeKrakenPrices(bool on) =>
      _write(() => _prefs.setBool(_krakenPricesKey, on));

  Future<void> _write(Future<void> Function() body) async {
    try {
      await body();
    } on Exception catch (e) {
      throw StorageException(e);
    }
  }
}
