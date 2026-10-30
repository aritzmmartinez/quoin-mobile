import 'package:flutter/material.dart';

@immutable
class QuoinColors extends ThemeExtension<QuoinColors> {
  const QuoinColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.borderSubtle,
    required this.text,
    required this.body,
    required this.muted,
    required this.faint,
    required this.accent,
    required this.onAccent,
    required this.positive,
    required this.negative,
    required this.dn1,
    required this.dn2,
    required this.dn3,
    required this.dn4,
    required this.dn5,
  });

  static const dark = QuoinColors(
    bg: Color(0xFF0A0A0B),
    surface: Color(0xFF151518),
    surface2: Color(0xFF1A1A1E),
    border: Color(0xFF26262A),
    borderSubtle: Color(0xFF1F1F24),
    text: Color(0xFFFFFFFF),
    body: Color(0xFFC9C9CF),
    muted: Color(0xFF8B8B93),
    faint: Color(0xFF4E4E54),
    accent: Color(0xFFF2F2F4),
    onAccent: Color(0xFF0A0A0B),
    positive: Color(0xFF00D68F),
    negative: Color(0xFFFF4757),
    dn1: Color(0xFFF2F2F4),
    dn2: Color(0xFF9A9A9C),
    dn3: Color(0xFF69696C),
    dn4: Color(0xFF4A4A4D),
    dn5: Color(0xFF26262A),
  );

  static const light = QuoinColors(
    bg: Color(0xFFF5F5F7),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF2F2F5),
    border: Color(0xFFE3E3E8),
    borderSubtle: Color(0xFFECECF0),
    text: Color(0xFF0A0A0B),
    body: Color(0xFF3C3C43),
    muted: Color(0xFF6B6B74),
    faint: Color(0xFFA3A3AB),
    accent: Color(0xFF0A0A0B),
    onAccent: Color(0xFFFFFFFF),
    positive: Color(0xFF009A6B),
    negative: Color(0xFFD93644),
    dn1: Color(0xFF0A0A0B),
    dn2: Color(0xFF6C6C6D),
    dn3: Color(0xFFA2A2A2),
    dn4: Color(0xFFC4C4C4),
    dn5: Color(0xFFE3E3E8),
  );

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color borderSubtle;
  final Color text;
  final Color body;
  final Color muted;
  final Color faint;
  final Color accent;
  final Color onAccent;
  final Color positive;
  final Color negative;
  final Color dn1;
  final Color dn2;
  final Color dn3;
  final Color dn4;
  final Color dn5;

  static QuoinColors of(BuildContext context) =>
      Theme.of(context).extension<QuoinColors>()!;

  @override
  QuoinColors copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? border,
    Color? borderSubtle,
    Color? text,
    Color? body,
    Color? muted,
    Color? faint,
    Color? accent,
    Color? onAccent,
    Color? positive,
    Color? negative,
    Color? dn1,
    Color? dn2,
    Color? dn3,
    Color? dn4,
    Color? dn5,
  }) {
    return QuoinColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      text: text ?? this.text,
      body: body ?? this.body,
      muted: muted ?? this.muted,
      faint: faint ?? this.faint,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      dn1: dn1 ?? this.dn1,
      dn2: dn2 ?? this.dn2,
      dn3: dn3 ?? this.dn3,
      dn4: dn4 ?? this.dn4,
      dn5: dn5 ?? this.dn5,
    );
  }

  @override
  QuoinColors lerp(QuoinColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return QuoinColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surface2: l(surface2, other.surface2),
      border: l(border, other.border),
      borderSubtle: l(borderSubtle, other.borderSubtle),
      text: l(text, other.text),
      body: l(body, other.body),
      muted: l(muted, other.muted),
      faint: l(faint, other.faint),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      positive: l(positive, other.positive),
      negative: l(negative, other.negative),
      dn1: l(dn1, other.dn1),
      dn2: l(dn2, other.dn2),
      dn3: l(dn3, other.dn3),
      dn4: l(dn4, other.dn4),
      dn5: l(dn5, other.dn5),
    );
  }
}
