import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/ui/organisms/quoin_bottom_bar.dart';
import 'package:quoin/src/ui/organisms/quoin_segmented_pages.dart';

import '../../helpers.dart';

void main() {
  testWidgets('a tap two views away jumps: the middle view never shows', (
    tester,
  ) async {
    await pumpApp(tester, prefs: {'locale': 'es'});
    await tester.tap(
      find.descendant(
        of: find.byType(QuoinBottomBar),
        matching: find.text('Ajustes'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(verticalLists.first, const Offset(0, -2000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Galería de componentes'));
    await tester.pumpAndSettle();
    final demo = find.byType(QuoinSegmentedPages<int>);
    await tester.scrollUntilVisible(
      demo,
      300,
      scrollable: verticalLists.first,
    );
    await tester.ensureVisible(demo);
    await tester.pumpAndSettle();
    Finder inDemo(String text) =>
        find.descendant(of: demo, matching: find.text(text));
    expect(inDemo('Resultado'), findsOneWidget);

    final views = find
        .descendant(of: demo, matching: find.byType(PageView))
        .first;
    double view() => tester.widget<PageView>(views).controller!.page!;
    await tester.tap(inDemo('Resumen'));
    do {
      await tester.pump(const Duration(milliseconds: 16));
      expect(inDemo('Base'), findsNothing);
      expect(view(), anyOf(0, 2));
    } while (tester.binding.hasScheduledFrame);
    expect(view(), 2);
    expect(inDemo('Coste'), findsOneWidget);
  });
}
