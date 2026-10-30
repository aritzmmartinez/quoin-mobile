import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/settings/domain/entities/preferences.dart';
import 'package:quoin/src/features/settings/domain/repositories/settings_repository.dart';
import 'package:quoin/src/features/settings/domain/usecases/get_preferences.dart';
import 'package:quoin/src/features/settings/domain/usecases/set_language.dart';
import 'package:quoin/src/features/settings/domain/usecases/set_theme.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => throw UnimplementedError('settingsRepositoryProvider not bound'),
);

final getPreferencesProvider = Provider(
  (ref) => GetPreferences(ref.watch(settingsRepositoryProvider)),
);
final setThemeProvider = Provider(
  (ref) => SetTheme(ref.watch(settingsRepositoryProvider)),
);
final setLanguageProvider = Provider(
  (ref) => SetLanguage(ref.watch(settingsRepositoryProvider)),
);

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => switch (ref.watch(getPreferencesProvider)()) {
    Ok(:final value) => ThemeMode.values.byName(value.theme.name),
    Err() => ThemeMode.system,
  };

  Future<Result<void>> set(ThemeMode mode) {
    state = mode;
    return ref.read(setThemeProvider)(ThemePreference.values.byName(mode.name));
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() => switch (ref.watch(getPreferencesProvider)()) {
    Ok(value: Preferences(language: LanguagePreference.system)) => null,
    Ok(:final value) => Locale(value.language.name),
    Err() => null,
  };

  Future<Result<void>> set(Locale? locale) {
    state = locale;
    return ref.read(setLanguageProvider)(
      locale == null
          ? LanguagePreference.system
          : LanguagePreference.values.byName(locale.languageCode),
    );
  }
}

final appVersionProvider = FutureProvider<String>(
  (ref) async => (await PackageInfo.fromPlatform()).version,
);
