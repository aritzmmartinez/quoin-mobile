import 'dart:convert';

import 'package:quoin_core/src/domain/ledger.dart';
import 'package:quoin_core/src/sort.dart';
import 'package:quoin_core/src/sync/exchange.dart';
import 'package:quoin_core/src/sync/hlc.dart';

enum InstrumentField {
  quoteSymbol('quoteSymbolHlc', ['quoteSymbol']),
  exposure('exposureHlc', ['exposureKind', 'exposureLeafId']),
  ter('terHlc', ['ter']),
  hedgedToBase('hedgedToBaseHlc', ['hedgedToBase']),
  thesis('thesisHlc', ['thesis']);

  const InstrumentField(this.mark, this.columns);

  final String mark;
  final List<String> columns;
}

Object? instrumentColumn(InstrumentRecord row, String column) =>
    switch (column) {
      'assetClass' => row.assetClass,
      'quoteSymbol' => row.quoteSymbol,
      'quoteSymbolHlc' => row.quoteSymbolHlc,
      'exposureKind' => row.exposureKind,
      'exposureLeafId' => row.exposureLeafId,
      'exposureHlc' => row.exposureHlc,
      'ter' => row.ter,
      'terHlc' => row.terHlc,
      'hedgedToBase' => row.hedgedToBase,
      'hedgedToBaseHlc' => row.hedgedToBaseHlc,
      'thesis' => row.thesis,
      'thesisHlc' => row.thesisHlc,
      _ => throw ArgumentError('Not an instrument column: $column'),
    };

sealed class Conflict {
  const Conflict();

  Map<String, Object?> toJson();
}

final class FieldConflict extends Conflict {
  const FieldConflict({
    required this.entity,
    required this.key,
    required this.field,
    required this.local,
    required this.incoming,
  });

  final String entity;
  final String key;
  final String field;
  final Object? local;
  final Object? incoming;

  @override
  Map<String, Object?> toJson() => {
        'kind': 'field',
        'entity': entity,
        'key': key,
        'field': field,
        'local': local,
        'incoming': incoming,
      };
}

final class TargetConflict extends Conflict {
  const TargetConflict(this.id);

  final String id;

  @override
  Map<String, Object?> toJson() => {'kind': 'target', 'id': id};
}

final class TargetDayConflict extends Conflict {
  const TargetDayConflict({
    required this.day,
    required this.local,
    required this.incoming,
  });

  final String day;
  final String local;
  final String incoming;

  @override
  Map<String, Object?> toJson() => {
        'kind': 'target-day',
        'day': day,
        'local': local,
        'incoming': incoming,
      };
}

final class HoldingsConflict extends Conflict {
  const HoldingsConflict(this.instrumentId);

  final String instrumentId;

  @override
  Map<String, Object?> toJson() =>
      {'kind': 'holdings', 'instrumentId': instrumentId};
}

final class LedgerConflict {
  const LedgerConflict({required this.key, required this.fields});

  final String key;
  final List<String> fields;

  Map<String, Object?> toJson() =>
      {'kind': 'ledger', 'key': key, 'fields': fields};
}

enum Resolution { keep, take }

typedef Resolutions = Map<String, Resolution>;

class UnknownResolution implements Exception {
  const UnknownResolution(this.keys);

  final List<String> keys;

  @override
  String toString() =>
      'No conflict matches the resolution of ${keys.join(', ')}';
}

String conflictKey(Conflict conflict) => switch (conflict) {
      FieldConflict(entity: 'settings', :final field) => 'settings:$field',
      FieldConflict(:final key, :final field) => 'instrument:$key:$field',
      TargetConflict(:final id) => 'target:$id',
      TargetDayConflict(:final day) => 'target-day:$day',
      HoldingsConflict(:final instrumentId) => 'holdings:$instrumentId',
    };

sealed class Restamp {
  const Restamp();

  Map<String, Object?> toJson();
}

