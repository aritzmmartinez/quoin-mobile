import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/features/analysis/presentation/pages/analysis_page.dart';
import 'package:quoin/src/features/import/presentation/pages/import_page.dart';
import 'package:quoin/src/features/portfolio/presentation/pages/home_page.dart';
import 'package:quoin/src/features/portfolio/presentation/pages/instrument_page.dart';
import 'package:quoin/src/features/portfolio/presentation/pages/portfolio_page.dart';
import 'package:quoin/src/features/settings/presentation/pages/settings_page.dart';
import 'package:quoin/src/ui/organisms/quoin_bar_fade.dart';
import 'package:quoin/src/ui/organisms/quoin_bottom_bar.dart';
import 'package:quoin/src/ui/templates/quoin_page.dart';

import '../helpers.dart';

Finder _title(String title) =>
    find.descendant(of: find.byType(QuoinPage), matching: find.text(title));

Finder _tab(String label) => find.descendant(
  of: find.byType(QuoinBottomBar),
  matching: find.text(label),
);

const _left = Offset(-500, 0);
const _right = Offset(500, 0);

Future<void> _openPortfolio(WidgetTester tester) async {
  await pumpApp(tester, prefs: {'locale': 'es'}, sample: true);
  await tester.tap(_tab('Cartera'));
  await tester.pumpAndSettle();
}

Future<void> _swipe(WidgetTester tester, Offset by) async {
  await tester.drag(find.byType(PageView).first, by);
  await tester.pumpAndSettle();
}

double _page(WidgetTester tester) =>
    tester.widget<PageView>(find.byType(PageView).first).controller!.page!;

void main() {
  testWidgets('a swipe skips the «+»: Cartera, then Análisis, never import', (
    tester,
  ) async {
    await _openPortfolio(tester);

    await _swipe(tester, _left);
    expect(_title('Análisis'), findsOneWidget);
    expect(find.byType(ImportPage), findsNothing);

    await _swipe(tester, _left);
    expect(_title('Ajustes'), findsOneWidget);
    expect(find.byType(ImportPage), findsNothing);

    await _swipe(tester, _left);
    expect(_title('Ajustes'), findsOneWidget, reason: 'the last tab');

    await tester.fling(find.byType(PageView).first, _right, 4000);
    await tester.pumpAndSettle();
    expect(_title('Análisis'), findsOneWidget, reason: 'one tab per fling');
    expect(find.byType(ImportPage), findsNothing);
  });

  testWidgets('each tab keeps its state, and a swipe rebuilds no page', (
    tester,
  ) async {
    await _openPortfolio(tester);
    await tester.tap(find.text('Por valor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alfabético').last);
    await tester.pumpAndSettle();
    final list = find.descendant(
      of: find.byType(PortfolioPage),
      matching: find.byType(Scrollable),
    );
    await tester.drag(list.first, const Offset(0, -120));
    await tester.pumpAndSettle();
    final scrolled = tester.state<ScrollableState>(list.first).position.pixels;
    expect(scrolled, greaterThan(0));

    final rebuilt = <Type>{};
    const pages = {HomePage, PortfolioPage, AnalysisPage, SettingsPage};
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      if (builtOnce && pages.contains(element.widget.runtimeType)) {
        rebuilt.add(element.widget.runtimeType);
      }
    };
    addTearDown(() => debugOnRebuildDirtyWidget = null);
    final gesture = await tester.startGesture(const Offset(400, 300));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(rebuilt, isEmpty, reason: 'pages move, they are not built again');
    await gesture.up();
    await tester.pumpAndSettle();
    debugOnRebuildDirtyWidget = null;
    expect(_title('Cartera'), findsOneWidget, reason: 'short of half a page');

    await _swipe(tester, _left);
    expect(_title('Análisis'), findsOneWidget);
    await _swipe(tester, _right);
    expect(_title('Cartera'), findsOneWidget);

    expect(find.text('Alfabético'), findsOneWidget, reason: 'the order stays');
    expect(tester.state<ScrollableState>(list.first).position.pixels, scrolled);
  });

  testWidgets('with reduce motion a swipe jumps, with no frame in between', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _openPortfolio(tester);
    expect(_page(tester), 1);

    final gesture = await tester.startGesture(const Offset(400, 300));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(_page(tester), 1, reason: 'the pages do not follow the finger');
    await gesture.up();
    await tester.pump();
    expect(_page(tester), 2);
    do {
      expect(_page(tester), 2, reason: 'no page between two tabs');
      final pill = tester.widget<PositionedDirectional>(
        find
            .descendant(
              of: find.byType(QuoinBottomBar),
              matching: find.byType(PositionedDirectional),
            )
            .first,
      );
      expect(pill.start! / pill.width!, 2, reason: 'no pill between tabs');
      await tester.pump(const Duration(milliseconds: 16));
    } while (tester.binding.hasScheduledFrame);
    expect(_title('Análisis'), findsOneWidget);
  });

  testWidgets('inside a tab or over the shell, a swipe changes no tab', (
    tester,
  ) async {
    await _openPortfolio(tester);
    await tester.tap(find.text('Fondo Global Indexado'));
    await tester.pumpAndSettle();
    expect(find.byType(InstrumentPage), findsOneWidget);
    await tester.drag(find.byType(InstrumentPage), _left);
    await tester.pumpAndSettle();
    expect(find.byType(InstrumentPage), findsOneWidget);
    await tester.tap(find.byTooltip('Atrás'));
    await tester.pumpAndSettle();
    expect(_title('Cartera'), findsOneWidget);

    await tester.tap(_tab('Ajustes'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -2000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Galería de componentes'));
    await tester.pumpAndSettle();
    await _swipe(tester, _right);
    expect(_title('Galería de componentes'), findsOneWidget);
    expect(_page(tester), 3);
  });

  testWidgets('a swipe from the system gesture edge is not a tab swipe', (
    tester,
  ) async {
    tester.view.systemGestureInsets = FakeViewPadding(
      left: 40 * tester.view.devicePixelRatio,
      right: 40 * tester.view.devicePixelRatio,
    );
    addTearDown(tester.view.resetSystemGestureInsets);
    await _openPortfolio(tester);
    final width = tester.getSize(find.byType(PageView).first).width;

    await tester.dragFrom(Offset(width - 10, 300), _left);
    await tester.pumpAndSettle();
    expect(_title('Cartera'), findsOneWidget);
    await tester.dragFrom(const Offset(10, 300), _right);
    await tester.pumpAndSettle();
    expect(_title('Cartera'), findsOneWidget);

    await _swipe(tester, _left);
    expect(_title('Análisis'), findsOneWidget, reason: 'clear of the edge');
  });

  testWidgets('the fade under the bar takes no touch and says nothing', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, prefs: {'locale': 'es'}, sample: true);
    final fade = find.byType(QuoinBarFade);
    expect(fade, findsOneWidget);
    expect(
      find.descendant(of: fade, matching: find.byType(IgnorePointer)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: fade, matching: find.byType(ExcludeSemantics)),
      findsOneWidget,
    );
    final bar = tester.getRect(find.byType(QuoinBottomBar));
    expect(
      tester.getRect(fade).top,
      lessThanOrEqualTo(bar.top - QuoinBarFade.reach),
    );
    handle.dispose();
  });
}
