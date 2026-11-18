import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';

/// One capture of what lies behind the bar, shared by every [QuoinBarSurface]
/// inside it: the pill and a detached button refract the same backdrop and
/// cost one pass, not two.
///
/// Premium quality: the standard shader keeps a hard rim over dark backdrops.
/// No blending, so shapes a few pixels apart stay apart instead of melting
/// into each other.
class QuoinGlassLayer extends StatelessWidget {
  const QuoinGlassLayer({super.key, required this.child});

  /// How much of the tint covers the backdrop. Nearly opaque on purpose: the
  /// bar reads as a solid surface and the glass only shows at the rim.
  static const tintOpacity = 0.82;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final settings = dark
        ? LiquidGlassSettings.ios27Dark
        : LiquidGlassSettings.ios27Light.copyWith(rimShade: 0);
    return AdaptiveLiquidGlassLayer(
      quality: GlassQuality.premium,
      blendAmount: 0,
      settings: settings.copyWith(
        glassColor: (dark ? c.border : c.surface).withValues(
          alpha: tintOpacity,
        ),
      ),
      child: child,
    );
  }
}

/// A glass shape of the bar, drawn in the nearest [QuoinGlassLayer]: the
/// pill, or a [QuoinBarSurface.circle] as wide as the pill is high.
class QuoinBarSurface extends StatelessWidget {
  const QuoinBarSurface({super.key, required this.child}) : _circle = false;

  const QuoinBarSurface.circle({super.key, required this.child})
    : _circle = true;

  static const double height = 68;

  final Widget child;
  final bool _circle;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _TopRim(QuoinColors.of(context).rim),
      child: GlassContainer(
        quality: GlassQuality.premium,
        height: height,
        width: _circle ? height : null,
        shape: const LiquidRoundedSuperellipse(borderRadius: height / 2),
        child: child,
      ),
    );
  }
}

class _TopRim extends CustomPainter {
  const _TopRim(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.5);
    final path = const RoundedSuperellipseBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(QuoinBarSurface.height / 2),
      ),
    ).getOuterPath(rect);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0, 0.5],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_TopRim old) => old.color != color;
}
