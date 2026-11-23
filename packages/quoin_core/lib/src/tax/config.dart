import '../calendar/calendar_date.dart';
import '../decimal/dec.dart';
import '../domain/residence.dart';
import '../money/money.dart';
import 'territory.dart';

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

/// Which purchases in the window count: [all] reads "hubiera adquirido"
/// literally, so units received in kind (a reward, a saveback) are an
/// acquisition; [cashOnly] leaves them out of the window and out of the
/// recipients of the deferral. Homogeneity is always the instrument id.
enum RepurchaseAcquisitions { all, cashOnly }

/// Art. 43 NF 13/2013 de Bizkaia, pérdidas no computables por recompra: one
/// entry per letter over one engine. A territory's rules live in
/// [territoryRules].
///
/// [from] and [to] are Madrid calendar days of the transmission, inclusive.
final class RepurchaseRule {
  const RepurchaseRule({
    required this.letter,
    required this.assetClass,
    required this.windowMonths,
    required this.acquisitions,
    required this.from,
    required this.to,
    required this.source,
  });

  final RepurchaseLetter letter;
  final RepurchaseAssetClass assetClass;
  final int windowMonths;
  final RepurchaseAcquisitions acquisitions;
  final String? from;
  final String? to;
  final String source;
}

RepurchaseRule? repurchaseRuleFor(
  Territory territory,
  RepurchaseAssetClass assetClass,
  CalendarDate saleDay, [
  List<RepurchaseRule>? rules,
]) {
  final day = saleDay.toString();
  for (final rule in rules ?? territoryRules(territory).repurchase) {
    if (rule.assetClass == assetClass &&
        (rule.from == null || rule.from!.compareTo(day) <= 0) &&
        (rule.to == null || day.compareTo(rule.to!) <= 0)) {
      return rule;
    }
  }
  return null;
}

/// The period a territory values a crypto swap at the greater of its two
/// sides, and the norm that says so. [from] and [to] are calendar days of the
/// swap in the residence's zone, inclusive; null is open.
final class SwapValuationRule {
  const SwapValuationRule({this.from, this.to, required this.source});

  final String? from;
  final String? to;
  final String source;
}

SwapValuationRule? swapValuationRuleFor(
  Territory territory,
  String swapDay, [
  List<SwapValuationRule>? rules,
]) {
  for (final rule in rules ?? territoryRules(territory).swapValuation) {
    if ((rule.from == null || rule.from!.compareTo(swapDay) <= 0) &&
        (rule.to == null || swapDay.compareTo(rule.to!) <= 0)) {
      return rule;
    }
  }
  return null;
}

final class TaxBracket {
  const TaxBracket(this.from, this.to, this.rate);

  final String from;
  final String? to;
  final String rate;
}

final class SavingsBaseTaxScale {
  const SavingsBaseTaxScale({
    required this.year,
    required this.source,
    required this.brackets,
  });

  final int year;

  final String source;
  final List<TaxBracket> brackets;
}

SavingsBaseTaxScale? getTaxScale(Territory territory, int year) {
  for (final scale in territoryRules(territory).savingsScales) {
    if (scale.year == year) return scale;
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
