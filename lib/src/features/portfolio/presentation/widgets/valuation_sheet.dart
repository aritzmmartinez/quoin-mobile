import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:quoin/src/app/router.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/portfolio/domain/entities/portfolio_overview.dart';
import 'package:quoin/src/ui/organisms/quoin_sheet.dart';

Future<void> showValuationSheet(
  BuildContext context,
  List<ValuationIssue> issues,
) {
  final l10n = AppLocalizations.of(context);
  final router = GoRouter.of(context);
  return showQuoinSheet<void>(
    context,
    title: l10n.valuationTitle,
    body: (sheet) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final issue in issues)
          _IssueRow(
            issue: issue,
            onTap: issue.gap == ValuationGap.leftOut
                ? null
                : () {
                    Navigator.of(sheet).pop();
                    router.push(Routes.instrument(issue.instrumentId));
                  },
          ),
      ],
    ),
  );
}

class _IssueRow extends StatelessWidget {
  const _IssueRow({required this.issue, this.onTap});

  final ValuationIssue issue;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final reason = switch (issue.gap) {
      ValuationGap.leftOut => l10n.valuationLeftOut,
      ValuationGap.noRate => l10n.valuationNoRate(issue.currency ?? ''),
      ValuationGap.noPrice => l10n.valuationNoPrice,
    };
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: QuoinSpace.gutter,
        vertical: QuoinSpace.m,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: QuoinSpace.xxs,
        children: [
          Text(issue.name, style: type.row),
          Text(reason, style: type.secondary.copyWith(color: c.muted)),
        ],
      ),
    );
    return Semantics(
      container: true,
      button: onTap != null,
      onTap: onTap,
      label: '${issue.name}, $reason',
      excludeSemantics: true,
      child: onTap == null ? row : InkWell(onTap: onTap, child: row),
    );
  }
}
