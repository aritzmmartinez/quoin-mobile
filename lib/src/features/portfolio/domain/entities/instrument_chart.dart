import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/features/portfolio/domain/entities/movement.dart';
import 'package:quoin/src/features/portfolio/domain/entities/price_series.dart';

class InstrumentChart {
  const InstrumentChart({
    required this.points,
    required this.source,
    required this.today,
    required this.unrated,
  }) : assert(points.length >= 2);

  final List<DayValue> points;
  final PriceSource source;
  final String today;
  final int unrated;
}

List<({String day, List<Movement> trades})> tradesByDay(
  List<Movement> movements,
  String zone,
) {
  final byDay = <String, List<Movement>>{};
  for (final m in movements) {
    if (m.type != 'BUY' && m.type != 'SELL') continue;
    (byDay[dayOf(m.ts, zone)] ??= []).add(m);
  }
  final days = byDay.keys.toList()..sort();
  return [for (final day in days) (day: day, trades: byDay[day]!)];
}
