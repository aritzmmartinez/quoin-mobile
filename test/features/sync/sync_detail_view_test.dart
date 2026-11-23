import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_theme.dart';
import 'package:quoin/src/features/sync/presentation/widgets/sync_detail_view.dart';
import 'package:quoin_core/quoin_core.dart';

void main() {
  testWidgets('days use the app date format', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: quoinDarkTheme,
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: SingleChildScrollView(
            child: SyncDetailView(
              detail: SyncDetail(
                resolved: Cut.of(const [
                  ResolvedConflict(
                    kind: ResolvedKind.targetDay,
                    subject: '2026-03-01',
                    resolution: Resolution.keep,
                  ),
                ]),
                setAside: Cut.of(const [
                  SetAsideRow(
                    ts: '2026-02-03T10:00:00.000Z',
                    type: 'BUY',
                    instrument: null,
                    fields: ['price'],
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Conflictos resueltos'));
    await tester.tap(find.text('Movimientos apartados'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('1 mar 2026', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('3 feb 2026', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('compositions and targets fold their names as tags', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: quoinDarkTheme,
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: SingleChildScrollView(
            child: SyncDetailView(
              detail: SyncDetail(
                compositions: Cut.of(const ['Fondo Uno']),
                newTargets: Cut.of(const ['Objetivo Uno']),
                deletedTargets: Cut.of([
                  for (var i = 0; i < detailNames + 2; i++) 'Viejo $i',
                ]),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fondo Uno'), findsNothing, reason: 'folded');

    for (final fold in [
      'Composiciones de fondo',
      'Objetivos nuevos',
      'Objetivos borrados',
    ]) {
      await tester.tap(find.text(fold));
    }
    await tester.pumpAndSettle();
    expect(find.text('Fondo Uno'), findsOneWidget);
    expect(find.text('Objetivo Uno'), findsOneWidget);
    expect(find.text('Viejo 0'), findsOneWidget);
    expect(find.text('y 2 más'), findsOneWidget);
  });
}
