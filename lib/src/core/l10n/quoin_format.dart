import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
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
/// as Intl does («−0,0 %»), except in a signed figure. Signed figures and
/// percentages use the minus sign (U+2212), as wide as the plus.
class QuoinFormat {
  const QuoinFormat(this.languageCode);

  factory QuoinFormat.of(BuildContext context) =>
      QuoinFormat(Localizations.localeOf(context).languageCode);

  final String languageCode;

  bool get _es => languageCode == 'es';
  String get _group => _es ? '.' : ',';
  String get _decimal => _es ? ',' : '.';

  String date(DateTime instant, String zone) =>
      day(calendarDateOf(instant, zone));

  String day(CalendarDate date) =>
      DateFormat.yMMMd(languageCode)
          .format(DateTime(date.year, date.month, date.day));

  String dayMonth(DateTime instant, String zone) {
    final d = calendarDateOf(instant, zone);
    return DateFormat.MMMd(languageCode)
        .format(DateTime(d.year, d.month, d.day));
  }

  String month(CalendarDate date) {
    final text = DateFormat(
      'LLLL y',
      languageCode,
    ).format(DateTime(date.year, date.month));
    return text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
  }

  String money(Money value, {bool floorNonZero = false, int decimals = 2}) {
    final amount = value.amount;
    if (floorNonZero && amount.isPositive && amount.roundTo(2).isZero) {
      return '< ${money(Money.parse('0.01'))}';
    }
    final number = _number(
      amount.abs(),
      minDecimals: decimals,
      maxDecimals: decimals,
    );
    final sign = amount.isNegative ? '-' : '';
    return _es ? '$sign$number$_nbsp€' : '$sign€$number';
  }

  String price(Money value) {
    final amount = value.amount;
    if (amount.isZero || amount.abs() >= Dec.one) return money(value);
    final rounded = amount.roundTo(_leadingZeros(amount) + 4);
    if (rounded.abs() >= Dec.one) return money(Money.of(rounded));
    final zeros = _leadingZeros(rounded);
    final number = _number(
      rounded.abs(),
      minDecimals: zeros + 2,
      maxDecimals: zeros + 4,
    );
    final sign = rounded.isNegative ? '-' : '';
    return _es ? '$sign$number$_nbsp€' : '$sign€$number';
  }

  static int _leadingZeros(Dec fraction) {
    final text = fraction.abs().toString();
    final decimals = text.substring(text.indexOf('.') + 1);
    return decimals.length - decimals.replaceFirst(RegExp('^0+'), '').length;
  }

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

  ({String text, int sign}) gainLine(Money amount, Dec? fraction) {
    final money = signedMoney(amount);
    return (
      text: fraction == null
          ? money.text
          : '${money.text} · ${percent(fraction, signed: true)}',
      sign: money.sign,
    );
  }

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
        ? (roundsToZero ? '' : (value.isNegative ? _minus : '+'))
        : (value.isNegative ? _minus : '');
    return _es ? '$sign$number$_nbsp%' : '$sign$number%';
  }

  String quantity(Dec value, {int minDecimals = 0, int maxDecimals = 10}) {
    final number = _number(
      value.abs(),
      minDecimals: minDecimals,
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
