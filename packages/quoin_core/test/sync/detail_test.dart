import 'package:quoin_core/quoin_core.dart';
import 'package:test/test.dart';

const fund =
    InstrumentRecord(id: 'XX00TEST0001', name: 'QSAMPLE Fund', type: 'ETF');
const stock =
    InstrumentRecord(id: 'XX00TEST0002', name: 'QSAMPLE Stock', type: 'STOCK');

LedgerRecord row(String id, String type, {String? instrument}) => LedgerRecord(
      source: 'QSAMPLE',
      externalId: id,
      ts: '2026-03-02T10:00:00.000Z',
      type: type,
      instrumentId: instrument,
      quantity: instrument == null ? null : '1',
      grossAmount: '-100',
      currency: 'EUR',
      account: 'QSAMPLE',
    );

TargetRecord target(String id, String name) => TargetRecord(
      id: id,
      name: name,
      activeFrom: '2026-01-01',
      createdAt: '2026-01-01T00:00:00.000Z',
      lines: const [],
    );

MergePlan plan(
  ApplyPlan apply, {
  List<LedgerConflict> setAside = const [],
}) =>
    MergePlan(
      apply: apply,
      conflicts: const [],
      setAside: setAside,
      effects: const [],
    );

const settings = SettingsRecord(residence: 'bizkaia');

