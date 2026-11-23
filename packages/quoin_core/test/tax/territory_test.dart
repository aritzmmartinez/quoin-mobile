import 'package:quoin_core/quoin_core.dart';
import 'package:test/test.dart';

void main() {
  final rules = territoryRules(Territory.bizkaia);

  test(
      'Bizkaia carries losses four years and notices crypto for twelve '
      'months', () {
    expect(rules.lossCarryforwardYears, 4);
    expect(
      rules.unlistedNotice.assetClass,
      RepurchaseAssetClass.fungibleCrypto,
    );
    expect(rules.unlistedNotice.windowMonths, 12);
  });

  test(
      'Bizkaia repurchase rules: letter g for listed securities, letter i '
      'for crypto from 2025', () {
    expect(
      [
        for (final r in rules.repurchase)
          (
            r.letter,
            r.assetClass,
            r.windowMonths,
            r.acquisitions,
            r.from,
            r.to,
            r.source,
          ),
      ],
      [
        (
          RepurchaseLetter.g,
          RepurchaseAssetClass.listedSecurity,
          2,
          RepurchaseAcquisitions.all,
          null,
          null,
          'Art. 43.g NF 13/2013 de Bizkaia',
        ),
        (
          RepurchaseLetter.i,
          RepurchaseAssetClass.fungibleCrypto,
          2,
          RepurchaseAcquisitions.all,
          '2025-01-01',
          null,
          'Art. 43.i NF 13/2013, redacción de la NF 6/2025, de 12 de '
              'diciembre (BOB 15/12/2025)',
        ),
      ],
    );
  });

  test('Bizkaia values a swap at the greater side, with no bounds', () {
    expect(
      [for (final r in rules.swapValuation) (r.from, r.to, r.source)],
      [
        (
          null,
          null,
          'Arts. 47.1.i, 45.1 y 45.3 NF 13/2013 de Bizkaia; '
              'Art. 47.1.p, redacción de la NF 6/2025',
        ),
      ],
    );
  });

  test('Bizkaia 2026 savings scale', () {
    final scale = getTaxScale(Territory.bizkaia, 2026)!;
    expect(
      scale.source,
      'Art. 76 NF 13/2013 de Bizkaia, redacción NF 2/2025, efectos 1-1-2026',
    );
    expect(
      [for (final b in scale.brackets) (b.from, b.to, b.rate)],
      [
        ('0', '7500', '0.19'),
        ('7500', '15000', '0.20'),
        ('15000', '30000', '0.22'),
        ('30000', '50000', '0.24'),
        ('50000', '90000', '0.255'),
        ('90000', '120000', '0.26'),
        ('120000', '240000', '0.265'),
        ('240000', '300000', '0.27'),
        ('300000', null, '0.28'),
      ],
    );
  });

  test(
      'Bizkaia keeps its two savings pools apart and exempts stock '
      'dividends up to 1500', () {
    expect(rules.crossOffsetLimit, '0');
    final exemption = rules.dividendExemption!;
    expect(exemption.limit, '1500');
    expect(exemption.excludesCollectiveInvestment, isTrue);
    expect(exemption.source, 'Art. 9.24 NF 13/2013 de Bizkaia');
  });

  test('Bizkaia 2025 savings scale, before NF 2/2025', () {
    final scale = getTaxScale(Territory.bizkaia, 2025)!;
    expect(scale.year, 2025);
    expect(
      scale.source,
      'Art. 76 NF 13/2013 de Bizkaia, redacción anterior a la NF 2/2025, '
      'vigente hasta 31-12-2025',
    );
    expect(
      [for (final b in scale.brackets) (b.from, b.to, b.rate)],
      [
        ('0', '2500', '0.20'),
        ('2500', '10000', '0.21'),
        ('10000', '15000', '0.22'),
        ('15000', '30000', '0.23'),
        ('30000', null, '0.25'),
      ],
    );
  });

  test(
      'the scale in force is the latest not after the year, and none '
      'before the first', () {
    expect(getTaxScale(Territory.bizkaia, 2024), isNull);
    expect(getTaxScale(Territory.bizkaia, 2026)!.year, 2026);
    expect(getTaxScale(Territory.bizkaia, 2030)!.year, 2026);
  });
}
