import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
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
    Widget failed([String? message]) => QuoinPage(
      title: title,
      body: EmptyState(message: message ?? l10n.portfolioLoadFailed),
    );
    return switch (value.value) {
      Ok(:final value) => builder(value),
      Err(:final failure) => switch (failure) {
        UnsupportedResidenceFailure() => failed(l10n.residenceUnsupported),
        StorageFailure() || NetworkFailure() || ImportFailure() => failed(),
      },
      null when value.hasError => failed(),
      null => QuoinPage(title: title, body: const SizedBox.shrink()),
    };
  }
}
