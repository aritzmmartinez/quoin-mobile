import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/theme/quoin_theme.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/molecules/gain_badge.dart';
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
              name: 'Ejemplo Tecnología Inc.',
              detail: '12',
              value: '12.345.678,90 €',
              change: const GainBadge(
                text: '+1.234.567,89 € (+123,4 %)',
                sign: 1,
              ),
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
}
