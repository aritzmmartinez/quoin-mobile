import '../domain/ledger.dart';
import '../fx/rates.dart';
import '../fx/value.dart';
import 'batch.dart';
import 'detect.dart';
import 'kraken.dart';
import 'reasons.dart';
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

const Map<Broker, Map<String, RowType>> brokerRowTypes = {
  Broker.tradeRepublic: {
    'INTEREST_PAYMENT': RowType.interest,
    'CUSTOMER_INPAYMENT': RowType.deposit,
    'TRANSFER_INBOUND': RowType.transferIn,
    'TRANSFER_INSTANT_INBOUND': RowType.transferIn,
    'TRANSFER_DIRECT_DEBIT_INBOUND': RowType.directDebit,
    'TRANSFER_INSTANT_OUTBOUND': RowType.transferOut,
    'BENEFITS_SAVEBACK': RowType.saveback,
    'CARD_TRANSACTION': RowType.cardPayment,
    'CARD_TRANSACTION_INTERNATIONAL': RowType.cardPaymentAbroad,
  },
  Broker.kraken: {
    'deposit': RowType.deposit,
    'withdrawal': RowType.withdrawal,
    'transfer': RowType.transfer,
    'reward': RowType.reward,
    'earn': RowType.earn,
    'hybridearnwithdrawal': RowType.earnWithdrawal,
    'spend': RowType.spend,
    'receive': RowType.receive,
    'trade': RowType.trade,
  },
};

bool isKrakenReward(LedgerEvent event) =>
    event.source == 'KRAKEN_CSV' &&
    event is TradeEvent &&
    event.type == TradeType.buy &&
    event.note == krakenRewardNote;
