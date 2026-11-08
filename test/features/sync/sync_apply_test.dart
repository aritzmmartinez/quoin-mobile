import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';
import 'package:quoin/src/features/sync/data/datasources/sync_local_datasource.dart';
import 'package:quoin/src/features/sync/domain/entities/exchange_import.dart';
import 'package:quoin_core/quoin_core.dart';

import '../../helpers.dart';

typedef Json = Map<String, Object?>;

const settings = {'residence': 'bizkaia', 'residenceHlc': null};
const nowMs = 1761700000000;

Object? plain(Object? value) => jsonDecode(jsonEncode(value));

List<Json> rows(Object? value) => [
  for (final row in (value as List<Object?>? ?? const [])) row! as Json,
];

SyncState stateOf(Object? raw) =>
    SyncState.fromJson({'settings': settings, ...(raw! as Json)});

Exchange exchangeOf(Object? raw) => parseExchange({
  'schemaVersion': 1,
  'deviceName': null,
  'settings': settings,
  ...(raw! as Json),
});

Resolutions resolutionsOf(Object? raw) => {
  for (final MapEntry(:key, :value)
      in ((raw ?? const <String, Object?>{}) as Json).entries)
    key: Resolution.values.byName(value! as String),
};

SyncState withOriginals(SyncState s) => SyncState(
  deviceId: s.deviceId,
  peers: s.peers,
  ledger: [
    for (final r in s.ledger)
      LedgerRecord.fromJson({
        ...r.toJson(),
        'originalAmount': r.originalAmount ?? r.grossAmount,
        'originalCurrency': r.originalCurrency ?? r.currency,
      }),
  ],
  instruments: s.instruments,
  targets: s.targets,
  tombstones: s.tombstones,
  holdings: s.holdings,
  identities: s.identities,
  settings: s.settings,
);

Exchange exchangeWithOriginals(Exchange e) => Exchange.of(
  withOriginals(e),
  deviceName: e.deviceName,
  exportHlc: e.exportHlc,
);

DateTime instant(String text) => DateTime.parse(text).toUtc();

