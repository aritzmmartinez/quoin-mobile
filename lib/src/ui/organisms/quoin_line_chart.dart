import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/organisms/line_chart_geometry.dart';

export 'package:quoin/src/ui/organisms/line_chart_geometry.dart'
    show ChartMark, ChartMarkKind;

class ChartReference {
  const ChartReference(this.value, this.label);

  final Dec value;
  final String label;
}

class QuoinLineChart extends StatefulWidget {
  const QuoinLineChart({
    super.key,
    required this.points,
    required this.semanticLabel,
    required this.formatValue,
    this.marks = const [],
    this.reference,
    this.onScrub,
    this.onMarkTap,
    this.height = 176,
  }) : assert(points.length >= 2);

  final List<DayValue> points;
  final String semanticLabel;
  final String Function(Dec value) formatValue;
  final List<ChartMark> marks;
  final ChartReference? reference;
  final ValueChanged<DayValue?>? onScrub;
  final ValueChanged<ChartMark>? onMarkTap;
  final double height;

  @override
  State<QuoinLineChart> createState() => _QuoinLineChartState();
}

class _QuoinLineChartState extends State<QuoinLineChart>
    with SingleTickerProviderStateMixin {
  static const _markTarget = 48.0;
  static const _inset = 5.0;

  late final _morph = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: 1,
  );
  List<double>? _from;
  LineChartGeometry? _geometry;
  (List<DayValue>, double, List<DayValue>)? _thinned;
  int? _scrub;

  @override
  void didUpdateWidget(QuoinLineChart old) {
    super.didUpdateWidget(old);
    if (identical(old.points, widget.points) ||
        listEquals(old.points, widget.points)) {
      return;
    }
    if (_scrub != null) _endScrub();
    final previous = _geometry;
    if (previous == null || MediaQuery.disableAnimationsOf(context)) return;
    _from = previous.sample(previous.plot.width.round().clamp(2, 1000));
    _morph.forward(from: 0);
  }

  @override
  void dispose() {
    _morph.dispose();
    super.dispose();
  }

  void _scrubTo(double dx) {
    final geometry = _geometry;
    if (geometry == null) return;
    final i = geometry.indexAt(dx);
    if (i == _scrub) return;
    setState(() => _scrub = i);
    HapticFeedback.selectionClick();
    widget.onScrub?.call(widget.points[i]);
  }

  void _endScrub() {
    if (_scrub == null) return;
    setState(() => _scrub = null);
    widget.onScrub?.call(null);
  }

  void _tap(Offset at) {
    final onMarkTap = widget.onMarkTap;
    final mark = _geometry?.markAt(at, widget.marks, _markTarget / 2);
    if (onMarkTap != null && mark != null) onMarkTap(mark);
  }

  List<DayValue> _thin(double width) {
    final cached = _thinned;
    if (cached != null &&
        identical(cached.$1, widget.points) &&
        cached.$2 == width) {
      return cached.$3;
    }
    final thin = lttb(widget.points, width.round());
    _thinned = (widget.points, width, thin);
    return thin;
  }

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final style = QuoinType.of(context).small.mono.copyWith(color: c.muted);
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final line = (TextPainter(
      text: TextSpan(text: '0', style: style),
      textScaler: scaler,
      textDirection: direction,
    )..layout()).height;
    final band = line + QuoinSpace.xs;

    final reference = widget.reference;
    final probe = LineChartGeometry(widget.points, Rect.zero);
    final side = reference == null
        ? null
        : probe.spans(reference.value)
        ? _Side.inside
        : reference.value > widget.points[probe.high].value
        ? _Side.above
        : _Side.below;
    final top = band + (side == _Side.above ? band : 0);
    final bottom = band + (side == _Side.below ? band : 0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final plot = Rect.fromLTWH(
          _inset,
          top,
          width - 2 * _inset,
          widget.height,
        );
        final geometry = LineChartGeometry(widget.points, plot);
        _geometry = geometry;
        return Semantics(
          container: true,
          label: widget.semanticLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (d) => _scrubTo(d.localPosition.dx),
            onHorizontalDragUpdate: (d) => _scrubTo(d.localPosition.dx),
            onHorizontalDragEnd: (_) => _endScrub(),
            onHorizontalDragCancel: _endScrub,
            onTapUp: widget.onMarkTap == null
                ? null
                : (d) => _tap(d.localPosition),
            child: AnimatedBuilder(
              animation: _morph,
              builder: (context, _) => CustomPaint(
                size: Size(width, top + widget.height + bottom),
                painter: _LineChartPainter(
                  geometry: geometry,
                  thinned: _thin(plot.width),
                  from: _morph.isAnimating ? _from : null,
                  t: Curves.easeOutCubic.transform(_morph.value),
                  scrub: _scrub,
                  marks: widget.marks,
                  reference: reference,
                  side: side,
                  formatValue: widget.formatValue,
                  onMarkTap: widget.onMarkTap,
                  markTarget: _markTarget,
                  colors: c,
                  style: style,
                  scaler: scaler,
                  direction: direction,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _Side { inside, above, below }

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.geometry,
    required this.thinned,
    required this.from,
    required this.t,
    required this.scrub,
    required this.marks,
    required this.reference,
    required this.side,
    required this.formatValue,
    required this.onMarkTap,
    required this.markTarget,
    required this.colors,
    required this.style,
    required this.scaler,
    required this.direction,
  });

  final LineChartGeometry geometry;
  final List<DayValue> thinned;
  final List<double>? from;
  final double t;
  final int? scrub;
  final List<ChartMark> marks;
  final ChartReference? reference;
  final _Side? side;
  final String Function(Dec value) formatValue;
  final ValueChanged<ChartMark>? onMarkTap;
  final double markTarget;
  final QuoinColors colors;
  final TextStyle style;
  final TextScaler scaler;
  final TextDirection direction;

  static const _lineWidth = 1.5;
  static const _markRadius = 3.5;
  static const _dotRadius = 4.5;

  Rect get plot => geometry.plot;

  @override
  void paint(Canvas canvas, Size size) {
    final line = _line();
    _paintFill(canvas, line);
    _paintLine(canvas, size, line);
    if (from != null) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..color = Color.fromRGBO(0, 0, 0, t),
      );
    }
    _paintReference(canvas, size);
    _paintExtremes(canvas, size);
    _paintMarks(canvas);
    if (from != null) canvas.restore();
    _paintScrub(canvas);
  }

  Path _line() {
    final path = Path();
    final start = from;
    if (start != null) {
      final to = geometry.sample(start.length);
      for (var s = 0; s < start.length; s++) {
        final x = plot.left + plot.width * s / (start.length - 1);
        final y = start[s] + (to[s] - start[s]) * t;
        s == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      return path;
    }
    for (final (i, p) in thinned.indexed) {
      final at = geometry.offsetOf(p);
      i == 0 ? path.moveTo(at.dx, at.dy) : path.lineTo(at.dx, at.dy);
    }
    return path;
  }

  void _paintFill(Canvas canvas, Path line) {
    final area = Path.from(line)
      ..lineTo(plot.right, plot.bottom)
      ..lineTo(plot.left, plot.bottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.text.withValues(alpha: 0.10),
            colors.text.withValues(alpha: 0),
          ],
        ).createShader(plot),
    );
  }

  void _paintLine(Canvas canvas, Size size, Path line) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _lineWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = colors.text;
    final at = scrub;
    if (at == null) {
      canvas.drawPath(line, paint);
      return;
    }
    final x = geometry.xAt(at);
    canvas
      ..save()
      ..clipRect(Rect.fromLTRB(x, 0, size.width, size.height))
      ..drawPath(line, Paint.from(paint)..color = colors.faint)
      ..restore()
      ..save()
      ..clipRect(Rect.fromLTRB(0, 0, x, size.height))
      ..drawPath(line, paint)
      ..restore();
  }

  TextPainter _text(String text, {Paint? halo}) => TextPainter(
    text: TextSpan(
      text: text,
      style: halo == null ? style : style.copyWith(foreground: halo),
    ),
    textScaler: scaler,
    textDirection: direction,
    maxLines: 1,
  )..layout();

  double _clampX(double centre, double width, Size size) => (centre - width / 2)
      .clamp(0.0, (size.width - width).clamp(0.0, size.width));

  void _paintExtremes(Canvas canvas, Size size) {
    final high = geometry.offsetAt(geometry.high);
    final low = geometry.offsetAt(geometry.low);
    final top = _text(formatValue(geometry.points[geometry.high].value));
    top.paint(
      canvas,
      Offset(
        _clampX(high.dx, top.width, size),
        plot.top - QuoinSpace.xs - top.height,
      ),
    );
    final bottom = _text(formatValue(geometry.points[geometry.low].value));
    bottom.paint(
      canvas,
      Offset(_clampX(low.dx, bottom.width, size), plot.bottom + QuoinSpace.xs),
    );
  }

  void _paintReference(Canvas canvas, Size size) {
    final reference = this.reference;
    if (reference == null) return;
    final label = _text(reference.label);
    switch (side) {
      case _Side.inside:
        final y = geometry.yOf(reference.value);
        _dashed(canvas, y);
        final above = y - QuoinSpace.xxs - label.height;
        final labelY = above >= plot.top ? above : y + QuoinSpace.xxs;
        final at = Offset(size.width - label.width, labelY);
        // A halo, not a box: the line and the fill stay whole around it.
        _text(
          reference.label,
          halo: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeJoin = StrokeJoin.round
            ..color = colors.bg,
        ).paint(canvas, at);
        label.paint(canvas, at);
      case _Side.above:
        _edgeLabel(canvas, size, label, 0, up: true);
      case _Side.below:
        _edgeLabel(canvas, size, label, size.height - label.height, up: false);
      case null:
        break;
    }
  }

  void _dashed(Canvas canvas, double y) {
    const dash = 4.0;
    const gap = 4.0;
    final paint = Paint()
      ..color = colors.muted
      ..strokeWidth = 1;
    for (var x = plot.left; x < plot.right; x += dash + gap) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + dash).clamp(x, plot.right), y),
        paint,
      );
    }
  }

  void _edgeLabel(
    Canvas canvas,
    Size size,
    TextPainter label,
    double y, {
    required bool up,
  }) {
    final arrow = label.height * 0.5;
    final gap = QuoinSpace.xs;
    final x = size.width - label.width;
    label.paint(canvas, Offset(x, y));
    final cx = x - gap - arrow / 2;
    final cy = y + label.height / 2;
    final h = arrow / 2;
    canvas.drawPath(
      Path()
        ..moveTo(cx - h, up ? cy + h / 2 : cy - h / 2)
        ..lineTo(cx, up ? cy - h / 2 : cy + h / 2)
        ..lineTo(cx + h, up ? cy + h / 2 : cy - h / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = colors.muted,
    );
  }

  void _paintMarks(Canvas canvas) {
    for (final mark in marks) {
      final i = geometry.indexOfDay(mark.day);
      if (i == null) continue;
      final at = geometry.offsetAt(i);
      switch (mark.kind) {
        case ChartMarkKind.filled:
          canvas.drawCircle(at, _markRadius + 1.5, Paint()..color = colors.bg);
          canvas.drawCircle(at, _markRadius, Paint()..color = colors.text);
        case ChartMarkKind.ring:
          canvas.drawCircle(at, _markRadius, Paint()..color = colors.bg);
          canvas.drawCircle(
            at,
            _markRadius,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = colors.text,
          );
      }
    }
  }

  void _paintScrub(Canvas canvas) {
    final i = scrub;
    if (i == null) return;
    final at = geometry.offsetAt(i);
    canvas
      ..drawLine(
        Offset(at.dx, plot.top),
        Offset(at.dx, plot.bottom),
        Paint()
          ..color = colors.border
          ..strokeWidth = 1,
      )
      ..drawCircle(at, _dotRadius + 2, Paint()..color = colors.bg)
      ..drawCircle(at, _dotRadius, Paint()..color = colors.text);
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder => (size) {
    final onMarkTap = this.onMarkTap;
    return [
      for (final mark in marks)
        if (geometry.indexOfDay(mark.day) case final i?)
          CustomPainterSemantics(
            key: ValueKey(mark.id),
            rect: Rect.fromCenter(
              center: geometry.offsetAt(i),
              width: markTarget,
              height: markTarget,
            ),
            properties: SemanticsProperties(
              label: mark.label,
              button: onMarkTap != null,
              onTap: onMarkTap == null ? null : () => onMarkTap(mark),
              textDirection: direction,
            ),
          ),
    ];
  };

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.geometry.plot != geometry.plot ||
      !identical(old.geometry.points, geometry.points) ||
      !identical(old.thinned, thinned) ||
      old.from != from ||
      old.t != t ||
      old.scrub != scrub ||
      !identical(old.marks, marks) ||
      old.reference?.value != reference?.value ||
      old.reference?.label != reference?.label ||
      old.colors != colors ||
      old.style != style ||
      old.scaler != scaler;

  @override
  bool shouldRebuildSemantics(_LineChartPainter old) =>
      old.geometry.plot != geometry.plot ||
      !identical(old.geometry.points, geometry.points) ||
      !identical(old.marks, marks) ||
      (old.onMarkTap == null) != (onMarkTap == null);
}
