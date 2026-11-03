import 'package:quoin_core/src/domain/ledger.dart';
import 'package:quoin_core/src/sort.dart';
import 'package:quoin_core/src/sync/exchange.dart';
import 'package:quoin_core/src/sync/hlc.dart';
import 'package:quoin_core/src/sync/merge.dart';

class LocalDevice {
  const LocalDevice({required this.state, required this.lastHlc});

  final SyncState state;
  final String? lastHlc;
}

({Exchange exchange, LocalDevice device}) exportDevice(
  LocalDevice device,
  int nowMs, {
  String? deviceName,
}) {
  final exportHlc = tick(device.lastHlc, nowMs, device.state.deviceId);
  return (
    exchange: Exchange.of(
      device.state,
      deviceName: deviceName,
      exportHlc: exportHlc,
    ),
    device: LocalDevice(state: device.state, lastHlc: exportHlc),
  );
}

LocalDevice applyPlan(LocalDevice device, ApplyPlan plan, int nowMs) {
  final state = device.state;
  var last = device.lastHlc;
  String fresh() => last = tick(last, nowMs, state.deviceId);

  final instruments = {for (final i in state.instruments) i.id: i};
  for (final row in plan.instrumentInsert) {
    instruments[row.id] = row;
  }
  for (final InstrumentUpdate(:id, :patch) in plan.instrumentUpdate) {
    if (instruments[id] case final row?) {
      instruments[id] = _instrument(row, patch);
    }
  }

  final inKind = plan.markInKind.toSet();
  final ledger = [
    for (final row in state.ledger)
      if (inKind.contains(row.key) && row.funding == 'CASH')
        LedgerRecord.fromJson({...row.toJson(), 'funding': 'IN_KIND'})
      else
        row,
    ...plan.ledgerInsert,
  ];

  final deleted = plan.targetDelete.toSet();
  final targets = [
    for (final t in state.targets)
      if (!deleted.contains(t.id)) t,
    ...plan.targetInsert,
  ];
  final tombstones = [...state.tombstones, ...plan.tombstones];

  final holdings = {for (final b in state.holdings) b.instrumentId: b};
  for (final block in plan.holdings) {
    holdings[block.instrumentId] = block;
  }

  final identities = {for (final i in state.identities) i.identity: i};
  for (final row in plan.identities) {
    identities[row.identity] = row;
  }

  var settings = plan.settings ?? state.settings;

  for (final restamp in plan.restamp) {
    switch (restamp) {
      case InstrumentRestamp(:final id, :final field):
        if (instruments[id] case final row?) {
          instruments[id] = _instrument(row, {field.mark: fresh()});
        }
      case SettingsRestamp():
        settings = SettingsRecord(
          residence: settings.residence,
          residenceHlc: fresh(),
        );
      case HoldingsRestamp(:final instrumentId):
        if (holdings[instrumentId] case final block?) {
          holdings[instrumentId] = HoldingsBlock(
            instrumentId: block.instrumentId,
            asOf: block.asOf,
            asOfInferred: block.asOfInferred,
            hlc: fresh(),
            rows: block.rows,
          );
        }
      case TombstoneRestamp(:final key):
        tombstones.add(Tombstone(key: key, hlc: fresh()));
      case ReissueRestamp(:final target):
        final mark = fresh();
        tombstones.add(Tombstone(key: target.id, hlc: mark));
        targets.add(
          TargetRecord(
            id: mark,
            name: target.name,
            activeFrom: target.activeFrom,
            note: target.note,
            createdAt: target.createdAt,
            lines: target.lines,
          ),
        );
    }
  }

  return LocalDevice(
    lastHlc: last,
    state: SyncState(
      deviceId: state.deviceId,
      peers: plan.peers,
      ledger: stableSorted(
        ledger,
        (a, b) {
          final bySource = compareCodeUnits(a.source, b.source);
          return bySource != 0
              ? bySource
              : compareCodeUnits(a.externalId, b.externalId);
        },
      ),
      instruments: stableSorted(
        instruments.values,
        (a, b) => compareCodeUnits(a.id, b.id),
      ),
      targets: stableSorted(targets, (a, b) => compareCodeUnits(a.id, b.id)),
      tombstones: stableSorted(
        tombstones,
        (a, b) => compareCodeUnits(
          '${a.entity}\u0000${a.key}',
          '${b.entity}\u0000${b.key}',
        ),
      ),
      holdings: stableSorted(
        holdings.values,
        (a, b) => compareCodeUnits(a.instrumentId, b.instrumentId),
      ),
      identities: stableSorted(
        identities.values,
        (a, b) => compareCodeUnits(a.identity, b.identity),
      ),
      settings: settings,
    ),
  );
}

InstrumentRecord _instrument(
        InstrumentRecord row, Map<String, Object?> patch) =>
    InstrumentRecord.fromJson({...row.toJson(), ...patch});

class PlanCounts {
  const PlanCounts({
    required this.ledger,
    required this.inKind,
    required this.setAside,
    required this.newInstruments,
    required this.changedInstruments,
    required this.newTargets,
    required this.deletedTargets,
    required this.newHoldings,
    required this.replacedHoldings,
    required this.newIdentities,
    required this.updatedIdentities,
    required this.settings,
    required this.restamped,
  });

  final int ledger;
  final int inKind;
  final int setAside;
  final int newInstruments;
  final int changedInstruments;
  final int newTargets;
  final int deletedTargets;
  final int newHoldings;
  final int replacedHoldings;
  final int newIdentities;
  final int updatedIdentities;
  final bool settings;
  final int restamped;

  Map<String, Object?> toJson() => {
        'ledger': ledger,
        'inKind': inKind,
        'setAside': setAside,
        'newInstruments': newInstruments,
        'changedInstruments': changedInstruments,
        'newTargets': newTargets,
        'deletedTargets': deletedTargets,
        'newHoldings': newHoldings,
        'replacedHoldings': replacedHoldings,
        'newIdentities': newIdentities,
        'updatedIdentities': updatedIdentities,
        'settings': settings,
        'restamped': restamped,
      };
}

PlanCounts planCounts(MergePlan plan, SyncState local) {
  final apply = plan.apply;
  final funds = {for (final b in local.holdings) b.instrumentId};
  final known = {for (final i in local.identities) i.identity};
  final newHoldings =
      apply.holdings.where((b) => !funds.contains(b.instrumentId)).length;
  final newIdentities =
      apply.identities.where((i) => !known.contains(i.identity)).length;
  return PlanCounts(
    ledger: apply.ledgerInsert.length,
    inKind: apply.markInKind.length,
    setAside: plan.setAside.length,
    newInstruments: apply.instrumentInsert.length,
    changedInstruments: apply.instrumentUpdate.length,
    newTargets: apply.targetInsert.length,
    deletedTargets: apply.targetDelete.length,
    newHoldings: newHoldings,
    replacedHoldings: apply.holdings.length - newHoldings,
    newIdentities: newIdentities,
    updatedIdentities: apply.identities.length - newIdentities,
    settings: apply.settings != null,
    restamped: apply.restamp.length,
  );
}
