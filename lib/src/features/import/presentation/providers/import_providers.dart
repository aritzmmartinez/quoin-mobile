import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/import/domain/entities/import_batch.dart';
import 'package:quoin/src/features/import/domain/repositories/fx_repository.dart';
import 'package:quoin/src/features/import/domain/repositories/import_repository.dart';
import 'package:quoin/src/features/import/domain/usecases/commit_import.dart';
import 'package:quoin/src/features/import/domain/usecases/ensure_rates.dart';
import 'package:quoin/src/features/import/domain/usecases/pick_import_file.dart';
import 'package:quoin/src/features/import/domain/usecases/plan_import.dart';
import 'package:quoin/src/features/import/domain/usecases/preview_import.dart';
import 'package:quoin/src/features/import/domain/usecases/sample_import_batch.dart';
import 'package:quoin/src/features/portfolio/presentation/providers/portfolio_providers.dart';

final importRepositoryProvider = Provider<ImportRepository>(
  (ref) => throw UnimplementedError('importRepositoryProvider not bound'),
);
final fxRepositoryProvider = Provider<FxRepository>(
  (ref) => throw UnimplementedError('fxRepositoryProvider not bound'),
);

final pickImportFileProvider = Provider(
  (ref) => PickImportFile(ref.watch(importRepositoryProvider)),
);
final planImportProvider = Provider((ref) => const PlanImport());
final previewImportProvider = Provider(
  (ref) => PreviewImport(ref.watch(importRepositoryProvider)),
);
final commitImportProvider = Provider(
  (ref) => CommitImport(ref.watch(importRepositoryProvider)),
);
final sampleImportBatchProvider = Provider(
  (ref) => SampleImportBatch(ref.watch(importRepositoryProvider)),
);

/// Used by the brokers' adapters for rows in another currency.
final ensureRatesProvider = Provider(
  (ref) => EnsureRates(ref.watch(fxRepositoryProvider)),
);

/// The wizard's steps, in order.
enum ImportStage { help, select, processing, review, writing, done }

/// Where the wizard is. A [failure] is shown over the current stage, which is
/// the one the user goes back to: choosing a file for anything that went wrong
/// before the review, the review for a failed write.
final class ImportState {
  const ImportState(this.stage, {this.file, this.preview, this.failure});

  final ImportStage stage;
  final ImportFile? file;
  final ImportPreview? preview;
  final Failure? failure;
}

final importFlowProvider =
    NotifierProvider.autoDispose<ImportFlow, ImportState>(ImportFlow.new);

class ImportFlow extends Notifier<ImportState> {
  @override
  ImportState build() => const ImportState(ImportStage.help);

  void showSelect() => state = const ImportState(ImportStage.select);

  Future<void> pick() async {
    final result = await ref.read(pickImportFileProvider)();
    if (!ref.mounted) return;
    switch (result) {
      case Ok(value: null):
        break;
      case Ok(:final value):
        state = ImportState(ImportStage.select, file: value);
      case Err(:final failure):
        state = ImportState(ImportStage.select, failure: failure);
    }
  }

  void clearFile() => state = const ImportState(ImportStage.select);

  Future<void> process() async {
    final file = state.file;
    if (file == null) return;
    state = ImportState(ImportStage.processing, file: file);
    final result = await ref.read(planImportProvider)(file);
    if (!ref.mounted) return;
    switch (result) {
      case Ok(:final value):
        await _review(value);
      case Err(:final failure):
        state = ImportState(ImportStage.select, failure: failure);
    }
  }

  /// Debug builds only: the invented batch, straight to the review.
  Future<void> processSample(DateTime now) async {
    state = const ImportState(ImportStage.processing);
    await _review(ref.read(sampleImportBatchProvider)(now));
  }

  Future<void> _review(ImportBatch batch) async {
    final result = await ref.read(previewImportProvider)(batch);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => ImportState(ImportStage.review, preview: value),
      Err(:final failure) => ImportState(ImportStage.select, failure: failure),
    };
  }

  Future<void> commit() async {
    final preview = state.preview;
    if (preview == null) return;
    state = ImportState(ImportStage.writing, preview: preview);
    final result = await ref.read(commitImportProvider)(preview.batch);
    if (!ref.mounted) return;
    switch (result) {
      case Ok(:final value):
        ref.invalidate(portfolioOverviewProvider);
        state = ImportState(ImportStage.done, preview: value);
      case Err(:final failure):
        state = ImportState(
          ImportStage.review,
          preview: preview,
          failure: failure,
        );
    }
  }

  void dismissFailure() => state = ImportState(
    state.stage,
    file: state.file,
    preview: state.preview,
  );
}
