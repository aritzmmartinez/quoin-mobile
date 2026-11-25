import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/import/data/datasources/ecb_remote_datasource.dart';
import 'package:quoin/src/features/portfolio/data/database/prices_database.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';
import 'package:quoin/src/features/portfolio/data/datasources/kraken_remote_datasource.dart';
import 'package:quoin/src/features/portfolio/domain/repositories/kraken_repository.dart';
import 'package:quoin/src/features/settings/domain/entities/preferences.dart';
import 'package:quoin/src/features/settings/domain/repositories/settings_repository.dart';
import 'package:quoin/src/features/settings/domain/usecases/set_kraken_prices.dart';
import 'package:quoin/src/ui/molecules/notice_row.dart';
import 'package:quoin/src/ui/organisms/quoin_bottom_bar.dart';

import '../../helpers.dart';

class _Settings implements SettingsRepository {
  final saved = <bool>[];

  @override
  Result<Preferences> get() => throw UnimplementedError();

  @override
  Future<Result<void>> setTheme(ThemePreference theme) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> setLanguage(LanguagePreference language) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> setKrakenPrices(bool on) async {
    saved.add(on);
    return const Ok(null);
  }
}

class _Kraken implements KrakenRepository {
  var dropped = 0;

  @override
  Future<Result<void>> dropAll() async {
    dropped += 1;
    return const Ok(null);
  }

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<(QuoinDatabase, PricesDatabase)> cryptoWithoutPrice() async {
  final db = memoryDatabase();
  await db
      .into(db.instrument)
      .insert(
        InstrumentCompanion.insert(
          id: 'TESTCOIN',
          name: 'Moneda Prueba',
          type: 'CRYPTO',
          createdAt: testNow,
        ),
      );
  await db
      .into(db.ledgerEntry)
      .insert(
        LedgerEntryCompanion.insert(
          id: 'row-1',
          ts: DateTime.utc(2026, 10, 1, 9),
          type: 'BUY',
          instrumentId: const Value('TESTCOIN'),
          quantity: const Value('2'),
          price: const Value('50'),
          grossAmount: '100',
          currency: 'EUR',
          createdAt: testNow,
        ),
      );
  return (db, memoryPrices());
}

void main() {
  test(
    'turning off deletes the Kraken series; turning on deletes nothing',
    () async {
      final settings = _Settings();
      final kraken = _Kraken();
      final set = SetKrakenPrices(settings, kraken);

      expect(await set(true), isA<Ok<void>>());
      expect(kraken.dropped, 0);
      expect(await set(false), isA<Ok<void>>());
      expect(kraken.dropped, 1);
      expect(settings.saved, [true, false]);
    },
  );

  testWidgets('a crypto without a price invites to turn Kraken on, which '
      'says first what Kraken sees', (tester) async {
    final (db, prices) = await cryptoWithoutPrice();
    final asked = <Uri>[];
    final cache = await pumpApp(
      tester,
      prefs: {'locale': 'es'},
      database: db,
      prices: prices,
      overrides: [
        httpClientProvider.overrideWithValue(
          MockClient((request) async {
            asked.add(request.url);
            return http.Response(
              jsonEncode({
                'error': ['EQuery:Unknown asset pair'],
              }),
              200,
            );
          }),
        ),
      ],
    );
    expect(asked, isEmpty);

    await tester.tap(
      find.descendant(
        of: find.byType(QuoinBottomBar),
        matching: find.text('Cartera'),
      ),
    );
    await tester.pumpAndSettle();
    final invite = find.widgetWithText(
      NoticeRow,
      'Criptos sin precio: el '
      'móvil puede pedirlo a Kraken.',
    );
    expect(invite, findsOneWidget);

    await tester.tap(invite);
    await tester.pumpAndSettle();
    expect(find.text('Precios de cripto desde Kraken'), findsOneWidget);
    expect(find.textContaining('Kraken ve la dirección IP'), findsOneWidget);
    expect(find.text('Market Data: Kraken'), findsOneWidget);

    await tester.tap(find.text('Activar').last);
    // Kraken's queue waits a second between the two requests.
    await tester.pump(krakenSpacing);
    await tester.pumpAndSettle();
    expect(cache.getBool('krakenPrices'), isTrue);
    expect(invite, findsNothing);
    expect(asked.map((u) => u.queryParameters['pair']).toSet(), {
      'TESTCOIN/EUR',
    });

    await db.close();
    await prices.close();
  });

  testWidgets('settings says whether it is on and turns it off', (
    tester,
  ) async {
    final cache = await pumpApp(
      tester,
      prefs: {'locale': 'es', 'krakenPrices': true},
    );
    await tester.tap(
      find.descendant(
        of: find.byType(QuoinBottomBar),
        matching: find.text('Ajustes'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Precios de cripto'), findsOneWidget);
    expect(find.text('Activados'), findsOneWidget);

    await tester.tap(find.text('Precios de cripto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desactivar'));
    await tester.pumpAndSettle();

    expect(cache.getBool('krakenPrices'), isFalse);
    expect(find.text('Desactivados'), findsOneWidget);
  });
}
