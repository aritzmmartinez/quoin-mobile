import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/molecules/icon_tile.dart';
import 'package:quoin/src/ui/molecules/quoin_disclosure.dart';
import 'package:quoin/src/ui/organisms/quoin_sheet.dart';

typedef ExplainPoint = ({
  QuoinIconData icon,
  String title,
  String body,
  String? source,
});

Future<void> showExplainSheet(
  BuildContext context, {
  required String title,
  required List<ExplainPoint> points,
  String? intro,
  String? detailTitle,
  List<String> detail = const [],
}) => showQuoinSheet<void>(
  context,
  title: title,
  subtitle: intro,
  body: (sheet) =>
      ExplainSheet(points: points, detailTitle: detailTitle, detail: detail),
);

class ExplainSheet extends StatelessWidget {
  const ExplainSheet({
    super.key,
    required this.points,
    this.detailTitle,
    this.detail = const [],
  });

  final List<ExplainPoint> points;
  final String? detailTitle;
  final List<String> detail;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final detailTitle = this.detailTitle;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: QuoinSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, point) in points.indexed)
            MergeSemantics(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: QuoinSpace.card),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: i == points.length - 1
                        ? BorderSide.none
                        : BorderSide(color: c.borderSubtle),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: QuoinSpace.card,
                  children: [
                    ExcludeSemantics(child: IconTile(icon: point.icon)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: QuoinSpace.xs,
                        children: [
                          Text(point.title, style: type.rowStrong),
                          Text(
                            point.body,
                            style: type.secondary.copyWith(color: c.body),
                          ),
                          if (point.source case final source?)
                            Text(
                              source,
                              style: type.secondary.tabular.copyWith(
                                color: c.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (detailTitle != null && detail.isNotEmpty) ...[
            const SizedBox(height: QuoinSpace.s),
            QuoinDisclosure(title: detailTitle, paragraphs: detail),
          ],
        ],
      ),
    );
  }
}
