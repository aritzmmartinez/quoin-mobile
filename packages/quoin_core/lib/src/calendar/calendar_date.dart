import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// A day on the calendar, with no zone: what an instant falls on once it is
/// read in one.
final class CalendarDate implements Comparable<CalendarDate> {
  CalendarDate(this.year, this.month, this.day) {
    if (month < 1 || month > 12 || day < 1 || day > _daysInMonth(year, month)) {
      throw RangeError('Not a calendar date: $year-$month-$day');
    }
  }

  static final RegExp _iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  /// Inverse of [toString]; refuses anything that is not a real `YYYY-MM-DD`.
  factory CalendarDate.parse(String value) {
    final match = _iso.firstMatch(value);
    if (match == null) throw RangeError('Not a YYYY-MM-DD date: $value');
    return CalendarDate(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
  }

  final int year;
  final int month;
  final int day;

  @override
  int compareTo(CalendarDate other) => year != other.year
      ? year.compareTo(other.year)
      : month != other.month
          ? month.compareTo(other.month)
          : day.compareTo(other.day);

  @override
  bool operator ==(Object other) =>
      other is CalendarDate && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(year, month, day);

  /// `YYYY-MM-DD`.
  @override
  String toString() => '${'$year'.padLeft(4, '0')}-${'$month'.padLeft(2, '0')}-'
      '${'$day'.padLeft(2, '0')}';
}

int _daysInMonth(int year, int month) => DateTime.utc(year, month + 1, 0).day;

var _zonesLoaded = false;

/// The IANA database is compiled into the package (`latest_all`), so it loads
/// the same way under `dart test` and in the app, with no asset to ship.
tz.Location _location(String zone) {
  if (!_zonesLoaded) {
    tzdata.initializeTimeZones();
    _zonesLoaded = true;
  }
  return tz.getLocation(zone);
}

/// The calendar day [instant] falls on, read in [zone] (an IANA name).
CalendarDate calendarDateOf(DateTime instant, String zone) {
  final local = tz.TZDateTime.from(instant, _location(zone));
  return CalendarDate(local.year, local.month, local.day);
}

/// The instant [date] begins in [zone], in UTC. Throws for a zone whose clocks
/// skip midnight itself (none of the zones Quoin resolves to do).
DateTime startOfDay(CalendarDate date, String zone) {
  final start = tz.TZDateTime(_location(zone), date.year, date.month, date.day);
  if (CalendarDate(start.year, start.month, start.day) != date ||
      start.hour != 0 ||
      start.minute != 0 ||
      start.second != 0) {
    throw RangeError('$date has no midnight in $zone');
  }
  return DateTime.fromMillisecondsSinceEpoch(
    start.millisecondsSinceEpoch,
    isUtc: true,
  );
}
