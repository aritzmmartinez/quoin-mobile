import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_theme.dart';
import 'package:quoin/src/features/portfolio/domain/entities/movement.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/ledger_tiles.dart';
import 'package:quoin/src/ui/molecules/movement_row.dart';
import 'package:quoin_core/quoin_core.dart';

Movement _reward(String amount) => Movement(
  id: amount,
  ts: DateTime.utc(2026, 11, 2, 9),
  type: 'DIVIDEND',
  inKind: true,
  swapRoute: null,
  instrumentId: 'TESTCOIN',
  instrumentName: 'Moneda Prueba',
  instrumentType: 'CRYPTO',
  quantity: Dec.parse('0.0000001'),
  amount: Money.parse(amount),
  currency: 'EUR',
  converted: false,
);

void main() {
  Future<MovementRow> row(WidgetTester tester, String amount) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: quoinLightTheme,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) =>
                movementTile(context, _reward(amount), 'Europe/Madrid'),
          ),
        ),
      ),
    );
    return tester.widget<MovementRow>(find.byType(MovementRow));
  }

  testWidgets('a reward that rounds to nothing reads «< 0,01 €», muted', (
    tester,
  ) async {
    final tiny = await row(tester, '0.003');
    expect(tiny.amount, '< 0,01 €');
    expect(tiny.quiet, isTrue);
  });

  testWidgets('the exact zero and a cent are written as they are', (
    tester,
  ) async {
    final zero = await row(tester, '0');
    expect(zero.amount, '0,00 €');
    expect(zero.quiet, isFalse);

    final cent = await row(tester, '0.005');
    expect(cent.amount, '+0,01 €');
  });
}
