enum ThemePreference { system, light, dark }

enum LanguagePreference { system, es, en }

class Preferences {
  const Preferences({required this.theme, required this.language});

  final ThemePreference theme;
  final LanguagePreference language;
}
