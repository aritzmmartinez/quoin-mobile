import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/features/import/presentation/pages/import_page.dart';
import 'package:quoin/src/ui/organisms/quoin_bottom_bar.dart';
import 'package:quoin/src/ui/templates/quoin_page.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/types.dart';

import 'helpers.dart';

Finder _pageTitle(String title) =>
    find.descendant(of: find.byType(QuoinPage), matching: find.text(title));

Finder _tab(String label) => find.descendant(
  of: find.byType(QuoinBottomBar),
  matching: find.text(label),
);

void main() {
  const tabs = {
    'es': ['Inicio', 'Cartera', 'Análisis', 'Ajustes'],
    'en': ['Home', 'Portfolio', 'Analysis', 'Settings'],
  };

  for (final MapEntry(key: locale, value: titles) in tabs.entries) {
    testWidgets('starts in $locale and every tab shows its title', (
      tester,
    ) async {
      await pumpApp(tester, prefs: {'locale': locale});

      expect(_pageTitle(titles.first), findsOneWidget);
      for (final title in [...titles.skip(1), titles.first]) {
        await tester.tap(_tab(title));
        await tester.pumpAndSettle();
        expect(_pageTitle(title), findsOneWidget);
      }
    });
  }

  testWidgets('falls back to Spanish for an unsupported system language', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await pumpApp(tester);
    expect(_pageTitle('Inicio'), findsOneWidget);
  });

  testWidgets('the add button opens the import screen', (tester) async {
    await pumpApp(tester, prefs: {'locale': 'es'});
    await tester.tap(find.byTooltip('Importar CSV'));
    await tester.pumpAndSettle();
    expect(find.byType(ImportPage), findsOneWidget);
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('builds the ${mode.name} theme', (tester) async {
      await pumpApp(tester, prefs: {'themeMode': mode.name});
      final context = tester.element(find.byType(QuoinPage));
      final expected = mode == ThemeMode.light
          ? QuoinColors.light
          : QuoinColors.dark;
      expect(Theme.of(context).brightness.name, mode.name);
      expect(QuoinColors.of(context).bg, expected.bg);
    });
  }

  testWidgets('choosing a theme in Settings applies and stores it', (
    tester,
  ) async {
    final prefs = await pumpApp(
      tester,
      prefs: {'locale': 'es', 'themeMode': 'light'},
    );
    await tester.tap(_tab('Ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tema'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();

    expect(prefs.getString('themeMode'), 'dark');
    expect(
      Theme.of(tester.element(find.byType(QuoinPage))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('choosing a language in Settings applies and stores it', (
    tester,
  ) async {
    final prefs = await pumpApp(tester, prefs: {'locale': 'es'});
    await tester.tap(_tab('Ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Idioma'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(prefs.getString('locale'), 'en');
    expect(_pageTitle('Settings'), findsOneWidget);
  });

  testWidgets('a preference that fails to save warns and still applies', (
    tester,
  ) async {
    await pumpApp(tester, store: _ReadOnlyStore({'locale': 'es'}));
    await tester.tap(_tab('Ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tema'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();

    expect(find.text('No se ha podido guardar el ajuste'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(QuoinPage))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('the debug component gallery opens from Settings', (
    tester,
  ) async {
    await pumpApp(tester, prefs: {'locale': 'es'});
    await tester.tap(_tab('Ajustes'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Galería de componentes'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Galería de componentes'));
    await tester.pumpAndSettle();
    expect(_pageTitle('Galería de componentes'), findsOneWidget);
    expect(find.byType(QuoinBottomBar), findsOneWidget);
  });
}

final class _ReadOnlyStore extends InMemorySharedPreferencesAsync {
  _ReadOnlyStore(super.data) : super.withData();

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) async => throw Exception('read-only');

  @override
  Future<bool> clear(
    ClearPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) async => throw Exception('read-only');
}
