import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/features/portfolio/presentation/pages/instrument_page.dart';
import 'package:quoin/src/features/portfolio/presentation/pages/portfolio_page.dart';
import 'package:quoin/src/features/tax/presentation/pages/realized_page.dart';
import 'package:quoin/src/ui/molecules/allocation_bar.dart';
import 'package:quoin/src/ui/molecules/group_header.dart';
import 'package:quoin/src/ui/molecules/notice_row.dart';
import 'package:quoin/src/ui/molecules/position_row.dart';
import 'package:quoin/src/ui/molecules/quoin_segmented.dart';
import 'package:quoin/src/ui/molecules/stat_tile.dart';
import 'package:quoin/src/ui/organisms/quoin_bottom_bar.dart';

import '../../helpers.dart';

void main() {
  testWidgets('home shows the total, one notice, the allocation and the top '
      'four', (tester) async {
    await pumpApp(tester, prefs: {'locale': 'es'}, sample: true);

    expect(find.text('Patrimonio'), findsOneWidget);
    expect(find.textContaining('desde el inicio'), findsOneWidget);
    expect(find.byType(NoticeRow), findsOneWidget);
    expect(find.text('2 posiciones sin precio'), findsOneWidget);
    expect(find.byType(AllocationBar), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(AllocationBar)).label,
      contains('Sin clasificar'),
    );

    await tester.ensureVisible(find.text('Ver cartera'));
    await tester.pumpAndSettle();
    expect(find.byType(PositionRow), findsNWidgets(4));
    expect(find.textContaining('de la cartera'), findsNWidgets(4));
    await tester.tap(find.text('Ver cartera'));
    await tester.pumpAndSettle();
    expect(find.byType(PortfolioPage), findsOneWidget);
  });

  testWidgets('the notice lists what the total leaves out and why', (
    tester,
  ) async {
    await pumpApp(tester, prefs: {'locale': 'es'}, sample: true);
    await tester.tap(find.byType(NoticeRow));
    await tester.pumpAndSettle();
    expect(find.text('Fuera del total'), findsOneWidget);
    expect(find.text('Sin tipo de cambio reciente del USD'), findsOneWidget);
    expect(find.text('Sin precio de mercado'), findsOneWidget);
    await tester.tap(find.text('Fondo Emergentes'));
    await tester.pumpAndSettle();
    expect(find.byType(InstrumentPage), findsOneWidget);
  });

  testWidgets('the tax tile opens Realized on its tax view', (tester) async {
    await pumpApp(tester, prefs: {'locale': 'es'}, sample: true);
    final tile = find.widgetWithText(StatTile, 'Impuesto estimado 2026');
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.byType(RealizedPage), findsOneWidget);
    expect(
      tester
          .widget<QuoinSegmented<int>>(find.byType(QuoinSegmented<int>))
          .selected,
      1,
    );
  });

  testWidgets('portfolio filters by category and names the unpriced', (
    tester,
  ) async {
    await pumpApp(tester, prefs: {'locale': 'es'}, sample: true);
    await tester.tap(
      find.descendant(
        of: find.byType(QuoinBottomBar),
        matching: find.text('Cartera'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(GroupHeader, 'Cripto'), findsOneWidget);
    expect(find.textContaining('participaciones'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Sin precio').first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Sin precio'), findsWidgets);
    expect(find.textContaining('coste'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Todas las categorías'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text('Todas las categorías'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cripto').last);
    await tester.pumpAndSettle();
    expect(find.byType(PositionRow), findsNWidgets(3));
    expect(find.byType(GroupHeader), findsNothing);

    await tester.tap(find.text('Por valor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alfabético'));
    await tester.pumpAndSettle();
    final names = tester
        .widgetList<PositionRow>(find.byType(PositionRow))
        .map((row) => row.name);
    expect(names, [
      'Cripto Ejemplo ETP Físico',
      'Moneda Ejemplo',
      'Token Ejemplo',
    ]);
  });

  test('a notice closes its sentence once', () {
    for (final locale in const [Locale('es'), Locale('en')]) {
      final l10n = lookupAppLocalizations(locale);
      expect(l10n.fxUnconvertible('Acme', 'none'), endsWith(': Acme.'));
      expect(
        l10n.fxUnconvertible('Acme, Tesla Inc.', 'dot'),
        endsWith(': Acme, Tesla Inc.'),
      );
    }
  });

  testWidgets('with nothing imported both screens show the empty state', (
    tester,
  ) async {
    await pumpApp(tester, prefs: {'locale': 'es'});
    expect(find.text('Sin posiciones todavía'), findsOneWidget);
    expect(find.text('Patrimonio'), findsNothing);
  });
}
