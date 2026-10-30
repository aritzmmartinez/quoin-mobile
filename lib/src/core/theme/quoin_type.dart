import 'package:flutter/material.dart';

/// The type scale. Every text style comes from here, by role; no widget sets
/// a font size. Sizes are the base the system font size scales.
///
/// Amounts and percentages take any role's `.mono` (Geist Mono, tabular
/// digits), never a style of their own.
@immutable
class QuoinType extends ThemeExtension<QuoinType> {
  const QuoinType({
    required this.display,
    required this.title,
    required this.field,
    required this.row,
    required this.control,
    required this.secondary,
    required this.small,
    required this.section,
  });

  static const standard = QuoinType(
    // The big figure (total wealth, an instrument's value), as in the design:
    // 700 34px/1, letter-spacing -.03em. Mono already.
    display: TextStyle(
      fontFamily: 'GeistMono',
      fontFeatures: _tabular,
      fontSize: 34,
      fontWeight: FontWeight.w700,
      height: 1.1,
      letterSpacing: -1,
    ),
    title: TextStyle(
      fontFamily: 'Geist',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: -0.2,
    ),
    // What the user types, and the unit beside it.
    field: TextStyle(
      fontFamily: 'Geist',
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.4,
      letterSpacing: 0,
    ),
    // A row's or a card's main line: settings, a position, a tool.
    row: TextStyle(
      fontFamily: 'Geist',
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1.3,
      letterSpacing: 0,
    ),
    // Buttons, chips, segmented controls.
    control: TextStyle(
      fontFamily: 'Geist',
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.2,
      letterSpacing: 0,
    ),
    // Subtitles, tickers, help, errors, field labels, empty states.
    secondary: TextStyle(
      fontFamily: 'Geist',
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.4,
      letterSpacing: 0,
    ),
    // Bottom bar labels, badges.
    small: TextStyle(
      fontFamily: 'Geist',
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.2,
      letterSpacing: 0.2,
    ),
    // Section headers, set in capitals: hence the tracking.
    section: TextStyle(
      fontFamily: 'Geist',
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.2,
      letterSpacing: 1.1,
    ),
  );

  static const _tabular = [FontFeature.tabularFigures()];

  final TextStyle display;
  final TextStyle title;
  final TextStyle field;
  final TextStyle row;
  final TextStyle control;
  final TextStyle secondary;
  final TextStyle small;
  final TextStyle section;

  static QuoinType of(BuildContext context) =>
      Theme.of(context).extension<QuoinType>()!;

  @override
  QuoinType copyWith({
    TextStyle? display,
    TextStyle? title,
    TextStyle? field,
    TextStyle? row,
    TextStyle? control,
    TextStyle? secondary,
    TextStyle? small,
    TextStyle? section,
  }) {
    return QuoinType(
      display: display ?? this.display,
      title: title ?? this.title,
      field: field ?? this.field,
      row: row ?? this.row,
      control: control ?? this.control,
      secondary: secondary ?? this.secondary,
      small: small ?? this.small,
      section: section ?? this.section,
    );
  }

  @override
  QuoinType lerp(QuoinType? other, double t) {
    if (other == null) return this;
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return QuoinType(
      display: l(display, other.display),
      title: l(title, other.title),
      field: l(field, other.field),
      row: l(row, other.row),
      control: l(control, other.control),
      secondary: l(secondary, other.secondary),
      small: l(small, other.small),
      section: l(section, other.section),
    );
  }
}

extension QuoinMono on TextStyle {
  /// The same role in Geist Mono with tabular digits: for amounts and
  /// percentages.
  TextStyle get mono => copyWith(
    fontFamily: 'GeistMono',
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
