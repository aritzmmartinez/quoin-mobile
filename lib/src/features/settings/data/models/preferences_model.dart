import 'package:quoin/src/features/settings/domain/entities/preferences.dart';

class PreferencesModel {
  const PreferencesModel({this.theme, this.language, this.krakenPrices});

  final String? theme;
  final String? language;
  final bool? krakenPrices;

  Preferences toEntity() => Preferences(
    theme: ThemePreference.values.asNameMap()[theme] ?? ThemePreference.system,
    language:
        LanguagePreference.values.asNameMap()[language] ??
        LanguagePreference.system,
    krakenPrices: krakenPrices ?? false,
  );
}