final class InstrumentRestamp extends Restamp {
  const InstrumentRestamp(this.id, this.field);

  final String id;
  final InstrumentField field;

  @override
  Map<String, Object?> toJson() =>
      {'kind': 'instrument', 'id': id, 'field': field.name};
}

final class SettingsRestamp extends Restamp {
  const SettingsRestamp();

  @override
  Map<String, Object?> toJson() => {'kind': 'settings'};
}

final class HoldingsRestamp extends Restamp {
  const HoldingsRestamp(this.instrumentId);

  final String instrumentId;

  @override
  Map<String, Object?> toJson() =>
      {'kind': 'holdings', 'instrumentId': instrumentId};
}

final class TombstoneRestamp extends Restamp {
  const TombstoneRestamp(this.key);

  final String key;

  @override
  Map<String, Object?> toJson() => {'kind': 'tombstone', 'key': key};
}

final class ReissueRestamp extends Restamp {
  const ReissueRestamp(this.target);

  final TargetRecord target;

  @override
  Map<String, Object?> toJson() =>
      {'kind': 'reissue', 'target': target.toJson()};
}

String restampKey(Restamp restamp) => switch (restamp) {
      InstrumentRestamp(:final id, :final field) =>
        'instrument:$id:${field.name}',
      SettingsRestamp() => 'settings',
      HoldingsRestamp(:final instrumentId) => 'holdings:$instrumentId',
      TombstoneRestamp(:final key) => 'tombstone:$key',
      ReissueRestamp(:final target) => 'reissue:${target.id}',
    };

sealed class Effect {
  const Effect();

  Map<String, Object?> toJson();
}

final class PricesEffect extends Effect {
  const PricesEffect({required this.instrumentId, required this.symbol});

  final String instrumentId;
  final String symbol;

  @override
  Map<String, Object?> toJson() =>
      {'kind': 'prices', 'instrumentId': instrumentId, 'symbol': symbol};
}

final class RatesEffect extends Effect {
  const RatesEffect({required this.currency, required this.since});

  final String currency;
  final String since;

  @override
  Map<String, Object?> toJson() =>
      {'kind': 'rates', 'currency': currency, 'since': since};
}

String _effectKey(Effect effect) => switch (effect) {
      PricesEffect(:final instrumentId) => 'prices:$instrumentId',
      RatesEffect(:final currency) => 'rates:$currency',
    };

class InstrumentUpdate {
  const InstrumentUpdate(this.id, this.patch);

  final String id;
  final Map<String, Object?> patch;

  Map<String, Object?> toJson() => {'id': id, 'patch': patch};
}

class ApplyPlan {
  const ApplyPlan({
    this.ledgerInsert = const [],
    this.markInKind = const [],
    this.instrumentInsert = const [],
    this.instrumentUpdate = const [],
    this.targetInsert = const [],
    this.targetDelete = const [],
    this.tombstones = const [],
    this.holdings = const [],
    this.identities = const [],
    this.settings,
    this.restamp = const [],
    this.peers = const [],
  });

  final List<LedgerRecord> ledgerInsert;
  final List<String> markInKind;
  final List<InstrumentRecord> instrumentInsert;
  final List<InstrumentUpdate> instrumentUpdate;
  final List<TargetRecord> targetInsert;
  final List<String> targetDelete;
  final List<Tombstone> tombstones;
  final List<HoldingsBlock> holdings;
  final List<IdentityRecord> identities;
  final SettingsRecord? settings;
  final List<Restamp> restamp;
  final List<Peer> peers;

  bool get changesData =>
      ledgerInsert.isNotEmpty ||
      markInKind.isNotEmpty ||
      instrumentInsert.isNotEmpty ||
      instrumentUpdate.isNotEmpty ||
      targetInsert.isNotEmpty ||
      targetDelete.isNotEmpty ||
      tombstones.isNotEmpty ||
      holdings.isNotEmpty ||
      identities.isNotEmpty ||
      settings != null ||
      restamp.isNotEmpty;