Future<void> seed(QuoinDatabase db, SyncState s, String? lastHlc) =>
    db.transaction(() async {
      await db
          .update(db.syncDevice)
          .write(
            SyncDeviceCompanion(
              deviceId: Value(s.deviceId),
              lastHlc: Value(lastHlc),
            ),
          );
      await db
          .update(db.settings)
          .write(
            SettingsCompanion(
              residence: Value(s.settings.residence),
              residenceHlc: Value(s.settings.residenceHlc),
            ),
          );
      for (final p in s.peers) {
        await db
            .into(db.syncPeer)
            .insert(
              SyncPeerCompanion.insert(deviceId: p.deviceId, seen: p.seen),
            );
      }
      final created = DateTime.utc(2026, 1, 5, 9);
      for (final i in s.instruments) {
        await db
            .into(db.instrument)
            .insert(
              InstrumentCompanion.insert(
                id: i.id,
                name: i.name,
                type: i.type,
                assetClass: Value(i.assetClass),
                quoteSymbol: Value(i.quoteSymbol),
                quoteSymbolHlc: Value(i.quoteSymbolHlc),
                exposureKind: Value(i.exposureKind),
                exposureLeafId: Value(i.exposureLeafId),
                exposureHlc: Value(i.exposureHlc),
                ter: Value(i.ter),
                terHlc: Value(i.terHlc),
                hedgedToBase: Value(i.hedgedToBase),
                hedgedToBaseHlc: Value(i.hedgedToBaseHlc),
                thesis: Value(i.thesis),
                thesisHlc: Value(i.thesisHlc),
                createdAt: created,
              ),
            );
      }
      var n = 0;
      for (final r in s.ledger) {
        await db
            .into(db.ledgerEntry)
            .insert(
              LedgerEntryCompanion.insert(
                id: 'seed-${n++}',
                ts: instant(r.ts),
                type: r.type,
                instrumentId: Value(r.instrumentId),
                quantity: Value(r.quantity),
                price: Value(r.price),
                grossAmount: r.grossAmount,
                fees: Value(r.fees),
                taxWithheld: Value(r.taxWithheld),
                currency: r.currency,
                fxSource: Value(r.fxSource),
                fxDate: Value(r.fxDate),
                fxRate: Value(r.fxRate),
                fxDirection: Value(r.fxDirection),
                originalAmount: Value(r.originalAmount),
                originalCurrency: Value(r.originalCurrency),
                valuationSource: Value(r.valuationSource),
                linkId: Value(r.linkId),
                linkKind: Value(r.linkKind),
                funding: Value(r.funding),
                account: Value(r.account),
                source: Value(r.source),
                externalId: Value(r.externalId),
                note: Value(r.note),
                createdAt: created,
              ),
            );
      }
      for (final t in s.targets) {
        await db
            .into(db.portfolioTarget)
            .insert(
              PortfolioTargetCompanion.insert(
                id: t.id,
                name: t.name,
                activeFrom: Value(t.activeFrom),
                note: Value(t.note),
                createdAt: instant(t.createdAt),
              ),
            );
        for (final l in t.lines) {
          await db
              .into(db.portfolioTargetLine)
              .insert(
                PortfolioTargetLineCompanion.insert(
                  id: 'line-${t.id}-${l.instrumentId}',
                  targetId: t.id,
                  instrumentId: l.instrumentId,
                  monthlyAmount: l.monthlyAmount,
                ),
              );
        }
      }
      for (final t in s.tombstones) {
        await db
            .into(db.syncTombstone)
            .insert(
              SyncTombstoneCompanion.insert(
                entity: targetEntity,
                key: t.key,
                hlc: t.hlc,
              ),
            );
      }
      for (final b in s.holdings) {
        await db
            .into(db.etfHoldingBlock)
            .insert(
              EtfHoldingBlockCompanion.insert(
                instrumentId: b.instrumentId,
                asOf: b.asOf,
                asOfInferred: Value(b.asOfInferred),
                hlc: Value(b.hlc),
              ),
            );
        for (final h in b.rows) {
          await db
              .into(db.etfHolding)
              .insert(
                EtfHoldingCompanion.insert(
                  id: 'h-${b.instrumentId}-${h.identity}',
                  instrumentId: b.instrumentId,
                  identity: h.identity,
                  identityKind: h.identityKind,
                  name: h.name,
                  weight: h.weight,
                  createdAt: created,
                ),
              );
        }
      }
      for (final i in s.identities) {
        await db
            .into(db.securityIdentity)
            .insert(
              SecurityIdentityCompanion.insert(
                identity: i.identity,
                identityKind: i.identityKind,
                canonicalId: Value(i.canonicalId),
                exchCode: Value(i.exchCode),
                status: i.status,
                source: i.source,
                resolvedAt: instant(i.resolvedAt),
              ),
            );
      }
    });

/// What the phone holds, as the exchange reads it, with every instant by its
/// moment (the database writes UTC) and the last mark issued.
Future<Object?> held(QuoinDatabase db, SyncLocalDataSource store) async {
  final json = (await store.state()).toJson();
  for (final row in json['ledger']! as List<Object?>) {
    final map = row! as Json;
    map['ts'] = isoInstant(instant(map['ts']! as String));
  }
  return {
    'state': plain(json),
    'lastHlc': (await db.select(db.syncDevice).getSingle()).lastHlc,
  };
}

Object? modelled(LocalDevice device) {
  final json = device.state.toJson();
  void sortBy(String list, String Function(Json row) key) =>
      (json[list]! as List<Object?>).sort(
        (a, b) => compareCodeUnits(key(a! as Json), key(b! as Json)),
      );
  sortBy('peers', (r) => r['deviceId']! as String);
  sortBy('ledger', (r) => '${r['source']} ${r['externalId']}');
  sortBy('instruments', (r) => r['id']! as String);
  sortBy('targets', (r) => r['id']! as String);
  sortBy('tombstones', (r) => r['key']! as String);
  sortBy('holdings', (r) => r['instrumentId']! as String);
  sortBy('identities', (r) => r['identity']! as String);
  for (final block in json['holdings']! as List<Object?>) {
    ((block! as Json)['rows']! as List<Object?>).sort(
      (a, b) => compareCodeUnits(
        (a! as Json)['identity']! as String,
        (b! as Json)['identity']! as String,
      ),
    );
  }
  for (final row in json['ledger']! as List<Object?>) {
    final map = row! as Json;
    map['ts'] = isoInstant(instant(map['ts']! as String));
  }
  return {'state': plain(json), 'lastHlc': device.lastHlc};
}

