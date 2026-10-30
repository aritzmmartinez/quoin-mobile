import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// One capture of what lies behind the bar, shared by every [QuoinBarSurface]
/// inside it: the pill and a detached button refract the same backdrop and
/// cost one pass, not two.
///
/// Premium quality: the standard shader keeps a hard rim over dark backdrops.
/// No blending, so shapes a few pixels apart stay apart instead of melting
/// into each other.
class QuoinGlassLayer extends StatelessWidget {
  const QuoinGlassLayer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AdaptiveLiquidGlassLayer(
      quality: GlassQuality.premium,
      blendAmount: 0,
      settings: dark
          ? LiquidGlassSettings.ios27Dark
          : LiquidGlassSettings.ios27Light,
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
    return GlassContainer(
      quality: GlassQuality.premium,
      height: height,
      width: _circle ? height : null,
      shape: const LiquidRoundedSuperellipse(borderRadius: height / 2),
      child: child,
    );
  }
}
