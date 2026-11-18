import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:quoin/src/app/router.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/features/import/presentation/providers/import_providers.dart';
import 'package:quoin/src/features/import/presentation/widgets/import_steps.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';
import 'package:quoin/src/ui/templates/quoin_page.dart';

class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key, this.sample = false});

  final bool sample;

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  @override
  void initState() {
    super.initState();
    if (widget.sample) {
      Future.microtask(
        () => ref.read(importFlowProvider.notifier).processSample(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(importFlowProvider);
    final flow = ref.read(importFlowProvider.notifier);

    ref.listen(importFlowProvider.select((s) => s.failure), (_, failure) async {
      if (failure == null) return;
      final retry = await showImportFailure(context, failure);
      if (!context.mounted) return;
      flow.dismissFailure();
      if (!retry) Navigator.of(context).pop();
    });

    final step = switch (state.stage) {
      ImportStage.help => 1,
      ImportStage.select => 2,
      ImportStage.processing || ImportStage.review || ImportStage.writing => 3,
      ImportStage.done => 4,
    };

    final body = switch (state.stage) {
      ImportStage.help => const ImportHelpStep(),
      ImportStage.select => ImportSelectStep(
        file: state.file,
        onPick: flow.pick,
        onClear: flow.clearFile,
      ),
      ImportStage.processing || ImportStage.writing => const ImportBusyStep(),
      ImportStage.review => ImportReviewStep(
        preview: state.preview!,
        fileName: state.file?.name,
      ),
      ImportStage.done => ImportDoneStep(written: state.preview!.toWrite),
    };

    final actions = <Widget>[
      ...switch (state.stage) {
        ImportStage.help => [
          FilledButton(
            onPressed: flow.showSelect,
            child: Text(l10n.importContinue),
          ),
        ],
        ImportStage.select => [
          FilledButton(
            onPressed: state.file == null ? null : flow.process,
            child: Text(l10n.importContinue),
          ),
        ],
        ImportStage.processing || ImportStage.writing => const <Widget>[],
        ImportStage.review => [
          FilledButton(
            onPressed: state.preview!.toWrite == 0 ? null : flow.commit,
            child: Text(l10n.importConfirm(state.preview!.toWrite)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.importCancel),
          ),
        ],
        ImportStage.done => [
          FilledButton(
            onPressed: () => context.go(Routes.portfolio),
            child: Text(l10n.importSeePortfolio),
          ),
        ],
      },
    ];

    return Scaffold(
      body: QuoinPage.list(
        title: l10n.importCsv,
        leading: IconButton(
          icon: const QuoinIcon(QuoinIcons.close),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => Navigator.of(context).pop(),
        ),
        subheader: ImportProgress(step: step, total: 4),
        actions: actions,
        children: [body],
      ),
    );
  }
}
