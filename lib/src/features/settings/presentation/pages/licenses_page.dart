import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:quoin/src/app/router.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/settings/presentation/providers/settings_providers.dart';
import 'package:quoin/src/ui/atoms/quoin_card.dart';
import 'package:quoin/src/ui/molecules/settings_row.dart';
import 'package:quoin/src/ui/templates/quoin_page.dart';

class LicensesPage extends ConsumerWidget {
  const LicensesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final title = l10n.settingsThirdPartyLicenses;
    return switch (ref.watch(licensesProvider)) {
      AsyncData(value: final byPackage) => switch ([...byPackage.entries]) {
        final packages => QuoinPage.lazy(
          title: title,
          header: const [],
          itemCount: packages.length,
          itemBuilder: (context, i) {
            final MapEntry(key: package, value: entries) = packages[i];
            return Column(
              children: [
                if (i > 0) const Divider(height: 1),
                SettingsRow(
                  label: package,
                  value: l10n.licenseCount(entries.length),
                  onTap: () => context.push(Routes.license(package)),
                ),
              ],
            );
          },
        ),
      },
      _ => QuoinPage(title: title, body: const SizedBox.shrink()),
    };
  }
}

class LicensePackagePage extends ConsumerWidget {
  const LicensePackagePage({super.key, required this.package});

  final String package;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(licensesProvider).value?[package] ?? const [];
    return QuoinPage.list(
      title: package,
      children: [
        for (final (i, entry) in entries.indexed) ...[
          if (i > 0) const SizedBox(height: QuoinSpace.m),
          QuoinCard(child: _LicenseText(entry)),
        ],
      ],
    );
  }
}

class _LicenseText extends StatelessWidget {
  const _LicenseText(this.entry);

  final LicenseEntry entry;

  @override
  Widget build(BuildContext context) {
    final style = QuoinType.of(context).small
        .copyWith(color: QuoinColors.of(context).body);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: QuoinSpace.s,
      children: [
        for (final paragraph in entry.paragraphs)
          if (paragraph.indent == LicenseParagraph.centeredIndent)
            Text(paragraph.text, textAlign: TextAlign.center, style: style)
          else
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: QuoinSpace.card * paragraph.indent,
              ),
              child: Text(paragraph.text, style: style),
            ),
      ],
    );
  }
}
