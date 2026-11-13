import 'package:quoin_core/quoin_core.dart';
import 'package:test/test.dart';

void main() {
  group('latestEcbDay', () {
    test('a TARGET day counts from 16:30 on Frankfurt clocks', () {
      // Winter, UTC+1.
      expect(latestEcbDay(DateTime.utc(2026, 11, 11, 15, 29)), '2026-11-10');
      expect(latestEcbDay(DateTime.utc(2026, 11, 11, 15, 30)), '2026-11-11');
      // Summer, UTC+2.
      expect(latestEcbDay(DateTime.utc(2026, 7, 15, 14, 29)), '2026-07-14');
      expect(latestEcbDay(DateTime.utc(2026, 7, 15, 14, 30)), '2026-07-15');
    });

    test('the day the clocks change keeps 16:30 local', () {
      // 2026-03-29: CET to CEST, so 16:30 local is 14:30 UTC.
      // A Sunday, so the day to compare is the Friday before.
      expect(latestEcbDay(DateTime.utc(2026, 3, 30, 14, 29)), '2026-03-27');
      expect(latestEcbDay(DateTime.utc(2026, 3, 30, 14, 30)), '2026-03-30');
      // 2026-10-26, the Monday after CEST to CET: 16:30 local is 15:30 UTC.
      expect(latestEcbDay(DateTime.utc(2026, 10, 26, 15, 29)), '2026-10-23');
      expect(latestEcbDay(DateTime.utc(2026, 10, 26, 15, 30)), '2026-10-26');
    });

    test('weekends and TARGET closings fall back to the last business day', () {
      expect(latestEcbDay(DateTime.utc(2026, 11, 14, 12)), '2026-11-13');
      expect(latestEcbDay(DateTime.utc(2026, 11, 16, 9)), '2026-11-13');
      // Good Friday and Easter Monday 2026.
      expect(latestEcbDay(DateTime.utc(2026, 4, 3, 18)), '2026-04-02');
      expect(latestEcbDay(DateTime.utc(2026, 4, 6, 18)), '2026-04-02');
      expect(latestEcbDay(DateTime.utc(2026, 4, 7, 9)), '2026-04-02');
      // 25 and 26 December, then the weekend.
      expect(latestEcbDay(DateTime.utc(2026, 12, 28, 9)), '2026-12-24');
      expect(latestEcbDay(DateTime.utc(2027, 1, 1, 18)), '2026-12-31');
    });
  });

  group('ecbFetchFrom', () {
    final afterPublication = DateTime.utc(2026, 11, 11, 17);

    test('nothing stored asks from what is needed', () {
      expect(
        ecbFetchFrom(
          needed: '2026-01-01',
          firstUse: '2026-01-08',
          stored: (first: null, last: null),
          now: afterPublication,
        ),
        '2026-01-01',
      );
    });

    test('a series that holds the newest published day asks nothing', () {
      expect(
        ecbFetchFrom(
          needed: '2026-01-01',
          firstUse: '2026-01-08',
          stored: (first: '2025-12-01', last: '2026-11-11'),
          now: afterPublication,
        ),
        isNull,
      );
      expect(
        ecbFetchFrom(
          needed: '2026-01-01',
          firstUse: '2026-01-08',
          stored: (first: '2025-12-01', last: '2026-11-10'),
          now: DateTime.utc(2026, 11, 11, 9),
        ),
        isNull,
        reason: 'before 16:30 the day before is the newest out',
      );
    });

    test('a series behind the schedule asks from its last day', () {
      expect(
        ecbFetchFrom(
          needed: '2026-01-01',
          firstUse: '2026-01-08',
          stored: (first: '2025-12-01', last: '2026-11-10'),
          now: afterPublication,
        ),
        '2026-11-10',
      );
    });

    test(
        'a first use before what is stored asks from what is needed, even '
        'when the series is up to date', () {
      expect(
        ecbFetchFrom(
          needed: '2025-10-01',
          firstUse: '2025-10-08',
          stored: (first: '2025-12-01', last: '2026-11-11'),
          now: afterPublication,
        ),
        '2025-10-01',
      );
    });
  });

  group('EcbHold', () {
    final now = DateTime.utc(2026, 11, 11, 17);

    test('an answer without the expected day holds the currency 15 minutes',
        () {
      final hold = EcbHold();
      hold.answered('USD', '2026-11-10', now);
      expect(hold.holds('USD', now.add(const Duration(minutes: 14))), isTrue);
      expect(hold.holds('USD', now.add(const Duration(minutes: 15))), isFalse);
      expect(hold.holds('GBP', now), isFalse);
    });

    test('an empty answer holds too; one with the day releases it', () {
      final hold = EcbHold()..answered('USD', null, now);
      expect(hold.holds('USD', now), isTrue);
      hold.answered('USD', '2026-11-11', now);
      expect(hold.holds('USD', now), isFalse);
    });
  });
}
