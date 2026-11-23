import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/ui/molecules/empty_state.dart';
import 'package:quoin/src/ui/templates/quoin_page.dart';

class ResultView<T> extends StatelessWidget {
  const ResultView({
    super.key,
    required this.title,
    required this.value,
    required this.builder,
  });

  final String title;
  final AsyncValue<Result<T>> value;
  final Widget Function(T value) builder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget failed({bool residence = false}) => QuoinPage(
      title: title,
      body: EmptyState(
        icon: QuoinIcons.alert,
        title: residence
            ? l10n.residenceUnsupportedTitle
            : l10n.portfolioLoadFailed,
        body: residence ? l10n.residenceUnsupported : l10n.loadFailedBody,
        negative: true,
      ),
    );
    return switch (value.value) {
      Ok(:final value) => builder(value),
      Err(:final failure) => switch (failure) {
        UnsupportedResidenceFailure() => failed(residence: true),
        StorageFailure() ||
        NetworkFailure() ||
        ImportFailure() ||
        SyncFailure() => failed(),
      },
      null when value.hasError => failed(),
      null => QuoinPage(title: title, body: const SizedBox.shrink()),
    };
  }
}
