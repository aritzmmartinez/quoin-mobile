import 'dart:convert';
import 'dart:io';

import 'package:quoin_core/quoin_core.dart';
import 'package:test/test.dart';

const settings = {'residence': 'bizkaia', 'residenceHlc': null};

typedef Json = Map<String, Object?>;

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

Json expectedApply(Json apply) {
  List<Json> each(Object? raw, Json Function(Json row) read) =>
      [for (final row in rows(raw)) read(row)];
  final ledger = (apply['ledger'] ?? const <String, Object?>{}) as Json;
  final instruments =
      (apply['instruments'] ?? const <String, Object?>{}) as Json;
  final targets = (apply['targets'] ?? const <String, Object?>{}) as Json;
  return {
    'ledger': {
      'insert':
          each(ledger['insert'], (r) => LedgerRecord.fromJson(r).toJson()),
      'markInKind': ledger['markInKind'] ?? const <String>[],
    },
    'instruments': {
      'insert': each(
          instruments['insert'], (r) => InstrumentRecord.fromJson(r).toJson()),
      'update': instruments['update'] ?? const <Object?>[],
    },
    'targets': {
      'insert':
          each(targets['insert'], (r) => TargetRecord.fromJson(r).toJson()),
      'delete': targets['delete'] ?? const <String>[],
    },
    'tombstones':
        each(apply['tombstones'], (r) => Tombstone.fromJson(r).toJson()),
    'holdings':
        each(apply['holdings'], (r) => HoldingsBlock.fromJson(r).toJson()),
    'identities':
        each(apply['identities'], (r) => IdentityRecord.fromJson(r).toJson()),
    'settings': apply['settings'] == null
        ? null
        : SettingsRecord.fromJson(apply['settings']).toJson(),
    'restamp': each(apply['restamp'], (r) {
      if (r['kind'] != 'reissue') return r;
      return {
        'kind': 'reissue',
        'target': TargetRecord.fromJson(r['target']).toJson()
      };
    }),
  };
}

