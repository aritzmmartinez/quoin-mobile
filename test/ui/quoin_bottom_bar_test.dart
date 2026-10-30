import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_theme.dart';
import 'package:quoin/src/ui/organisms/quoin_bottom_bar.dart';

const _labels = ['Inicio', 'Cartera', 'Análisis', 'Ajustes'];

Widget _bar({bool reduceMotion = false}) {
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
}
