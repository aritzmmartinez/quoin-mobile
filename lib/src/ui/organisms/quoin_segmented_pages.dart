import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/ui/molecules/quoin_segmented.dart';

class QuoinSegmentedPages<T> extends StatefulWidget {
  const QuoinSegmentedPages({
    super.key,
    required this.segments,
    required this.pages,
    this.padding = const EdgeInsets.symmetric(horizontal: QuoinSpace.gutter),
    this.initialIndex = 0,
  }) : assert(segments.length == pages.length);

  final List<(T, String)> segments;
  final List<List<Widget>> pages;
  final EdgeInsets padding;
  final int initialIndex;

  @override
  State<QuoinSegmentedPages<T>> createState() => _QuoinSegmentedPagesState<T>();
}

class _QuoinSegmentedPagesState<T> extends State<QuoinSegmentedPages<T>> {
  static const _duration = Duration(milliseconds: 240);

  late final _pages = PageController(initialPage: widget.initialIndex);
  late final _position = ValueNotifier(widget.initialIndex.toDouble());
  late var _index = widget.initialIndex;
  var _swipe = 0.0;

  @override
  void initState() {
    super.initState();
    _pages.addListener(
      () => _position.value = _pages.page ?? _index.toDouble(),
    );
  }

  @override
  void dispose() {
    _pages.dispose();
    _position.dispose();
    super.dispose();
  }

  void _settle(int index) {
    if (index == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = index);
  }

  void _select(T value) {
    final index = widget.segments.indexWhere((s) => s.$1 == value);
    if (index == _index) return;
    if (MediaQuery.disableAnimationsOf(context) || (index - _index).abs() > 1) {
      _pages.jumpToPage(index);
    } else {
      _pages.animateToPage(
        index,
        duration: _duration,
        curve: Curves.easeOutCubic,
      );
    }
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth == 0 && n is ScrollEndNotification) {
      _settle(_pages.page!.round());
    }
    return false;
  }

  void _onSwipeEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final fling = velocity.abs() > kMinFlingVelocity;
    if (!fling && _swipe.abs() < context.size!.width / 3) return;
    var step = -(fling ? velocity : _swipe).sign.toInt();
    if (Directionality.of(context) == TextDirection.rtl) step = -step;
    final index = (_index + step).clamp(0, widget.pages.length - 1);
    if (index != _index) _pages.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final padding = widget.padding;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: padding.copyWith(top: 0, bottom: 0),
          child: QuoinSegmented<T>(
            segments: widget.segments,
            selected: widget.segments[_index].$1,
            position: _position,
            onChanged: _select,
          ),
        ),
        Expanded(
          child: GestureDetector(
            onHorizontalDragStart: reduceMotion ? (_) => _swipe = 0 : null,
            onHorizontalDragUpdate: reduceMotion
                ? (d) => _swipe += d.primaryDelta ?? 0
                : null,
            onHorizontalDragEnd: reduceMotion ? _onSwipeEnd : null,
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: PageView(
                controller: _pages,
                physics: reduceMotion
                    ? const NeverScrollableScrollPhysics()
                    : null,
                children: [
                  for (final page in widget.pages)
                    _KeepAlive(
                      child: ListView(
                        padding: padding.copyWith(
                          top: QuoinSpace.section,
                          bottom: padding.bottom + QuoinSpace.gutter,
                        ),
                        children: page,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
