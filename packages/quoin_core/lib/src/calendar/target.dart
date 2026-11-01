import 'calendar_date.dart';
import 'day.dart';

String easterSunday(int year) {
  final a = year % 19;
  final b = year ~/ 100;
  final c = year % 100;
  final d = b ~/ 4;
  final e = b % 4;
  final f = (b + 8) ~/ 25;
  final g = (b - f + 1) ~/ 3;
  final h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4;
  final k = c % 4;
  final l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 22 * l) ~/ 451;
  final month = (h + l - 7 * m + 114) ~/ 31;
  final day = ((h + l - 7 * m + 114) % 31) + 1;
  return CalendarDate(year, month, day).toString();
}

Set<String> _closingDays(int year) {
  final easter = easterSunday(year);
  return {
    '$year-01-01',
    shiftDay(easter, -2),
    shiftDay(easter, 1),
    '$year-05-01',
    '$year-12-25',
    '$year-12-26',
  };
}

bool isTargetBusinessDay(String day) {
  final date = CalendarDate.parse(day);
  final weekday = DateTime.utc(date.year, date.month, date.day).weekday;
  if (weekday == DateTime.saturday || weekday == DateTime.sunday) return false;
  return !_closingDays(date.year).contains(day);
}

/// The TARGET day whose ECB rate a row dated [day] is booked at.
String rateDayFor(String day) {
  var candidate = day;
  while (!isTargetBusinessDay(candidate)) {
    candidate = shiftDay(candidate, -1);
  }
  return candidate;
}
