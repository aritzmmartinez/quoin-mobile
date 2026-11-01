import 'dart:math' as math;

import 'decimal_error.dart';

final class Dec implements Comparable<Dec> {
  const Dec._(this._unscaled, this._scale, [this._text]);

  final BigInt _unscaled;
  final int _scale;

  final String? _text;

  static const int precision = 40;

  static const int maxExponent = 1000;

  static final RegExp _grammar =
      RegExp(r'^([+-])?(\d+\.?\d*|\.\d+)(?:[eE]([+-]?\d+))?$');
  static final BigInt _ten = BigInt.from(10);
  static final BigInt _two = BigInt.two;

  static final Dec zero = Dec._(BigInt.zero, 0);
  static final Dec one = Dec._(BigInt.one, 0);

  static Dec parse(String text) {
    final value = tryParse(text);
    if (value == null) throw InvalidDecimal(text);
    return value;
  }

  static Dec? tryParse(String text) {
    final match = _grammar.firstMatch(text);
    if (match == null) return null;
    final exponentText = match.group(3);
    final exponent = exponentText == null ? 0 : int.tryParse(exponentText);
    if (exponent == null || exponent.abs() > maxExponent) return null;

    final body = match.group(2)!;
    final point = body.indexOf('.');
    final integer = point < 0 ? body : body.substring(0, point);
    final fraction = point < 0 ? '' : body.substring(point + 1);
    final digits = '$integer$fraction';
    final magnitude = BigInt.parse(digits.isEmpty ? '0' : digits);
    final unscaled = match.group(1) == '-' ? -magnitude : magnitude;
    final value = _normalized(unscaled, fraction.length - exponent);
    return Dec._(value._unscaled, value._scale, text);
  }

  factory Dec.fromInt(int value) => _normalized(BigInt.from(value), 0);

  bool get isZero => _unscaled == BigInt.zero;

  bool get isNegative => _unscaled.isNegative;

  bool get isPositive => _unscaled > BigInt.zero;

  int get sign => _unscaled.sign;

  Dec operator -() => Dec._(-_unscaled, _scale);

  Dec abs() => Dec._(_unscaled.abs(), _scale);

  String get text => _text ?? toString();

  Dec operator +(Dec other) {
    final scale = math.max(_scale, other._scale);
    return _rounded(_aligned(scale) + other._aligned(scale), scale);
  }

  Dec operator -(Dec other) => this + (-other);

  Dec operator *(Dec other) =>
      _rounded(_unscaled * other._unscaled, _scale + other._scale);

  Dec dividedBy(Dec divisor) {
    if (divisor.isZero) throw const DivisionByZero();
    if (isZero) return zero;
    final dividend = _unscaled.abs();
    final magnitude = divisor._unscaled.abs();
    final shift = math.max(
      0,
      precision + 1 + _digitCount(magnitude) - _digitCount(dividend),
    );
    final quotient = (dividend * _ten.pow(shift)) ~/ magnitude;
    final result = _rounded(quotient, _scale - divisor._scale + shift);
    return _unscaled.isNegative == divisor._unscaled.isNegative
        ? result
        : -result;
  }

  Dec roundTo(int places) {
    RangeError.checkNotNegative(places, 'places');
    if (_scale <= places) return this;
    return _normalized(_roundDropping(_unscaled, _scale - places), places);
  }

  /// decimal.js `toFixed(places)`: rounded half up and padded with zeros, so a
  /// weight of one reads `1.000000`, and a negative that rounds to zero keeps
  /// its sign (`-0.000000`).
  String toFixed(int places) {
    final rounded = roundTo(places);
    var text = rounded.toString();
    if (places > 0) {
      final point = text.indexOf('.');
      final decimals = point < 0 ? 0 : text.length - point - 1;
      text = '$text${point < 0 ? '.' : ''}${'0' * (places - decimals)}';
    }
    return isNegative && rounded.isZero ? '-$text' : text;
  }

  @override
  int compareTo(Dec other) {
    final scale = math.max(_scale, other._scale);
    return _aligned(scale).compareTo(other._aligned(scale)).sign;
  }

  bool operator <(Dec other) => compareTo(other) < 0;
  bool operator <=(Dec other) => compareTo(other) <= 0;
  bool operator >(Dec other) => compareTo(other) > 0;
  bool operator >=(Dec other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is Dec && other._unscaled == _unscaled && other._scale == _scale;

  @override
  int get hashCode => Object.hash(_unscaled, _scale);

  @override
  String toString() {
    if (isZero) return '0';
    var digits = _unscaled.abs().toString();
    if (_scale <= 0) {
      digits = '$digits${'0' * -_scale}';
    } else if (digits.length <= _scale) {
      digits = '0.${'0' * (_scale - digits.length)}$digits';
    } else {
      final point = digits.length - _scale;
      digits = '${digits.substring(0, point)}.${digits.substring(point)}';
    }
    return _unscaled.isNegative ? '-$digits' : digits;
  }

  double toDouble() => double.parse(toString());

  BigInt _aligned(int scale) => _unscaled * _ten.pow(scale - _scale);

  static Dec _normalized(BigInt unscaled, int scale) {
    if (unscaled == BigInt.zero) return zero;
    var value = unscaled;
    var exponent = scale;
    while (value.remainder(_ten) == BigInt.zero) {
      value = value ~/ _ten;
      exponent -= 1;
    }
    return Dec._(value, exponent);
  }

  static Dec _rounded(BigInt unscaled, int scale) {
    final drop = _digitCount(unscaled) - precision;
    if (drop <= 0) return _normalized(unscaled, scale);
    return _normalized(_roundDropping(unscaled, drop), scale - drop);
  }

  static BigInt _roundDropping(BigInt value, int drop) {
    final unit = _ten.pow(drop);
    final magnitude = value.abs();
    final kept = magnitude ~/ unit;
    final rest = magnitude.remainder(unit);
    final rounded = rest * _two >= unit ? kept + BigInt.one : kept;
    return value.isNegative ? -rounded : rounded;
  }

  static int _digitCount(BigInt value) => value.abs().toString().length;
}
