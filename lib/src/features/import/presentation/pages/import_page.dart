import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:quoin/src/app/router.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/features/import/presentation/providers/import_providers.dart';
import 'package:quoin/src/features/import/presentation/widgets/import_steps.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';

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
      ImportStage.review => ImportReviewStep(preview: state.preview!),
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
      appBar: AppBar(
        leading: IconButton(
          icon: const QuoinIcon(QuoinIcons.close),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(l10n.importCsv),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              QuoinSpace.gutter,
              0,
              QuoinSpace.gutter,
              12,
            ),
            child: ImportProgress(step: step, total: 4),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(QuoinSpace.gutter),
                children: [body],
              ),
            ),
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  QuoinSpace.gutter,
                  0,
                  QuoinSpace.gutter,
                  QuoinSpace.gutter,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8,
                  children: actions,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