  Map<String, Object?> toJson() => {
        'ledger': {
          'insert': [for (final r in ledgerInsert) r.toJson()],
          'markInKind': markInKind,
        },
        'instruments': {
          'insert': [for (final r in instrumentInsert) r.toJson()],
          'update': [for (final u in instrumentUpdate) u.toJson()],
        },
        'targets': {
          'insert': [for (final r in targetInsert) r.toJson()],
          'delete': targetDelete,
        },
        'tombstones': [for (final t in tombstones) t.toJson()],
        'holdings': [for (final h in holdings) h.toJson()],
        'identities': [for (final i in identities) i.toJson()],
        'settings': settings?.toJson(),
        'restamp': [for (final r in restamp) r.toJson()],
        'peers': [for (final p in peers) p.toJson()],
      };

  factory ApplyPlan.fromJson(Map<String, Object?> json) {
    Map<String, Object?> part(String key) =>
        (json[key] ?? const <String, Object?>{}) as Map<String, Object?>;
    List<T> each<T>(Object? raw, T Function(Object? row) read) => [
          for (final row in (raw ?? const <Object?>[]) as List<Object?>)
            read(row)
        ];
    List<String> keys(Object? raw) => each(raw, (key) => key! as String);
    final ledger = part('ledger');
    final instruments = part('instruments');
    final targets = part('targets');
    return ApplyPlan(
      ledgerInsert: each(ledger['insert'], LedgerRecord.fromJson),
      markInKind: keys(ledger['markInKind']),
      instrumentInsert: each(instruments['insert'], InstrumentRecord.fromJson),
      instrumentUpdate: each(instruments['update'], (raw) {
        final row = raw! as Map<String, Object?>;
        return InstrumentUpdate(
          row['id']! as String,
          row['patch']! as Map<String, Object?>,
        );
      }),
      targetInsert: each(targets['insert'], TargetRecord.fromJson),
      targetDelete: keys(targets['delete']),
      tombstones: each(json['tombstones'], Tombstone.fromJson),
      holdings: each(json['holdings'], HoldingsBlock.fromJson),
      identities: each(json['identities'], IdentityRecord.fromJson),
      settings: json['settings'] == null
          ? null
          : SettingsRecord.fromJson(json['settings']),
      restamp: each(
        json['restamp'],
        (raw) => switch (raw) {
          {
            'kind': 'instrument',
            'id': final String id,
            'field': final String field,
          } =>
            InstrumentRestamp(id, InstrumentField.values.byName(field)),
          {'kind': 'settings'} => const SettingsRestamp(),
          {'kind': 'holdings', 'instrumentId': final String id} =>
            HoldingsRestamp(id),
          {'kind': 'tombstone', 'key': final String key} =>
            TombstoneRestamp(key),
          {'kind': 'reissue', 'target': final Object target} =>
            ReissueRestamp(TargetRecord.fromJson(target)),
          _ => throw FormatException('Not a restamp: $raw'),
        },
      ),
      peers: each(json['peers'], Peer.fromJson),
    );
  }
}

class MergePlan {
  const MergePlan({
    required this.apply,
    required this.conflicts,
    required this.setAside,
    required this.effects,
  });

  final ApplyPlan apply;
  final List<Conflict> conflicts;
  final List<LedgerConflict> setAside;
  final List<Effect> effects;

  bool get changesData => apply.changesData;
}

class _Side {
  _Side(this.self, Iterable<Peer> peers)
      : seen = {for (final p in peers) p.deviceId: p.seen};

  final String self;
  final Map<String, String> seen;
}

bool _isNewFor(_Side side, String? mark) {
  if (mark == null) return false;
  final origin = originOf(mark);
  if (origin == side.self) return false;
  final seen = side.seen[origin];
  return seen == null || mark.compareTo(seen) > 0;
}

enum _Decision { keep, take, conflict }

