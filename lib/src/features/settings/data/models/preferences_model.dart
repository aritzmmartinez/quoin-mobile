import 'package:quoin/src/features/settings/domain/entities/preferences.dart';

class PreferencesModel {
  const PreferencesModel({this.theme, this.language});

  final String? theme;
  final String? language;

  Preferences toEntity() => Preferences(
    theme: ThemePreference.values.asNameMap()[theme] ?? ThemePreference.system,
    language:
        LanguagePreference.values.asNameMap()[language] ??
        LanguagePreference.system,
  );
}
