import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/portfolio/presentation/providers/portfolio_providers.dart';
import 'package:quoin/src/features/tax/domain/entities/realized_report.dart';
import 'package:quoin/src/features/tax/domain/usecases/realized_report_of.dart';

final realizedReportProvider = FutureProvider<Result<RealizedReport>>(
  (ref) =>
      fromLedger(ref, (l) => realizedReportOf(l, ref.watch(nowProvider)())),
);
