import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/features/portfolio/domain/entities/portfolio_overview.dart';
import 'package:quoin_core/quoin_core.dart';

Holding _holding(String id, String category, String? value) => Holding(
  instrumentId: id,
  name: id,
  type: 'ETF',
  category: category,
  position: Position(
    instrumentId: id,
    quantity: Dec.one,
    costBasis: Money.parse('10'),
    averageCost: Money.parse('10'),
    realizedPnL: Money.zero,
  ),
  value: MarketValue(marketValue: value == null ? null : Money.parse(value)),
);

void main() {
  test('groups follow the allocation, the unclassified last', () {
    final groups = groupByCategory(
      [
        _holding('a', otherCategory, '50'),
        _holding('b', 'CRYPTO', '30'),
        _holding('c', 'EQUITY_FUND', '20'),
        _holding('d', 'BOND_FUND', null),
        _holding('e', 'CRYPTO', null),
      ],
      [
        AllocationSlice(
          category: otherCategory,
          value: Money.parse('50'),
          weight: Dec.parse('0.5'),
        ),
        AllocationSlice(
          category: 'CRYPTO',
          value: Money.parse('30'),
          weight: Dec.parse('0.3'),
        ),
        AllocationSlice(
          category: 'EQUITY_FUND',
          value: Money.parse('20'),
          weight: Dec.parse('0.2'),
        ),
      ],
    );
    expect(
      [for (final g in groups) g.category],
      ['CRYPTO', 'EQUITY_FUND', 'BOND_FUND', otherCategory],
    );
    expect([for (final h in groups.first.holdings) h.instrumentId], ['b', 'e']);
    expect(groups.first.value, Money.parse('30'));
    expect(groups[2].value, isNull);
  });
}
