import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/portfolio/domain/entities/instrument_detail.dart';
import 'package:quoin/src/features/portfolio/domain/entities/movement.dart';
import 'package:quoin/src/features/portfolio/domain/entities/portfolio_ledger.dart';
import 'package:quoin/src/features/portfolio/domain/entities/portfolio_overview.dart';
import 'package:quoin/src/features/portfolio/domain/repositories/kraken_repository.dart';
import 'package:quoin/src/features/portfolio/domain/repositories/portfolio_repository.dart';
import 'package:quoin/src/features/portfolio/domain/usecases/clear_portfolio.dart';
import 'package:quoin/src/features/portfolio/domain/usecases/get_portfolio_overview.dart';
import 'package:quoin/src/features/portfolio/domain/usecases/instrument_detail_of.dart';
import 'package:quoin/src/features/portfolio/domain/usecases/load_ledger.dart';
import 'package:quoin/src/features/portfolio/domain/usecases/load_sample_portfolio.dart';
import 'package:quoin/src/features/portfolio/domain/usecases/movements_of.dart';
import 'package:quoin/src/features/portfolio/domain/usecases/pull_kraken_prices.dart';
import 'package:quoin/src/features/portfolio/domain/usecases/set_instrument_category.dart';
import 'package:quoin/src/features/sync/presentation/providers/sync_providers.dart';

final portfolioRepositoryProvider = Provider<PortfolioRepository>(
  (ref) => throw UnimplementedError('portfolioRepositoryProvider not bound'),
);

final krakenRepositoryProvider = Provider<KrakenRepository>(
  (ref) => throw UnimplementedError('krakenRepositoryProvider not bound'),
);

final krakenHoldProvider = Provider((ref) => KrakenHold());

final pullKrakenPricesProvider = Provider(
  (ref) => PullKrakenPrices(
    ref.watch(krakenRepositoryProvider),
    ref.watch(ensureRatesFromProvider),
    ref.watch(krakenHoldProvider),
    now: ref.watch(nowProvider),
  ),
);

final loadLedgerProvider = Provider(
  (ref) => LoadLedger(ref.watch(portfolioRepositoryProvider)),
);
final loadSamplePortfolioProvider = Provider(
  (ref) => LoadSamplePortfolio(ref.watch(portfolioRepositoryProvider)),
);
final clearPortfolioProvider = Provider(
  (ref) => ClearPortfolio(ref.watch(portfolioRepositoryProvider)),
);

final setInstrumentCategoryProvider = Provider(
  (ref) => SetInstrumentCategory(ref.watch(portfolioRepositoryProvider)),
);

final nowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final ledgerProvider = FutureProvider<Result<PortfolioLedger>>(
  (ref) => ref.watch(loadLedgerProvider)(),
);

Future<Result<T>> fromLedger<T>(
  Ref ref,
  T Function(PortfolioLedger ledger) compute,
) async => switch (await ref.watch(ledgerProvider.future)) {
  Ok(:final value) => Ok(compute(value)),
  Err(:final failure) => Err(failure),
};

final portfolioOverviewProvider = FutureProvider<Result<PortfolioOverview>>(
  (ref) => fromLedger(ref, (l) => overviewOf(l, ref.watch(nowProvider)())),
);

final movementsProvider =
    FutureProvider<Result<({String zone, List<Movement> rows})>>(
      (ref) => fromLedger(
        ref,
        (l) => (zone: jurisdictionOf(l.residence).zone, rows: movementsOf(l)),
      ),
    );

final instrumentDetailProvider =
    FutureProvider.family<Result<InstrumentDetail?>, String>(
      (ref, id) => fromLedger(
        ref,
        (l) => instrumentDetailOf(l, id, ref.watch(nowProvider)()),
      ),
    );
