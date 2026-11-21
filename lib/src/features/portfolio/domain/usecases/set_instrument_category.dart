import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/portfolio/domain/repositories/portfolio_repository.dart';

enum CategoryChoice {
  equityFund(ExposureKind.equityFund),
  bondFund(ExposureKind.bondFund),
  automatic(null);

  const CategoryChoice(this.kind);

  final ExposureKind? kind;
}

class SetInstrumentCategory {
  const SetInstrumentCategory(this._repository);

  final PortfolioRepository _repository;

  Future<Result<void>> call(String id, CategoryChoice choice) =>
      _repository.setExposure(id, choice.kind, null);
}
