import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_theme.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/atoms/instrument_icon.dart';
import 'package:quoin/src/ui/molecules/position_row.dart';

void main() {
  testWidgets('long figures shrink before a name breaks inside a word', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const scaler = TextScaler.linear(1.3);
    await tester.pumpWidget(
      MaterialApp(
        theme: quoinLightTheme,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: scaler),
          child: Scaffold(
            body: PositionRow(
              leading: InstrumentIcon.circle('E'),
              name: 'Ejemplo Tecnología Inc.',
              detail: '12 acciones',
              value: '12.345.678,90 €',
              change: '+1.234.567,89 € · +123,4 %',
            ),
          ),
        ),
      ),
    );

    final context = tester.element(find.byType(PositionRow));
    final word = TextPainter(
      text: TextSpan(
        text: 'Tecnología',
        style: DefaultTextStyle.of(context).style
            .merge(QuoinType.of(context).row),
      ),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final column = find
        .ancestor(
          of: find.text('Ejemplo Tecnología Inc.'),
          matching: find.byType(Column),
        )
        .first;
    expect(tester.getSize(column).width, greaterThanOrEqualTo(word.width));
    expect(tester.takeException(), isNull);
    word.dispose();
  });

  testWidgets('a row is read as its name, detail, value and result', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: quoinDarkTheme,
        home: Scaffold(
          body: PositionRow(
            leading: const InstrumentIcon.tile(QuoinIcons.fund),
            name: 'Fondo Ejemplo',
            detail: '75 participaciones',
            value: 'Sin precio',
            valueIsFigure: false,
            changePrefix: 'coste',
            change: '591,56 €',
            onTap: () {},
          ),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(PositionRow)),
      matchesSemantics(
        label: 'Fondo Ejemplo, 75 participaciones, Sin precio, coste 591,56 €',
        isButton: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('when the name would take three lines the figures go under it', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Widget row(double scale) => MaterialApp(
      theme: quoinDarkTheme,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: const Scaffold(
          body: PositionRow(
            leading: InstrumentIcon.tile(QuoinIcons.fund),
            name: 'Fondo Global Indexado',
            detail: '75 participaciones',
            value: '8131,50 €',
            change: '+1098,50 € · +15,6 %',
          ),
        ),
      ),
    );
    bool under() =>
        tester.getTopLeft(find.text('8131,50 €')).dy >=
        tester.getBottomLeft(find.text('Fondo Global Indexado')).dy;

    tester.view.physicalSize = const Size(900, 800);
    await tester.pumpWidget(row(1));
    expect(under(), isFalse);
    tester.view.physicalSize = const Size(600, 800);
    await tester.pumpWidget(row(1.3));
    expect(under(), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('in a list, one row that needs to stack stacks them all', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(600, 800);
    addTearDown(tester.view.reset);
    const long = PositionRow(
      leading: InstrumentIcon.tile(QuoinIcons.fund),
      name: 'Fondo Global Indexado',
      detail: '75 participaciones',
      value: '8131,50 €',
      change: '+1098,50 € · +15,6 %',
    );
    const short = PositionRow(
      leading: InstrumentIcon.circle('O'),
      name: 'Oro',
      detail: '2',
      value: '9 €',
      change: '+1 %',
    );
    Widget page(Widget body) => MaterialApp(
      theme: quoinDarkTheme,
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: Scaffold(body: body),
      ),
    );
    bool under(String value, String name) =>
        tester.getTopLeft(find.text(value)).dy >=
        tester.getBottomLeft(find.text(name)).dy;

    await tester.pumpWidget(page(const Column(children: [short])));
    expect(under('9 €', 'Oro'), isFalse, reason: 'alone it fits beside');

    await tester.pumpWidget(page(const PositionList(children: [long, short])));
    expect(under('8131,50 €', 'Fondo Global Indexado'), isTrue);
    expect(under('9 €', 'Oro'), isTrue, reason: 'the list stacks every row');
    expect(
      under('+1 %', '9 €'),
      isTrue,
      reason: 'the result goes on its own line, however short',
    );
    expect(tester.takeException(), isNull);
  });
}
