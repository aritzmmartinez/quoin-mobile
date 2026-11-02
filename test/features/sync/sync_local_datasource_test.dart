import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';
import 'package:quoin/src/features/sync/data/datasources/sync_local_datasource.dart';
import 'package:quoin_core/quoin_core.dart';

import '../../helpers.dart';

final at = DateTime.utc(2026, 1, 5, 9);

/// Invented rows in every table sync carries.
Future<void> fill(QuoinDatabase db) async {
  await db.batch((b) {
    b
      ..insertAll(db.instrument, [
        InstrumentCompanion.insert(
          id: 'XX00TEST0002',
          name: 'Test Stock',
          type: 'STOCK',
          createdAt: at,
        ),
        InstrumentCompanion.insert(
          id: 'XX00TEST0001',
          name: 'Test World ETF',
          type: 'ETF',
          ter: const Value('0.0022'),
          terHlc: const Value('001761599940000-0000-dev-z'),
          createdAt: at,
        ),
      ])
      ..insertAll(db.ledgerEntry, [
        LedgerEntryCompanion.insert(
          id: 'row-2',
          ts: DateTime.utc(2026, 3, 31, 22, 30, 0, 0, 123),
          type: 'BUY',
          instrumentId: const Value('XX00TEST0002'),
          quantity: const Value('2'),
          price: const Value('110.50'),
          grossAmount: '221.00',
          currency: 'USD',
          fxSource: const Value('ECB'),
          fxDate: const Value('2026-03-31'),
          fxRate: const Value('1.1525'),
          fxDirection: const Value('QUOTE_PER_BASE'),
          source: const Value('TR_CSV'),
          externalId: const Value('t-2'),
          createdAt: at,
        ),
        LedgerEntryCompanion.insert(
          id: 'row-1',
          ts: at,
          type: 'BUY',
          instrumentId: const Value('XX00TEST0001'),
          quantity: const Value('1.50'),
          price: const Value('100.10'),
          grossAmount: '150.150',
          currency: 'EUR',
          source: const Value('TR_CSV'),
          externalId: const Value('t-1'),
          createdAt: at,
        ),
      ])
      ..insert(
        db.portfolioTarget,
        PortfolioTargetCompanion.insert(
          id: 'target-1',
          name: 'Plan',
          activeFrom: const Value('2026-01-01'),
          createdAt: at,
        ),
      )
      ..insertAll(db.portfolioTargetLine, [
        PortfolioTargetLineCompanion.insert(
          id: 'line-2',
          targetId: 'target-1',
          instrumentId: 'XX00TEST0002',
          monthlyAmount: '100',
        ),
        PortfolioTargetLineCompanion.insert(
          id: 'line-1',
          targetId: 'target-1',
          instrumentId: 'XX00TEST0001',
          monthlyAmount: '300.00',
        ),
      ])
      ..insert(
        db.syncTombstone,
        SyncTombstoneCompanion.insert(
          entity: targetEntity,
          key: 'target-0',
          hlc: '001761600000000-0000-dev-z',
        ),
      )
      ..insert(
        db.etfHoldingBlock,
        EtfHoldingBlockCompanion.insert(
          instrumentId: 'XX00TEST0001',
          asOf: '2026-09-30',
        ),
      )
      ..insertAll(db.etfHolding, [
        EtfHoldingCompanion.insert(
          id: 'h-2',
          instrumentId: 'XX00TEST0001',
          identity: 'US00TEST0101',
          identityKind: 'ISIN',
          name: 'Alpha Corp',
          weight: '0.60',
          createdAt: at,
        ),
        EtfHoldingCompanion.insert(
          id: 'h-1',
          instrumentId: 'XX00TEST0001',
          identity: 'BETA.US',
          identityKind: 'TICKER',
          name: 'Beta Inc',
          weight: '0.4',
          createdAt: at,
        ),
      ])
      ..insert(
        db.securityIdentity,
        SecurityIdentityCompanion.insert(
          identity: 'US00TEST0101',
          identityKind: 'ISIN',
          status: 'resolved',
          source: 'OPENFIGI',
          resolvedAt: at,
        ),
      )
      ..insert(
        db.syncPeer,
        SyncPeerCompanion.insert(
          deviceId: 'dev-z',
          seen: '001761600000000-0000-dev-z',
        ),
      );
  });
}

