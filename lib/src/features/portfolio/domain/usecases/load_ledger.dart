import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/portfolio/domain/entities/portfolio_ledger.dart';
import 'package:quoin/src/features/portfolio/domain/repositories/portfolio_repository.dart';

class LoadLedger {
  const LoadLedger(this._repository);

  final PortfolioRepository _repository;

  Future<Result<PortfolioLedger>> call() => _repository.load();
}
