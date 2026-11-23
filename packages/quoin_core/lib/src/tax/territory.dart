import '../domain/residence.dart';
import 'config.dart';

/// A sale of [assetClass] that no repurchase rule covers, at a loss, followed
/// by a purchase of the same asset within [windowMonths], is pointed out.
/// Informative only: it changes no figure.
final class UnlistedNoticeRule {
  const UnlistedNoticeRule({
    required this.assetClass,
    required this.windowMonths,
  });

  final RepurchaseAssetClass assetClass;
  final int windowMonths;
}

/// Dividends exempt up to [limit] euros a year. With
/// [excludesCollectiveInvestment], those of a fund or ETF are never exempt.
final class DividendExemptionRule {
  const DividendExemptionRule({
    required this.limit,
    required this.excludesCollectiveInvestment,
    required this.source,
  });

  final String limit;
  final bool excludesCollectiveInvestment;
  final String source;
}

/// Everything the tax engine reads that depends on the territory, and only
/// that. Same table as Quoin's `TERRITORY_RULES` (core/tax/territory.ts),
/// which says why each value is what it is.
final class TerritoryRules {
  const TerritoryRules({
    required this.savingsScales,
    required this.repurchase,
    required this.swapValuation,
    required this.lossCarryforwardYears,
    required this.crossOffsetLimit,
    required this.dividendExemption,
    required this.unlistedNotice,
  });

  final List<SavingsBaseTaxScale> savingsScales;
  final List<RepurchaseRule> repurchase;
  final List<SwapValuationRule> swapValuation;
  final int lossCarryforwardYears;

  /// Share of one savings pool's positive balance that the other pool's
  /// negative balance may offset, as a decimal string. Zero keeps the pools
  /// apart.
  final String crossOffsetLimit;
  final DividendExemptionRule? dividendExemption;
  final UnlistedNoticeRule unlistedNotice;
}

// An exhaustive switch over Territory: a new territory does not compile
// until it has its rules, as `satisfies Record<Territory, …>` does in Quoin.
TerritoryRules territoryRules(Territory territory) => switch (territory) {
      Territory.bizkaia => _bizkaia,
    };

const _bizkaia = TerritoryRules(
  savingsScales: [
    SavingsBaseTaxScale(
      year: 2025,
      source: 'Art. 76 NF 13/2013 de Bizkaia, redacción anterior a la NF '
          '2/2025, vigente hasta 31-12-2025',
      brackets: [
        TaxBracket('0', '2500', '0.20'),
        TaxBracket('2500', '10000', '0.21'),
        TaxBracket('10000', '15000', '0.22'),
        TaxBracket('15000', '30000', '0.23'),
        TaxBracket('30000', null, '0.25'),
      ],
    ),
    SavingsBaseTaxScale(
      year: 2026,
      source: 'Art. 76 NF 13/2013 de Bizkaia, redacción NF 2/2025, efectos '
          '1-1-2026',
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
  ],
  repurchase: [
    RepurchaseRule(
      letter: RepurchaseLetter.g,
      assetClass: RepurchaseAssetClass.listedSecurity,
      windowMonths: 2,
      acquisitions: RepurchaseAcquisitions.all,
      from: null,
      to: null,
      source: 'Art. 43.g NF 13/2013 de Bizkaia',
    ),
    RepurchaseRule(
      letter: RepurchaseLetter.i,
      assetClass: RepurchaseAssetClass.fungibleCrypto,
      windowMonths: 2,
      acquisitions: RepurchaseAcquisitions.all,
      from: '2025-01-01',
      to: null,
      source: 'Art. 43.i NF 13/2013, redacción de la NF 6/2025, de 12 de '
          'diciembre (BOB 15/12/2025)',
    ),
  ],
  swapValuation: [
    SwapValuationRule(
      source: 'Arts. 47.1.i, 45.1 y 45.3 NF 13/2013 de Bizkaia; '
          'Art. 47.1.p, redacción de la NF 6/2025',
    ),
  ],
  lossCarryforwardYears: 4,
  // Art. 66.1 NF 13/2013 de Bizkaia: income and gains compensate only within
  // their own pool.
  crossOffsetLimit: '0',
  // Art. 9.24 over Art. 34.a and b. The exemption does not reach shares bought
  // in the two months before the payment when homogeneous ones are sold in the
  // two after; that is not applied.
  dividendExemption: DividendExemptionRule(
    limit: '1500',
    excludesCollectiveInvestment: true,
    source: 'Art. 9.24 NF 13/2013 de Bizkaia',
  ),
  unlistedNotice: UnlistedNoticeRule(
    assetClass: RepurchaseAssetClass.fungibleCrypto,
    windowMonths: 12,
  ),
);
