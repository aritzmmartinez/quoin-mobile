import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:quoin/src/app/router.dart';
import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/sync/domain/usecases/pair_with_pc.dart';
import 'package:quoin/src/features/sync/presentation/providers/sync_providers.dart';
import 'package:quoin/src/features/sync/presentation/widgets/sync_failure_text.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';
import 'package:quoin/src/ui/molecules/icon_tile.dart';
import 'package:quoin/src/ui/molecules/step_list.dart';
import 'package:quoin/src/ui/molecules/empty_state.dart';
import 'package:quoin/src/ui/molecules/quoin_text_field.dart';
import 'package:quoin/src/ui/templates/quoin_page.dart';

enum _Step { intro, checking, name, waiting, moved }

class PairPage extends ConsumerStatefulWidget {
  const PairPage({super.key, this.repair = false});

  final bool repair;

  @override
  ConsumerState<PairPage> createState() => _PairPageState();
}

class _PairPageState extends ConsumerState<PairPage> {
  var _step = _Step.intro;
  PairingStart? _start;
  Failure? _failure;
  var _cameraDenied = false;
  String? _nameError;
  TextEditingController? _name;

  @override
  void dispose() {
    _name?.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final l10n = AppLocalizations.of(context);
    final scan = await ref.read(qrScannerProvider)(
      title: l10n.pairScannerTitle,
      hint: '${l10n.quoinStepOf(2, 3)} · ${l10n.pairScannerHint}',
      color: QuoinColors.dark.accent,
    );
    if (!mounted) return;
    if (scan.denied) return setState(() => _cameraDenied = true);
    if (scan.text case final text?) await _scanned(text);
  }

  Future<void> _scanned(String text) async {
    setState(() => _step = _Step.checking);
    final result = await ref
        .read(pairWithPcProvider)
        .start(text, repair: widget.repair);
    if (!mounted) return;
    setState(() {
      switch (result) {
        case Ok(:final value):
          _start = value;
          _step = value.known == null ? _Step.name : _Step.moved;
        case Err(:final failure):
          _failure = failure;
      }
    });
  }

  Future<void> _pair(String defaultName) async {
    final name = (_name?.text ?? defaultName).trim();
    if (name.isEmpty || name.length > 100) {
      setState(() => _nameError = AppLocalizations.of(context).pairNameInvalid);
      return;
    }
    setState(() {
      _nameError = null;
      _step = _Step.waiting;
    });
    final result = await ref
        .read(pairWithPcProvider)
        .confirm(_start!, name: name, now: DateTime.now());
    if (!mounted) return;
    ref.read(syncControllerProvider.notifier).reset();
    switch (result) {
      case Ok():
        context.pushReplacement(Routes.sync);
      case Err(:final failure):
        setState(() => _failure = failure);
    }
  }

