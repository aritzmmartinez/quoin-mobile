import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/portfolio/domain/repositories/portfolio_repository.dart';

class LoadSamplePortfolio {
  const LoadSamplePortfolio(this._repository);

  final PortfolioRepository _repository;

  Future<Result<void>> call(DateTime now) => _repository.loadSample(now);
}
