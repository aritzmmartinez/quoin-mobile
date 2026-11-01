import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/features/import/domain/entities/import_batch.dart';

/// An invented, already normalised batch for debug builds, dated around [now].
/// Every name and figure is made up; it walks the import wizard through a
/// deposit, trades in euros and dollars, a dividend, a reward in kind, a swap
/// and two warnings. Its ids are fixed, so importing it twice adds nothing.
ImportBatch sampleImportBatch(DateTime now) {
  final day = DateTime.utc(now.year, now.month, now.day, 9);
  DateTime ago(int days) => day.subtract(Duration(days: days));
  const fund = 'IE00QIMPORT1';
  const stock = 'US00QIMPORT2';
  const coin = 'QICOIN';
  const token = 'QITOKEN';
  const zone = 'Europe/Madrid';

  TradeEvent trade(
    int n,
    TradeType type,
    String instrument,
    int daysAgo,
    String quantity,
    String gross, {
    String fees = '0',
    String? usdRate,
    String? swap,
    Funding funding = Funding.cash,
  }) {
    final ts = ago(daysAgo);
    final account = instrument == coin || instrument == token
        ? 'kraken'
        : 'trade-republic';
    return TradeEvent(
      id: 'sample-import-$n',
      ts: ts,
      type: type,
      instrumentId: instrument,
      quantity: Dec.parse(quantity),
      price: Money.parse(gross).divideBy(Dec.parse(quantity)),
      grossAmount: Money.parse(gross),
      fees: Money.parse(fees),
      currency: usdRate == null ? baseCurrency : 'USD',
      funding: funding,
      fxSource: usdRate == null ? FxSource.identity : FxSource.ecb,
      fxRate: usdRate == null ? null : Dec.parse(usdRate),
      fxDirection: usdRate == null ? null : FxDirection.quotePerBase,
      fxDate: usdRate == null ? null : rateDayFor(dayOf(ts, zone)),
      linkId: swap,
      linkKind: swap == null ? null : 'swap',
      account: account,
      source: 'SAMPLE',
      externalId: 'sample-import-$n',
    );
  }

  final events = <LedgerEvent>[
    CashEvent(
      id: 'sample-import-1',
      ts: ago(60),
      type: CashType.deposit,
      grossAmount: Money.parse('3000'),
      currency: baseCurrency,
      account: 'trade-republic',
      source: 'SAMPLE',
      externalId: 'sample-import-1',
    ),
    trade(2, TradeType.buy, fund, 58, '12', '1200', fees: '1'),
    trade(
      3,
      TradeType.buy,
      stock,
      40,
      '4',
      '868',
      fees: '1',
      usdRate: '1.0850',
    ),
    DividendEvent(
      id: 'sample-import-4',
      ts: ago(20),
      instrumentId: fund,
      grossAmount: Money.parse('6.40'),
      taxWithheld: Money.parse('1.22'),
      currency: baseCurrency,
      account: 'trade-republic',
      source: 'SAMPLE',
      externalId: 'sample-import-4',
    ),
    trade(5, TradeType.buy, coin, 35, '0.02', '900'),
    trade(6, TradeType.buy, coin, 10, '0.0005', '24', funding: Funding.inKind),
    trade(
      7,
      TradeType.sell,
      coin,
      5,
      '0.005',
      '230',
      swap: 'sample-import-swap',
    ),
    trade(8, TradeType.buy, token, 5, '80', '230', swap: 'sample-import-swap'),
  ];

  return ImportBatch(
    total: 11,
    instruments: const [
      Instrument(
        id: fund,
        name: 'Fondo Ejemplo Mundial',
        type: 'ETF',
        assetClass: 'fund',
      ),
      Instrument(
        id: stock,
        name: 'Ejemplo Industrial Corp.',
        type: 'STOCK',
        assetClass: 'stock',
      ),
      Instrument(
        id: coin,
        name: 'QICOIN',
        type: 'CRYPTO',
        assetClass: 'crypto',
      ),
      Instrument(
        id: token,
        name: 'QITOKEN',
        type: 'CRYPTO',
        assetClass: 'crypto',
      ),
    ],
    events: events,
    operationOf: const [0, 1, 2, 3, 4, 5, 6, 6],
    warnings: [
      ImportWarning(
        reason: 'fx-unavailable',
        ts: ago(1),
        type: 'trade',
        subtype: 'buy',
        instrument: 'Ejemplo Industrial Corp. (USD)',
      ),
      ImportWarning(reason: 'card-spending', ts: ago(3), type: 'card_payment'),
      ImportWarning(
        reason: 'account-transfer',
        ts: ago(15),
        type: 'withdrawal',
        instrument: 'EUR',
      ),
    ],
  );
}
