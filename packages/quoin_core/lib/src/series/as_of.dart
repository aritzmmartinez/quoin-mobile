import '../calendar/day.dart';

/// The last item of [sorted] whose key is at or before [key], by binary
/// search; null when there is none or it is older than [earliest].
T? lastOnOrBefore<T, K extends Comparable<K>>(
  List<T> sorted,
  K Function(T item) keyOf,
  K key,
  K? earliest,
) {
  var lo = 0;
  var hi = sorted.length - 1;
  T? found;
  while (lo <= hi) {
    final mid = (lo + hi) >> 1;
    final candidate = sorted[mid];
    if (keyOf(candidate).compareTo(key) <= 0) {
      found = candidate;
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  if (found == null) return null;
  if (earliest != null && keyOf(found).compareTo(earliest) < 0) return null;
  return found;
}

T? onOrBeforeDay<T>(
  List<T> sorted,
  String Function(T item) dayOf,
  String day,
  int? maxAgeDays,
) =>
    lastOnOrBefore(
      sorted,
      dayOf,
      day,
      maxAgeDays == null ? null : shiftDay(day, -maxAgeDays),
    );
