import 'package:flutter/semantics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/theme/quoin_theme.dart';
import 'package:quoin/src/ui/organisms/line_chart_geometry.dart';
import 'package:quoin/src/ui/organisms/quoin_line_chart.dart';
import 'package:quoin_core/quoin_core.dart';

List<DayValue> series(List<String> values, {String from = '2026-11-02'}) => [
  for (final (i, v) in values.indexed)
    DayValue(shiftDay(from, i), Dec.parse(v)),
];

final _points = series(['10', '12', '11', '15', '14', '9', '13', '16']);

Widget _app(Widget child, {bool reduceMotion = false, double scale = 1}) =>
    MaterialApp(
      theme: quoinDarkTheme,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduceMotion,
            textScaler: TextScaler.linear(scale),
          ),
          child: Scaffold(body: child),
        ),
      ),
    );

QuoinLineChart _chart({
  List<DayValue>? points,
  List<ChartMark> marks = const [],
  ChartReference? reference,
  ValueChanged<DayValue?>? onScrub,
  ValueChanged<ChartMark>? onMarkTap,
}) => QuoinLineChart(
  key: const ValueKey('chart'),
  points: points ?? _points,
  semanticLabel: 'Prueba, de 10 a 16',
  formatValue: (v) => '$v €',
  marks: marks,
  reference: reference,
  onScrub: onScrub,
  onMarkTap: onMarkTap,
);

final _chartFinder = find.byKey(const ValueKey('chart'));

