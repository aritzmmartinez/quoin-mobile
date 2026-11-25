import 'package:flutter/material.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/l10n/quoin_format.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/portfolio/domain/entities/instrument_chart.dart';
import 'package:quoin/src/features/portfolio/domain/entities/movement.dart';
import 'package:quoin/src/features/portfolio/domain/entities/price_series.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/ledger_tiles.dart';
import 'package:quoin/src/ui/atoms/quoin_chip.dart';
import 'package:quoin/src/ui/organisms/quoin_line_chart.dart';
import 'package:quoin/src/ui/organisms/quoin_sheet.dart';

class PriceChartSection extends StatefulWidget {
  const PriceChartSection({
    super.key,
    required this.chart,
    required this.name,
    required this.zone,
    required this.movements,
    this.averageCost,
  });

  final InstrumentChart chart;
  final String name;
  final String zone;
  final List<Movement> movements;
  final Money? averageCost;

  @override
  State<PriceChartSection> createState() => _PriceChartSectionState();
}

class _PriceChartSectionState extends State<PriceChartSection> {
  late ChartRange _range = _initial();
  DayValue? _scrub;

  List<ChartRange> get _ranges =>
      rangesOf(widget.chart.points, widget.chart.today);

  ChartRange _initial() =>
      _ranges.contains(ChartRange.year) ? ChartRange.year : ChartRange.max;

  @override
  void didUpdateWidget(PriceChartSection old) {
    super.didUpdateWidget(old);
    if (!_ranges.contains(_range)) {
      _range = _initial();
      _scrub = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = QuoinFormat.of(context);
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final chart = widget.chart;
    final window =
        cutRange(chart.points, _range, chart.today) ??
        cutRange(chart.points, ChartRange.max, chart.today)!;
    final period = l10n.chartPeriod(_range.name);
    String price(Dec value) => format.price(Money.of(value));

    final shown = _scrub ?? window.last;
    final gain = _change(format, window.first.value, shown.value);
    final averageCost = widget.averageCost;
    final ranges = _ranges;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.chartPrice, style: type.secondary.copyWith(color: c.muted)),
        const SizedBox(height: QuoinSpace.xxs),
        Text(price(shown.value), style: type.title.mono),
        Text.rich(
          TextSpan(
            text: gain.text,
            style: type.secondary.mono.copyWith(
              color: switch (gain.sign) {
                > 0 => c.positive,
                < 0 => c.negative,
                _ => c.text,
              },
            ),
            children: [
              TextSpan(
                text:
                    ' · ${_scrub == null ? period : format.day(CalendarDate.parse(shown.day))}',
                style: type.secondary.copyWith(color: c.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: QuoinSpace.m),
        QuoinLineChart(
          points: window.points,
          semanticLabel: l10n.chartSummary(
            widget.name,
            period,
            price(window.first.value),
            price(window.last.value),
            _change(format, window.first.value, window.last.value).text,
          ),
          formatValue: price,
          marks: _marks(l10n, format),
          reference: averageCost == null
              ? null
              : ChartReference(
                  averageCost.amount,
                  l10n.chartAverageLine(format.price(averageCost)),
                ),
          onScrub: (point) => setState(() => _scrub = point),
          onMarkTap: (mark) => _openTrades(context, mark.id),
        ),
        if (ranges.length > 1) ...[
          const SizedBox(height: QuoinSpace.s),
          Wrap(
            spacing: QuoinSpace.s,
            runSpacing: QuoinSpace.s,
            children: [
              for (final range in ranges)
                QuoinChip.code(
                  label: l10n.chartRange(range.name),
                  selected: range == _range,
                  onTap: () => setState(() {
                    _range = range;
                    _scrub = null;
                  }),
                ),
            ],
          ),
        ],
        if (chart.unrated > 0) ...[
          const SizedBox(height: QuoinSpace.s),
          Text(
            l10n.chartUnrated(chart.unrated),
            style: type.secondary.copyWith(color: c.muted),
          ),
        ],
        if (chart.source == PriceSource.kraken) ...[
          const SizedBox(height: QuoinSpace.s),
          Text(
            l10n.krakenAttribution,
            style: type.secondary.copyWith(color: c.muted),
          ),
        ],
      ],
    );
  }

  ({String text, int sign}) _change(QuoinFormat format, Dec from, Dec to) {
    final change = Money.of(to - from);
    final signed = format.signedPrice(change);
    if (from.isZero) return signed;
    final ratio = change.amount.dividedBy(from).roundTo(ratioDecimals);
    return (
      text: '${signed.text} · ${format.percent(ratio, signed: true)}',
      sign: signed.sign,
    );
  }

  List<({String day, List<Movement> trades})> get _trades =>
      tradesByDay(widget.movements, widget.zone);

  List<ChartMark> _marks(AppLocalizations l10n, QuoinFormat format) => [
    for (final (:day, :trades) in _trades)
      () {
        final date = format.day(CalendarDate.parse(day));
        final sales = trades.every((t) => t.type == 'SELL');
        return ChartMark(
          id: day,
          day: day,
          kind: sales ? ChartMarkKind.ring : ChartMarkKind.filled,
          label: switch (trades) {
            [final one] when one.type == 'BUY' => l10n.chartMarkBuy(date),
            [_] => l10n.chartMarkSell(date),
            _ => l10n.chartMarkMany(trades.length, date),
          },
        );
      }(),
  ];

  void _openTrades(BuildContext context, String day) {
    final trades = _trades.where((d) => d.day == day).firstOrNull?.trades;
    if (trades == null) return;
    showQuoinSheet<void>(
      context,
      title: QuoinFormat.of(context).day(CalendarDate.parse(day)),
      body: (sheet) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: QuoinSpace.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in trades)
              movementTile(sheet, m, widget.zone, inMonth: false),
          ],
        ),
      ),
    );
  }
}