Future<Map<String, List<Json>>> dump(QuoinDatabase db) async => {
  for (final table in [
    'Instrument',
    'LedgerEntry',
    'FxRate',
    'Settings',
    'EtfHolding',
    'EtfHoldingBlock',
    'PortfolioTarget',
    'PortfolioTargetLine',
    'SecurityIdentity',
    'SyncDevice',
    'SyncPeer',
    'SyncTombstone',
  ])
    table: [
      for (final r
          in await db
              .customSelect('SELECT * FROM "$table" ORDER BY rowid')
              .get())
        r.data,
    ],
};

LedgerRecord row(String externalId, {String amount = '100'}) =>
    LedgerRecord.fromJson({
      'source': 'TR_CSV',
      'externalId': externalId,
      'ts': '2026-01-05T09:00:00.000Z',
      'type': 'BUY',
      'instrumentId': 'IE00TEST0001',
      'quantity': '1',
      'price': amount,
      'grossAmount': amount,
      'currency': 'EUR',
      'originalAmount': amount,
      'originalCurrency': 'EUR',
      'account': 'trade-republic',
    });

const fund = InstrumentRecord(
  id: 'IE00TEST0001',
  name: 'Test World ETF',
  type: 'ETF',
  quoteSymbol: 'OLD.DE',
  quoteSymbolHlc: '001761599940000-0000-dev-a',
);

Exchange fileFrom(
  String deviceId, {
  List<LedgerRecord> ledger = const [],
  List<InstrumentRecord> instruments = const [fund],
  List<Peer> peers = const [],
  int exportMs = 1761600000000,
}) => Exchange.of(
  SyncState(
    deviceId: deviceId,
    peers: peers,
    ledger: ledger,
    instruments: instruments,
    settings: const SettingsRecord(residence: 'bizkaia'),
  ),
  exportHlc: formatHlc((ms: exportMs, counter: 0, deviceId: deviceId)),
);

