import '../calendar/calendar_date.dart';
import '../decimal/dec.dart';
import '../domain/residence.dart';
import '../money/money.dart';

enum RepurchaseAssetClass {
  listedSecurity('listed-security'),
  fungibleCrypto('fungible-crypto'),
  unclassified('unclassified');

  const RepurchaseAssetClass(this.code);

  final String code;
}

/// The class an instrument's type puts it in for the repurchase rule. A bond
/// held directly yields income from movable capital, outside Art. 43, and a
/// commodity held directly would fall under a letter that is not modelled, so
/// no rule covers them.
RepurchaseAssetClass repurchaseAssetClassOf(String instrumentType) =>
    switch (instrumentType) {
      'ETF' || 'STOCK' => RepurchaseAssetClass.listedSecurity,
      'CRYPTO' => RepurchaseAssetClass.fungibleCrypto,
      'BOND' || 'COMMODITY' || 'CASH' => RepurchaseAssetClass.unclassified,
      _ => throw ArgumentError.value(
          instrumentType,
          'instrumentType',
          'No repurchase asset class',
        ),
    };

enum RepurchaseLetter { g, i }

/// Art. 43 NF 13/2013 de Bizkaia, pérdidas no computables por recompra: one
/// entry per letter over one engine. Same table as Quoin's `REPURCHASE_RULES`
/// (core/tax/config.ts), which says why each field is what it is.
///
/// [from] and [to] are Madrid calendar days of the transmission, inclusive.
final class RepurchaseRule {
  const RepurchaseRule({
    required this.territory,
    required this.letter,
    required this.assetClass,
    required this.windowMonths,
    required this.cashOnly,
    required this.from,
    required this.to,
    required this.source,
  });

  final Territory territory;
  final RepurchaseLetter letter;
  final RepurchaseAssetClass assetClass;
  final int windowMonths;

  /// Whether units received in kind are left out of the window; false reads
  /// "hubiera adquirido" literally. Homogeneity is always the instrument id.
  final bool cashOnly;
  final String? from;
  final String? to;
  final String source;
}

const repurchaseRules = [
  RepurchaseRule(
    territory: Territory.bizkaia,
    letter: RepurchaseLetter.g,
    assetClass: RepurchaseAssetClass.listedSecurity,
    windowMonths: 2,
    cashOnly: false,
    from: null,
    to: null,
    source: 'Art. 43.g NF 13/2013 de Bizkaia',
  ),
  RepurchaseRule(
    territory: Territory.bizkaia,
    letter: RepurchaseLetter.i,
    assetClass: RepurchaseAssetClass.fungibleCrypto,
    windowMonths: 2,
    cashOnly: false,
    from: '2025-01-01',
    to: null,
    source: 'Art. 43.i NF 13/2013, redacción de la NF 6/2025, de 12 de '
        'diciembre (BOB 15/12/2025)',
  ),
];

RepurchaseRule? repurchaseRuleFor(
  Territory territory,
  RepurchaseAssetClass assetClass,
  CalendarDate saleDay, [
  List<RepurchaseRule> rules = repurchaseRules,
]) {
  final day = saleDay.toString();
  for (final rule in rules) {
    if (rule.territory == territory &&
        rule.assetClass == assetClass &&
        (rule.from == null || rule.from!.compareTo(day) <= 0) &&
        (rule.to == null || day.compareTo(rule.to!) <= 0)) {
      return rule;
    }
  }
  return null;
}

const unlistedNoticeWindowMonths = 12;

/// Art. 66 NF 13/2013 de Bizkaia: losses offset the savings base for four
/// years.
const lossCarryforwardYears = 4;

final class TaxBracket {
  const TaxBracket(this.from, this.to, this.rate);

  final String from;
  final String? to;
  final String rate;
}

final class SavingsBaseTaxScale {
  const SavingsBaseTaxScale({
    required this.territory,
    required this.year,
    required this.source,
    required this.brackets,
  });

  final Territory territory;
  final int year;

  final String source;
  final List<TaxBracket> brackets;
}

const taxScales = [
  SavingsBaseTaxScale(
    territory: Territory.bizkaia,
    year: 2026,
    source:
        'Art. 76 NF 13/2013 de Bizkaia, redacción NF 2/2025, efectos 1-1-2026',
    brackets: [
      TaxBracket('0', '7500', '0.19'),
      TaxBracket('7500', '15000', '0.20'),
      TaxBracket('15000', '30000', '0.22'),
      TaxBracket('30000', '50000', '0.24'),
      TaxBracket('50000', '90000', '0.255'),
      TaxBracket('90000', '120000', '0.26'),
      TaxBracket('120000', '240000', '0.265'),
      TaxBracket('240000', '300000', '0.27'),
      TaxBracket('300000', null, '0.28'),
    ],
  ),
];

SavingsBaseTaxScale? getTaxScale(Territory territory, int year) {
  for (final scale in taxScales) {
    if (scale.territory == territory && scale.year == year) return scale;
  }
  return null;
}

Money computeSavingsQuota(Money netBase, SavingsBaseTaxScale scale) {
  if (!netBase.isPositive) return Money.zero;
  final base = netBase.amount;
  var quota = Money.zero;
  for (final bracket in scale.brackets) {
    final from = Dec.parse(bracket.from);
    if (base <= from) break;
    final to = bracket.to == null ? base : minDec(Dec.parse(bracket.to!), base);
    final taxable = to - from;
    if (taxable <= Dec.zero) continue;
    quota = quota.add(Money.of(taxable).scaleBy(Dec.parse(bracket.rate)));
  }
  return quota;
}

Dec minDec(Dec a, Dec b) => a <= b ? a : b;

Dec maxDec(Dec a, Dec b) => a >= b ? a : b;

Dec sumDec(Iterable<Dec> values) => values.fold(Dec.zero, (a, b) => a + b);
