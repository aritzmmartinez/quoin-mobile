import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';

class MovementRow extends StatelessWidget {
  const MovementRow({
    super.key,
    required this.type,
    required this.date,
    required this.amount,
    this.subject,
    this.marks = const [],
    this.onTap,
  });

  final String type;
  final String date;
  final String amount;
  final String? subject;
  final List<String> marks;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final text = QuoinType.of(context);
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          spacing: 12,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(type, style: text.row),
                  if (subject case final subject?)
                    Text(
                      subject,
                      style: text.secondary.copyWith(color: c.body),
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        date,
                        style: text.small.mono.copyWith(color: c.muted),
                      ),
                      for (final mark in marks)
                        DecoratedBox(
                          decoration: ShapeDecoration(
                            shape: StadiumBorder(
                              side: BorderSide(color: c.border),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              mark,
                              style: text.small.copyWith(color: c.muted),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.5),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  amount,
                  style: text.row.mono.copyWith(color: c.text),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}