  void _again() => setState(() {
    _step = _Step.intro;
    _start = null;
    _failure = null;
    _cameraDenied = false;
    _nameError = null;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = QuoinType.of(context);
    final c = QuoinColors.of(context);
    final failure = _failure;
    Widget stepOf(int step) => Text(
      l10n.quoinStepOf(step, 3),
      style: type.secondary.tabular.copyWith(color: c.muted),
    );

    if (failure != null || _cameraDenied) {
      return QuoinPage(
        title: l10n.syncPair,
        body: EmptyState(
          icon: QuoinIcons.alert,
          title: l10n.pairFailedTitle,
          body: failure == null
              ? l10n.pairCameraDenied
              : syncFailureDetail(l10n, failure),
          negative: true,
          actionLabel: l10n.syncRescan,
          onAction: () {
            _again();
            _scan();
          },
        ),
      );
    }

    final start = _start;
    return switch (_step) {
      _Step.intro => QuoinPage.list(
        title: l10n.syncPair,
        subheader: stepOf(1),
        actions: [FilledButton(onPressed: _scan, child: Text(l10n.pairScan))],
        children: [
          const SizedBox(height: QuoinSpace.s),
          ExcludeSemantics(
            child: Row(
              spacing: QuoinSpace.m,
              children: [
                const IconTile(icon: QuoinIcons.computer),
                QuoinIcon(
                  QuoinIcons.sync,
                  size: QuoinIconSize.small,
                  color: c.muted,
                ),
                const IconTile(icon: QuoinIcons.phone),
              ],
            ),
          ),
          const SizedBox(height: QuoinSpace.section),
          Semantics(
            header: true,
            child: Text(l10n.pairIntroTitle, style: type.title),
          ),
          const SizedBox(height: QuoinSpace.s),
          Text(
            l10n.pairIntroBody,
            style: type.secondary.copyWith(color: c.body),
          ),
          const SizedBox(height: QuoinSpace.block),
          StepList(steps: _steps(l10n, current: 1)),
        ],
      ),
      _Step.moved => QuoinPage(
        title: l10n.syncPair,
        body: EmptyState(
          icon: QuoinIcons.computer,
          title: l10n.pairMovedTitle,
          body: l10n.pairAddressUpdated(start!.known!.pcName),
          actionLabel: l10n.syncNow,
          onAction: () {
            ref.read(syncControllerProvider.notifier).reset();
            context.pushReplacement(Routes.sync);
          },
        ),
      ),
      _Step.checking => QuoinPage(
        title: l10n.syncPair,
        subheader: stepOf(2),
        body: _Busy(text: l10n.pairChecking),
      ),
      _Step.name || _Step.waiting => QuoinPage.list(
        title: l10n.syncPair,
        subheader: stepOf(3),
        actions: [
          if (_step == _Step.name) ...[
            FilledButton(
              onPressed: () => _pair(l10n.pairDefaultName),
              child: Text(l10n.pairMatch),
            ),
            TextButton(onPressed: _again, child: Text(l10n.pairNoMatch)),
          ],
        ],
        children: [
          const SizedBox(height: QuoinSpace.s),
          StepList(
            steps: _steps(
              l10n,
              current: 3,
              pc: start!.qr.name,
              compare: _compare(context, start.code),
            ),
          ),
        ],
      ),
    };
  }

  Widget _compare(BuildContext context, String code) {
    final l10n = AppLocalizations.of(context);
    final type = QuoinType.of(context);
    final c = QuoinColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: QuoinSpace.card,
      children: [
        Text(
          l10n.pairCompareBody,
          style: type.secondary.copyWith(color: c.body),
        ),
        Semantics(
          container: true,
          label: l10n.pairCodeLabel(_grouped(code)),
          excludeSemantics: true,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              _grouped(code),
              maxLines: 1,
              style: type.display.copyWith(color: c.text),
            ),
          ),
        ),
        if (_step == _Step.name)
          QuoinTextField(
            label: l10n.pairPhoneName,
            help: l10n.pairPhoneNameHelp,
            error: _nameError,
            controller: _name ??= TextEditingController(
              text: l10n.pairDefaultName,
            ),
          )
        else
          MergeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: QuoinSpace.m,
              children: [
                SizedBox.square(
                  dimension: QuoinIconSize.row,
                  child: CircularProgressIndicator(color: c.accent),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: QuoinSpace.xxs,
                    children: [
                      Text(l10n.pairAccept, style: type.row),
                      Text(
                        l10n.pairWaiting,
                        style: type.secondary.copyWith(color: c.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<StepEntry> _steps(
    AppLocalizations l10n, {
    required int current,
    String? pc,
    Widget? compare,
  }) {
    StepStatus status(int step) => step < current
        ? StepStatus.done
        : step == current
        ? StepStatus.current
        : StepStatus.pending;
    return [
      StepEntry(
        title: l10n.pairStepOpen,
        detail: l10n.pairStepOpenDetail,
        status: status(1),
      ),
      StepEntry(
        title: l10n.pairStepScan,
        detail: pc == null
            ? l10n.pairStepScanDetail
            : l10n.pairStepScanDone(pc),
        status: status(2),
      ),
      StepEntry(
        title: l10n.pairStepCompare,
        detail: compare == null ? l10n.pairStepCompareDetail : null,
        status: status(3),
        child: compare,
      ),
    ];
  }
}

String _grouped(String code) => '${code.substring(0, 3)} ${code.substring(3)}';

class _Busy extends StatelessWidget {
  const _Busy({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(QuoinSpace.gutter),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: QuoinSpace.card,
      children: [
        const CircularProgressIndicator(),
        Text(
          text,
          textAlign: TextAlign.center,
          style: QuoinType.of(context).row,
        ),
      ],
    ),
  );
}
