import 'package:quoin_core/src/sync/exchange.dart';
import 'package:quoin_core/src/sync/merge.dart';

const detailNames = 20;

final class Cut<T> {
  const Cut(this.items, this.total);

  Cut.of(List<T> all)
      : items = all.take(detailNames).toList(),
        total = all.length;

  const Cut.empty()
      : items = const [],
        total = 0;

  final List<T> items;
  final int total;

  int get more => total - items.length;

  Cut<T> plus(Cut<T> other) => Cut(
        [...items, ...other.items].take(detailNames).toList(),
        total + other.total,
      );

  Map<String, Object?> toJson(Object? Function(T) item) => {
        'items': [for (final i in items) item(i)],
        'total': total,
      };

  static Cut<T> fromJson<T>(Object? json, T? Function(Object?) item) =>
      switch (json) {
        {'items': final List<Object?> items, 'total': final int total} => Cut(
            [
              for (final raw in items)
                if (item(raw) case final T value) value,
            ],
            total,
          ),
        _ => const Cut.empty(),
      };
}

enum DetailField {
  quoteSymbol,
  exposure,
  ter,
  hedgedToBase,
  thesis,
  assetClass,
}

final class InstrumentChange {
  const InstrumentChange(this.name, this.fields);

  final String name;
  final List<DetailField> fields;

  Map<String, Object?> toJson() => {
        'name': name,
        'fields': [for (final f in fields) f.name],
      };

  static InstrumentChange? fromJson(Object? json) => switch (json) {
        {'name': final String name, 'fields': final List<Object?> fields} =>
          InstrumentChange(name, [
            for (final f in fields)
              if (DetailField.values.asNameMap()[f] case final field?) field,
          ]),
        _ => null,
      };
}

final class SetAsideRow {
  const SetAsideRow({
    required this.ts,
    required this.type,
    required this.instrument,
    required this.fields,
  });

  final String ts;
  final String type;
  final String? instrument;
  final List<String> fields;

  Map<String, Object?> toJson() => {
        'ts': ts,
        'type': type,
        'instrument': instrument,
        'fields': fields,
      };

  static SetAsideRow? fromJson(Object? json) => switch (json) {
        {
          'ts': final String ts,
          'type': final String type,
          'fields': final List<Object?> fields,
        } =>
          SetAsideRow(
            ts: ts,
            type: type,
            instrument: json['instrument'] as String?,
            fields: [
              for (final f in fields)
                if (f is String) f,
            ],
          ),
        _ => null,
      };
}

enum ResolvedKind { instrument, residence, target, targetDay, holdings }

final class ResolvedConflict {
  const ResolvedConflict({
    required this.kind,
    required this.subject,
    required this.resolution,
    this.field,
  });

  final ResolvedKind kind;
  final String subject;
  final DetailField? field;
  final Resolution resolution;

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'subject': subject,
        'field': field?.name,
        'resolution': resolution.name,
      };

  static ResolvedConflict? fromJson(Object? json) {
    if (json
        case {
          'kind': final String kind,
          'subject': final String subject,
          'resolution': final String resolution,
        }) {
      final k = ResolvedKind.values.asNameMap()[kind];
      final r = Resolution.values.asNameMap()[resolution];
      if (k == null || r == null) return null;
      return ResolvedConflict(
        kind: k,
        subject: subject,
        field: DetailField.values.asNameMap()[json['field']],
        resolution: r,
      );
    }
    return null;
  }
}

final class SyncDetail {
  const SyncDetail({
    this.newInstruments = const Cut.empty(),
    this.changedInstruments = const Cut.empty(),
    this.ledger = const {},
    this.inKind = 0,
    this.newTargets = const Cut.empty(),
    this.deletedTargets = const Cut.empty(),
    this.compositions = const Cut.empty(),
    this.residence = false,
    this.setAside = const Cut.empty(),
    this.resolved = const Cut.empty(),
  });

  final Cut<String> newInstruments;
  final Cut<InstrumentChange> changedInstruments;
  final Map<String, int> ledger;
  final int inKind;
  final Cut<String> newTargets;
  final Cut<String> deletedTargets;
  final Cut<String> compositions;
  final bool residence;
  final Cut<SetAsideRow> setAside;
  final Cut<ResolvedConflict> resolved;

  int get ledgerRows => ledger.values.fold(0, (a, b) => a + b);

  bool get writesNothing =>
      newInstruments.total == 0 &&
      changedInstruments.total == 0 &&
      ledgerRows == 0 &&
      inKind == 0 &&
      newTargets.total == 0 &&
      deletedTargets.total == 0 &&
      compositions.total == 0 &&
      !residence;

  SyncDetail plus(SyncDetail other) => SyncDetail(
        newInstruments: newInstruments.plus(other.newInstruments),
        changedInstruments: changedInstruments.plus(other.changedInstruments),
        ledger: {
          for (final type in {...ledger.keys, ...other.ledger.keys})
            type: (ledger[type] ?? 0) + (other.ledger[type] ?? 0),
        },
        inKind: inKind + other.inKind,
        newTargets: newTargets.plus(other.newTargets),
        deletedTargets: deletedTargets.plus(other.deletedTargets),
        compositions: compositions.plus(other.compositions),
        residence: residence || other.residence,
        setAside: other.setAside.total > 0 ? other.setAside : setAside,
        resolved: resolved.plus(other.resolved),
      );

