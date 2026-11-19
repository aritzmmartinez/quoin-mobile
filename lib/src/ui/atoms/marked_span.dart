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
