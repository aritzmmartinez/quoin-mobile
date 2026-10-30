import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class QuoinBarSurface extends StatelessWidget {
  const QuoinBarSurface({super.key, required this.child});

  static const double height = 68;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GlassContainer(
      useOwnLayer: true,
      quality: GlassQuality.premium,
      height: height,
      shape: const LiquidRoundedSuperellipse(borderRadius: height / 2),
      settings: dark
          ? LiquidGlassSettings.ios27Dark
          : LiquidGlassSettings.ios27Light,
      child: child,
    );
  }
}
