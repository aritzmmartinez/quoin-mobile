import 'package:flutter/widgets.dart';
import 'package:quoin_core/quoin_core.dart';

// Written by code point: one is invisible, the other looks like a hyphen.
final _nbsp = String.fromCharCode(0x00A0);
final _minus = String.fromCharCode(0x2212);

/// Amounts and percentages as the web's `createFormat` writes them (Intl in
/// es-ES and en-GB), built from the decimal itself: no `double` on the way.
///
/// es-ES groups thousands only from five integer digits (CLDR's minimum
/// grouping digits is 2): «1234,56 €» but «12.345,67 €». Rounding is half up,
/// away from zero, as Intl's. A negative that rounds to zero keeps its sign,
/// as Intl does («-0,0 %»), except in a signed figure.
class QuoinFormat {
  const QuoinFormat(this.languageCode);

  factory QuoinFormat.of(BuildContext context) =>
      QuoinFormat(Localizations.localeOf(context).languageCode);

  final String languageCode;

  bool get _es => languageCode == 'es';
  String get _group => _es ? '.' : ',';
  String get _decimal => _es ? ',' : '.';

  /// «1234,56 €», «€1,234.56». With [floorNonZero], a positive amount that
  /// rounds to zero reads «<0,01 €».
  String money(Money value, {bool floorNonZero = false}) {
    final amount = value.amount;
    if (floorNonZero && amount.isPositive && amount.roundTo(2).isZero) {
      return '<${money(Money.parse('0.01'))}';
    }
    final number = _number(amount.abs(), minDecimals: 2, maxDecimals: 2);
    final sign = amount.isNegative ? '-' : '';
    return _es ? '$sign$number$_nbsp€' : '$sign€$number';
  }

  /// The magnitude with «+» or «−» (U+2212) in front, and which sign it is;
  /// zero carries none.
  ({String text, int sign}) signedMoney(Money value) {
    final magnitude = money(value.isNegative ? value.negate() : value);
    final sign = value.amount.sign;
    final prefix = switch (sign) {
      > 0 => '+',
      < 0 => _minus,
      _ => '',
    };
    return (text: '$prefix$magnitude', sign: sign);
  }

  /// [fraction] as a percentage: «12,3 %», «12.3%». [signed] puts «+» or «-»
  /// in front of anything that does not round to zero. With [floorNonZero], a
  /// positive fraction that rounds to zero reads «<0,1 %».
  String percent(
    Dec fraction, {
    int decimals = 1,
    bool signed = false,
    bool floorNonZero = false,
  }) {
    final value = fraction * Dec.fromInt(100);
    final roundsToZero = value.roundTo(decimals).isZero;
    if (floorNonZero && value.isPositive && roundsToZero) {
      final smallest = Dec.parse('1e-${decimals + 2}');
      return '<${percent(smallest, decimals: decimals)}';
    }
    final number = _number(
      value.abs(),
      minDecimals: decimals,
      maxDecimals: decimals,
    );
    final sign = signed
        ? (roundsToZero ? '' : (value.isNegative ? '-' : '+'))
        : (value.isNegative ? '-' : '');
    return _es ? '$sign$number$_nbsp%' : '$sign$number%';
  }

  /// A number of units, up to [maxDecimals] places: «12.345», «0,5».
  String quantity(Dec value, {int maxDecimals = 10}) {
    final number = _number(
      value.abs(),
      minDecimals: 0,
      maxDecimals: maxDecimals,
    );
    return value.isNegative ? '-$number' : number;
  }

  String _number(
    Dec magnitude, {
    required int minDecimals,
    required int maxDecimals,
  }) {
    final text = magnitude.roundTo(maxDecimals).toString();
    final point = text.indexOf('.');
    final integer = point < 0 ? text : text.substring(0, point);
    final decimals = (point < 0 ? '' : text.substring(point + 1)).padRight(
      minDecimals,
      '0',
    );
    final grouped = integer.length < (_es ? 5 : 4)
        ? integer
        : integer.replaceAllMapped(
            RegExp(r'\d(?=(\d{3})+$)'),
            (m) => '${m[0]}$_group',
          );
    return decimals.isEmpty ? grouped : '$grouped$_decimal$decimals';
  }
}
