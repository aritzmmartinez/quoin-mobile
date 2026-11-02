import 'dart:convert';
import 'dart:io';

import 'package:quoin_core/quoin_core.dart';
import 'package:test/test.dart';

const settings = {'residence': 'bizkaia', 'residenceHlc': null};

/// An incoming file as the contract writes it, with what it omits filled in.
Map<String, Object?> file(Map<String, Object?> fields) => {
      'schemaVersion': 1,
      'deviceName': null,
      'settings': settings,
      ...fields,
    };

Map<String, Object?> get valid => file({
      'deviceId': 'dev-b',
      'exportHlc': '001761600000000-0000-dev-b',
      'instruments': [
        {'id': 'IE00TEST0001', 'name': 'Test World ETF', 'type': 'ETF'},
      ],
      'ledger': [
        {
          'source': 'TR_CSV',
          'externalId': 't-1',
          'ts': '2026-03-31T23:30:00.000+01:00',
          'type': 'BUY',
          'instrumentId': 'IE00TEST0001',
          'quantity': '1.50',
          'price': '100.10',
          'grossAmount': '150.150',
          'currency': 'EUR',
          'account': 'trade-republic',
        },
      ],
    });

Matcher refused(String what) => throwsA(
    isA<InvalidExchange>().having((e) => e.issue, 'issue', contains(what)));

void main() {
  final contract =
      jsonDecode(File('test/contract/sync.json').readAsStringSync())
          as Map<String, dynamic>;

  group('sync contract refusals', () {
    for (final c in (contract['refusals'] as List<dynamic>)
        .cast<Map<String, dynamic>>()) {
      test(c['name'] as String, () {
        void read() {
          final incoming = parseExchange(c['file']);
          final local = SyncState.fromJson({
            'deviceId': c['localDeviceId'] ?? 'dev-a',
            'settings': settings,
          });
          refuseOwnExport(local, incoming);
        }

        final type = switch (c['error']) {
          'unsupported-schema-version' => isA<UnsupportedSchemaVersion>(),
          'same-device' => isA<SameDevice>(),
          'invalid' => isA<InvalidExchange>(),
          final other => throw StateError('Unknown error "$other"'),
        };
        expect(read, throwsA(type));
      });
    }
  });

  group('sync contract states', () {
    for (final c
        in (contract['merges'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      test('reads both sides of "${c['name']}"', () {
        final local = c['local'] as Map<String, dynamic>;
        SyncState.fromJson({'settings': settings, ...local});
        parseExchange(file(c['incoming'] as Map<String, dynamic>));
      });
    }
  });

  group('exchange format', () {
    test('fills in what a file omits, as zod defaults it', () {
      final read = parseExchange(valid);
      final row = read.ledger.single;
      final instrument = read.instruments.single;

      expect(row.fees, '0');
      expect(row.taxWithheld, '0');
      expect(row.fxSource, 'IDENTITY');
      expect(row.funding, 'CASH');
      expect(row.note, isNull);
      expect(instrument.thesis, 'CORE');
      expect(instrument.hedgedToBase, isFalse);
      expect(read.targets, isEmpty);
      expect(read.peers, isEmpty);
    });

    test('keeps every amount and instant exactly as written', () {
      final json = jsonEncode(parseExchange(valid).toJson());
      final again = parseExchange(jsonDecode(json));

      expect(again.toJson(), parseExchange(valid).toJson());
      expect(again.ledger.single.quantity, '1.50');
      expect(again.ledger.single.grossAmount, '150.150');
      expect(again.ledger.single.ts, '2026-03-31T23:30:00.000+01:00');
    });

    test('ignores keys it does not know', () {
      final read = parseExchange({...valid, 'futureField': 1});

      expect(read.toJson().containsKey('futureField'), isFalse);
    });

    test('refuses a field of the wrong type', () {
      final row =
          (valid['ledger']! as List<Object?>).single! as Map<String, Object?>;
      Map<String, Object?> withRow(Map<String, Object?> change) => {
            ...valid,
            'ledger': [
              {...row, ...change}
            ]
          };

      expect(() => parseExchange(withRow({'grossAmount': 150})),
          refused('grossAmount'));
      expect(() => parseExchange(withRow({'fees': null})), refused('fees'));
      expect(() => parseExchange(withRow({'type': 'FEE'})), refused('type'));
      expect(() => parseExchange(withRow({'externalId': ''})),
          refused('externalId'));
      expect(
          () => parseExchange(withRow({'account': null})), refused('account'));
    });

    test('accepts only instants with seconds and a zone, and real days', () {
      for (final good in [
        '2026-01-05T09:00:00Z',
        '2026-01-05T09:00:00.123456Z',
        '2026-03-31T23:30:00.000+01:00',
        '2028-02-29T00:00:00Z',
      ]) {
        expect(isIsoInstant(good), isTrue, reason: good);
      }
      for (final bad in [
        '2026-01-05',
        '2026-01-05 09:00:00Z',
        '2026-01-05T09:00Z',
        '2026-01-05T09:00:00',
        '2026-01-05T24:00:00Z',
        '2026-02-29T09:00:00Z',
        '2026-01-05T09:00:00+0100',
        '+002026-01-05T09:00:00Z',
      ]) {
        expect(isIsoInstant(bad), isFalse, reason: bad);
      }
      expect(isIsoDay('2026-09-30'), isTrue);
      expect(isIsoDay('2026-09-31'), isFalse);
      expect(isIsoDay('2100-02-29'), isFalse);
      expect(isIsoDay('2000-02-29'), isTrue);
    });

    test('refuses a ledger key that appears twice', () {
      final row = (valid['ledger']! as List<Object?>).single;

      expect(
        () => parseExchange({
          ...valid,
          'ledger': [row, row]
        }),
        refused('appears twice'),
      );
    });

    test('refuses an export that is not valid as it is built', () {
      final state = SyncState.fromJson({
        'deviceId': 'dev-a',
        'settings': settings,
      });

      expect(
        () => Exchange.of(state, exportHlc: '001761600000000-0000-dev-b'),
        refused('another device'),
      );
    });
  });
}
