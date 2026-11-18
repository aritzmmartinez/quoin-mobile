import 'package:flutter/material.dart';

import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';

enum StepStatus { done, current, pending }

class StepEntry {
  const StepEntry({
    required this.title,
    required this.status,
    this.detail,
    this.child,
  });

  final String title;
  final StepStatus status;
  final String? detail;
  final Widget? child;
}

class StepList extends StatelessWidget {
  const StepList({super.key, required this.steps});

  static const double marker = QuoinIconSize.feature;

  final List<StepEntry> steps;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, step) in steps.indexed)
          Stack(
            children: [
              if (i < steps.length - 1)
                PositionedDirectional(
                  start: marker / 2,
                  top: marker,
                  bottom: 0,
                  child: SizedBox(
                    width: 1,
                    child: ColoredBox(
                      color: step.status == StepStatus.done
                          ? c.accent
                          : c.border,
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: QuoinSpace.card,
                children: [
                  Semantics(
                    label: [
                      l10n.quoinStepOf(i + 1, steps.length),
                      switch (step.status) {
                        StepStatus.done => l10n.quoinStepDone,
                        StepStatus.current => l10n.quoinStepCurrent,
                        StepStatus.pending => l10n.quoinStepPending,
                      },
                    ].join(', '),
                    excludeSemantics: true,
                    child: _Marker(number: i + 1, status: step.status),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: QuoinSpace.xs,
                        bottom: i < steps.length - 1 ? QuoinSpace.section : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: QuoinSpace.xxs,
                        children: [
                          Text(
                            step.title,
                            style: type.row.copyWith(
                              color: step.status == StepStatus.pending
                                  ? c.muted
                                  : c.text,
                            ),
                          ),
                          if (step.detail case final detail?)
                            Text(
                              detail,
                              style: type.secondary.copyWith(
                                color: step.status == StepStatus.pending
                                    ? c.faint
                                    : c.muted,
                              ),
                            ),
                          if (step.child case final child?) ...[
                            const SizedBox(height: QuoinSpace.m),
                            child,
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.number, required this.status});

  final int number;
  final StepStatus status;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    return Container(
      width: StepList.marker,
      height: StepList.marker,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: switch (status) {
          StepStatus.done => c.accent,
          _ => c.bg,
        },
        shape: CircleBorder(
          side: BorderSide(
            color: status == StepStatus.pending ? c.border : c.accent,
          ),
        ),
      ),
      child: status == StepStatus.done
          ? QuoinIcon(
              QuoinIcons.check,
              size: QuoinIconSize.small,
              color: c.onAccent,
            )
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$number',
                maxLines: 1,
                style: type.secondary.mono.copyWith(
                  color: status == StepStatus.pending ? c.muted : c.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }
}