_Decision _decide(_Side me, _Side them, String? local, String? incoming) {
  final takeIt = _isNewFor(me, incoming);
  final keepIt = _isNewFor(them, local);
  if (takeIt && !keepIt) return _Decision.take;
  if (keepIt && !takeIt) return _Decision.keep;
  return _Decision.conflict;
}

class _Conflicts {
  _Conflicts(this._resolutions);

  final Resolutions _resolutions;
  final List<Conflict> open = [];
  final Set<String> _used = {};

  Resolution? resolve(Conflict conflict) {
    final key = conflictKey(conflict);
    final resolution = _resolutions[key];
    if (resolution == null) {
      open.add(conflict);
      return null;
    }
    _used.add(key);
    return resolution;
  }

  void assertAllUsed() {
    final unused = [
      for (final key in _resolutions.keys)
        if (!_used.contains(key)) key,
    ]..sort(compareCodeUnits);
    if (unused.isNotEmpty) throw UnknownResolution(unused);
  }
}

bool _same(Map<String, Object?> a, Map<String, Object?> b) =>
    jsonEncode(a) == jsonEncode(b);

int _instant(String value) => DateTime.parse(value).millisecondsSinceEpoch;

const _baseCurrency = 'EUR';

MergePlan merge(
  SyncState local,
  Exchange incoming, [
  Resolutions resolutions = const {},
]) {
  refuseOwnExport(local, incoming);
  final me = _Side(local.deviceId, local.peers);
  final them = _Side(incoming.deviceId, incoming.peers);

  final conflicts = _Conflicts(resolutions);
  final restamp = <Restamp>[];
  final effects = <Effect>[];

  final ledger = _mergeLedger(local.ledger, incoming.ledger, effects);
  final instruments = _mergeInstruments(
    local.instruments,
    incoming.instruments,
    me,
    them,
    conflicts,
    restamp,
    effects,
  );
  final targets = _mergeTargets(local, incoming, conflicts, restamp);
  final holdings = _mergeHoldings(
    local.holdings,
    incoming.holdings,
    me,
    them,
    conflicts,
    restamp,
  );
  final identities = _mergeIdentities(local.identities, incoming.identities);

  SettingsRecord? settings;
  if (local.settings.residence != incoming.settings.residence) {
    var decision = _decide(
      me,
      them,
      local.settings.residenceHlc,
      incoming.settings.residenceHlc,
    );
    if (decision == _Decision.conflict) {
      final resolution = conflicts.resolve(
        FieldConflict(
          entity: 'settings',
          key: 'settings',
          field: 'residence',
          local: local.settings.residence,
          incoming: incoming.settings.residence,
        ),
      );
      if (resolution != null) {
        decision = _Decision.values.byName(resolution.name);
      }
      if (decision == _Decision.keep) restamp.add(const SettingsRestamp());
    }
    if (decision == _Decision.take) settings = incoming.settings;
  }

  conflicts.assertAllUsed();

  return MergePlan(
    apply: ApplyPlan(
      ledgerInsert: ledger.insert,
      markInKind: ledger.markInKind,
      instrumentInsert: instruments.insert,
      instrumentUpdate: instruments.update,
      targetInsert: targets.insert,
      targetDelete: targets.delete,
      tombstones: targets.tombstones,
      holdings: holdings,
      identities: identities,
      settings: settings,
      restamp: stableSorted(
        restamp,
        (a, b) => compareCodeUnits(restampKey(a), restampKey(b)),
      ),
      peers: _mergeSeen(me, them, incoming.exportHlc),
    ),
    conflicts: conflicts.open,
    setAside: ledger.setAside,
    effects: stableSorted(
      effects,
      (a, b) => compareCodeUnits(_effectKey(a), _effectKey(b)),
    ),
  );
}

