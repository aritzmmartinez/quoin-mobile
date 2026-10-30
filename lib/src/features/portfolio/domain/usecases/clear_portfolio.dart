import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/portfolio/domain/repositories/portfolio_repository.dart';

class ClearPortfolio {
  const ClearPortfolio(this._repository);

  final PortfolioRepository _repository;

  Future<Result<void>> call() => _repository.clear();
}
