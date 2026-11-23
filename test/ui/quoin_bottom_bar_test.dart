import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_theme.dart';
import 'package:quoin/src/ui/organisms/quoin_bar_surface.dart';
import 'package:quoin/src/ui/organisms/quoin_bottom_bar.dart';

const _labels = ['Inicio', 'Cartera', 'Análisis', 'Ajustes'];

Widget _bar({
  bool reduceMotion = false,
  QuoinBarActionPlacement placement = QuoinBarActionPlacement.trailing,
}) {
  var current = 0;
  return MaterialApp(
    theme: quoinDarkTheme,
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: StatefulBuilder(
        builder: (context, setState) => Scaffold(
          bottomNavigationBar: QuoinBottomBar(
            items: [
              for (final label in _labels)
                QuoinBarItem(icon: QuoinIcons.home, label: label),
            ],
            currentIndex: current,
            onSelected: (i) => setState(() => current = i),
            addIcon: QuoinIcons.add,
            addLabel: 'Importar CSV',
            onAdd: () {},
            placement: placement,
          ),
        ),
      ),
    ),
  );
}

double _pillX(WidgetTester tester) => tester
    .getCenter(
      find.descendant(
        of: find.byType(PositionedDirectional),
        matching: find.byType(DecoratedBox),
      ),
    )
    .dx;

void main() {
  testWidgets('the pill springs under the tapped tab', (tester) async {
    await tester.pumpWidget(_bar());
    await tester.tap(find.text('Ajustes'));
    await tester.pump(const Duration(milliseconds: 50));
    final target = tester.getCenter(find.text('Ajustes')).dx;
    expect(_pillX(tester), lessThan(target - 1), reason: 'still moving');
    await tester.pumpAndSettle();
    expect(_pillX(tester), moreOrLessEquals(target, epsilon: 0.5));
  });

  testWidgets('with reduce motion the pill jumps', (tester) async {
    await tester.pumpWidget(_bar(reduceMotion: true));
    await tester.tap(find.text('Análisis'));
    await tester.pump();
    expect(
      _pillX(tester),
      moreOrLessEquals(
        tester.getCenter(find.text('Análisis')).dx,
        epsilon: 0.5,
      ),
    );
  });

  testWidgets('a tab scales while pressed and clicks on tap', (tester) async {
    final haptics = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments);
        }
        return null;
      },
    );
    await tester.pumpWidget(_bar());
    final scale = find.ancestor(
      of: find.text('Cartera'),
      matching: find.byType(AnimatedScale),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Cartera')),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(scale).scale, 0.92);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(scale).scale, 1);
    expect(haptics, ['HapticFeedbackType.selectionClick']);
  });

  group('the add button', () {
    Rect pill(WidgetTester tester) => tester.getRect(
      find.byWidgetPredicate((w) => w is QuoinBarSurface && w.child is Padding),
    );
    Rect add(WidgetTester tester) =>
        tester.getRect(find.byTooltip('Importar CSV'));
    List<double> tabWidths(WidgetTester tester) => [
      for (final label in _labels)
        tester
            .getRect(
              find
                  .ancestor(
                    of: find.text(label),
                    matching: find.byType(Expanded),
                  )
                  .first,
            )
            .width,
    ];

    testWidgets('trails the pill as a circle as high as it, a gap away', (
      tester,
    ) async {
      await tester.pumpWidget(_bar());
      final p = pill(tester);
      final a = add(tester);
      expect(a.height, QuoinBarSurface.height);
      expect(a.width, a.height);
      expect(a.top, p.top);
      expect(a.left - p.right, QuoinBottomBar.gap);
      expect(tabWidths(tester).toSet(), hasLength(1), reason: 'equal tabs');
    });

    testWidgets('can lead the pill', (tester) async {
      await tester.pumpWidget(_bar(placement: QuoinBarActionPlacement.leading));
      expect(pill(tester).left - add(tester).right, QuoinBottomBar.gap);
    });

    testWidgets('can sit above the end of the pill', (tester) async {
      await tester.pumpWidget(_bar(placement: QuoinBarActionPlacement.above));
      final p = pill(tester);
      final a = add(tester);
      expect(p.top - a.bottom, QuoinBottomBar.gap);
      expect(a.right, p.right);
    });

    testWidgets('can sit inside the pill, between the middle tabs', (
      tester,
    ) async {
      await tester.pumpWidget(_bar(placement: QuoinBarActionPlacement.center));
      final a = add(tester);
      expect(pill(tester).contains(a.center), isTrue);
      expect(a.left, greaterThan(tester.getCenter(find.text('Cartera')).dx));
      expect(a.right, lessThan(tester.getCenter(find.text('Análisis')).dx));
    });
  });
}
