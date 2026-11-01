import 'package:quoin_core/quoin_core.dart';
import 'package:test/test.dart';

TradeEvent buy({
  String currency = 'EUR',
  FxSource fxSource = FxSource.identity,
  String? fxRate,
  FxDirection? fxDirection,
  String? fxDate,
  String? externalId = 'tx-1',
  String? linkId,
  String? linkKind,
  String? valuationSource,
  Funding funding = Funding.cash,
}) =>
    TradeEvent(
      id: 'e1',
      ts: DateTime.utc(2026, 3, 2, 10),
      type: TradeType.buy,
      instrumentId: 'XX0000000001',
      quantity: Dec.parse('1'),
      price: Money.parse('10'),
      grossAmount: Money.parse('10'),
      fees: Money.zero,
      currency: currency,
      funding: funding,
      fxSource: fxSource,
      fxRate: fxRate == null ? null : Dec.parse(fxRate),
      fxDirection: fxDirection,
      fxDate: fxDate,
      externalId: externalId,
      linkId: linkId,
      linkKind: linkKind,
      valuationSource: valuationSource,
      account: 'trade-republic',
      source: 'trade-republic',
    );

void main() {
  test('a euro row booked as it stands may be written', () {
    expect(ledgerWriteIssues(buy()), isEmpty);
  });

  test('a converted foreign row may be written', () {
    expect(
      ledgerWriteIssues(buy(
        currency: 'USD',
        fxSource: FxSource.ecb,
        fxRate: '1.08',
        fxDirection: FxDirection.quotePerBase,
        fxDate: '2026-03-02',
      )),
      isEmpty,
    );
  });

  test('each broken rule is named', () {
    expect(ledgerWriteIssues(buy(externalId: null)), hasLength(1));
    expect(ledgerWriteIssues(buy(currency: 'USD')), hasLength(1));
    expect(ledgerWriteIssues(buy(fxRate: '1.1')), hasLength(1));
    expect(ledgerWriteIssues(buy(fxSource: FxSource.ecb)), hasLength(2));
    expect(
      ledgerWriteIssues(buy(
        currency: 'USD',
        fxSource: FxSource.ecb,
        fxRate: '0',
        fxDirection: FxDirection.quotePerBase,
        fxDate: '2026-02-30',
      )),
      hasLength(2),
    );
    expect(ledgerWriteIssues(buy(linkId: 'l1')), hasLength(1));
    expect(
        ledgerWriteIssues(buy(linkId: 'l1', linkKind: 'pair')), hasLength(1));
    expect(ledgerWriteIssues(buy(valuationSource: 'guess')), hasLength(1));
    expect(
        ledgerWriteIssues(buy(valuationSource: 'kraken-amountusd')), isEmpty);
  });

  test('a swap leg is a trade', () {
    final dividend = DividendEvent(
      id: 'd1',
      ts: DateTime.utc(2026, 3, 2),
      instrumentId: 'XX0000000001',
      grossAmount: Money.parse('1'),
      taxWithheld: Money.zero,
      currency: 'EUR',
      account: 'kraken',
      source: 'kraken',
      externalId: 'd1',
      linkId: 'l1',
      linkKind: 'swap',
    );
    expect(ledgerWriteIssues(dividend), hasLength(1));
  });

  test('isInKind reads the funding of trades and dividends', () {
    expect(isInKind(buy(funding: Funding.inKind)), isTrue);
    expect(isInKind(buy()), isFalse);
  });
}
