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
  final Dec? quantity;
  final Money? amount;
  final String currency;
  final bool converted;

  bool get isSwap => swapRoute != null;

  bool get noRate => amount == null;
}
