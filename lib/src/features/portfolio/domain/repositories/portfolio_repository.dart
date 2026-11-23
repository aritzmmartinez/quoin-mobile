import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/portfolio/domain/entities/portfolio_ledger.dart';

abstract interface class PortfolioRepository {
  Future<Result<PortfolioLedger>> load();

  /// Debug builds only.
  Future<Result<void>> loadSample(DateTime now);

  Future<Result<void>> setExposure(
    String id,
    ExposureKind? kind,
    String? leafId,
  );

  Future<Result<void>> clear();
}