final _ledgerCompared = <(String, Object? Function(LedgerRecord))>[
  ('type', (r) => r.type),
  ('instrumentId', (r) => r.instrumentId),
  ('quantity', (r) => r.quantity),
  ('price', (r) => r.price),
  ('grossAmount', (r) => r.grossAmount),
  ('fees', (r) => r.fees),
  ('taxWithheld', (r) => r.taxWithheld),
  ('currency', (r) => r.currency),
  ('fxSource', (r) => r.fxSource),
  ('fxDate', (r) => r.fxDate),
  ('fxRate', (r) => r.fxRate),
  ('fxDirection', (r) => r.fxDirection),
  ('originalAmount', (r) => r.originalAmount),
  ('originalCurrency', (r) => r.originalCurrency),
  ('valuationSource', (r) => r.valuationSource),
  ('linkId', (r) => r.linkId),
  ('linkKind', (r) => r.linkKind),
  ('account', (r) => r.account),
  ('note', (r) => r.note),
];

typedef _LedgerMerge = ({
  List<LedgerRecord> insert,
  List<String> markInKind,
  List<LedgerConflict> setAside,
});

_LedgerMerge _mergeLedger(
  List<LedgerRecord> local,
  List<LedgerRecord> incoming,
  List<Effect> effects,
) {
  final stored = {for (final row in local) row.key: row};
  final markInKind = <String>[];
  final setAside = <LedgerConflict>[];
  final blockedLinks = <String>{};

  for (final row in incoming) {
    final mine = stored[row.key];
    if (mine == null) continue;
    final fields = [
      for (final (name, read) in _ledgerCompared)
        if (read(mine) != read(row)) name,
    ];
    if (_instant(mine.ts) != _instant(row.ts)) fields.insert(0, 'ts');
    if (fields.isNotEmpty) {
      setAside.add(LedgerConflict(key: row.key, fields: fields));
      for (final side in [row, mine]) {
        if (side.linkId case final linkId?) {
          blockedLinks.add('${side.source}::$linkId');
        }
      }
    } else if (mine.funding == 'CASH' && row.funding == 'IN_KIND') {
      markInKind.add(row.key);
    }
  }

  final insert = <LedgerRecord>[];
  final since = <String, String>{};
  for (final row in incoming) {
    if (stored.containsKey(row.key)) continue;
    if (row.linkId case final linkId?
        when blockedLinks.contains('${row.source}::$linkId')) {
      continue;
    }
    insert.add(row);
    if (row.currency != _baseCurrency) {
      final first = since[row.currency];
      if (first == null || _instant(row.ts) < _instant(first)) {
        since[row.currency] = row.ts;
      }
    }
  }
  for (final MapEntry(key: currency, value: ts) in since.entries) {
    effects.add(RatesEffect(currency: currency, since: ts));
  }

  return (
    insert: stableSorted(
      insert,
      (a, b) => compareCodeUnits(a.key, b.key),
    ),
    markInKind: [...markInKind]..sort(compareCodeUnits),
    setAside: stableSorted(
      setAside,
      (a, b) => compareCodeUnits(a.key, b.key),
    ),
  );
}

typedef _InstrumentsMerge = ({
  List<InstrumentRecord> insert,
  List<InstrumentUpdate> update,
});

