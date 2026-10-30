import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/settings/domain/entities/preferences.dart';

abstract interface class SettingsRepository {
  Result<Preferences> get();

  Future<Result<void>> setTheme(ThemePreference theme);

  Future<Result<void>> setLanguage(LanguagePreference language);
}
