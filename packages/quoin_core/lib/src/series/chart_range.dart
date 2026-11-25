import '../calendar/day.dart';
import '../decimal/dec.dart';
import '../fx/value.dart';
import '../projections/market_value.dart';

final class DayValue {
  const DayValue(this.day, this.value);

  final String day;
  final Dec value;

  @override
  bool operator ==(Object other) =>
      other is DayValue && other.day == day && other.value == value;

  @override
  int get hashCode => Object.hash(day, value);

  @override
  String toString() => '$day $value';
}

enum ChartRange {
  week(7),
  month(30),
  halfYear(182),
  year(365),
  max(null);

  const ChartRange(this.days);

  final int? days;
}

List<DayValue> dailyCloses(List<PriceSnapshot> history, String zone) {
  final sorted = [...history]..sort((a, b) => a.asOf.compareTo(b.asOf));
  final byDay = <String, DayValue>{};
  for (final snapshot in sorted) {
    final day = dayOf(snapshot.asOf, zone);
    byDay[day] = DayValue(day, snapshot.price.amount);
  }
  return byDay.values.toList();
}

const int baseMaxAgeDays = 7;

final class ChartWindow {
  ChartWindow._(this.points);

  final List<DayValue> points;

  DayValue get first => points.first;
  DayValue get last => points.last;

  Dec get change => last.value - first.value;
  Dec? get changeRatio => first.value.isZero
      ? null
      : change.dividedBy(first.value).roundTo(ratioDecimals);
}

ChartWindow? cutRange(List<DayValue> points, ChartRange range, String today) {
  final start = _startOf(points, range, today);
  if (points.length - start < 2) return null;
  return ChartWindow._(List.unmodifiable(points.sublist(start)));
}

List<ChartRange> rangesOf(List<DayValue> points, String today) => [
      for (final range in ChartRange.values)
        if (range == ChartRange.max ||
            (_startOf(points, range, today) > 0 &&
                cutRange(points, range, today) != null))
          range,
    ];

int _startOf(List<DayValue> points, ChartRange range, String today) {
  final days = range.days;
  if (days == null) return 0;
  final cutoff = shiftDay(today, -days);
  final inside = points.indexWhere((p) => p.day.compareTo(cutoff) > 0);
  if (inside < 0) return points.length;
  // A base from before a long gap would draw weeks of flat line.
  final oldest = shiftDay(cutoff, -baseMaxAgeDays);
  return inside > 0 && points[inside - 1].day.compareTo(oldest) >= 0
      ? inside - 1
      : inside;
}
