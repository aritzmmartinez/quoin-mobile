import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:quoin/src/app/runtime_packages.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/settings/domain/entities/preferences.dart';
import 'package:quoin/src/features/portfolio/presentation/providers/portfolio_providers.dart';
import 'package:quoin/src/features/settings/domain/repositories/residence_repository.dart';
import 'package:quoin/src/features/settings/domain/repositories/settings_repository.dart';
import 'package:quoin/src/features/settings/domain/usecases/get_residence.dart';
import 'package:quoin/src/features/settings/domain/usecases/get_preferences.dart';
import 'package:quoin/src/features/portfolio/domain/usecases/pull_kraken_prices.dart';
import 'package:quoin/src/features/settings/domain/usecases/set_kraken_prices.dart';
import 'package:quoin/src/features/settings/domain/usecases/set_language.dart';
import 'package:quoin/src/features/settings/domain/usecases/set_residence.dart';
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

final setKrakenPricesProvider = Provider(
  (ref) => SetKrakenPrices(
    ref.watch(settingsRepositoryProvider),
    ref.watch(krakenRepositoryProvider),
  ),
);

final krakenPricesProvider = NotifierProvider<KrakenPricesController, bool>(
  KrakenPricesController.new,
);

class KrakenPricesController extends Notifier<bool> {
  Future<Result<KrakenOutcome>?>? _running;

  @override
  bool build() => switch (ref.watch(getPreferencesProvider)()) {
    Ok(:final value) => value.krakenPrices,
    Err() => false,
  };

  /// Null when the switch is off.
  Future<Result<KrakenOutcome>?> pull() {
    if (!state) return Future.value();
    return _running ??= _pass().whenComplete(() => _running = null);
  }

  Future<Result<KrakenOutcome>?> _pass() async {
    final result = await ref.read(pullKrakenPricesProvider)();
    if (result case Ok(value: KrakenOutcome(updated: > 0)) when ref.mounted) {
      ref.invalidate(ledgerProvider);
    }
    return result;
  }

  Future<Result<void>> set(bool on) async {
    state = on;
    if (!on) await _running;
    final result = await ref.read(setKrakenPricesProvider)(on);
    if (!ref.mounted) return result;
    switch (result) {
      case Err():
        state = !on;
      case Ok() when on:
        unawaited(pull());
      case Ok():
        ref.invalidate(ledgerProvider);
    }
    return result;
  }
}

final residenceRepositoryProvider = Provider<ResidenceRepository>(
  (ref) => throw UnimplementedError('residenceRepositoryProvider not bound'),
);

final getResidenceProvider = Provider(
  (ref) => GetResidence(ref.watch(residenceRepositoryProvider)),
);
final setResidenceProvider = Provider(
  (ref) => SetResidence(ref.watch(residenceRepositoryProvider)),
);

/// The residence as stored. It follows `ledgerProvider` because every write
/// that can change it (a sync, a choice here) invalidates the ledger.
final residenceProvider = FutureProvider<Result<String>>((ref) {
  ref.watch(ledgerProvider);
  return ref.watch(getResidenceProvider)();
});

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

final licensesProvider = FutureProvider<Map<String, List<LicenseEntry>>>(
  (ref) async => runtimeLicenses(await LicenseRegistry.licenses.toList()),
);

Map<String, List<LicenseEntry>> runtimeLicenses(List<LicenseEntry> entries) {
  final byPackage = SplayTreeMap<String, List<LicenseEntry>>(
    (a, b) => switch (a.toLowerCase().compareTo(b.toLowerCase())) {
      0 => a.compareTo(b),
      final order => order,
    },
  );
  for (final entry in entries) {
    for (final package in entry.packages) {
      if (devPackages.contains(package)) continue;
      (byPackage[package] ??= []).add(entry);
    }
  }
  return byPackage;
}
