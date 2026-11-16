import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';

enum QuoinToastTone { positive, negative, neutral }

typedef QuoinToastAction = ({String label, VoidCallback onPressed});

OverlayEntry? _shown;

void showQuoinToast(
  BuildContext context, {
  required QuoinToastTone tone,
  required String title,
  String? body,
  QuoinToastAction? action,
}) {
  _shown?.remove();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _Toast(
      tone: tone,
      title: title,
      body: body,
      action: action,
      onGone: () {
        if (_shown == entry) _shown = null;
        if (entry.mounted) entry.remove();
      },
    ),
  );
  _shown = entry;
  Overlay.of(context, rootOverlay: true).insert(entry);
  if (tone == QuoinToastTone.negative) HapticFeedback.lightImpact();
}

class _Toast extends StatefulWidget {
  const _Toast({
    required this.tone,
    required this.title,
    required this.body,
    required this.action,
    required this.onGone,
  });

  final QuoinToastTone tone;
  final String title;
  final String? body;
  final QuoinToastAction? action;
  final VoidCallback onGone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  Timer? _timer;
  var _drag = 0.0;
  var _started = false;
  var _leaving = false;

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduceMotion ? _slide.value = 1 : _slide.forward();
    final action = widget.action;
    if (action != null && MediaQuery.accessibleNavigationOf(context)) return;
    final long = widget.body != null || action != null;
    _timer = Timer(Duration(seconds: long ? 6 : 4), _leave);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _slide.dispose();
    super.dispose();
  }

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    _timer?.cancel();
    if (!_reduceMotion) await _slide.reverse();
    widget.onGone();
  }

  void _onDragEnd(DragEndDetails details) {
    final height = context.size?.height ?? 0;
    if (-_drag > height / 3 || (details.primaryVelocity ?? 0) < -500) {
      _leave();
    } else {
      setState(() => _drag = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final (fill, ink, glyph) = switch (widget.tone) {
      QuoinToastTone.positive => (
        c.positiveSolid,
        c.onSignal,
        QuoinIcons.check,
      ),
      QuoinToastTone.negative => (
        c.negativeSolid,
        c.onSignal,
        QuoinIcons.close,
      ),
      QuoinToastTone.neutral => (c.accent, c.onAccent, QuoinIcons.exclamation),
    };
    final status =
        ThemeData.estimateBrightnessForColor(fill) == Brightness.light
        ? SystemUiOverlayStyle.dark
        : SystemUiOverlayStyle.light;
    final body = widget.body;
    final action = widget.action;

    final toast = AnnotatedRegion(
      value: status,
      child: Semantics(
        container: true,
        liveRegion: true,
        child: Material(
          color: fill,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                QuoinSpace.gutter,
                QuoinSpace.section,
                QuoinSpace.gutter,
                QuoinSpace.section,
              ),
              child: Row(
                spacing: QuoinSpace.m,
                children: [
                  DecoratedBox(
                    decoration: ShapeDecoration(
                      color: ink,
                      shape: const CircleBorder(),
                    ),
                    child: SizedBox.square(
                      dimension: QuoinIconSize.large,
                      child: Center(
                        child: QuoinIcon(
                          glyph,
                          size: QuoinIconSize.small,
                          color: fill,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: QuoinSpace.xxs,
                      children: [
                        Text(
                          widget.title,
                          style: type.rowStrong.copyWith(color: ink),
                        ),
                        if (body != null)
                          // on the signals.
                          Text(
                            body,
                            style: type.secondary.copyWith(color: ink),
                          ),
                      ],
                    ),
                  ),
                  if (action != null)
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: ink),
                      onPressed: () {
                        _leave();
                        action.onPressed();
                      },
                      child: Text(action.label),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onVerticalDragUpdate: (d) =>
            setState(() => _drag = (_drag + d.delta.dy).clamp(-1e9, 0)),
        onVerticalDragEnd: _onDragEnd,
        child: AnimatedBuilder(
          animation: _slide,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, _drag),
            child: FractionalTranslation(
              translation: Offset(
                0,
                Curves.easeOutCubic.transform(_slide.value) - 1,
              ),
              child: child,
            ),
          ),
          child: toast,
        ),
      ),
    );
  }
}
