import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/ui/organisms/quoin_bottom_bar.dart';
import 'package:quoin/src/ui/templates/quoin_page.dart';

import 'helpers.dart';

void main() {
  testWidgets('every screen fits at 200 % text size', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpApp(
      tester,
      prefs: {'locale': 'es'},
      database: await sampleDatabase(),
    );

    Future<void> scrollToEnd() async {
      final list = find.descendant(
        of: find.byType(QuoinPage),
        matching: find.byType(Scrollable),
      );
      if (list.evaluate().isEmpty) return;
      for (var i = 0; i < 30; i++) {
        await tester.drag(list.first, const Offset(0, -600));
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    await scrollToEnd();
    for (final tab in ['Cartera', 'Análisis', 'Ajustes']) {
      await tester.tap(
        find.descendant(
          of: find.byType(QuoinBottomBar),
          matching: find.text(tab),
        ),
      );
      await tester.pumpAndSettle();
      await scrollToEnd();
    }

    await tester.tap(find.text('Galería de componentes'));
    await tester.pumpAndSettle();
    await scrollToEnd();

    await tester.tap(find.byTooltip('Importar CSV'));
    await tester.pumpAndSettle();
  });
}
