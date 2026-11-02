import 'package:quoin_core/quoin_core.dart';
import 'package:test/test.dart';

const device = '3f2a9c1e-0b7d-4e21-9a55-6c0d8e7f1a2b';
final t = DateTime.utc(2026, 10, 28, 9, 15).millisecondsSinceEpoch;

String mark(int ms, int counter) =>
    formatHlc((ms: ms, counter: counter, deviceId: device));

void main() {
  group('HLC marks', () {
    test('round-trip through their text form, which sorts as time does', () {
      final m = mark(t, 7);

      expect(m, '00$t-0007-$device');
      expect(parseHlc(m), (ms: t, counter: 7, deviceId: device));
      expect(originOf(m), device);
      expect(mark(999, 0).compareTo(m), isNegative);
    });

    test('refuse a value that is not a mark', () {
      expect(
          () => parseHlc('2026-10-28T09:15:00Z'), throwsA(isA<InvalidHlc>()));
      expect(() => parseHlc('$t-0000-$device'), throwsA(isA<InvalidHlc>()));
    });

    test('take the physical clock when it is ahead', () {
      expect(tick(null, t, device), mark(t, 0));
      expect(tick(mark(t - 1, 3), t, device), mark(t, 0));
    });

    test('never go back when the clock does, or stands still', () {
      final last = mark(t, 3);

      final same = tick(last, t, device);
      final behind = tick(same, t - 10 * 60000, device);

      expect(same, mark(t, 4));
      expect(behind, mark(t, 5));
      expect(behind.compareTo(same), isPositive);
      expect(same.compareTo(last), isPositive);
    });

    test('move to the next millisecond when the counter is spent', () {
      final last = mark(t, 9999);
      final next = tick(last, t, device);

      expect(next, mark(t + 1, 0));
      expect(next.compareTo(last), isPositive);
    });

    test('keep the time of a mark issued under another device id', () {
      final old = formatHlc((ms: t, counter: 2, deviceId: 'old-device'));

      expect(tick(old, t - 1, device), mark(t, 3));
    });
  });
}
