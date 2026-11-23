import 'package:flutter/painting.dart';

InlineSpan markedSpan(String text, String part, TextStyle style) {
  final at = text.indexOf(part);
  if (at < 0) return TextSpan(text: text);
  return TextSpan(
    children: [
      TextSpan(text: text.substring(0, at)),
      TextSpan(text: part, style: style),
      TextSpan(text: text.substring(at + part.length)),
    ],
  );
}

InlineSpan starredSpan(String text, TextStyle strong) {
  final parts = text.split('*');
  return TextSpan(
    children: [
      for (final (i, part) in parts.indexed)
        if (part.isNotEmpty)
          TextSpan(text: part, style: i.isOdd ? strong : null),
    ],
  );
}
