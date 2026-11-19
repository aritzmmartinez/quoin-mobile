# qrscan, as Quoin uses it

A fork of [qrscan](https://pub.dev/packages/qrscan) **1.2.4** by Shusheng
(MIT, see `LICENSE`, kept as it came). The changes below are under the same
licence.

The camera (CameraX), the decoder (ZXing), permissions, rotation and errors
are upstream's and unchanged. Only the scanner's look and the way its words
reach it change:

- `lib/qrscan.dart`: `scan()` takes `ScanLabels` (every word the scanner
  shows or announces) and `ScanFonts` (Flutter asset paths of the caller's
  fonts). Without them it falls back to the title and hint.
- `QrscanPlugin.java`: passes the labels, and the fonts resolved to their
  asset keys, to the scanner.
- `SecondActivity.java`: shows those words and fonts; draws under the system
  bars with the navigation bar hidden; sizes the viewfinder (260 dp, smaller
  only when large text needs the room); the torch button shows whether it is
  on and says it when it cannot light, both in the caller's words. Its old
  toast in English is gone.
- `ScanOverlayView.java`: a still veil (66 %) with the viewfinder cut out,
  rounded (radius 32 dp), and only its four corners marked. No scan line, so
  nothing moves.
- `res/layout/activity_second.xml`: a round, translucent close button, the
  step centred at the top, the title and where to find the code, a tag while
  it looks, and a round torch button with its name under it.
- `res/`: the colours, sizes, vector icons and shapes those use.

iOS has not been touched: the app is Android only for now, and the iOS
scanner ignores the labels and fonts.

To take a newer upstream release, diff it against 1.2.4 and carry these
changes over.