  Map<String, Object?> toJson() => {
        'newInstruments': newInstruments.toJson((n) => n),
        'changedInstruments': changedInstruments.toJson((c) => c.toJson()),
        'ledger': ledger,
        'inKind': inKind,
        'newTargets': newTargets.toJson((n) => n),
        'deletedTargets': deletedTargets.toJson((n) => n),
        'compositions': compositions.toJson((n) => n),
        'residence': residence,
        'setAside': setAside.toJson((r) => r.toJson()),
        'resolved': resolved.toJson((r) => r.toJson()),
      };

  static SyncDetail fromJson(Object? json) {
    if (json is! Map<String, Object?>) return const SyncDetail();
    String? name(Object? raw) => raw is String ? raw : null;
    return SyncDetail(
      newInstruments: Cut.fromJson(json['newInstruments'], name),
      changedInstruments: Cut.fromJson(
        json['changedInstruments'],
        InstrumentChange.fromJson,
      ),
      ledger: {
        if (json['ledger'] case final Map<String, Object?> ledger)
          for (final MapEntry(:key, :value) in ledger.entries)
            if (value is int) key: value,
      },
      inKind: json['inKind'] as int? ?? 0,
      newTargets: Cut.fromJson(json['newTargets'], name),
      deletedTargets: Cut.fromJson(json['deletedTargets'], name),
      compositions: Cut.fromJson(json['compositions'], name),
      residence: json['residence'] == true,
      setAside: Cut.fromJson(json['setAside'], SetAsideRow.fromJson),
      resolved: Cut.fromJson(json['resolved'], ResolvedConflict.fromJson),
    );
  }
}

Map<String, String> instrumentNames(
  MergePlan plan,
  SyncState local,
  SyncState incoming,
) =>
    {
      for (final i in incoming.instruments) i.id: i.name,
      for (final i in local.instruments) i.id: i.name,
      for (final i in plan.apply.instrumentInsert) i.id: i.name,
    };

SyncDetail syncDetail(
  MergePlan plan,
  SyncState local,
  SyncState incoming, {
  List<Conflict> conflicts = const [],
  Resolutions resolutions = const {},
}) {
  final apply = plan.apply;
  final names = instrumentNames(plan, local, incoming);
  final targets = {
    for (final t in incoming.targets) t.id: t.name,
    for (final t in local.targets) t.id: t.name,
  };
  final rows = {for (final row in local.ledger) row.key: row};
  String instrument(String id) => names[id] ?? '';

  final ledger = <String, int>{};
  for (final row in apply.ledgerInsert) {
    ledger[row.type] = (ledger[row.type] ?? 0) + 1;
  }

  return SyncDetail(
    newInstruments: Cut.of([for (final i in apply.instrumentInsert) i.name]),
    changedInstruments: Cut.of([
      for (final InstrumentUpdate(:id, :patch) in apply.instrumentUpdate)
        if (_fields(patch) case final fields when fields.isNotEmpty)
          InstrumentChange(instrument(id), fields),
    ]),
    ledger: ledger,
    inKind: apply.markInKind.length,
    newTargets: Cut.of([for (final t in apply.targetInsert) t.name]),
    deletedTargets: Cut.of([
      for (final id in apply.targetDelete)
        if (targets[id] case final name?) name,
    ]),
    compositions: Cut.of([
      for (final block in apply.holdings) instrument(block.instrumentId),
    ]),
    residence: switch (apply.settings) {
      final settings? => settings.residence != local.settings.residence,
      null => false,
    },
    setAside: Cut.of([
      for (final LedgerConflict(:key, :fields) in plan.setAside)
        if (rows[key] case final row?)
          SetAsideRow(
            ts: row.ts,
            type: row.type,
            instrument: switch (row.instrumentId) {
              final id? => instrument(id),
              null => null,
            },
            fields: fields,
          ),
    ]),
    resolved: Cut.of([
      for (final conflict in conflicts)
        if (resolutions[conflictKey(conflict)] case final resolution?)
          switch (conflict) {
            FieldConflict(entity: 'settings') => ResolvedConflict(
                kind: ResolvedKind.residence,
                subject: '',
                resolution: resolution,
              ),
            FieldConflict(:final key, :final field) => ResolvedConflict(
                kind: ResolvedKind.instrument,
                subject: instrument(key),
                field: DetailField.values.asNameMap()[field],
                resolution: resolution,
              ),
            TargetConflict(:final id) => ResolvedConflict(
                kind: ResolvedKind.target,
                subject: targets[id] ?? '',
                resolution: resolution,
              ),
            TargetDayConflict(:final day) => ResolvedConflict(
                kind: ResolvedKind.targetDay,
                subject: day,
                resolution: resolution,
              ),
            HoldingsConflict(:final instrumentId) => ResolvedConflict(
                kind: ResolvedKind.holdings,
                subject: instrument(instrumentId),
                resolution: resolution,
              ),
          },
    ]),
  );
}

List<DetailField> _fields(Map<String, Object?> patch) => [
      for (final field in InstrumentField.values)
        if (field.columns.any(patch.containsKey))
          DetailField.values.byName(field.name),
      if (patch.containsKey('assetClass')) DetailField.assetClass,
    ];
