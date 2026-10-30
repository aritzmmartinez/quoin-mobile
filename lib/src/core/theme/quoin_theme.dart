import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';

final ThemeData quoinDarkTheme = _build(QuoinColors.dark, Brightness.dark);
final ThemeData quoinLightTheme = _build(QuoinColors.light, Brightness.light);

ThemeData _build(QuoinColors c, Brightness brightness) {
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.accent,
    onPrimary: c.onAccent,
    secondary: c.accent,
    onSecondary: c.onAccent,
    error: c.negative,
    onError: c.onAccent,
    surface: c.bg,
    onSurface: c.text,
    onSurfaceVariant: c.muted,
    surfaceContainerLowest: c.bg,
    surfaceContainerLow: c.surface,
    surfaceContainer: c.surface,
    surfaceContainerHigh: c.surface2,
    surfaceContainerHighest: c.surface2,
    outline: c.border,
    outlineVariant: c.borderSubtle,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Geist',
    scaffoldBackgroundColor: c.bg,
    splashFactory: NoSplash.splashFactory,
    highlightColor: c.text.withValues(alpha: 0.06),
    extensions: [c, QuoinType.standard],
  );
  const t = QuoinType.standard;
  final buttonText = t.control.copyWith(fontWeight: FontWeight.w600);
  OutlineInputBorder pill(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(999),
    borderSide: BorderSide(color: color),
  );
  return base.copyWith(
    textTheme: base.textTheme
        .copyWith(
          titleLarge: t.title,
          titleMedium: t.row,
          titleSmall: t.row,
          bodyLarge: t.field,
          bodyMedium: t.row,
          bodySmall: t.secondary,
          labelLarge: t.control,
          labelMedium: t.control,
          labelSmall: t.small,
        )
        .apply(bodyColor: c.text, displayColor: c.text),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        textStyle: buttonText,
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.text,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        textStyle: buttonText,
        side: BorderSide(color: c.border),
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.text,
        minimumSize: const Size(0, 44),
        textStyle: buttonText,
        shape: const StadiumBorder(),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide(color: c.border),
      backgroundColor: Colors.transparent,
      selectedColor: c.accent,
      labelStyle: TextStyle(color: c.muted),
      secondaryLabelStyle: TextStyle(color: c.onAccent),
      showCheckmark: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      hintStyle: t.field.copyWith(color: c.faint),
      helperStyle: t.secondary.copyWith(color: c.muted),
      errorStyle: t.secondary.copyWith(color: c.negative),
      border: pill(c.border),
      enabledBorder: pill(c.border),
      focusedBorder: pill(c.accent),
      disabledBorder: pill(c.borderSubtle),
      errorBorder: pill(c.negative),
      focusedErrorBorder: pill(c.negative),
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(QuoinRadius.card),
        side: BorderSide(color: c.borderSubtle),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(QuoinRadius.sheet),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(QuoinRadius.sheet),
        ),
      ),
      showDragHandle: true,
      dragHandleColor: c.border,
    ),
    dividerTheme: DividerThemeData(color: c.borderSubtle, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.text,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: quoinOverlayStyle(brightness),
    ),
  );
}

SystemUiOverlayStyle quoinOverlayStyle(Brightness brightness) {
  final icons = brightness == Brightness.dark
      ? Brightness.light
      : Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: icons,
    statusBarBrightness: brightness,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: icons,
    systemNavigationBarContrastEnforced: false,
  );
}
