import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/portfolio/domain/entities/portfolio_ledger.dart';

abstract interface class PortfolioRepository {
  Future<Result<PortfolioLedger>> load();

  /// Replaces everything stored with an invented portfolio dated around [now].
  /// Debug builds only.
  Future<Result<void>> loadSample(DateTime now);

  /// Deletes the ledger, the instruments, the prices and the rates.
  Future<Result<void>> clear();
}
