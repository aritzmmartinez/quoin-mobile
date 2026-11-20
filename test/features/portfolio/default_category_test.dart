import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/features/portfolio/domain/entities/portfolio_ledger.dart';
import 'package:quoin/src/features/portfolio/domain/usecases/get_portfolio_overview.dart';
import 'package:quoin_core/quoin_core.dart';

import '../../helpers.dart';

final _at = DateTime.utc(2026, 3, 2, 10);

TradeEvent _buy(String id) => TradeEvent(
  id: 'buy-$id',
  ts: _at,
  type: TradeType.buy,
  instrumentId: id,
  quantity: Dec.one,
  price: Money.parse('100'),
  grossAmount: Money.parse('100'),
  fees: Money.zero,
  currency: 'EUR',
  account: 'test',
  source: 'TR_CSV',
);

PriceSnapshot _price(String id, String value) => PriceSnapshot(
  instrumentId: id,
  price: Money.parse(value),
  currency: 'EUR',
  asOf: _at,
);

void main() {
  test('the home allocation shows the category each type derives, and the '
      "user's choice wins", () {
    const instruments = [
      Instrument(id: 'XX00TSTOCK01', name: 'Acción Prueba', type: 'STOCK'),
      Instrument(id: 'TESTCOIN', name: 'Moneda Prueba', type: 'CRYPTO'),
      Instrument(id: 'XX00TFUND001', name: 'Fondo Prueba', type: 'ETF'),
      Instrument(
        id: 'XX00TFUND002',
        name: 'Fondo Elegido',
        type: 'ETF',
        exposureKind: ExposureKind.equityFund,
      ),
      Instrument(
        id: 'XX00TSTOCK02',
        name: 'Acción Elegida',
        type: 'STOCK',
        exposureKind: ExposureKind.bondFund,
      ),
    ];
    final values = {
      'XX00TSTOCK01': '500',
      'TESTCOIN': '400',
      'XX00TFUND001': '300',
      'XX00TFUND002': '200',
      'XX00TSTOCK02': '100',
    };
    final overview = overviewOf(
      PortfolioLedger(
        residence: Residence.bizkaia,
        instruments: instruments,
        events: [for (final id in values.keys) _buy(id)],
        latestPrices: {
          for (final MapEntry(key: id, :value) in values.entries)
            id: _price(id, value),
        },
        rates: const [],
      ),
      testNow,
    );

    expect(
      [for (final s in overview.allocation) (s.category, '${s.value}')],
      [
        ('COMPANY', '500'),
        ('CRYPTO', '400'),
        (otherCategory, '300'),
        ('EQUITY_FUND', '200'),
        ('BOND_FUND', '100'),
      ],
    );
    expect(
      {for (final h in overview.holdings) h.instrumentId: h.category},
      {
        'XX00TSTOCK01': 'COMPANY',
        'TESTCOIN': 'CRYPTO',
        'XX00TFUND001': otherCategory,
        'XX00TFUND002': 'EQUITY_FUND',
        'XX00TSTOCK02': 'BOND_FUND',
      },
    );
  });
}
