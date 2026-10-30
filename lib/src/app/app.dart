import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quoin/src/app/router.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_theme.dart';
import 'package:quoin/src/features/settings/presentation/providers/settings_providers.dart';

class QuoinApp extends ConsumerWidget {
  const QuoinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: quoinLightTheme,
      darkTheme: quoinDarkTheme,
      themeMode: ref.watch(themeModeProvider),
      locale: ref.watch(localeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supported) => supported.firstWhere(
        (l) => l.languageCode == locale?.languageCode,
        orElse: () => const Locale('es'),
      ),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: quoinOverlayStyle(Theme.of(context).brightness),
        child: child!,
      ),
    );
  }
}
