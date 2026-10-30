import 'calendar_date.dart';

/// `YYYY-MM-DD`, the day an instant belongs to in [zone].
String dayOf(DateTime instant, String zone) =>
    calendarDateOf(instant, zone).toString();

String today(String zone, DateTime now) => dayOf(now, zone);

/// `YYYY-MM`, the month an instant belongs to in [zone].
String periodOf(DateTime instant, String zone) =>
    dayOf(instant, zone).substring(0, 7);

int fiscalYearOf(DateTime instant, String zone) =>
    calendarDateOf(instant, zone).year;

String shiftDay(String day, int n) {
  final date = CalendarDate.parse(day);
  final shifted = DateTime.utc(date.year, date.month, date.day + n);
  return CalendarDate(shifted.year, shifted.month, shifted.day).toString();
}