void main() {
  final contract = jsonDecode(
    File('packages/quoin_core/test/contract/sync.json').readAsStringSync(),
  ) as Json;

  late QuoinDatabase db;
  late SyncLocalDataSource store;

  setUp(() {
    db = memoryDatabase();
    store = SyncLocalDataSource(db);
  });
  tearDown(() => db.close());

  group('importExchange writes what applyPlan says', () {
    for (final c in rows(contract['merges'])) {
      if ((c['expected']! as Json)['error'] != null) continue;
      test(c['name']! as String, () async {
        final local = withOriginals(stateOf(c['local']));
        final incoming = exchangeWithOriginals(exchangeOf(c['incoming']));
        final resolutions = resolutionsOf(c['resolutions']);
        final plan = merge(local, incoming, resolutions);
        final before = await dump(db);
        await seed(db, local, null);
        final seeded = await dump(db);
        expect(before, isNot(equals(seeded)));

        final result = await store.importExchange(
          incoming,
          resolutions: resolutions,
          dryRun: false,
          nowMs: nowMs,
        );

        final device = LocalDevice(state: local, lastHlc: null);
        final expected = plan.conflicts.isNotEmpty
            ? device
            : plan.changesData
            ? applyPlan(device, plan.apply, nowMs)
            : LocalDevice(
                state: SyncState(
                  deviceId: local.deviceId,
                  peers: plan.apply.peers,
                  ledger: local.ledger,
                  instruments: local.instruments,
                  targets: local.targets,
                  tombstones: local.tombstones,
                  holdings: local.holdings,
                  identities: local.identities,
                  settings: local.settings,
                ),
                lastHlc: null,
              );
        expect(await held(db, store), modelled(expected));
        expect(result.status, switch (plan) {
          MergePlan(conflicts: [_, ...]) => ImportStatus.conflicts,
          MergePlan(changesData: true) => ImportStatus.applied,
          _ => ImportStatus.upToDate,
        });
        if (plan.conflicts.isNotEmpty) {
          expect(await dump(db), seeded);
        }
      });
    }
  });

  group('two phones go through every scenario', () {
    for (final c in rows(contract['scenarios'])) {
      test(c['name']! as String, () async {
        var clock = 0;
        final dbs = <String, QuoinDatabase>{};
        final stores = <String, SyncLocalDataSource>{};
        final models = <String, LocalDevice>{};
        for (final MapEntry(:key, :value) in (c['devices']! as Json).entries) {
          final device = value! as Json;
          final state = withOriginals(stateOf(device['state']));
          final lastHlc = device['lastHlc'] as String?;
          final own = memoryDatabase();
          addTearDown(own.close);
          await seed(own, state, lastHlc);
          dbs[key] = own;
          stores[key] = SyncLocalDataSource(
            own,
            now: () => DateTime.fromMillisecondsSinceEpoch(clock, isUtc: true),
          );
          models[key] = LocalDevice(
            state: await stores[key]!.state(),
            lastHlc: lastHlc,
          );
        }

        for (final (i, step) in rows(c['steps']).indexed) {
          final label = 'step ${i + 1}';
          final from = step['from']! as String;
          final to = step['to']! as String;
          clock = step['nowMs']! as int;

          final sent = exportDevice(models[from]!, clock);
          models[from] = sent.device;
          final file = await stores[from]!.export();
          expect(file.toJson(), sent.exchange.toJson(), reason: label);

          final receiver = models[to]!;
          final resolutions = resolutionsOf(step['resolutions']);
          final plan = merge(receiver.state, sent.exchange, resolutions);
          final result = await stores[to]!.importExchange(
            parseExchange(plain(file.toJson())),
            resolutions: resolutions,
            dryRun: false,
            nowMs: clock,
          );

          if (plan.conflicts.isNotEmpty) {
            expect('conflicts', step['status'], reason: label);
            expect(result.status, ImportStatus.conflicts, reason: label);
          } else if (!plan.changesData) {
            expect('up-to-date', step['status'], reason: label);
            expect(result.status, ImportStatus.upToDate, reason: label);
            final s = receiver.state;
            models[to] = LocalDevice(
              lastHlc: receiver.lastHlc,
              state: SyncState(
                deviceId: s.deviceId,
                peers: plan.apply.peers,
                ledger: s.ledger,
                instruments: s.instruments,
                targets: s.targets,
                tombstones: s.tombstones,
                holdings: s.holdings,
                identities: s.identities,
                settings: s.settings,
              ),
            );
          } else {
            expect('applied', step['status'], reason: label);
            expect(result.status, ImportStatus.applied, reason: label);
            models[to] = applyPlan(receiver, plan.apply, clock);
          }
          for (final id in dbs.keys) {
            expect(
              await held(dbs[id]!, stores[id]!),
              modelled(models[id]!),
              reason: '$label, $id',
            );
          }
        }
      });
    }
  });

  group('one transaction', () {
    Future<void> local() => seed(
      db,
      SyncState(
        deviceId: 'dev-a',
        instruments: const [fund],
        ledger: [row('local-1')],
        settings: const SettingsRecord(residence: 'bizkaia'),
      ),
      null,
    );

    test(
      'a write from outside waits for it and stays out of what it read',
      () async {
        await local();
        final events = <String>[];
        Future<void>? outside;
        var insideSaw = <String>[];

        final result = await store.importExchange(
          fileFrom('dev-b', ledger: [row('remote-1')]),
          dryRun: false,
          nowMs: nowMs,
          beforeApply: () async {
            // Launched from outside the transaction while it is open.
            outside = Zone.root.run(
              () => db
                  .into(db.ledgerEntry)
                  .insert(
                    LedgerEntryCompanion.insert(
                      id: 'outside',
                      ts: DateTime.utc(2026, 1, 6),
                      type: 'DEPOSIT',
                      grossAmount: '50',
                      currency: 'EUR',
                      source: const Value('TR_CSV'),
                      externalId: const Value('outside-1'),
                      createdAt: DateTime.utc(2026, 1, 6),
                    ),
                  )
                  .then((_) => events.add('outside written')),
            );
            await Future<void>.delayed(const Duration(milliseconds: 200));
            insideSaw = [for (final r in (await store.state()).ledger) r.key];
            events.add('transaction still open');
          },
        );

        expect(events, ['transaction still open']);
        expect(insideSaw, ['TR_CSV::local-1']);
        await outside;
        expect(events, ['transaction still open', 'outside written']);
        expect(result.status, ImportStatus.applied);
        expect(result.counts.ledger, 1);
        expect(
          [for (final r in (await store.state()).ledger) r.key],
          ['TR_CSV::local-1', 'TR_CSV::outside-1', 'TR_CSV::remote-1'],
        );
      },
    );

    test('open conflicts write nothing, not even the marks seen', () async {
      await seed(
        db,
        SyncState(
          deviceId: 'dev-a',
          instruments: const [
            InstrumentRecord(
              id: 'IE00TEST0001',
              name: 'Test World ETF',
              type: 'ETF',
              ter: '0.0025',
              terHlc: '001761600000000-0000-dev-a',
            ),
          ],
          ledger: [row('local-1')],
          settings: const SettingsRecord(residence: 'bizkaia'),
        ),
        '001761600000000-0000-dev-a',
      );
      final before = await dump(db);

      final result = await store.importExchange(
        fileFrom(
          'dev-b',
          ledger: [
            row('local-1', amount: '999'),
            row('remote-1'),
          ],
          instruments: const [
            InstrumentRecord(
              id: 'IE00TEST0001',
              name: 'Test World ETF',
              type: 'ETF',
              quoteSymbol: 'NEW.DE',
              quoteSymbolHlc: '001761600060000-0000-dev-b',
              ter: '0.0030',
              terHlc: '001761600060000-0000-dev-b',
            ),
          ],
        ),
        dryRun: false,
        nowMs: nowMs,
      );

      expect(result.status, ImportStatus.conflicts);
      expect(
        [for (final c in result.plan.conflicts) conflictKey(c)],
        ['instrument:IE00TEST0001:ter'],
      );
      expect(await dump(db), before);
    });

    test('a dry run writes nothing', () async {
      await local();
      final before = await dump(db);

      final result = await store.importExchange(
        fileFrom('dev-b', ledger: [row('remote-1')]),
        dryRun: true,
        nowMs: nowMs,
      );

      expect(result.status, ImportStatus.dryRun);
      expect(result.counts.ledger, 1);
      expect(await dump(db), before);
    });

    test(
      'its own file, or a resolution that fits nothing, writes nothing',
      () async {
        await local();
        final before = await dump(db);

        await expectLater(
          store.importExchange(
            fileFrom('dev-a', ledger: [row('remote-1')]),
            dryRun: false,
            nowMs: nowMs,
          ),
          throwsA(isA<SameDevice>()),
        );
        await expectLater(
          store.importExchange(
            fileFrom('dev-b', ledger: [row('remote-1')]),
            resolutions: {'settings:residence': Resolution.keep},
            dryRun: false,
            nowMs: nowMs,
          ),
          throwsA(isA<UnknownResolution>()),
        );
        expect(await dump(db), before);
      },
    );

    test(
      'only the marks of what was seen are saved when nothing changes',
      () async {
        await local();

        final result = await store.importExchange(
          fileFrom('dev-b', instruments: const [fund]),
          dryRun: false,
          nowMs: nowMs,
        );

        expect(result.status, ImportStatus.upToDate);
        final peer = await db.select(db.syncPeer).getSingle();
        expect(peer.deviceId, 'dev-b');
        expect(peer.seen, '001761600000000-0000-dev-b');
        expect(
          peer.lastSyncedAt,
          DateTime.fromMillisecondsSinceEpoch(nowMs, isUtc: true),
        );
      },
    );

    test('the effects stay pending for the caller', () async {
      await seed(
        db,
        const SyncState(
          deviceId: 'dev-a',
          settings: SettingsRecord(residence: 'bizkaia'),
        ),
        null,
      );

      final result = await store.importExchange(
        fileFrom(
          'dev-b',
          ledger: [
            LedgerRecord.fromJson({
              ...row('usd-1').toJson(),
              'currency': 'USD',
              'fxSource': 'ECB',
              'fxDate': '2026-01-05',
              'fxRate': '1.04',
              'fxDirection': 'QUOTE_PER_BASE',
            }),
          ],
        ),
        dryRun: false,
        nowMs: nowMs,
      );

      expect(result.status, ImportStatus.applied);
      expect(
        [for (final e in result.pendingEffects) e.toJson()],
        [
          {
            'kind': 'prices',
            'instrumentId': 'IE00TEST0001',
            'symbol': 'OLD.DE',
          },
          {
            'kind': 'rates',
            'currency': 'USD',
            'since': '2026-01-05T09:00:00.000Z',
          },
        ],
      );
    });
  });

  test(
    'a residence this version does not know is stored and sent on as it came',
    () async {
      await seed(
        db,
        const SyncState(
          deviceId: 'dev-a',
          settings: SettingsRecord(residence: 'bizkaia'),
        ),
        null,
      );
      const mark = '001761600000000-0000-dev-b';
      final file = Exchange.of(
        const SyncState(
          deviceId: 'dev-b',
          settings: SettingsRecord(residence: 'araba', residenceHlc: mark),
        ),
        exportHlc: mark,
      );

      final result = await store.importExchange(
        file,
        dryRun: false,
        nowMs: nowMs,
      );

      expect(result.status, ImportStatus.applied);
      final stored = await db.select(db.settings).getSingle();
      expect([stored.residence, stored.residenceHlc], ['araba', mark]);
      final sent = await store.export();
      expect(sent.settings.toJson(), {
        'residence': 'araba',
        'residenceHlc': mark,
      });
    },
  );

  group('apply', () {
    test(
      'a new quote symbol is written, its series left to the effect',
      () async {
        await seed(
          db,
          SyncState(
            deviceId: 'dev-a',
            instruments: const [
              fund,
              InstrumentRecord(
                id: 'XX00TEST0002',
                name: 'Test Stock',
                type: 'STOCK',
              ),
            ],
            settings: const SettingsRecord(residence: 'bizkaia'),
          ),
          null,
        );
        await store.apply(
          const ApplyPlan(
            instrumentUpdate: [
              InstrumentUpdate('IE00TEST0001', {
                'quoteSymbol': 'NEW.DE',
                'quoteSymbolHlc': '001761600060000-0000-dev-b',
              }),
            ],
          ),
          const SyncSender(deviceId: 'dev-b', name: null),
          nowMs,
        );

        final changed = await (db.select(
          db.instrument,
        )..where((i) => i.id.equals('IE00TEST0001'))).getSingle();
        expect(changed.quoteSymbol, 'NEW.DE');
      },
    );

    test('a plan that fails half way leaves nothing of it', () async {
      await seed(
        db,
        const SyncState(
          deviceId: 'dev-a',
          instruments: [fund],
          settings: SettingsRecord(residence: 'bizkaia'),
        ),
        '001761599000000-0000-dev-a',
      );
      final before = await dump(db);

      await expectLater(
        store.apply(
          ApplyPlan(
            instrumentUpdate: const [
              InstrumentUpdate('IE00TEST0001', {'quoteSymbol': 'NEW.DE'}),
            ],
            // A type the table refuses.
            ledgerInsert: [
              LedgerRecord.fromJson({...row('bad').toJson(), 'type': 'BUY'}),
              LedgerRecord(
                source: 'TR_CSV',
                externalId: 'worse',
                ts: '2026-01-05T09:00:00.000Z',
                type: 'FEE',
                grossAmount: '1',
                currency: 'EUR',
                account: 'trade-republic',
              ),
            ],
            restamp: const [SettingsRestamp()],
            peers: const [
              Peer(deviceId: 'dev-b', seen: '001761600000000-0000-dev-b'),
            ],
          ),
          const SyncSender(deviceId: 'dev-b', name: 'phone'),
          nowMs,
        ),
        throwsA(isA<StorageException>()),
      );

      expect(await dump(db), before);
    });

    test('a column the sync does not write is refused', () async {
      await seed(
        db,
        const SyncState(
          deviceId: 'dev-a',
          instruments: [fund],
          settings: SettingsRecord(residence: 'bizkaia'),
        ),
        null,
      );

      await expectLater(
        store.apply(
          const ApplyPlan(
            instrumentUpdate: [
              InstrumentUpdate('IE00TEST0001', {'name': 'Renamed'}),
            ],
          ),
          const SyncSender(deviceId: 'dev-b', name: null),
          nowMs,
        ),
        throwsArgumentError,
      );
    });
  });
}
