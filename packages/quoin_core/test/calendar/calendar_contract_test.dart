import 'dart:convert';
import 'dart:io';

import 'package:quoin_core/quoin_core.dart';
import 'package:test/test.dart';

void main() {
  final contract =
      jsonDecode(File('test/contract/calendar.json').readAsStringSync())
          as Map<String, dynamic>;
  List<Map<String, dynamic>> listOf(String key) =>
      (contract[key] as List<dynamic>).cast<Map<String, dynamic>>();

  group('calendar contract', () {
    for (final c in listOf('assignments')) {
      group(c['name'] as String, () {
        final instant = DateTime.parse(c['instant'] as String);
        final zone = c['zone'] as String;
        test('day', () => expect(dayOf(instant, zone), c['day']));
        test('period', () => expect(periodOf(instant, zone), c['period']));
        test(
          'fiscal year',
          () => expect(fiscalYearOf(instant, zone), c['fiscalYear']),
        );
      });
    }

    for (final c in listOf('startOfDay')) {
      test(c['name'] as String, () {
        final start = startOfDay(
          CalendarDate.parse(c['day'] as String),
          c['zone'] as String,
        );
        expect(start.toIso8601String(), c['instant']);
      });
    }
  });

  group('TARGET days', () {
    test('Easter 2026 closes Good Friday and Easter Monday', () {
      expect(easterSunday(2026), '2026-04-05');
      expect(isTargetBusinessDay('2026-04-03'), isFalse);
      expect(isTargetBusinessDay('2026-04-06'), isFalse);
      expect(isTargetBusinessDay('2026-04-07'), isTrue);
    });

    test('a weekend or a closing day books at the last TARGET day', () {
      expect(rateDayFor('2026-04-06'), '2026-04-02');
      expect(rateDayFor('2026-04-02'), '2026-04-02');
    });
  });

  test('shiftDay crosses months and years', () {
    expect(shiftDay('2026-12-31', 1), '2027-01-01');
    expect(shiftDay('2026-03-01', -1), '2026-02-28');
  });
}
