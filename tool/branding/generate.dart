// Renders the app icon and splash sources in assets/branding from the mark
// in docs/design/logo/quoin-mark-light.svg. Plain Dart, no packages.
//
//   dart run tool/branding/generate.dart
//
// Then regenerate the platform files (see CLAUDE.md).
//
// The mark is a 32-unit tile (first rect) with a stroked glyph (second rect)
// whose corner is cut by rects painted in the tile colour (the rest). Shapes
// are drawn with signed distance fields, so every edge is antialiased
// exactly.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const _source = 'docs/design/logo/quoin-mark-light.svg';
const _out = 'assets/branding';

void main() {
  final mark = _Mark.parse(File(_source).readAsStringSync());

  _writePng('$_out/icon.png', mark.render(1024, 1024 / 32, opaque: true));
  _writePng('$_out/play_store.png', mark.render(512, 512 / 32, opaque: true));

  const adaptive = 1024 * 72 / 108 / 32;
  _writePng(
    '$_out/icon_foreground.png',
    mark.render(1024, adaptive, glyphOnly: true),
  );
  _writePng(
    '$_out/icon_monochrome.png',
    mark.render(1024, adaptive, glyphOnly: true, glyphColor: _white),
  );

  _writePng('$_out/splash.png', mark.render(1152, 576 / 32));
}

const _white = (255, 255, 255);

typedef _Rgb = (int, int, int);

class _Rect {
  _Rect(
    this.x,
    this.y,
    this.w,
    this.h,
    this.rx,
    this.fill,
    this.stroke,
    this.strokeWidth,
  );

  final double x, y, w, h, rx, strokeWidth;
  final _Rgb? fill, stroke;

  double distance(double px, double py) {
    final qx = (px - (x + w / 2)).abs() - w / 2 + rx;
    final qy = (py - (y + h / 2)).abs() - h / 2 + rx;
    final outside = math.sqrt(
      math.pow(math.max(qx, 0), 2) + math.pow(math.max(qy, 0), 2),
    );
    return outside + math.min(math.max(qx, qy), 0) - rx;
  }
}

class _Mark {
  _Mark(this.tile, this.glyph, this.cuts);

  factory _Mark.parse(String svg) {
    final rects = [
      for (final m in RegExp(r'<rect\b([^>]*)>').allMatches(svg))
        _parseRect(m[1]!),
    ];
    return _Mark(rects[0], rects[1], rects.sublist(2));
  }

  final _Rect tile;
  final _Rect glyph;
  final List<_Rect> cuts;

  Uint8List render(
    int size,
    double scale, {
    bool opaque = false,
    bool glyphOnly = false,
    _Rgb? glyphColor,
  }) {
    final bg = tile.fill!;
    final fg = glyphColor ?? glyph.stroke!;
    final channels = opaque ? 3 : 4;
    final pixels = Uint8List(size * size * channels);
    double cover(double d) => (0.5 - d).clamp(0.0, 1.0);

    for (var py = 0; py < size; py++) {
      for (var px = 0; px < size; px++) {
        final ux = 16 + (px + 0.5 - size / 2) / scale;
        final uy = 16 + (py + 0.5 - size / 2) / scale;

        var g = cover(
          (glyph.distance(ux, uy).abs() - glyph.strokeWidth / 2) * scale,
        );
        for (final cut in cuts) {
          g *= 1 - cover(cut.distance(ux, uy) * scale);
        }
        final t = opaque
            ? 1.0
            : glyphOnly
            ? 0.0
            : cover(tile.distance(ux, uy) * scale);

        final alpha = g + (1 - g) * t;
        final i = (py * size + px) * channels;
        for (final (c, (f, b)) in [
          (fg.$1, bg.$1),
          (fg.$2, bg.$2),
          (fg.$3, bg.$3),
        ].indexed) {
          pixels[i + c] = alpha == 0
              ? 0
              : ((g * f + (1 - g) * t * b) / alpha).round();
        }
        if (!opaque) pixels[i + 3] = (alpha * 255).round();
      }
    }
    return _png(size, pixels, channels);
  }
}

_Rect _parseRect(String attrs) {
  String? attr(String name) =>
      RegExp('\\b$name="([^"]*)"').firstMatch(attrs)?[1];
  double number(String name) => double.parse(attr(name) ?? '0');
  _Rgb? color(String name) {
    final hex = attr(name);
    if (hex == null || hex == 'none') return null;
    final v = int.parse(hex.substring(1), radix: 16);
    return (v >> 16 & 0xFF, v >> 8 & 0xFF, v & 0xFF);
  }

  return _Rect(
    number('x'),
    number('y'),
    number('width'),
    number('height'),
    number('rx'),
    color('fill'),
    color('stroke'),
    number('stroke-width'),
  );
}

Uint8List _png(int size, Uint8List pixels, int channels) {
  final row = size * channels;
  final raw = BytesBuilder();
  for (var y = 0; y < size; y++) {
    raw
      ..addByte(0)
      ..add(Uint8List.sublistView(pixels, y * row, (y + 1) * row));
  }
  final header = ByteData(13)
    ..setUint32(0, size)
    ..setUint32(4, size)
    ..setUint8(8, 8)
    ..setUint8(9, channels == 3 ? 2 : 6);
  return (BytesBuilder()
        ..add(const [137, 80, 78, 71, 13, 10, 26, 10])
        ..add(_chunk('IHDR', header.buffer.asUint8List()))
        ..add(_chunk('IDAT', ZLibEncoder(level: 9).convert(raw.takeBytes())))
        ..add(_chunk('IEND', const [])))
      .takeBytes();
}

Uint8List _chunk(String type, List<int> data) {
  final body = [...type.codeUnits, ...data];
  final length = ByteData(4)..setUint32(0, data.length);
  final crc = ByteData(4)..setUint32(0, _crc32(body));
  return Uint8List.fromList([
    ...length.buffer.asUint8List(),
    ...body,
    ...crc.buffer.asUint8List(),
  ]);
}

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = c & 1 != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}

void _writePng(String path, Uint8List bytes) {
  File(path).writeAsBytesSync(bytes);
  stdout.writeln('$path (${bytes.length ~/ 1024} KB)');
}
