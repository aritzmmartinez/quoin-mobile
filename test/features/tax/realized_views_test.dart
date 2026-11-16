import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/features/tax/presentation/pages/realized_page.dart';
import 'package:quoin/src/ui/atoms/quoin_chip.dart';
import 'package:quoin/src/ui/molecules/quoin_segmented.dart';
import 'package:quoin/src/ui/organisms/quoin_segmented_pages.dart';

import '../../helpers.dart';
import 'realized_page_test.dart' show openRealized;

Finder get _views => find
    .descendant(
      of: find.byType(QuoinSegmentedPages<int>),
      matching: find.byType(PageView),
    )
    .first;

double _view(WidgetTester tester) =>
    tester.widget<PageView>(_views).controller!.page!;

Matcher get _isSelected => isSemantics(isSelected: true);

double _indicator(WidgetTester tester) {
  final align = tester.widget<AnimatedAlign>(
    find.descendant(
      of: find.byType(QuoinSegmented<int>),
      matching: find.byType(AnimatedAlign),
    ),
  );
  return ((align.alignment as Alignment).x + 1) / 2;
}

bool _year2025(WidgetTester tester) =>
    tester.widget<QuoinChip>(find.widgetWithText(QuoinChip, '2025')).selected;

void main() {
  testWidgets(
    'a swipe moves between Ventas and Fiscal, the indicator with it',
    (tester) async {
      await openRealized(tester);
      expect(tester.getSemantics(find.text('Ventas')), _isSelected);

      final gesture = await tester.startGesture(tester.getCenter(_views));
      for (var i = 0; i < 6; i++) {
        await gesture.moveBy(const Offset(-30, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(_indicator(tester), closeTo(_view(tester), 1e-9));
      expect(_indicator(tester), inExclusiveRange(0, 1), reason: 'mid swipe');
      await gesture.moveBy(const Offset(-400, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_view(tester), 1);
      expect(tester.getSemantics(find.text('Fiscal (Bizkaia)')), _isSelected);
      expect(find.text('Base liquidable del ahorro'), findsOneWidget);

      await tester.drag(_views, const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(tester.getSemantics(find.text('Ventas')), _isSelected);

      await tester.tap(find.text('Fiscal (Bizkaia)'));
      await tester.pumpAndSettle();
      expect(_view(tester), 1, reason: 'a tap still switches');
    },
  );

  testWidgets('each view keeps its order, year and scroll, and is not rebuilt '
      'while it slides', (tester) async {
    await openRealized(tester);
    await tester.tap(find.text('Resultado'));
    await tester.pumpAndSettle();
    await tester.drag(verticalLists.first, const Offset(0, -150));
    await tester.pumpAndSettle();
    final sales = tester.state<ScrollableState>(verticalLists.first);
    final scrolled = sales.position.pixels;
    expect(scrolled, greaterThan(0));

    await tester.drag(_views, const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(QuoinChip, '2025'));
    await tester.pumpAndSettle();
    expect(_year2025(tester), isTrue);

    final rebuilt = <Element>[];
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      if (builtOnce && element.widget is RealizedPage) rebuilt.add(element);
    };
    addTearDown(() => debugOnRebuildDirtyWidget = null);
    final gesture = await tester.startGesture(tester.getCenter(_views));
    for (var i = 0; i < 8; i++) {
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(rebuilt, isEmpty, reason: 'the views move, the page is not built');
    await gesture.moveBy(const Offset(400, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    debugOnRebuildDirtyWidget = null;

    expect(tester.getSemantics(find.text('Ventas')), _isSelected);
    expect(sales.position.pixels, scrolled, reason: 'same list, same place');
    await tester.drag(verticalLists.first, const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(
      tester.widget<QuoinChip>(find.widgetWithText(QuoinChip, 'Resultado')),
      isA<QuoinChip>().having((c) => c.selected, 'selected', isTrue),
    );

    await tester.drag(_views, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(_year2025(tester), isTrue);
  });

  testWidgets('with reduce motion a swipe jumps, with no frame in between', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await openRealized(tester);

    final gesture = await tester.startGesture(tester.getCenter(_views));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(_view(tester), 0, reason: 'the views do not follow the finger');
    expect(_indicator(tester), 0);
    await gesture.up();
    await tester.pump();
    do {
      expect(_view(tester), 1, reason: 'no view between two');
      expect(_indicator(tester), 1, reason: 'no indicator between two');
      await tester.pump(const Duration(milliseconds: 16));
    } while (tester.binding.hasScheduledFrame);
    expect(tester.getSemantics(find.text('Fiscal (Bizkaia)')), _isSelected);
  });

  testWidgets(
    'a change of view clicks, a swipe back to the same one does not',
    (tester) async {
      final clicks = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            clicks.add(call.arguments);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await openRealized(tester);
      clicks.clear();

      await tester.drag(_views, const Offset(-60, 0));
      await tester.pumpAndSettle();
      expect(_view(tester), 0);
      expect(clicks, isEmpty, reason: 'back on the same view');

      await tester.drag(_views, const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(clicks, ['HapticFeedbackType.selectionClick']);

      await tester.tap(find.text('Ventas'));
      await tester.pumpAndSettle();
      expect(clicks, hasLength(2), reason: 'a tap clicks too');
    },
  );
}
