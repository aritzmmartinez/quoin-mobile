import '../domain/residence.dart';
import 'config.dart';

final class UnlistedNoticeRule {
  const UnlistedNoticeRule({
    required this.assetClass,
    required this.windowMonths,
  });

  final RepurchaseAssetClass assetClass;
  final int windowMonths;
}

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

final class TerritoryCitations {
  const TerritoryCitations({
    required this.repurchase,
    required this.incomeCarryforward,
    required this.gainsCarryforward,
  });

  final String repurchase;
  final String incomeCarryforward;
  final String gainsCarryforward;
}

final class TerritoryRules {
  const TerritoryRules({
    required this.citations,
    required this.savingsScales,
    required this.repurchase,
    required this.swapValuation,
    required this.lossCarryforwardYears,
    required this.crossOffsetLimit,
    required this.dividendExemption,
    required this.unlistedNotice,
  });

  final TerritoryCitations citations;
  final List<SavingsBaseTaxScale> savingsScales;
  final List<RepurchaseRule> repurchase;
  final List<SwapValuationRule> swapValuation;
  final int lossCarryforwardYears;
  final String crossOffsetLimit;
  final DividendExemptionRule? dividendExemption;
  final UnlistedNoticeRule unlistedNotice;
}

TerritoryRules territoryRules(Territory territory) => switch (territory) {
      Territory.bizkaia => _bizkaia,
      Territory.comun => _comun,
    };

const _bizkaia = TerritoryRules(
  citations: TerritoryCitations(
    repurchase: 'Art. 43 NF 13/2013',
    incomeCarryforward: 'Art. 66.1.a NF 13/2013',
    gainsCarryforward: 'Art. 66.1.b NF 13/2013',
  ),
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
      assetClass: RepurchaseAssetClass.listedSecurity,
      windowMonths: 2,
      acquisitions: RepurchaseAcquisitions.all,
      from: null,
      to: null,
      source: 'Art. 43.g NF 13/2013 de Bizkaia',
    ),
    RepurchaseRule(
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

const _comun = TerritoryRules(
  citations: TerritoryCitations(
    repurchase: 'art. 33.5 LIRPF',
    incomeCarryforward: 'art. 49.1.a LIRPF',
    gainsCarryforward: 'art. 49.1.b LIRPF',
  ),
  // Arts. 66.1 (state) and 76 (regional) LIRPF add up to one scale, the same
  // in every autonomous community. Ley 7/2024 added the 30% bracket from 2025;
  // no earlier scale is on file.
  savingsScales: [
    SavingsBaseTaxScale(
      year: 2025,
      source: 'Arts. 66.1 y 76 Ley 35/2006 del IRPF, redacción de la Ley '
          '7/2024, efectos 1-1-2025',
      brackets: [
        TaxBracket('0', '6000', '0.19'),
        TaxBracket('6000', '50000', '0.21'),
        TaxBracket('50000', '200000', '0.23'),
        TaxBracket('200000', '300000', '0.27'),
        TaxBracket('300000', null, '0.30'),
      ],
    ),
  ],
  // Art. 33.5.f: two months for securities admitted to trading on a regulated
  // EEA market or an equivalent one (the US included, DGT V0778-25). Letter g
  // gives one year to those not admitted; the app does not know the market a
  // security trades on, so stocks and ETFs take letter f. Crypto has no
  // repurchase rule.
  repurchase: [
    RepurchaseRule(
      assetClass: RepurchaseAssetClass.listedSecurity,
      windowMonths: 2,
      acquisitions: RepurchaseAcquisitions.all,
      from: null,
      to: null,
      source: 'Art. 33.5.f Ley 35/2006 del IRPF',
    ),
  ],
  // Art. 37.1.h LIRPF: a swap is valued at the greater of the two.
  swapValuation: [
    SwapValuationRule(source: 'Art. 37.1.h Ley 35/2006 del IRPF; DGT V0999-18'),
  ],
  lossCarryforwardYears: 4,
  // Art. 49.1.a and b LIRPF: up to 25% of the other pool's positive balance.
  crossOffsetLimit: '0.25',
  dividendExemption: null,
  // Whether art. 33.5.e reaches crypto rebought within a year is unsettled by
  // the DGT.
  unlistedNotice: UnlistedNoticeRule(
    assetClass: RepurchaseAssetClass.fungibleCrypto,
    windowMonths: 12,
  ),
);
