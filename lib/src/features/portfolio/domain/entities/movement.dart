import 'package:quoin_core/quoin_core.dart';

class Movement {
  const Movement({
    required this.id,
    required this.ts,
    required this.type,
    required this.inKind,
    required this.swapRoute,
    required this.instrumentId,
    required this.instrumentName,
    this.instrumentType,
    this.exposureKind,
    required this.quantity,
    required this.amount,
    required this.currency,
    required this.converted,
  });

  final String id;
  final DateTime ts;
  final String type;
  final bool inKind;
  final String? swapRoute;
  final String? instrumentId;
  final String? instrumentName;
  final String? instrumentType;
  final ExposureKind? exposureKind;
  final Dec? quantity;
  final Money? amount;
  final String currency;
  final bool converted;

  bool get isSwap => swapRoute != null;

  bool get noRate => amount == null;
}

typedef MovementMonth = ({CalendarDate month, Money net, List<Movement> rows});

List<MovementMonth> byMonth(List<Movement> rows, String zone) {
  final months = <MovementMonth>[];
  for (final m in rows) {
    final day = calendarDateOf(m.ts, zone);
    final month = CalendarDate(day.year, day.month, 1);
    final last = months.lastOrNull;
    final amount = m.amount;
    final add = m.isSwap || amount == null ? Money.zero : amount;
    if (last != null && last.month == month) {
      last.rows.add(m);
      months[months.length - 1] = (
        month: month,
        net: last.net.add(add),
        rows: last.rows,
      );
    } else {
      months.add((month: month, net: add, rows: [m]));
    }
  }
  return months;
}
