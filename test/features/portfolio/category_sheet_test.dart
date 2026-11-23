import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_theme.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';
import 'package:quoin/src/features/sync/presentation/widgets/conflict_card.dart';
import 'package:quoin/src/ui/molecules/group_header.dart';
import 'package:quoin/src/ui/organisms/quoin_bottom_bar.dart';
import 'package:quoin/src/ui/organisms/quoin_sheet.dart';
import 'package:quoin_core/quoin_core.dart';

import '../../helpers.dart';

const _world = 'IE00TCLASS01';
const _bonds = 'IE00TCLASS02';
const _gold = 'XS00TCLASS03';
final _at = DateTime.utc(2026, 3, 2, 10);

Future<QuoinDatabase> _stores() async {
  final db = memoryDatabase();
  await db.batch((b) {
    b
      ..insertAll(db.instrument, [
        InstrumentCompanion.insert(
          id: _world,
          name: 'Fondo Mundo Prueba',
          type: 'ETF',
          createdAt: _at,
        ),
        InstrumentCompanion.insert(
          id: _bonds,
          name: 'Fondo Bonos Prueba',
          type: 'ETF',
          createdAt: _at,
        ),
        InstrumentCompanion.insert(
          id: _gold,
          name: 'Oro Prueba ETC',
          type: 'ETF',
          exposureKind: const Value('COMMODITY'),
          exposureLeafId: const Value('XAU'),
          exposureHlc: const Value('001761599940000-0000-dev-pc'),
          createdAt: _at,
        ),
      ])
      ..insertAll(db.ledgerEntry, [
        for (final id in [_world, _bonds, _gold])
          LedgerEntryCompanion.insert(
            id: 'buy-$id',
            ts: _at,
            type: 'BUY',
            instrumentId: Value(id),
            quantity: const Value('1'),
            price: const Value('100'),
            grossAmount: '100',
            currency: 'EUR',
            source: const Value('TR_CSV'),
            externalId: Value('buy-$id'),
            createdAt: _at,
          ),
      ]);
  });
  return db;
}

Future<InstrumentRow> _row(QuoinDatabase db, String id) =>
    (db.select(db.instrument)..where((i) => i.id.equals(id))).getSingle();