void main() {
  group('geometry', () {
    final g = LineChartGeometry(_points, const Rect.fromLTWH(0, 0, 70, 100));

    test('x by place, y between the extremes', () {
      expect(g.high, 7);
      expect(g.low, 5);
      expect(g.offsetAt(0).dx, 0);
      expect(g.offsetAt(7), const Offset(70, 0));
      expect(g.offsetAt(5).dy, 100);
      expect(g.indexAt(-20), 0);
      expect(g.indexAt(34), 3);
      expect(g.indexAt(500), 7);
    });

    test('a mark sits on the last point on or before its day', () {
      final gap = LineChartGeometry([
        DayValue('2026-10-30', Dec.parse('1')),
        DayValue('2026-11-02', Dec.parse('2')),
      ], const Rect.fromLTWH(0, 0, 10, 10));
      expect(gap.indexOfDay('2026-10-31'), 0);
      expect(gap.indexOfDay('2026-11-02'), 1);
      expect(gap.indexOfDay('2026-10-29'), isNull);
      expect(gap.indexOfDay('2026-11-03'), isNull);
    });

    test('a reference off the range does not widen it', () {
      expect(g.spans(Dec.parse('12')), isTrue);
      expect(g.spans(Dec.parse('20')), isFalse);
      expect(g.spans(Dec.parse('8')), isFalse);
    });

    test('a flat series sits in the middle', () {
      final flat = LineChartGeometry(
        series(['5', '5']),
        const Rect.fromLTWH(0, 0, 10, 40),
      );
      expect(flat.offsetAt(1).dy, 20);
    });
  });

  testWidgets('a horizontal drag scrubs and does not turn the page', (
    tester,
  ) async {
    final scrubbed = <DayValue?>[];
    final pages = PageController();
    addTearDown(pages.dispose);
    await tester.pumpWidget(
      _app(
        PageView(
          controller: pages,
          children: [
            Center(child: _chart(onScrub: scrubbed.add)),
            const Text('otra'),
          ],
        ),
      ),
    );

    final box = tester.getRect(_chartFinder);
    final gesture = await tester.startGesture(box.center);
    await gesture.moveBy(const Offset(-40, 0));
    await gesture.moveBy(const Offset(-200, 0));
    await tester.pump();
    expect(scrubbed.last, isNotNull);
    expect(scrubbed.last!.day.compareTo(_points[4].day), lessThan(0));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(scrubbed.last, isNull);
    expect(pages.page, 0);
    expect(find.text('otra'), findsNothing);
  });

  testWidgets('a vertical drag scrolls and does not scrub', (tester) async {
    final scrubbed = <DayValue?>[];
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      _app(
        ListView(
          controller: scroll,
          children: [
            _chart(onScrub: scrubbed.add),
            const SizedBox(height: 2000),
          ],
        ),
      ),
    );
    await tester.drag(_chartFinder, const Offset(0, -150));
    await tester.pumpAndSettle();
    expect(scroll.offset, greaterThan(0));
    expect(scrubbed, isEmpty);
  });

  testWidgets('tapping near a mark reports it; marks are announced', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final tapped = <ChartMark>[];
    const buy = ChartMark(
      id: 'b',
      day: '2026-11-05',
      kind: ChartMarkKind.filled,
      label: 'Compra, 5 de noviembre',
    );
    await tester.pumpWidget(
      _app(
        Center(
          child: _chart(marks: [buy], onMarkTap: tapped.add),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Prueba, de 10 a 16'), findsOneWidget);
    final node = find.semantics.byLabel('Compra, 5 de noviembre');
    expect(node, findsOne);
    expect(
      node.evaluate().single.getSemanticsData().hasAction(SemanticsAction.tap),
      isTrue,
    );
    tester.semantics.tap(node);
    expect(tapped, [buy]);

    final box = tester.getRect(_chartFinder);
    await tester.tapAt(box.topLeft);
    expect(tapped, [buy]);
    await tester.tapAt(box.topLeft + node.evaluate().single.rect.center);
    expect(tapped, [buy, buy]);
    semantics.dispose();
  });

  testWidgets('a mark takes taps within 24 dp of it, the nearest first', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final tapped = <String>[];
    ChartMark mark(String id, String day) =>
        ChartMark(id: id, day: day, kind: ChartMarkKind.filled, label: id);
    // Narrow enough that the two marks' targets overlap.
    await tester.pumpWidget(
      _app(
        Center(
          child: SizedBox(
            width: 150,
            child: _chart(
              marks: [mark('a', '2026-11-05'), mark('b', '2026-11-06')],
              onMarkTap: (m) => tapped.add(m.id),
            ),
          ),
        ),
      ),
    );
    final box = tester.getRect(_chartFinder);
    Rect target(String id) => find.semantics.byLabel(id).evaluate().single.rect;
    expect(target('a').size, const Size(48, 48));

    final a = box.topLeft + target('a').center;
    final b = box.topLeft + target('b').center;
    expect((a - b).distance, lessThan(48));
    await tester.tapAt(a - const Offset(0, 23));
    await tester.tapAt(a - const Offset(0, 25));
    expect(tapped, ['a']);
    await tester.tapAt(Offset.lerp(a, b, 0.6)!);
    expect(tapped, ['a', 'b']);
    semantics.dispose();
  });

  testWidgets('a mark on a day without a point sits on the one before', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    // 30 October 2026 is a Friday; nothing on the weekend.
    final weekdays = [
      DayValue('2026-10-29', Dec.parse('10')),
      DayValue('2026-10-30', Dec.parse('12')),
      DayValue('2026-11-02', Dec.parse('11')),
      DayValue('2026-11-03', Dec.parse('15')),
    ];
    ChartMark mark(String id, String day) =>
        ChartMark(id: id, day: day, kind: ChartMarkKind.ring, label: id);
    await tester.pumpWidget(
      _app(
        Center(
          child: _chart(
            points: weekdays,
            marks: [
              mark('friday', '2026-10-30'),
              mark('saturday', '2026-10-31'),
              mark('before', '2026-10-28'),
              mark('after', '2026-11-04'),
            ],
            onMarkTap: (_) {},
          ),
        ),
      ),
    );
    Rect target(String id) => find.semantics.byLabel(id).evaluate().single.rect;
    expect(target('saturday'), target('friday'));
    expect(find.semantics.byLabel('before'), findsNothing);
    expect(find.semantics.byLabel('after'), findsNothing);
    semantics.dispose();
  });

  testWidgets('a new period morphs and settles; with reduce motion it jumps', (
    tester,
  ) async {
    for (final reduceMotion in [false, true]) {
      await tester.pumpWidget(
        _app(Center(child: _chart()), reduceMotion: reduceMotion),
      );
      await tester.pumpWidget(
        _app(
          Center(child: _chart(points: _points.sublist(3))),
          reduceMotion: reduceMotion,
        ),
      );
      expect(tester.hasRunningAnimations, !reduceMotion);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('labels grow with 200 % text and the chart grows with them', (
    tester,
  ) async {
    Future<double> heightAt(double scale) async {
      await tester.pumpWidget(
        _app(
          Center(
            child: _chart(
              reference: ChartReference(Dec.parse('30'), 'Tu precio medio'),
            ),
          ),
          scale: scale,
        ),
      );
      expect(tester.takeException(), isNull);
      return tester.getSize(_chartFinder).height;
    }

    expect(await heightAt(2), greaterThan(await heightAt(1)));
  });
}
