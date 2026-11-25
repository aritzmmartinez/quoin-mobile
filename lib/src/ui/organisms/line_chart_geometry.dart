import 'dart:ui';

import 'package:quoin_core/quoin_core.dart';

enum ChartMarkKind { filled, ring }

class ChartMark {
  const ChartMark({
    required this.id,
    required this.day,
    required this.kind,
    required this.label,
  });

  final String id;
  final String day;
  final ChartMarkKind kind;
  final String label;
}

class LineChartGeometry {
  LineChartGeometry(this.points, this.plot)
    : assert(points.length >= 2),
      high = _extreme(points, (a, b) => a > b),
      low = _extreme(points, (a, b) => a < b);

  final List<DayValue> points;
  final Rect plot;
  final int high;
  final int low;

  late final double _top = points[high].value.toDouble();
  late final double _bottom = points[low].value.toDouble();
  late final Map<String, int> _index = {
    for (final (i, p) in points.indexed) p.day: i,
  };

  double xAt(int i) => plot.left + plot.width * i / (points.length - 1);

  double yOf(Dec value) {
    final span = _top - _bottom;
    if (span == 0) return plot.center.dy;
    return plot.bottom - plot.height * (value.toDouble() - _bottom) / span;
  }

  Offset offsetAt(int i) => Offset(xAt(i), yOf(points[i].value));

  Offset offsetOf(DayValue p) => Offset(xAt(_index[p.day]!), yOf(p.value));

  int indexAt(double dx) {
    final f = ((dx - plot.left) / plot.width).clamp(0.0, 1.0);
    return (f * (points.length - 1)).round();
  }

  bool spans(Dec value) =>
      value >= points[low].value && value <= points[high].value;

  int? indexOfDay(String day) {
    if (day.compareTo(points.first.day) < 0 ||
        day.compareTo(points.last.day) > 0) {
      return null;
    }
    return _index[day] ??
        points.lastIndexWhere((p) => p.day.compareTo(day) <= 0);
  }

  ChartMark? markAt(Offset at, List<ChartMark> marks, double slop) {
    ChartMark? best;
    var bestDistance = slop;
    for (final mark in marks) {
      final i = indexOfDay(mark.day);
      if (i == null) continue;
      final distance = (offsetAt(i) - at).distance;
      if (distance <= bestDistance) {
        best = mark;
        bestDistance = distance;
      }
    }
    return best;
  }

  List<double> sample(int samples) => [
    for (var s = 0; s < samples; s++) _yAtFraction(s / (samples - 1)),
  ];

  double _yAtFraction(double f) {
    final at = f * (points.length - 1);
    final i = at.floor().clamp(0, points.length - 2);
    final a = yOf(points[i].value);
    final b = yOf(points[i + 1].value);
    return a + (b - a) * (at - i);
  }

  static int _extreme(List<DayValue> points, bool Function(Dec, Dec) beats) {
    var best = 0;
    for (var i = 1; i < points.length; i++) {
      if (beats(points[i].value, points[best].value)) best = i;
    }
    return best;
  }
}
