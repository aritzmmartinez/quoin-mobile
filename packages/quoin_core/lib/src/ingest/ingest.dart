import '../domain/ledger.dart';
import '../fx/rates.dart';
import '../fx/value.dart';
import 'batch.dart';
import 'detect.dart';
import 'kraken.dart';
import 'trade_republic.dart';

final class IngestContext {
  const IngestContext({
    required this.zone,
    this.rates = const {},
    this.prices = const [],
    this.names = const {},
    this.rewardRefids = const {},
  });
  final String zone;
  final RateBook rates;
  final List<PriceSnapshot> prices;
  final Map<String, String> names;
  final Set<String> rewardRefids;
}

MappedBatch planIngest(Broker broker, String csv, IngestContext context) {
  final builder =
      BatchBuilder(context.zone, rateLookupFrom(context.rates, context.zone));
  return switch (broker) {
    Broker.tradeRepublic => planTradeRepublic(csv, builder),
    Broker.kraken => planKraken(
        csv,
        builder,
        prices: context.prices,
        names: context.names,
        rewardRefids: context.rewardRefids,
      ),
  };
}

bool isKrakenReward(LedgerEvent event) =>
    event.source == 'KRAKEN_CSV' &&
    event is TradeEvent &&
    event.type == TradeType.buy &&
    event.note == krakenRewardNote;
