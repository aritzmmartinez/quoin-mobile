import 'package:drift/drift.dart';
import 'package:quoin_core/quoin_core.dart' hide Instrument, PriceSnapshot;

import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';

/// An invented portfolio for debug builds, dated around [now] so its prices
/// and rates are always recent. Every name and figure is made up; it exists to
/// exercise the screens: categories, a position in dollars, a crypto swap, a
/// closed position, one with no price and one with no category.
class SamplePortfolio {
  SamplePortfolio(DateTime now) : _now = now.toUtc();

  final DateTime _now;
  var _seq = 0;

  late final instruments = [
    _instrument(_fund, 'Fondo Global Indexado', 'ETF', 'EQUITY_FUND'),
    _instrument(_bonds, 'Bonos Euro Gobierno', 'ETF', 'BOND_FUND'),
    _instrument(_gold, 'Oro Físico ETC', 'COMMODITY', 'COMMODITY'),
    _instrument(_tech, 'Ejemplo Tecnología Inc.', 'STOCK', 'COMPANY'),
    _instrument(_coin, 'Moneda Ejemplo', 'CRYPTO', 'CRYPTO'),
    _instrument(_token, 'Token Ejemplo', 'CRYPTO', 'CRYPTO'),
    _instrument(_emerging, 'Fondo Emergentes', 'ETF', 'EQUITY_FUND'),
    _instrument(_property, 'Inmobiliario Europa', 'ETF', null),
    _instrument(_health, 'Salud Mundial', 'ETF', 'EQUITY_FUND'),
  ];

  late final entries = [
    _trade('BUY', _fund, 420, '40', '3600', fees: '1'),
    _trade('BUY', _fund, 300, '20', '1900', fees: '1'),
    _trade('BUY', _fund, 120, '15', '1530', fees: '1'),
    _trade('BUY', _bonds, 400, '30', '1500', fees: '1'),
    _trade('SELL', _bonds, 90, '5', '248', fees: '1'),
    _trade('BUY', _gold, 260, '25', '1050', fees: '1'),
    _trade('BUY', _tech, 200, '12', '2170', fees: '1.09', usd: '1.0850'),
    _trade('BUY', _coin, 380, '0.9', '2700'),
    _trade('BUY', _coin, 150, '0.1', '410', funding: 'IN_KIND'),
    _trade('SELL', _coin, 60, '0.4', '1600', swap: 'sample-swap'),
    _trade('BUY', _token, 60, '500', '1580', fees: '30', swap: 'sample-swap'),
    _trade('BUY', _emerging, 180, '18', '720', fees: '1'),
    _trade('BUY', _property, 240, '40', '1000', fees: '1'),
    _trade('BUY', _health, 360, '10', '800', fees: '1'),
    _trade('SELL', _health, 30, '10', '910', fees: '1'),
  ];

  late final prices = [
    _price(_fund, '108.42'),
    _price(_bonds, '50.15'),
    _price(_gold, '48.90'),
    _price(_tech, '214.30', currency: 'USD'),
    _price(_coin, '4380'),
    _price(_token, '3.42'),
    _price(_property, '23.70'),
  ];

  late final rates = [
    FxRateCompanion.insert(
      id: 'sample-rate',
      base: baseCurrency,
      quote: 'USD',
      day: rateDayFor(shiftDay(dayOf(_now, _zone), -1)),
      rate: '1.0912',
      source: 'ECB',
      createdAt: _now,
    ),
  ];

  static const _zone = 'Europe/Madrid';
  static const _fund = 'IE00QSAMPLE1';
  static const _bonds = 'IE00QSAMPLE2';
  static const _gold = 'XS00QSAMPLE3';
  static const _tech = 'US00QSAMPLE4';
  static const _coin = 'QCOIN';
  static const _token = 'QTOKEN';
  static const _emerging = 'IE00QSAMPLE7';
  static const _property = 'IE00QSAMPLE8';
  static const _health = 'IE00QSAMPLE9';

  InstrumentCompanion _instrument(
    String id,
    String name,
    String type,
    String? exposureKind,
  ) => InstrumentCompanion.insert(
    id: id,
    name: name,
    type: type,
    exposureKind: Value(exposureKind),
    createdAt: _now,
  );

  LedgerEntryCompanion _trade(
    String type,
    String instrumentId,
    int daysAgo,
    String quantity,
    String grossAmount, {
    String fees = '0',
    String? usd,
    String? swap,
    String funding = 'CASH',
  }) {
    final id = 'sample-${++_seq}';
    final ts = DateTime.utc(_now.year, _now.month, _now.day - daysAgo, 9);
    final price = Dec.parse(grossAmount).dividedBy(Dec.parse(quantity));
    return LedgerEntryCompanion.insert(
      id: id,
      ts: ts,
      type: type,
      instrumentId: Value(instrumentId),
      quantity: Value(quantity),
      price: Value('$price'),
      grossAmount: grossAmount,
      fees: Value(fees),
      currency: usd == null ? baseCurrency : 'USD',
      fxSource: Value(usd == null ? 'IDENTITY' : 'ECB'),
      fxDate: Value(usd == null ? null : rateDayFor(dayOf(ts, _zone))),
      fxRate: Value(usd),
      fxDirection: Value(usd == null ? null : 'QUOTE_PER_BASE'),
      linkId: Value(swap),
      linkKind: Value(swap == null ? null : 'swap'),
      funding: Value(funding),
      account: const Value('sample'),
      source: const Value('SAMPLE'),
      externalId: Value(id),
      createdAt: _now,
    );
  }

  PriceSnapshotCompanion _price(
    String instrumentId,
    String price, {
    String currency = baseCurrency,
  }) => PriceSnapshotCompanion.insert(
    id: 'sample-price-$instrumentId',
    instrumentId: instrumentId,
    price: price,
    currency: currency,
    asOf: DateTime.utc(_now.year, _now.month, _now.day - 1, 16, 30),
    source: const Value('SAMPLE'),
    createdAt: _now,
  );
}
