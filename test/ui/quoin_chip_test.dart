import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_theme.dart';
import 'package:quoin/src/ui/atoms/quoin_chip.dart';

void main() {
  final themes = {
    'light': (quoinLightTheme, QuoinColors.light),
    'dark': (quoinDarkTheme, QuoinColors.dark),
  };

  Future<void> pumpChip(
    WidgetTester tester,
    ThemeData theme, {
    required bool selected,
    VoidCallback? onTap,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(
            child: QuoinChip(
              label: '1M',
              selected: selected,
              onTap: onTap ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  Color fill(WidgetTester tester) => tester
      .widget<Material>(
        find.descendant(
          of: find.byType(QuoinChip),
          matching: find.byType(Material),
        ),
      )
      .color!;

  Color textColor(WidgetTester tester) =>
      tester.widget<Text>(find.text('1M')).style!.color!;

  for (final MapEntry(key: name, value: (theme, c)) in themes.entries) {
    testWidgets('selected chip uses the accent in the $name theme', (
      tester,
    ) async {
      await pumpChip(tester, theme, selected: true);
      expect(fill(tester), c.accent);
      expect(textColor(tester), c.onAccent);
    });

    testWidgets('unselected chip is outlined in the $name theme', (
      tester,
    ) async {
      await pumpChip(tester, theme, selected: false);
      expect(fill(tester), Colors.transparent);
      expect(textColor(tester), c.muted);
    });
  }

  testWidgets('tapping the chip calls onTap', (tester) async {
    var taps = 0;
    await pumpChip(
      tester,
      quoinDarkTheme,
      selected: false,
      onTap: () => taps++,
    );
    await tester.tap(find.byType(QuoinChip));
    expect(taps, 1);
  });
}
