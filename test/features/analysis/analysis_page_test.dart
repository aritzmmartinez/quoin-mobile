import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/ui/atoms/quoin_card.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';
import 'package:quoin/src/ui/organisms/quoin_bottom_bar.dart';

import '../../helpers.dart';

void main() {
  testWidgets('only a tool that opens something has a chevron', (tester) async {
    await pumpApp(tester, prefs: {'locale': 'es'});
    await tester.tap(
      find.descendant(
        of: find.byType(QuoinBottomBar),
        matching: find.text('Análisis'),
      ),
    );
    await tester.pumpAndSettle();

    final chevrons = find.byWidgetPredicate(
      (w) => w is QuoinIcon && w.icon == QuoinIcons.chevronRight,
    );
    expect(chevrons, findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(of: chevrons, matching: find.byType(QuoinCard)),
        matching: find.text('Realizado'),
      ),
      findsOneWidget,
    );
  });
}