Future<void> _openPortfolio(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(QuoinBottomBar),
      matching: find.text('Cartera'),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openInstrument(WidgetTester tester, String name) async {
  await _openPortfolio(tester);
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

Finder _option(String label) => find.descendant(
  of: find.byType(QuoinChoiceRow),
  matching: find.text(label),
);

void main() {
  testWidgets('the page shows the category and the sheet saves a choice', (
    tester,
  ) async {
    final db = await _stores();
    await pumpApp(tester, prefs: {'locale': 'es'}, database: db);
    await _openInstrument(tester, 'Fondo Mundo Prueba');

    await tester.tap(find.text('Sin clasificar'));
    await tester.pumpAndSettle();
    expect(find.text('Fondo de renta variable'), findsOneWidget);
    expect(find.text('Fondo de bonos'), findsOneWidget);
    expect(find.text('Materias primas'), findsNothing);
    expect(find.text('Acción'), findsNothing);
    expect(find.textContaining('Clasifícalo en el PC'), findsOneWidget);
    expect(find.text('Saltar'), findsNothing);

    await tester.tap(_option('Fondo de renta variable'));
    await tester.pumpAndSettle();

    final row = await _row(db, _world);
    expect(row.exposureKind, 'EQUITY_FUND');
    expect(row.exposureHlc, isNotNull);
    expect(find.byType(QuoinChoiceRow), findsNothing);
    expect(find.text('Fondo de renta variable'), findsWidgets);
    await db.close();
  });

  testWidgets('the options are one choice with the current one selected', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final db = await _stores();
    await pumpApp(tester, prefs: {'locale': 'es'}, database: db);
    await _openInstrument(tester, 'Fondo Mundo Prueba');
    await tester.tap(find.text('Sin clasificar'));
    await tester.pumpAndSettle();

    for (final (label, selected) in [
      ('Fondo de renta variable', false),
      ('Fondo de bonos', false),
      ('Sin clasificar', true),
    ]) {
      expect(
        tester.getSemantics(_option(label)),
        matchesSemantics(
          label: label,
          isButton: true,
          hasSelectedState: true,
          isSelected: selected,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
        reason: label,
      );
    }
    handle.dispose();
    await db.close();
  });

  testWidgets('a commodity chosen on the PC shows its leaf and can change', (
    tester,
  ) async {
    final db = await _stores();
    await pumpApp(tester, prefs: {'locale': 'es'}, database: db);
    await _openInstrument(tester, 'Oro Prueba ETC');

    await tester.tap(find.text('Materias primas · XAU'));
    await tester.pumpAndSettle();
    expect(_option('Materias primas · XAU'), findsOneWidget);
    expect(_option('Automática · Materias primas'), findsNothing);
    expect(_option('Sin clasificar'), findsOneWidget);

    await tester.tap(_option('Materias primas · XAU'));
    await tester.pumpAndSettle();
    expect((await _row(db, _gold)).exposureHlc, '001761599940000-0000-dev-pc');

    await tester.tap(find.text('Materias primas · XAU'));
    await tester.pumpAndSettle();
    await tester.tap(_option('Fondo de bonos'));
    await tester.pumpAndSettle();

    final row = await _row(db, _gold);
    expect(row.exposureKind, 'BOND_FUND');
    expect(row.exposureLeafId, isNull);
    expect(row.exposureHlc, isNot('001761599940000-0000-dev-pc'));
    await db.close();
  });

  testWidgets('the unclassified group classifies its funds one after another', (
    tester,
  ) async {
    final db = await _stores();
    await pumpApp(tester, prefs: {'locale': 'es'}, database: db);
    await _openPortfolio(tester);

    final group = find.widgetWithText(GroupHeader, 'Sin clasificar');
    expect(group, findsOneWidget);
    await tester.tap(
      find.descendant(of: group, matching: find.text('Clasificar')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('1 de 2'), findsOneWidget);

    await tester.tap(_option('Fondo de bonos'));
    await tester.pumpAndSettle();
    expect(find.textContaining('2 de 2'), findsOneWidget);
    await tester.tap(find.text('Saltar'));
    await tester.pumpAndSettle();

    expect(find.byType(QuoinChoiceRow), findsNothing);
    expect((await _row(db, _bonds)).exposureKind, 'BOND_FUND');
    expect((await _row(db, _world)).exposureKind, isNull);
    expect((await _row(db, _world)).exposureHlc, isNull);
    expect(find.widgetWithText(GroupHeader, 'Fondo de bonos'), findsOneWidget);
    await db.close();
  });

  testWidgets('closing the sheet ends the pass without writing', (
    tester,
  ) async {
    final db = await _stores();
    await pumpApp(tester, prefs: {'locale': 'es'}, database: db);
    await _openPortfolio(tester);
    await tester.tap(find.text('Clasificar'));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.byType(QuoinChoiceRow), findsNothing);
    expect((await db.select(db.syncDevice).getSingle()).lastHlc, isNull);
    await db.close();
  });

  testWidgets('the sheet fits at 200 % text size', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final db = await _stores();
    await pumpApp(tester, prefs: {'locale': 'es'}, database: db);
    await _openPortfolio(tester);

    final classify = find.text('Clasificar');
    await tester.ensureVisible(classify);
    await tester.pumpAndSettle();
    await tester.tap(classify);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Saltar'));
    await tester.pumpAndSettle();
    expect(find.text('Saltar'), findsOneWidget);
    await db.close();
  });

  testWidgets('a category conflict names the categories, never their codes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: quoinDarkTheme,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListView(
            children: [
              for (final (local, incoming) in [
                (['COMMODITY', 'XAU'], ['EQUITY_FUND', null]),
                ([null, null], ['BOND_FUND', null]),
              ])
                ConflictCard(
                  conflict: FieldConflict(
                    entity: 'instrument',
                    key: _gold,
                    field: 'exposure',
                    local: local,
                    incoming: incoming,
                  ),
                  names: const {_gold: 'Oro Prueba ETC'},
                  choice: null,
                  onChanged: (_) {},
                ),
            ],
          ),
        ),
      ),
    );

    expect(find.textContaining('Materias primas · XAU'), findsOneWidget);
    expect(find.textContaining('Fondo de renta variable'), findsOneWidget);
    expect(find.textContaining('Automática'), findsOneWidget);
    expect(find.textContaining('Fondo de bonos'), findsOneWidget);
    expect(find.textContaining('COMMODITY'), findsNothing);
    expect(find.textContaining('_FUND'), findsNothing);
  });
}
