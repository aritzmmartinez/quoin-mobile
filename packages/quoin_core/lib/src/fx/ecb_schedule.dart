import '../calendar/calendar_date.dart';
import '../calendar/day.dart';
import '../calendar/target.dart';

const ecbZone = 'Europe/Berlin';
const ecbPublishedHour = 16;
const ecbPublishedMinute = 30;

String syncStart(
  String needed,
  String? firstUse,
  ({String? first, String? last}) stored,
) {
  final (:first, :last) = stored;
  if (first == null || last == null) return needed;
  if (firstUse != null && firstUse.compareTo(first) < 0) return needed;
  return last;
}

String latestEcbDay(DateTime now) {
  final day = dayOf(now, ecbZone);
  final published = atLocalTime(
    CalendarDate.parse(day),
    ecbPublishedHour,
    ecbPublishedMinute,
    ecbZone,
  );
  return rateDayFor(now.isBefore(published) ? shiftDay(day, -1) : day);
}

String? ecbFetchFrom({
  required String needed,
  required String? firstUse,
  required ({String? first, String? last}) stored,
  required DateTime now,
}) {
  final from = syncStart(needed, firstUse, stored);
  final last = stored.last;
  if (last != null && from == last && last.compareTo(latestEcbDay(now)) >= 0) {
    return null;
  }
  return from;
}

class EcbHold {
  EcbHold({this.pause = const Duration(minutes: 15)});

  final Duration pause;
  final _until = <String, DateTime>{};

  bool holds(String currency, DateTime now) =>
      _until[currency]?.isAfter(now) ?? false;

  void answered(String currency, String? newest, DateTime now) {
    if (newest == null || newest.compareTo(latestEcbDay(now)) < 0) {
      _until[currency] = now.add(pause);
    } else {
      _until.remove(currency);
    }
  }
}
