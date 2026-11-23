/// Corner radii. Everything is rounded, like the landing page: buttons,
/// chips, segmented controls, text fields and the bottom bar are pills
/// (`StadiumBorder`, no number); the rest use these.
abstract final class QuoinRadius {
  static const double card = 24;
  static const double sheet = 28;

  /// A small card or a bordered row that sits loose on the page.
  static const double compact = 16;

  /// A square nested in a card: [card] minus the card's padding, rounded up.
  static const double tile = 12;
}

/// Spacing. [gutter] and [row] match `--spacing-gutter` and `--spacing-row`
/// in `../quoin/app/app.css`; the rest come from the design.
abstract final class QuoinSpace {
  static const double xxs = 2;
  static const double xs = 4;
  static const double tight = 6;
  static const double s = 8;
  static const double row = 10;
  static const double m = 12;
  static const double card = 16;
  static const double gutter = 20;
  static const double section = 24;
  static const double block = 32;
  static const double hero = 48;
}

/// Icon sizes, by what the icon does.
abstract final class QuoinIconSize {
  /// A chevron or a mark beside text.
  static const double small = 16;

  /// A row's leading icon.
  static const double row = 18;

  /// Inside an icon tile.
  static const double tile = 20;

  /// A control's or a page header's icon.
  static const double large = 24;

  /// The mark of a step or of a state.
  static const double feature = 32;
}