_InstrumentsMerge _mergeInstruments(
  List<InstrumentRecord> local,
  List<InstrumentRecord> incoming,
  _Side me,
  _Side them,
  _Conflicts conflicts,
  List<Restamp> restamp,
  List<Effect> effects,
) {
  final stored = {for (final row in local) row.id: row};
  final insert = <InstrumentRecord>[];
  final update = <InstrumentUpdate>[];

  for (final row in incoming) {
    final mine = stored[row.id];
    if (mine == null) {
      insert.add(row);
      if (row.quoteSymbol case final symbol? when symbol.isNotEmpty) {
        effects.add(PricesEffect(instrumentId: row.id, symbol: symbol));
      }
      continue;
    }

    final patch = <String, Object?>{};
    if (mine.assetClass == null && row.assetClass != null) {
      patch['assetClass'] = row.assetClass;
    }
    for (final field in InstrumentField.values) {
      if (field.columns.every(
        (v) => instrumentColumn(mine, v) == instrumentColumn(row, v),
      )) {
        continue;
      }
      final markOf = field.mark;
      var decision = _decide(
        me,
        them,
        instrumentColumn(mine, markOf) as String?,
        instrumentColumn(row, markOf) as String?,
      );
      if (decision == _Decision.conflict) {
        Object? valueOf(InstrumentRecord r) => field.columns.length == 1
            ? instrumentColumn(r, field.columns.single)
            : [for (final v in field.columns) instrumentColumn(r, v)];
        final resolution = conflicts.resolve(
          FieldConflict(
            entity: 'instrument',
            key: row.id,
            field: field.name,
            local: valueOf(mine),
            incoming: valueOf(row),
          ),
        );
        if (resolution != null) {
          decision = _Decision.values.byName(resolution.name);
        }
        if (decision == _Decision.keep) {
          restamp.add(InstrumentRestamp(row.id, field));
        }
      }
      if (decision == _Decision.take) {
        for (final v in field.columns) {
          patch[v] = instrumentColumn(row, v);
        }
        patch[markOf] = instrumentColumn(row, markOf);
      }
    }
    if (patch.isNotEmpty) update.add(InstrumentUpdate(row.id, patch));
    if (patch.containsKey('quoteSymbol')) {
      if (row.quoteSymbol case final symbol? when symbol.isNotEmpty) {
        effects.add(PricesEffect(instrumentId: row.id, symbol: symbol));
      }
    }
  }

  return (
    insert: stableSorted(insert, (a, b) => compareCodeUnits(a.id, b.id)),
    update: stableSorted(update, (a, b) => compareCodeUnits(a.id, b.id)),
  );
}

typedef _TargetsMerge = ({
  List<TargetRecord> insert,
  List<String> delete,
  List<Tombstone> tombstones,
});

_TargetsMerge _mergeTargets(
  SyncState local,
  Exchange incoming,
  _Conflicts conflicts,
  List<Restamp> restamp,
) {
  final buried = {for (final t in local.tombstones) t.key};
  final tombstones = stableSorted(
    [
      for (final t in incoming.tombstones)
        if (!buried.contains(t.key)) t,
    ],
    (a, b) => compareCodeUnits(a.key, b.key),
  );
  final dead = {...buried, for (final t in tombstones) t.key};

  final stored = {for (final t in local.targets) t.id: t};
  final insert = <TargetRecord>[];
  final remove = {
    for (final t in local.targets)
      if (dead.contains(t.id)) t.id,
  };
  final replaced = <String>{};
  for (final target in incoming.targets) {
    if (dead.contains(target.id)) continue;
    final mine = stored[target.id];
    if (mine == null) {
      insert.add(target);
      continue;
    }
    if (_same(mine.toJson(), target.toJson())) continue;
    final resolution = conflicts.resolve(TargetConflict(target.id));
    if (resolution == null) continue;
    remove.add(target.id);
    if (resolution == Resolution.take) {
      replaced.add(target.id);
      insert.add(target);
    } else {
      restamp.add(ReissueRestamp(mine));
    }
  }

  final localByDay = {
    for (final t in local.targets)
      if (!dead.contains(t.id) && !replaced.contains(t.id)) t.activeFrom: t.id,
  };
  final byDay = stableSorted(
    insert,
    (a, b) => compareCodeUnits(a.activeFrom, b.activeFrom),
  );
  for (final target in byDay) {
    final mine = localByDay[target.activeFrom];
    if (mine == null || mine == target.id) continue;
    final resolution = conflicts.resolve(
      TargetDayConflict(
        day: target.activeFrom,
        local: mine,
        incoming: target.id,
      ),
    );
    if (resolution == Resolution.take) {
      remove.add(mine);
      restamp.add(TombstoneRestamp(mine));
    } else if (resolution == Resolution.keep) {
      insert.remove(target);
      restamp.add(TombstoneRestamp(target.id));
    }
  }

  return (
    insert: stableSorted(insert, (a, b) => compareCodeUnits(a.id, b.id)),
    delete: [...remove]..sort(compareCodeUnits),
    tombstones: tombstones,
  );
}

