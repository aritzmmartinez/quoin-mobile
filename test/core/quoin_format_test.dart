import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quoin/src/core/l10n/quoin_format.dart';
import 'package:quoin_core/quoin_core.dart';

/// `~` stands for the no-break space Intl puts before «€» and «%» in Spanish,
/// `_` for the minus sign (U+2212) of a signed amount or a percentage.
String intl(String s) => s
    .replaceAll('~', String.fromCharCode(0x00A0))
    .replaceAll('_', String.fromCharCode(0x2212));

void main() {
  const es = QuoinFormat('es');
  const en = QuoinFormat('en');

  // Expected strings are what Node's Intl (ICU 78) writes for es-ES and en-GB,
  // but for the minus sign of signed figures and percentages.
  test('money', () {
    final cases = {
      '0': ('0,00~€', '€0.00'),
      '0.005': ('0,01~€', '€0.01'),
      '1234.565': ('1234,57~€', '€1,234.57'),
      '-1234.56': ('-1234,56~€', '-€1,234.56'),
      '12345.678': ('12.345,68~€', '€12,345.68'),
      '1234567.8': ('1.234.567,80~€', '€1,234,567.80'),
      '999.995': ('1000,00~€', '€1,000.00'),
      '-0.004': ('-0,00~€', '-€0.00'),
    };
    for (final MapEntry(key: value, value: (inEs, inEn)) in cases.entries) {
      expect(es.money(Money.parse(value)), intl(inEs), reason: value);
      expect(en.money(Money.parse(value)), inEn, reason: value);
    }
    expect(
      es.money(Money.parse('0.004'), floorNonZero: true),
      intl('< 0,01~€'),
    );
  });

  test('price', () {
    final cases = {
      '769.05': ('769,05~€', '€769.05'),
      '1': ('1,00~€', '€1.00'),
      '0': ('0,00~€', '€0.00'),
      '0.5': ('0,50~€', '€0.50'),
      '0.1234567': ('0,1235~€', '€0.1235'),
      '0.17345': ('0,1735~€', '€0.1735'),
      '0.000006123456': ('0,000006123~€', '€0.000006123'),
      '0.00000438': ('0,00000438~€', '€0.00000438'),
      '0.0999996': ('0,10~€', '€0.10'),
      '0.99996': ('1,00~€', '€1.00'),
      '84123.4567': ('84.123,46~€', '€84,123.46'),
    };
    for (final MapEntry(key: value, value: (inEs, inEn)) in cases.entries) {
      expect(es.price(Money.parse(value)), intl(inEs), reason: value);
      expect(en.price(Money.parse(value)), inEn, reason: value);
    }
  });

  test('signed price keeps a small change', () {
    expect(es.signedPrice(Money.parse('-0.0023')), (
      text: intl('_0,0023~€'),
      sign: -1,
    ));
    expect(en.signedPrice(Money.parse('12.5')), (text: '+€12.50', sign: 1));
  });

  test('signed money', () {
    expect(es.signedMoney(Money.parse('6.8')), (
      text: intl('+6,80~€'),
      sign: 1,
    ));
    expect(es.signedMoney(Money.parse('-30')), (
      text: intl('_30,00~€'),
      sign: -1,
    ));
    expect(en.signedMoney(Money.zero), (text: '€0.00', sign: 0));
  });

  test('gain', () {
    expect(es.gainLine(Money.parse('-30'), Dec.parse('-0.123')), (
      text: intl('_30,00~€ · _12,3~%'),
      sign: -1,
    ));
    expect(en.gainLine(Money.parse('6.8'), null), (text: '+€6.80', sign: 1));
  });

  test('percent', () {
    final signed = {
      '0.1234': ('+12,3~%', '+12.3%'),
      '-0.0004': ('0,0~%', '0.0%'),
      '0': ('0,0~%', '0.0%'),
      '-0.123': ('_12,3~%', '_12.3%'),
      '12.3456': ('+1234,6~%', '+1,234.6%'),
    };
    for (final MapEntry(key: value, value: (inEs, inEn)) in signed.entries) {
      expect(es.percent(Dec.parse(value), signed: true), intl(inEs));
      expect(en.percent(Dec.parse(value), signed: true), intl(inEn));
    }
    expect(es.percent(Dec.parse('-0.0004')), intl('_0,0~%'));
    expect(en.percent(Dec.parse('-0.25')), intl('_25.0%'));
    expect(es.percent(Dec.parse('0.0004'), floorNonZero: true), intl('<0,1~%'));
  });

  test('quantity', () {
    final cases = {
      '0.5': ('0,5', '0.5'),
      '1234.5678': ('1234,5678', '1,234.5678'),
      '12345': ('12.345', '12,345'),
      '0.0000000001': ('0,0000000001', '0.0000000001'),
    };
    for (final MapEntry(key: value, value: (inEs, inEn)) in cases.entries) {
      expect(es.quantity(Dec.parse(value)), inEs);
      expect(en.quantity(Dec.parse(value)), inEn);
    }
  });

  test('a date is the day in the given zone, not the device one', () async {
    await initializeDateFormatting();
    final lateNight = DateTime.utc(2026, 3, 1, 23, 30);
    expect(es.date(lateNight, 'Europe/Madrid'), '2 mar 2026');
    expect(es.date(lateNight, 'Atlantic/Canary'), '1 mar 2026');
  });
}
