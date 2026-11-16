import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_theme.dart';
import 'package:quoin/src/ui/molecules/settings_row.dart';
import 'package:quoin/src/ui/organisms/settings_section.dart';

const _long =
    'Última: 10 mar 2026 10:41 · 5 movimientos, 3 instrumentos, 1 objetivo, '
    '1 conflicto resuelto, 1 apartado';

Future<void> _pump(WidgetTester tester, Widget child, {double scale = 1}) {
  tester.view.physicalSize = const Size(360 * 3, 800 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    MaterialApp(
      theme: quoinDarkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Scaffold(body: ListView(children: [child])),
      ),
    ),
  );
}

void main() {
  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('a long state under the label fits at $scale', (tester) async {
      await _pump(
        tester,
        SettingsRow(
          icon: QuoinIcons.computer,
          label: 'Sobremesa',
          subtitle: _long,
          onTap: () {},
        ),
        scale: scale,
      );
      expect(tester.takeException(), isNull);
      // The name keeps its line: the state wraps under it, not beside it.
      final name = tester.getSize(find.text('Sobremesa'));
      final state = tester.getSize(find.text(_long));
      expect(name.height, lessThan(state.height));
    });

    testWidgets('a long value ends in an ellipsis at $scale', (tester) async {
      await _pump(
        tester,
        const SettingsRow(icon: QuoinIcons.theme, label: 'Tema', value: _long),
        scale: scale,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a section heading is its own node, not part of a row', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      SettingsSection(
        title: 'Acerca de',
        rows: [
          const SettingsRow(icon: QuoinIcons.version, label: 'Versión'),
          SettingsRow(
            icon: QuoinIcons.thirdPartyLicenses,
            label: 'Licencias de terceros',
            onTap: () {},
          ),
        ],
      ),
    );
    final row = tester.getSemantics(find.text('Licencias de terceros'));
    expect(row.label, isNot(contains('ACERCA DE')));
    expect(row.flagsCollection.isButton, isTrue);
    expect(
      tester.getSemantics(find.text('ACERCA DE')).flagsCollection.isHeader,
      isTrue,
    );
    semantics.dispose();
  });
}