void main() {
  final contract =
      jsonDecode(File('test/contract/sync.json').readAsStringSync()) as Json;

  group('sync contract merges', () {
    for (final c in rows(contract['merges'])) {
      final expected = c['expected']! as Json;
      final local = stateOf(c['local']);
      final incoming = exchangeOf(c['incoming']);
      final resolutions = resolutionsOf(c['resolutions']);

      if (expected['error'] != null) {
        test('${c['name']}: refuses the resolutions', () {
          expect(
            () => merge(local, incoming, resolutions),
            throwsA(isA<UnknownResolution>()),
          );
        });
        continue;
      }

      group(c['name']! as String, () {
        final plan = merge(local, incoming, resolutions);
        final conflicts = rows(expected['conflicts']);

        test('raises exactly the conflicts on file', () {
          expect(plain([for (final x in plan.conflicts) x.toJson()]),
              plain(conflicts));
        });

        test('sets aside exactly the ledger rows on file', () {
          expect(plain([for (final x in plan.setAside) x.toJson()]),
              plain(rows(expected['setAside'])));
        });

        if (conflicts.isEmpty || expected['compareApply'] == true) {
          test('applies exactly what is on file', () {
            final apply =
                (expected['apply'] ?? const <String, Object?>{}) as Json;
            final planned = plain(plan.apply.toJson())! as Json;
            final peers = planned.remove('peers');
            expect(planned, plain(expectedApply(apply)));
            if (apply['peers'] != null) expect(peers, plain(apply['peers']));
          });
        }

        if (conflicts.isEmpty) {
          test('leaves exactly the effects on file', () {
            expect(plain([for (final x in plan.effects) x.toJson()]),
                plain(rows(expected['effects'])));
          });
        }
      });
    }
  });

  group('sync contract scenarios', () {
    for (final c in rows(contract['scenarios'])) {
      test(c['name']! as String, () {
        final held = {
          for (final MapEntry(:key, :value) in (c['devices']! as Json).entries)
            key: LocalDevice(
              state: stateOf((value! as Json)['state']),
              lastHlc: (value as Json)['lastHlc'] as String?,
            ),
        };
        LocalDevice get(String id) =>
            held[id] ?? (throw StateError('No device $id in the scenario'));
        final apart = <String, Map<String, List<String>>>{};

        for (final (i, step) in rows(c['steps']).indexed) {
          final label = 'step ${i + 1}';
          final nowMs = step['nowMs']! as int;
          if (step['edit'] case final String id) {
            final device = get(id);
            held[id] = applyPlan(
              device,
              ApplyPlan.fromJson({
                ...step['apply']! as Json,
                'peers': [for (final p in device.state.peers) p.toJson()],
              }),
              nowMs,
            );
            continue;
          }
          final from = step['from']! as String;
          final to = step['to']! as String;
          final sent = exportDevice(get(from), nowMs);
          held[from] = sent.device;
          final receiver = get(to);
          final plan = merge(
            receiver.state,
            sent.exchange,
            resolutionsOf(step['resolutions']),
          );

          expect(
            [for (final x in plan.conflicts) conflictKey(x)],
            (step['conflicts'] as List<Object?>? ?? const []).cast<String>(),
            reason: label,
          );
          expect(
            [for (final x in plan.setAside) x.key],
            (step['setAside'] as List<Object?>? ?? const []).cast<String>(),
            reason: label,
          );
          (apart[to] ??= {})[from] = [for (final x in plan.setAside) x.key];
          if (step['apply'] case final Json apply) {
            final planned = plain(plan.apply.toJson())! as Json;
            final peers = planned.remove('peers');
            expect(planned, plain(expectedApply(apply)), reason: label);
            if (apply['peers'] != null) {
              expect(peers, plain(apply['peers']), reason: label);
            }
          }
          if (plan.conflicts.isNotEmpty) {
            expect('conflicts', step['status'], reason: label);
          } else if (!plan.changesData) {
            expect('up-to-date', step['status'], reason: label);
            held[to] = LocalDevice(
              state: SyncState(
                deviceId: receiver.state.deviceId,
                peers: plan.apply.peers,
                ledger: receiver.state.ledger,
                instruments: receiver.state.instruments,
                targets: receiver.state.targets,
                tombstones: receiver.state.tombstones,
                holdings: receiver.state.holdings,
                identities: receiver.state.identities,
                settings: receiver.state.settings,
              ),
              lastHlc: receiver.lastHlc,
            );
          } else {
            expect('applied', step['status'], reason: label);
            held[to] = applyPlan(receiver, plan.apply, nowMs);
          }
        }

        Object? userState(LocalDevice d) {
          final json = d.state.toJson()
            ..remove('deviceId')
            ..remove('peers');
          return plain(json);
        }

        if (c['end'] case final Json end) {
          expect(held.keys, end.keys);
          for (final MapEntry(key: id, :value) in end.entries) {
            final expected = value! as Json;
            expect(
              plain(get(id).state.toJson()),
              plain(stateOf(expected['state']).toJson()),
              reason: id,
            );
            expect(apart[id], plain(expected['setAside']), reason: id);
          }
        }
        if (c['converged'] == null) {
          expect(c['end'], isNotNull, reason: 'states converged or end');
          return;
        }
        final [first, second] = held.values.toList();
        if (c['converged'] == true) {
          expect(userState(first), userState(second));
        } else {
          expect(userState(first), isNot(userState(second)));
        }
      });
    }
  });

  test('a plan reads back as it is written', () {
    for (final c in rows(contract['merges'])) {
      if ((c['expected']! as Json)['error'] != null) continue;
      final plan = merge(
        stateOf(c['local']),
        exchangeOf(c['incoming']),
        resolutionsOf(c['resolutions']),
      ).apply;
      final json = plain(plan.toJson())! as Json;
      expect(plain(ApplyPlan.fromJson(json).toJson()), json,
          reason: '${c['name']}');
    }
  });

  group('plan counts', () {
    test('count what a plan writes, new rows apart from replaced ones', () {
      final c = rows(contract['merges']).firstWhere(
        (c) =>
            (c['expected']! as Json)['apply'] is Json &&
            rows(((c['expected']! as Json)['apply']! as Json)['holdings'])
                .isNotEmpty,
      );
      final local = stateOf(c['local']);
      final plan = merge(
        local,
        exchangeOf(c['incoming']),
        resolutionsOf(c['resolutions']),
      );
      final counts = planCounts(plan, local);

      expect(
        counts.newHoldings + counts.replacedHoldings,
        plan.apply.holdings.length,
      );
      expect(counts.setAside, plan.setAside.length);
      expect(counts.restamped, plan.apply.restamp.length);
    });
  });
}
