import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/theme/quoin_theme.dart';
import 'package:quoin/src/ui/molecules/quoin_segmented.dart';
import 'package:quoin/src/ui/organisms/quoin_segmented_pages.dart';

void main() {
  testWidgets('inside its views a swipe is theirs, also at the last one; on '
      'the control it moves the pages around it', (tester) async {
    final outer = PageController();
    addTearDown(outer.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: quoinDarkTheme,
        home: Scaffold(
          body: PageView(
            controller: outer,
            children: [
              QuoinSegmentedPages<int>(
                segments: const [(0, 'Ventas'), (1, 'Fiscal')],
                pages: const [
                  [SizedBox(height: 400, child: Text('Vista de ventas'))],
                  [SizedBox(height: 400, child: Text('Vista fiscal'))],
                ],
              ),
              const Center(child: Text('Otra pestaña')),
            ],
          ),
        ),
      ),
    );
    final inner = find
        .descendant(
          of: find.byType(QuoinSegmentedPages<int>),
          matching: find.byType(PageView),
        )
        .first;
    double innerPage() => tester.widget<PageView>(inner).controller!.page!;

    await tester.drag(find.text('Vista de ventas'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(innerPage(), 1);
    expect(outer.page, 0);

    await tester.drag(find.text('Vista fiscal'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(innerPage(), 1, reason: 'the last view stops');
    expect(outer.page, 0, reason: 'and does not pass the swipe on');

    await tester.drag(find.byType(QuoinSegmented<int>), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(outer.page, 1, reason: 'the control is not a view');
  });
}
