import 'dart:math' as math;

import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

final class CalendarDate implements Comparable<CalendarDate> {
  CalendarDate(this.year, this.month, this.day) {
    if (month < 1 || month > 12 || day < 1 || day > _daysInMonth(year, month)) {
      throw RangeError('Not a calendar date: $year-$month-$day');
    }
  }

  static final RegExp _iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

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

CalendarDate addCalendarMonths(CalendarDate date, int months) {
  final index = date.year * 12 + (date.month - 1) + months;
  final year = index ~/ 12;
  final month = index - year * 12 + 1;
  return CalendarDate(
    year,
    month,
    math.min(date.day, _daysInMonth(year, month)),
  );
}

bool isWithin(CalendarDate date, CalendarDate start, CalendarDate end) =>
    date.compareTo(start) >= 0 && date.compareTo(end) <= 0;

var _zonesLoaded = false;

tz.Location _location(String zone) {
  if (!_zonesLoaded) {
    tzdata.initializeTimeZones();
    _zonesLoaded = true;
  }
  return tz.getLocation(zone);
}

CalendarDate calendarDateOf(DateTime instant, String zone) {
  final local = tz.TZDateTime.from(instant, _location(zone));
  return CalendarDate(local.year, local.month, local.day);
}

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