void main() {
  test(
      'tells instruments, ledger rows by type, targets, compositions and '
      'the residence by name', () {
    final local = SyncState(
      deviceId: 'dev-phone',
      instruments: const [stock],
      targets: [target('t-old', 'QSAMPLE Old plan')],
      settings: settings,
    );
    final detail = syncDetail(
      plan(
        ApplyPlan(
          instrumentInsert: const [fund],
          instrumentUpdate: const [
            InstrumentUpdate('XX00TEST0002', {
              'ter': '0.2',
              'terHlc': 'mark',
              'assetClass': 'EQUITY',
            }),
            InstrumentUpdate('XX00TEST0002', {'thesisHlc': 'mark'}),
          ],
          ledgerInsert: [
            row('a', 'BUY', instrument: 'XX00TEST0001'),
            row('b', 'BUY', instrument: 'XX00TEST0002'),
            row('c', 'DIVIDEND', instrument: 'XX00TEST0002'),
            row('d', 'DEPOSIT'),
          ],
          markInKind: const ['QSAMPLE:x'],
          targetInsert: [target('t-new', 'QSAMPLE New plan')],
          targetDelete: const ['t-old'],
          holdings: const [
            HoldingsBlock(
              instrumentId: 'XX00TEST0001',
              asOf: '2026-02-01',
              asOfInferred: false,
              rows: [],
            ),
          ],
          settings: const SettingsRecord(residence: 'gipuzkoa'),
        ),
      ),
      local,
      const SyncState(deviceId: 'dev-pc', settings: settings),
    );

    expect(detail.newInstruments.items, ['QSAMPLE Fund']);
    expect(detail.changedInstruments.items.single.name, 'QSAMPLE Stock');
    expect(
        detail.changedInstruments.items.single.fields,
        [
          DetailField.ter,
          DetailField.assetClass,
        ],
        reason: 'a mark alone changes nothing the user sees');
    expect(detail.ledger, {'BUY': 2, 'DIVIDEND': 1, 'DEPOSIT': 1});
    expect(detail.ledgerRows, 4);
    expect(detail.inKind, 1);
    expect(detail.newTargets.items, ['QSAMPLE New plan']);
    expect(detail.deletedTargets.items, ['QSAMPLE Old plan']);
    expect(detail.compositions.items, ['QSAMPLE Fund']);
    expect(detail.residence, isTrue);
    expect(detail.writesNothing, isFalse);
  });

  test(
      'a set-aside row is its day, type, instrument and the columns that '
      'differ', () {
    final local = SyncState(
      deviceId: 'dev-phone',
      instruments: const [fund],
      ledger: [row('a', 'SELL', instrument: 'XX00TEST0001')],
      settings: settings,
    );
    final detail = syncDetail(
      plan(
        const ApplyPlan(),
        setAside: [
          LedgerConflict(
              key: ledgerKey('QSAMPLE', 'a'), fields: const ['ts', 'quantity']),
        ],
      ),
      local,
      const SyncState(deviceId: 'dev-pc', settings: settings),
    );

    final aside = detail.setAside.items.single;
    expect(aside.ts, '2026-03-02T10:00:00.000Z');
    expect(aside.type, 'SELL');
    expect(aside.instrument, 'QSAMPLE Fund');
    expect(aside.fields, ['ts', 'quantity']);
    expect(detail.writesNothing, isTrue);
  });

  test(
      'the conflicts settled, by name, with the side kept; those left '
      'open are not', () {
    final local = SyncState(
      deviceId: 'dev-phone',
      instruments: const [fund],
      targets: [target('t-1', 'QSAMPLE Plan')],
      settings: settings,
    );
    const ter = FieldConflict(
      entity: 'instrument',
      key: 'XX00TEST0001',
      field: 'ter',
      local: '0.1',
      incoming: '0.2',
    );
    const residence = FieldConflict(
      entity: 'settings',
      key: 'settings',
      field: 'residence',
      local: 'bizkaia',
      incoming: 'gipuzkoa',
    );
    const plan1 = TargetConflict('t-1');
    const day = TargetDayConflict(day: '2026-01-01', local: 'a', incoming: 'b');
    const composition = HoldingsConflict('XX00TEST0001');
    final detail = syncDetail(
      plan(const ApplyPlan()),
      local,
      const SyncState(deviceId: 'dev-pc', settings: settings),
      conflicts: const [ter, residence, plan1, day, composition],
      resolutions: {
        conflictKey(ter): Resolution.take,
        conflictKey(residence): Resolution.keep,
        conflictKey(plan1): Resolution.keep,
        conflictKey(day): Resolution.take,
      },
    );

    final resolved = detail.resolved.items;
    expect([
      for (final r in resolved) r.kind
    ], [
      ResolvedKind.instrument,
      ResolvedKind.residence,
      ResolvedKind.target,
      ResolvedKind.targetDay,
    ]);
    expect(resolved[0].subject, 'QSAMPLE Fund');
    expect(resolved[0].field, DetailField.ter);
    expect(resolved[0].resolution, Resolution.take);
    expect(resolved[2].subject, 'QSAMPLE Plan');
    expect(resolved[3].subject, '2026-01-01');
  });

  test(
      'a list keeps 20 names and the whole count; the ledger counts are '
      'whole', () {
    final many = [
      for (var i = 0; i < 25; i++)
        InstrumentRecord(id: 'XX00TEST1$i', name: 'QSAMPLE $i', type: 'ETF'),
    ];
    final detail = syncDetail(
      plan(
        ApplyPlan(
          instrumentInsert: many,
          ledgerInsert: [for (var i = 0; i < 300; i++) row('r$i', 'BUY')],
        ),
      ),
      const SyncState(deviceId: 'dev-phone', settings: settings),
      const SyncState(deviceId: 'dev-pc', settings: settings),
    );

    expect(detail.newInstruments.items, hasLength(20));
    expect(detail.newInstruments.total, 25);
    expect(detail.newInstruments.more, 5);
    expect(detail.ledger, {'BUY': 300});
  });

  test('round-trips through JSON, and two syncs add up', () {
    final detail = SyncDetail(
      newInstruments: Cut.of(['QSAMPLE Fund']),
      changedInstruments: Cut.of([
        const InstrumentChange('QSAMPLE Stock', [DetailField.thesis]),
      ]),
      ledger: const {'BUY': 2},
      inKind: 1,
      compositions: Cut.of(['QSAMPLE Fund']),
      residence: true,
      setAside: Cut.of([
        const SetAsideRow(
          ts: '2026-03-02T10:00:00.000Z',
          type: 'SELL',
          instrument: null,
          fields: ['ts'],
        ),
      ]),
      resolved: Cut.of([
        const ResolvedConflict(
          kind: ResolvedKind.holdings,
          subject: 'QSAMPLE Fund',
          resolution: Resolution.keep,
        ),
      ]),
    );

    final back = SyncDetail.fromJson(detail.toJson());
    expect(back.toJson(), detail.toJson());

    final sum = detail.plus(SyncDetail(ledger: const {'BUY': 1, 'SELL': 1}));
    expect(sum.ledger, {'BUY': 3, 'SELL': 1});
    expect(sum.newInstruments.total, 1);
    expect(SyncDetail.fromJson('garbage').writesNothing, isTrue);
  });
}
