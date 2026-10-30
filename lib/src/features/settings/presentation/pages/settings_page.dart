import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:quoin/src/app/router.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/settings/presentation/providers/settings_providers.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';
import 'package:quoin/src/ui/molecules/settings_row.dart';
import 'package:quoin/src/ui/organisms/settings_section.dart';
import 'package:quoin/src/ui/templates/quoin_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final version = ref.watch(appVersionProvider).value;

    final themes = {
      ThemeMode.system: l10n.optionSystem,
      ThemeMode.light: l10n.themeLight,
      ThemeMode.dark: l10n.themeDark,
    };
    final languages = <Locale?, String>{
      null: l10n.optionSystem,
      const Locale('es'): l10n.languageSpanish,
      const Locale('en'): l10n.languageEnglish,
    };

    return QuoinPage.list(
      title: l10n.tabSettings,
      children: [
        SettingsSection(
          title: l10n.settingsPreferences,
          rows: [
            SettingsRow(
              icon: QuoinIcons.currency,
              label: l10n.settingsCurrency,
              comingSoon: true,
            ),
            SettingsRow(
              icon: QuoinIcons.language,
              label: l10n.settingsLanguage,
              value: languages[locale],
              onTap: () => _choose(
                context,
                title: l10n.settingsLanguage,
                options: languages,
                current: locale,
                onSelected: (locale) => _save(
                  context,
                  ref.read(localeProvider.notifier).set(locale),
                ),
              ),
            ),
            SettingsRow(
              icon: QuoinIcons.theme,
              label: l10n.settingsTheme,
              value: themes[themeMode],
              onTap: () => _choose(
                context,
                title: l10n.settingsTheme,
                options: themes,
                current: themeMode,
                onSelected: (mode) => _save(
                  context,
                  ref.read(themeModeProvider.notifier).set(mode),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: QuoinSpace.gutter),
        SettingsSection(
          title: l10n.settingsPortfolio,
          rows: [
            SettingsRow(
              icon: QuoinIcons.dataSources,
              label: l10n.settingsDataSources,
              comingSoon: true,
            ),
            SettingsRow(
              icon: QuoinIcons.concentration,
              label: l10n.settingsConcentration,
              comingSoon: true,
            ),
          ],
        ),
        const SizedBox(height: QuoinSpace.gutter),
        SettingsSection(
          title: l10n.settingsAbout,
          rows: [
            SettingsRow(
              icon: QuoinIcons.version,
              label: l10n.settingsVersion,
              value: version,
              valueIsFigure: true,
            ),
            SettingsRow(
              icon: QuoinIcons.license,
              label: l10n.settingsLicense,
              value: l10n.licenseName,
            ),
            SettingsRow(
              icon: QuoinIcons.thirdPartyLicenses,
              label: l10n.settingsThirdPartyLicenses,
              onTap: () => showLicensePage(
                context: context,
                applicationName: l10n.appTitle,
                applicationVersion: version,
                applicationLegalese: l10n.aboutLegalese,
                useRootNavigator: true,
              ),
            ),
          ],
        ),
        if (kDebugMode) ...[
          const SizedBox(height: QuoinSpace.gutter),
          SettingsSection(
            title: 'Debug',
            rows: [
              SettingsRow(
                icon: QuoinIcons.gallery,
                label: 'Galería de componentes',
                onTap: () => context.push(Routes.gallery),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

Future<void> _save(BuildContext context, Future<Result<void>> saving) async {
  final result = await saving;
  if (!context.mounted) return;
  switch (result) {
    case Ok():
      break;
    case Err():
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).settingsSaveFailed),
          duration: const Duration(seconds: 3),
        ),
      );
  }
}

Future<void> _choose<T>(
  BuildContext context, {
  required String title,
  required Map<T, String> options,
  required T current,
  required Future<void> Function(T) onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              title,
              style: QuoinType.of(sheet).row
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          for (final MapEntry(:key, :value) in options.entries)
            ListTile(
              title: Text(value),
              trailing: key == current
                  ? const QuoinIcon(QuoinIcons.check, size: 18)
                  : null,
              onTap: () {
                Navigator.of(sheet).pop();
                onSelected(key);
              },
            ),
        ],
      ),
    ),
  );
}
