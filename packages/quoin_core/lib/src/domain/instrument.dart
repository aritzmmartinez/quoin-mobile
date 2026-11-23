import 'coded.dart';

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

enum ExposureSource { user, derived, none }

final class EffectiveExposure {
  const EffectiveExposure(this.kind, this.source);

  final ExposureKind? kind;
  final ExposureSource source;
}

EffectiveExposure effectiveExposure(String type, ExposureKind? exposureKind) {
  if (exposureKind != null) {
    return EffectiveExposure(exposureKind, ExposureSource.user);
  }
  final derived = switch (type) {
    'STOCK' => ExposureKind.company,
    'CRYPTO' => ExposureKind.crypto,
    'COMMODITY' => ExposureKind.commodity,
    _ => null,
  };
  return derived == null
      ? const EffectiveExposure(null, ExposureSource.none)
      : EffectiveExposure(derived, ExposureSource.derived);
}

final class Instrument {
  const Instrument({
    required this.id,
    required this.name,
    required this.type,
    this.assetClass,
    this.exposureKind,
    this.exposureLeafId,
  });

  final String id;
  final String name;
  final String type;
  final String? assetClass;
  final ExposureKind? exposureKind;
  final String? exposureLeafId;
}
