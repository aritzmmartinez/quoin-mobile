import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart'
    hide SettingsRow;
import 'package:quoin/src/features/sync/data/datasources/sync_remote_datasource.dart';
import 'package:quoin/src/features/sync/domain/usecases/pull_prices.dart';
import 'package:quoin/src/features/sync/presentation/providers/sync_providers.dart';
import 'package:quoin/src/ui/molecules/settings_row.dart';
import 'package:quoin/src/ui/organisms/quoin_bottom_bar.dart';
import 'package:quoin/src/ui/templates/quoin_page.dart';
import 'package:quoin_core/quoin_core.dart';

import '../../helpers.dart';
import 'fake_pc.dart';

const pcFund = 'XX00TEST0002';
const phoneFund = 'XX00TEST0001';

void main() {
  late FakePc pc;
  late QuoinDatabase db;

  setUp(() {
    db = memoryDatabase();
    pc = FakePc(
      const SyncState(
        deviceId: 'dev-pc',
        instruments: [
          InstrumentRecord(
            id: pcFund,
            name: 'PC Fund',
            type: 'ETF',
            quoteSymbol: 'PCF.DE',
            quoteSymbolHlc: '001761600000000-0000-dev-pc',
          ),
        ],
        settings: SettingsRecord(residence: 'bizkaia'),
      ),
    );
    fakeQr = jsonEncode({
      'v': 1,
      'host': 'pc.test',
      'port': 3443,
      'sha256': 'ab' * 32,
      'token': FakePc.qrToken,
      'name': 'Test PC',
    });
  });

  Future<void> open(WidgetTester tester) async {
    await pumpApp(
      tester,
      prefs: {'locale': 'es'},
      database: db,
      overrides: [
        syncRemoteDataSourceProvider.overrideWithValue(
          SyncRemoteDataSource(clientFor: (_) => pc.client, wait: (_) async {}),
        ),
        pullPricesProvider.overrideWith(
          (ref) => PullPrices(
            ref.watch(syncRepositoryProvider),
            ref.watch(ensureRatesFromProvider),
            wait: (_) async {},
          ),
        ),
      ],
    );
    await tester.tap(
      find.descendant(
        of: find.byType(QuoinBottomBar),
        matching: find.text('Ajustes'),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 200; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
      if (i > 5 &&
          find.byType(CircularProgressIndicator).evaluate().isEmpty &&
          find.textContaining('Actualizando precios').evaluate().isEmpty) {
        break;
      }
    }
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find
          .descendant(
            of: find.byType(QuoinPage),
            matching: find.byType(Scrollable),
          )
          .last,
    );
    await tester.tap(finder);
    await settle(tester);
  }

  Future<void> openRow(WidgetTester tester, String label) async {
    tester
        .widget<SettingsRow>(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(SettingsRow),
          ),
        )
        .onTap!();
    await tester.pumpAndSettle();
  }

  Future<void> pairFromSettings(WidgetTester tester) async {
    await tapVisible(tester, find.text('Vincular con tu PC'));
    expect(
      find.text('Comprueba que tu PC muestra este código'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextField, 'Mi móvil'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Móvil de prueba');
    await tester.tap(find.text('Vincular'));
    await settle(tester);
  }

  testWidgets('pairs, previews the first sync, then syncs on confirmation', (
    tester,
  ) async {
    await db
        .into(db.instrument)
        .insert(
          InstrumentCompanion.insert(
            id: phoneFund,
            name: 'Phone Fund',
            type: 'ETF',
            createdAt: DateTime.utc(2026, 1, 5),
          ),
        );
    await open(tester);
    await pairFromSettings(tester);

    expect(
      (pc.bodies['POST /v1/pair']!.single! as Map<String, Object?>)['name'],
      'Móvil de prueba',
    );
    expect(find.text('Del PC a este móvil'.toUpperCase()), findsOneWidget);
    expect(find.text('1 instrumento nuevo o cambiado'), findsNWidgets(2));
    expect(pc.log, isNot(contains('POST /v1/sync')));

    await tester.tap(find.text('Sincronizar'));
    await settle(tester);

    expect(find.text('Sincronizado'), findsOneWidget);
    expect(pc.log, contains('POST /v1/sync'));
    expect([for (final i in pc.device.state.instruments) i.id]..sort(), [
      phoneFund,
      pcFund,
    ]);

    await tester.tap(find.byTooltip('Atrás'));
    await settle(tester);
    expect(find.text('Test PC'), findsOneWidget);
    expect(find.textContaining('Última: '), findsOneWidget);
  });

  testWidgets('says when prices are still pending on the PC', (tester) async {
    pc.prices[pcFund] = List.filled(growable: true, 4, {
      'instrumentId': pcFund,
      'kind': 'pending',
    });
    await open(tester);
    await pairFromSettings(tester);
    await tester.tap(find.text('Sincronizar'));
    await settle(tester);

    expect(
      find.text(
        'Precios pendientes; se completarán en la próxima sincronización',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a conflict is settled by choosing a side', (tester) async {
    await open(tester);
    await pairFromSettings(tester);
    await tester.tap(find.text('Sincronizar'));
    await settle(tester);
    await tester.tap(find.byTooltip('Atrás'));
    await settle(tester);

    final fund = await (db.select(
      db.instrument,
    )..where((i) => i.id.equals(pcFund))).getSingle();
    final device = await db.select(db.syncDevice).getSingle();
    await (db.update(db.instrument)..where((i) => i.id.equals(pcFund))).write(
      InstrumentCompanion(
        ter: const Value('0.0020'),
        terHlc: Value(
          // After the phone's own export marks, which run on the real clock.
          '${(DateTime.now().millisecondsSinceEpoch + 3600000).toString().padLeft(15, '0')}'
          '-0000-${device.deviceId}',
        ),
      ),
    );
    final state = pc.device.state;
    pc.device = LocalDevice(
      state: SyncState(
        deviceId: state.deviceId,
        peers: state.peers,
        instruments: [
          for (final i in state.instruments)
            i.id == pcFund
                ? InstrumentRecord.fromJson({
                    ...i.toJson(),
                    'ter': '0.0030',
                    'terHlc': '001761600200000-0000-dev-pc',
                  })
                : i,
        ],
        settings: state.settings,
      ),
      lastHlc: '001761600200000-0000-dev-pc',
    );
    expect(fund.ter, isNull);

    await tapVisible(tester, find.text('Sincronizar ahora'));
    expect(find.text('TER'), findsOneWidget);
    expect(find.text('Este móvil: 0.0020'), findsOneWidget);
    expect(find.text('PC: 0.0030'), findsOneWidget);
    final apply = find.widgetWithText(FilledButton, 'Aplicar y sincronizar');
    expect(tester.widget<FilledButton>(apply).onPressed, isNull);

    await tester.tap(find.text('PC').last);
    await tester.pumpAndSettle();
    await tester.tap(apply);
    await settle(tester);

    expect(find.text('Sincronizado'), findsOneWidget);
    final settled = await (db.select(
      db.instrument,
    )..where((i) => i.id.equals(pcFund))).getSingle();
    expect(settled.ter, '0.0030');
  });

  testWidgets('a PC that shares its identity says so, at 200 % too, and '
      'unpairing says to revoke on the PC as well', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(tester, prefs: {'locale': 'es'}, database: db);
    Map<String, Object?> pc(String sha, String name, {bool shared = false}) => {
      'host': 'pc.test',
      'port': 3443,
      'sha256': sha,
      'token': FakePc.deviceToken,
      'pcName': name,
      'pairedAt': '2026-11-01T09:00:00.000Z',
      'lastSyncAt': null,
      'confirmed': true,
      'pcDeviceId': 'dev-pc',
      'shared': shared,
    };
    await const FlutterSecureStorage().write(
      key: 'pairings',
      value: jsonEncode({
        'pcs': [
          pc('ab' * 32, 'Test PC'),
          pc('cd' * 32, 'Copia PC', shared: true),
        ],
        'pricesFrom': null,
      }),
    );
    ProviderScope.containerOf(tester.element(find.byType(QuoinBottomBar)))
        .invalidate(pairingsProvider);
    await tester.tap(
      find.descendant(
        of: find.byType(QuoinBottomBar),
        matching: find.text('Ajustes'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Copia PC'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(QuoinPage),
            matching: find.byType(Scrollable),
          )
          .last,
    );
    expect(find.text('Comparte identidad con Test PC'), findsOneWidget);
    await openRow(tester, 'Copia PC');
    expect(
      find.textContaining('la misma identidad de sincronización'),
      findsOneWidget,
    );
    expect(find.text('Comprobar de nuevo'), findsOneWidget);

    await openRow(tester, 'Desvincular');
    expect(find.textContaining('revócalo también'), findsOneWidget);
  });

  testWidgets('a PC that cannot be found is shown in Settings with the way '
      'out', (tester) async {
    await open(tester);
    await pairFromSettings(tester);
    await tester.tap(find.text('Sincronizar'));
    await settle(tester);
    await tester.tap(find.byTooltip('Atrás'));
    await settle(tester);

    pc.offline = true;
    await tapVisible(tester, find.text('Sincronizar ahora'));
    expect(find.textContaining('No encuentro tu Quoin'), findsOneWidget);
    expect(find.textContaining('misma Wi‑Fi'), findsOneWidget);
    expect(find.text('Volver a escanear'), findsOneWidget);

    await tester.tap(find.byTooltip('Atrás'));
    await settle(tester);
    expect(find.text('No encuentro tu Quoin'), findsOneWidget);
    await openRow(tester, 'Test PC');
    expect(find.text('Volver a escanear'), findsOneWidget);
    expect(find.text('Desvincular'), findsOneWidget);
  });
}
