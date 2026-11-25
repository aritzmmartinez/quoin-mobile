import '../decimal/dec.dart';
import 'chart_range.dart';

List<DayValue> lttb(List<DayValue> points, int target) {
  final n = points.length;
  if (target < 3 || n <= target) return points;

  final kept = <int>{0, n - 1};
  final buckets = target - 2;
  int edge(int b) => 1 + b * (n - 2) ~/ buckets;
  var a = 0;
  for (var b = 0; b < buckets; b++) {
    final from = edge(b);
    final to = edge(b + 1);
    final nextFrom = to;
    final nextTo = b + 1 == buckets ? n : edge(b + 2);

    var sumX = 0;
    var sumY = Dec.zero;
    for (var i = nextFrom; i < nextTo; i++) {
      sumX += i;
      sumY += points[i].value;
    }
    final count = Dec.fromInt(nextTo - nextFrom);
    final cx = Dec.fromInt(sumX).dividedBy(count);
    final cy = sumY.dividedBy(count);

    final ax = Dec.fromInt(a);
    final ay = points[a].value;
    var best = from;
    Dec? bestArea;
    for (var i = from; i < to; i++) {
      final area = ((ax - cx) * (points[i].value - ay) -
              (ax - Dec.fromInt(i)) * (cy - ay))
          .abs();
      if (bestArea == null || area > bestArea) {
        bestArea = area;
        best = i;
      }
    }
    kept.add(best);
    a = best;
  }

  var high = 0;
  var low = 0;
  for (var i = 1; i < n; i++) {
    if (points[i].value > points[high].value) high = i;
    if (points[i].value < points[low].value) low = i;
  }
  kept
    ..add(high)
    ..add(low);
  return [for (final i in kept.toList()..sort()) points[i]];
}
