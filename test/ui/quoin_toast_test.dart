import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_theme.dart';
import 'package:quoin/src/ui/organisms/quoin_toast.dart';

double _contrast(Color a, Color b) {
  final (x, y) = (a.computeLuminance(), b.computeLuminance());
  return (x > y ? x + 0.05 : y + 0.05) / (x > y ? y + 0.05 : x + 0.05);
}

void main() {
  late BuildContext host;

  Future<void> pump(
    WidgetTester tester, {
    ThemeData? theme,
    double scale = 1,
    bool reduceMotion = false,
    bool screenReader = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? quoinDarkTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: reduceMotion,
            accessibleNavigation: screenReader,
            padding: const EdgeInsets.only(top: 24),
            viewPadding: const EdgeInsets.only(top: 24),
          ),
          child: child!,
        ),
        home: Builder(
          builder: (context) {
            host = context;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    );
  }

  void show({
    QuoinToastTone tone = QuoinToastTone.positive,
    String title = 'Cambios guardados',
    String? body,
    QuoinToastAction? action,
  }) => showQuoinToast(
    host,
    tone: tone,
    title: title,
    body: body,
    action: action,
  );

  Material toastMaterial(WidgetTester tester) => tester.widget<Material>(
    find
        .ancestor(
          of: find.text('Cambios guardados'),
          matching: find.byType(Material),
        )
        .first,
  );

  test('every tone reads at 4.5:1 or more, in both themes', () {
    for (final c in [QuoinColors.dark, QuoinColors.light]) {
      for (final (fill, ink) in [
        (c.positiveSolid, c.onSignal),
        (c.negativeSolid, c.onSignal),
        (c.accent, c.onAccent),
      ]) {
        expect(_contrast(fill, ink), greaterThanOrEqualTo(4.5));
      }
    }
  });

  for (final (name, theme, colors) in [
    ('dark', quoinDarkTheme, QuoinColors.dark),
    ('light', quoinLightTheme, QuoinColors.light),
  ]) {
    testWidgets('each tone has its fill and ink ($name)', (tester) async {
      await pump(tester, theme: theme);
      for (final (tone, fill, ink) in [
        (QuoinToastTone.positive, colors.positiveSolid, colors.onSignal),
        (QuoinToastTone.negative, colors.negativeSolid, colors.onSignal),
        (QuoinToastTone.neutral, colors.accent, colors.onAccent),
      ]) {
        show(tone: tone, body: 'Detalle');
        await tester.pumpAndSettle();
        expect(toastMaterial(tester).color, fill);
        expect(
          tester.widget<Text>(find.text('Cambios guardados')).style!.color,
          ink,
        );
        expect(tester.widget<Text>(find.text('Detalle')).style!.color, ink);
      }
    });
  }

  testWidgets('it sits under the status bar, its colour up to the top', (
    tester,
  ) async {
    await pump(tester);
    show();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(Material).last).dy, 0);
    expect(
      tester.getTopLeft(find.text('Cambios guardados')).dy,
      greaterThan(24),
    );
  });

  testWidgets('it goes by itself: 4 s, or 6 s with a detail', (tester) async {
    await pump(tester);
    show();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 3900));
    expect(find.text('Cambios guardados'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('Cambios guardados'), findsNothing);

    show(body: 'Detalle');
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 5900));
    expect(find.text('Detalle'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('Detalle'), findsNothing);
  });

  testWidgets('a new one replaces the one shown', (tester) async {
    await pump(tester);
    show();
    await tester.pumpAndSettle();
    show(title: 'Otro');
    await tester.pumpAndSettle();
    expect(find.text('Cambios guardados'), findsNothing);
    expect(find.text('Otro'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('swiped up, it goes; a small swipe puts it back', (tester) async {
    await pump(tester);
    show();
    await tester.pumpAndSettle();
    await tester.drag(find.text('Cambios guardados'), const Offset(0, -10));
    await tester.pumpAndSettle();
    expect(find.text('Cambios guardados'), findsOneWidget);
    await tester.fling(
      find.text('Cambios guardados'),
      const Offset(0, -100),
      1000,
    );
    await tester.pumpAndSettle();
    expect(find.text('Cambios guardados'), findsNothing);
  });

  testWidgets('its action runs and takes it away', (tester) async {
    await pump(tester);
    var ran = false;
    show(action: (label: 'Revisar', onPressed: () => ran = true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Revisar'));
    await tester.pumpAndSettle();
    expect(ran, isTrue);
    expect(find.text('Cambios guardados'), findsNothing);
  });

  testWidgets('with a screen reader, one with an action waits to be used', (
    tester,
  ) async {
    await pump(tester, screenReader: true);
    show(action: (label: 'Revisar', onPressed: () {}));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('Revisar'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Cambios guardados')),
      isSemantics(isLiveRegion: true),
    );
  });

  testWidgets('with reduce motion it comes and goes with no frame between', (
    tester,
  ) async {
    await pump(tester, reduceMotion: true);
    show();
    await tester.pump();
    final slide = find
        .ancestor(
          of: find.text('Cambios guardados'),
          matching: find.byType(FractionalTranslation),
        )
        .first;
    expect(
      tester.widget<FractionalTranslation>(slide).translation,
      Offset.zero,
    );
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    expect(find.text('Cambios guardados'), findsNothing);
  });

  testWidgets('at 200 % a long detail wraps without overflowing', (
    tester,
  ) async {
    await pump(tester, scale: 2);
    show(
      body: 'El PC no responde en su dirección y no está en la red del móvil.',
      action: (label: 'Revisar', onPressed: () {}),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
  });

  testWidgets('only an error clicks', (tester) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          calls.add(call.arguments as String);
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
    await pump(tester);
    show();
    show(tone: QuoinToastTone.neutral);
    expect(calls, isEmpty);
    show(tone: QuoinToastTone.negative);
    expect(calls, ['HapticFeedbackType.lightImpact']);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
