import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_theme.dart';
import 'package:quoin/src/ui/molecules/quoin_segmented.dart';

Widget _app(Widget child, {bool reduceMotion = false}) => MaterialApp(
  theme: quoinDarkTheme,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  const segments = [(0, 'Ventas'), (1, 'Fiscal'), (2, 'Resumen')];

  testWidgets('tapping a segment reports its value', (tester) async {
    int? changed;
    await tester.pumpWidget(
      _app(
        QuoinSegmented<int>(
          segments: segments,
          selected: 0,
          onChanged: (v) => changed = v,
        ),
      ),
    );
    await tester.tap(find.text('Resumen'));
    expect(changed, 2);
    expect(
      tester.getSemantics(find.text('Ventas')),
      isSemantics(isSelected: true, isButton: true),
    );
  });

  for (final reduceMotion in [false, true]) {
    testWidgets(
      'indicator ${reduceMotion ? 'jumps' : 'slides'} with reduce motion '
      '${reduceMotion ? 'on' : 'off'}',
      (tester) async {
        Widget seg(int selected) => _app(
          QuoinSegmented<int>(
            segments: segments,
            selected: selected,
            onChanged: (_) {},
          ),
          reduceMotion: reduceMotion,
        );
        await tester.pumpWidget(seg(0));
        await tester.pumpWidget(seg(2));
        await tester.pump(const Duration(milliseconds: 16));
        final align = tester.widget<AnimatedAlign>(find.byType(AnimatedAlign));
        expect(align.duration == Duration.zero, reduceMotion);
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets('with a position, indicator and labels follow it', (
    tester,
  ) async {
    final position = ValueNotifier(0.5);
    addTearDown(position.dispose);
    await tester.pumpWidget(
      _app(
        QuoinSegmented<int>(
          segments: segments.take(2).toList(),
          selected: 0,
          position: position,
          onChanged: (_) {},
        ),
      ),
    );
    final c = QuoinColors.of(tester.element(find.text('Ventas')));
    Color? colour(String label) => tester
        .widget<AnimatedDefaultTextStyle>(
          find
              .ancestor(
                of: find.text(label),
                matching: find.byType(AnimatedDefaultTextStyle),
              )
              .first,
        )
        .style
        .color;
    final half = Color.lerp(c.muted, c.onAccent, 0.5);
    expect(colour('Ventas'), half);
    expect(colour('Fiscal'), half);
    expect(
      tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment,
      Alignment.center,
    );

    position.value = 1;
    await tester.pump();
    expect(colour('Fiscal'), c.onAccent);
    expect(colour('Ventas'), c.muted);
  });
}
