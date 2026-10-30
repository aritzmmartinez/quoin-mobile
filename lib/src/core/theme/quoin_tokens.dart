/// Corner radii. Everything is rounded, like the landing page: buttons,
/// chips, segmented controls, text fields and the bottom bar are pills
/// (`StadiumBorder`, no number); the rest use these.
abstract final class QuoinRadius {
  static const double card = 24;
  static const double sheet = 28;

  /// A square nested in a card: [card] minus the card's padding, rounded up.
  static const double tile = 12;
}

/// Spacing. [gutter] and [row] match `--spacing-gutter` and `--spacing-row`
/// in `../quoin/app/app.css`; the rest come from the design.
abstract final class QuoinSpace {
  static const double gutter = 20;
  static const double row = 10;
  static const double card = 16;
  static const double section = 24;
}
