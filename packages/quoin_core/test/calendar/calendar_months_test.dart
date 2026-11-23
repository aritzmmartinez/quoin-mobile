import 'package:quoin_core/quoin_core.dart';
import 'package:test/test.dart';

void main() {
  CalendarDate d(String day) => CalendarDate.parse(day);

  test('moves by months and clamps the day to the end of the month', () {
    expect(addCalendarMonths(d('2025-03-31'), -1), d('2025-02-28'));
    expect(addCalendarMonths(d('2024-03-31'), -1), d('2024-02-29'));
    expect(addCalendarMonths(d('2025-12-31'), 2), d('2026-02-28'));
    expect(addCalendarMonths(d('2025-01-15'), -2), d('2024-11-15'));
    expect(addCalendarMonths(d('2024-11-04'), 12), d('2025-11-04'));
  });

  test('a window includes both ends', () {
    final start = d('2025-01-20');
    final end = d('2025-05-20');
    expect(isWithin(start, start, end), isTrue);
    expect(isWithin(end, start, end), isTrue);
    expect(isWithin(d('2025-01-19'), start, end), isFalse);
    expect(isWithin(d('2025-05-21'), start, end), isFalse);
  });
}
