import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:quoin/src/app/router.dart';
import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/sync/domain/usecases/pair_with_pc.dart';
import 'package:quoin/src/features/sync/presentation/providers/sync_providers.dart';
import 'package:quoin/src/features/sync/presentation/widgets/sync_failure_text.dart';
import 'package:quoin/src/ui/atoms/quoin_card.dart';
import 'package:quoin/src/ui/molecules/empty_state.dart';
import 'package:quoin/src/ui/molecules/quoin_text_field.dart';
import 'package:quoin/src/ui/templates/quoin_page.dart';

enum _Step { scan, checking, name, waiting }

class PairPage extends ConsumerStatefulWidget {
  const PairPage({super.key});

  @override
  ConsumerState<PairPage> createState() => _PairPageState();
}

class _PairPageState extends ConsumerState<PairPage> {
  var _step = _Step.scan;
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

  @override
  void initState() {
    super.initState();
    Future.microtask(_scan);
  }

  Future<void> _scan() async {
    final scan = await ref.read(qrScannerProvider)(
      hint: AppLocalizations.of(context).pairScanHint,
    );
    if (!mounted) return;
    if (scan.denied) return setState(() => _cameraDenied = true);
    if (scan.text case final text?) await _scanned(text);
  }

  Future<void> _scanned(String text) async {
    setState(() => _step = _Step.checking);
    final result = await ref.read(pairWithPcProvider).start(text);
    if (!mounted) return;
    setState(() {
      switch (result) {
        case Ok(:final value):
          _start = value;
          _step = _Step.name;
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
    _step = _Step.scan;
    _start = null;
    _failure = null;
    _cameraDenied = false;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = QuoinType.of(context);
    final c = QuoinColors.of(context);
    final failure = _failure;

    if (failure != null || _cameraDenied) {
      return QuoinPage(
        title: l10n.syncPair,
        body: EmptyState(
          message: failure == null
              ? l10n.pairCameraDenied
              : syncFailureDetail(l10n, failure),
          actionLabel: l10n.syncRescan,
          onAction: _again,
        ),
      );
    }

    return switch (_step) {
      _Step.scan => QuoinPage(
        title: l10n.syncPair,
        body: EmptyState(
          message: l10n.pairScanHint,
          actionLabel: l10n.pairScan,
          onAction: _scan,
        ),
      ),
      _Step.checking => QuoinPage(
        title: l10n.syncPair,
        body: _Busy(text: l10n.pairChecking),
      ),
      _Step.name || _Step.waiting => QuoinPage.list(
        title: l10n.syncPair,
        children: [
          Text(l10n.pairCodeTitle, style: type.row),
          const SizedBox(height: 12),
          QuoinCard(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _grouped(_start!.code),
                style: type.display.mono.copyWith(color: c.text),
              ),
            ),
          ),
          const SizedBox(height: QuoinSpace.gutter),
          if (_step == _Step.name) ...[
            QuoinTextField(
              label: l10n.pairPhoneName,
              help: l10n.pairPhoneNameHelp,
              error: _nameError,
              controller: _name ??= TextEditingController(
                text: l10n.pairDefaultName,
              ),
            ),
            const SizedBox(height: QuoinSpace.gutter),
            FilledButton(
              onPressed: () => _pair(l10n.pairDefaultName),
              child: Text(l10n.pairSend),
            ),
          ] else
            _Busy(text: l10n.pairWaiting),
        ],
      ),
    };
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
      spacing: 16,
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