List<HoldingsBlock> _mergeHoldings(
  List<HoldingsBlock> local,
  List<HoldingsBlock> incoming,
  _Side me,
  _Side them,
  _Conflicts conflicts,
  List<Restamp> restamp,
) {
  final stored = {for (final b in local) b.instrumentId: b};
  final replace = <HoldingsBlock>[];
  List<Map<String, Object?>> sortedRows(HoldingsBlock b) => [
        for (final row in stableSorted(
          b.rows,
          (x, y) => compareCodeUnits(x.identity, y.identity),
        ))
          row.toJson(),
      ];

  for (final block in incoming) {
    final mine = stored[block.instrumentId];
    if (mine == null) {
      replace.add(block);
      continue;
    }
    final sameRows =
        jsonEncode(sortedRows(mine)) == jsonEncode(sortedRows(block));
    if (sameRows &&
        mine.asOf == block.asOf &&
        mine.asOfInferred == block.asOfInferred) {
      continue;
    }
    final decision = _decide(me, them, mine.hlc, block.hlc);
    if (decision == _Decision.take) replace.add(block);
    if (decision != _Decision.conflict) continue;

    final bothRead = !mine.asOfInferred && !block.asOfInferred;
    if (bothRead && mine.asOf != block.asOf) {
      if (block.asOf.compareTo(mine.asOf) > 0) replace.add(block);
    } else if (sameRows) {
      if (mine.asOfInferred && !block.asOfInferred) replace.add(block);
    } else {
      final resolution =
          conflicts.resolve(HoldingsConflict(block.instrumentId));
      if (resolution == Resolution.take) replace.add(block);
      if (resolution == Resolution.keep) {
        restamp.add(HoldingsRestamp(block.instrumentId));
      }
    }
  }
  return stableSorted(
    replace,
    (a, b) => compareCodeUnits(a.instrumentId, b.instrumentId),
  );
}

bool _prefersIncoming(IdentityRecord mine, IdentityRecord theirs) {
  final mineResolved = mine.status == 'resolved';
  final theirsResolved = theirs.status == 'resolved';
  if (mineResolved != theirsResolved) return theirsResolved;
  if (mineResolved &&
      mine.canonicalId == theirs.canonicalId &&
      (mine.exchCode == null) != (theirs.exchCode == null)) {
    return theirs.exchCode != null;
  }
  return _instant(theirs.resolvedAt) > _instant(mine.resolvedAt);
}

List<IdentityRecord> _mergeIdentities(
  List<IdentityRecord> local,
  List<IdentityRecord> incoming,
) {
  final stored = {for (final row in local) row.identity: row};
  return stableSorted(
    [
      for (final row in incoming)
        if (stored[row.identity] case final mine?
            when !_same(mine.toJson(), row.toJson()) &&
                _prefersIncoming(mine, row))
          row
        else if (!stored.containsKey(row.identity))
          row,
    ],
    (a, b) => compareCodeUnits(a.identity, b.identity),
  );
}

List<Peer> _mergeSeen(_Side me, _Side them, String exportHlc) {
  final seen = {...me.seen};
  void raise(String deviceId, String mark) {
    if (deviceId == me.self) return;
    final current = seen[deviceId];
    if (current == null || mark.compareTo(current) > 0) seen[deviceId] = mark;
  }

  for (final MapEntry(key: deviceId, value: mark) in them.seen.entries) {
    raise(deviceId, mark);
  }
  raise(them.self, exportHlc);
  return stableSorted(
    [
      for (final MapEntry(:key, :value) in seen.entries)
        Peer(deviceId: key, seen: value)
    ],
    (a, b) => compareCodeUnits(a.deviceId, b.deviceId),
  );
}
