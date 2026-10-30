import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/portfolio/domain/entities/portfolio_overview.dart';
import 'package:quoin/src/features/portfolio/domain/repositories/portfolio_repository.dart';
import 'package:quoin/src/features/portfolio/domain/usecases/clear_portfolio.dart';
import 'package:quoin/src/features/portfolio/domain/usecases/get_portfolio_overview.dart';
import 'package:quoin/src/features/portfolio/domain/usecases/load_sample_portfolio.dart';

final portfolioRepositoryProvider = Provider<PortfolioRepository>(
  (ref) => throw UnimplementedError('portfolioRepositoryProvider not bound'),
);

final getPortfolioOverviewProvider = Provider(
  (ref) => GetPortfolioOverview(ref.watch(portfolioRepositoryProvider)),
);
final loadSamplePortfolioProvider = Provider(
  (ref) => LoadSamplePortfolio(ref.watch(portfolioRepositoryProvider)),
);
final clearPortfolioProvider = Provider(
  (ref) => ClearPortfolio(ref.watch(portfolioRepositoryProvider)),
);

/// The clock the portfolio is valued at; tests pin it.
final nowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final portfolioOverviewProvider = FutureProvider<Result<PortfolioOverview>>(
  (ref) => ref.watch(getPortfolioOverviewProvider)(ref.watch(nowProvider)()),
);
