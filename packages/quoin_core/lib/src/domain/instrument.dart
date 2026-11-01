import 'coded.dart';

/// How an instrument decomposes. Set by hand and never inferred from a name:
/// an ETF of gold miners has "Gold" in its name and holds companies.
enum ExposureKind with Coded {
  company('COMPANY'),
  equityFund('EQUITY_FUND'),
  bondFund('BOND_FUND'),
  commodity('COMMODITY'),
  crypto('CRYPTO');

  const ExposureKind(this.code);

  @override
  final String code;

  static ExposureKind of(String code) => byCode(values, code);
}

/// Instrument master. Keyed by its identifier: the ISIN normally, the symbol
/// for crypto.
final class Instrument {
  const Instrument({
    required this.id,
    required this.name,
    required this.type,
    this.assetClass,
    this.exposureKind,
  });

  final String id;
  final String name;

  /// ETF | STOCK | CRYPTO | BOND | COMMODITY | CASH.
  final String type;

  /// The broker's own class (`stock`, `fund`, `crypto`…), kept as given.
  final String? assetClass;
  final ExposureKind? exposureKind;
}