void main() {
  late QuoinDatabase db;
  late SyncLocalDataSource store;
  var now = at;

  setUp(() {
    now = at;
    db = memoryDatabase();
    store = SyncLocalDataSource(db, now: () => now);
  });
  tearDown(() => db.close());

  test('an export reads back exactly as it was written', () async {
    await fill(db);

    final sent = await store.export();
    final received = parseExchange(jsonDecode(jsonEncode(sent.toJson())));

    expect(received.toJson(), sent.toJson());
    expect(received.exportHlc, startsWith('00${at.millisecondsSinceEpoch}-'));
    expect(received.deviceId, originOf(received.exportHlc));
    expect(
      [for (final r in received.ledger) r.key],
      ['TR_CSV::t-1', 'TR_CSV::t-2'],
    );
    final row = received.ledger.first;
    expect(
      [row.quantity, row.price, row.grossAmount],
      ['1.50', '100.10', '150.150'],
    );
    expect(row.ts, '2026-01-05T09:00:00.000Z');
    expect(received.ledger.last.ts, '2026-03-31T22:30:00.000Z');
    expect(received.ledger.last.fxRate, '1.1525');
    expect(
      [for (final i in received.instruments) i.id],
      ['XX00TEST0001', 'XX00TEST0002'],
    );
    expect(received.instruments.first.terHlc, '001761599940000-0000-dev-z');
    final target = received.targets.single;
    expect([for (final l in target.lines) l.monthlyAmount], ['300.00', '100']);
    expect(
      [for (final h in received.holdings.single.rows) h.identity],
      ['BETA.US', 'US00TEST0101'],
    );
    expect(received.holdings.single.rows.last.weight, '0.60');
    expect(received.tombstones.single.key, 'target-0');
    expect(received.identities.single.resolvedAt, '2026-01-05T09:00:00.000Z');
    expect(received.peers.single.deviceId, 'dev-z');
    expect(received.settings.residence, 'bizkaia');
  });

  test(
    'no row is read or sent without its original amount and currency',
    () async {
      await fill(db);

      final read = await store.state();
      final sent = await store.export();

      for (final ledger in [read.ledger, sent.ledger]) {
        expect(ledger.last.originalAmount, '221.00');
        expect(ledger.last.originalCurrency, 'USD');
        for (final row in ledger) {
          expect(row.originalAmount, isNotNull);
          expect(row.originalCurrency, isNotNull);
        }
      }
    },
  );

  test('marks never go back, even when the clock does', () async {
    final first = await store.stamp();
    now = at.subtract(const Duration(minutes: 10));
    final second = await store.stamp();

    expect(second.compareTo(first), isPositive);
    expect(parseHlc(second).ms, at.millisecondsSinceEpoch);
    expect((await db.select(db.syncDevice).getSingle()).lastHlc, second);
  });

  test('a value saved unchanged issues no mark; a changed one does', () async {
    Future<void> setResidence(String residence) => store.setStamped(
      read: () => db.select(db.settings).getSingle(),
      unchanged: (row) => row.residence == residence,
      write: (hlc) => db
          .update(db.settings)
          .write(
            SettingsCompanion(
              residence: Value(residence),
              residenceHlc: Value(hlc),
            ),
          ),
    );

    await setResidence('bizkaia');
    expect((await db.select(db.syncDevice).getSingle()).lastHlc, isNull);
    expect((await db.select(db.settings).getSingle()).residenceHlc, isNull);

    await setResidence('spain');
    final mark = (await db.select(db.syncDevice).getSingle()).lastHlc;
    expect(mark, isNotNull);
    expect((await db.select(db.settings).getSingle()).residenceHlc, mark);
  });

  test('a write that fails leaves no mark behind', () async {
    await expectLater(
      store.setStamped<void>(
        read: () async {},
        unchanged: (_) => false,
        write: (_) => throw const FormatException('refused'),
      ),
      throwsA(anything),
    );

    expect((await db.select(db.syncDevice).getSingle()).lastHlc, isNull);
  });
}
