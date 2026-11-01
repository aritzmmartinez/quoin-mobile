import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quoin/src/core/l10n/quoin_format.dart';
import 'package:quoin_core/quoin_core.dart';

/// `~` stands for the no-break space Intl puts before «€» and «%» in Spanish,
/// `_` for the minus sign (U+2212) of a signed amount.
String intl(String s) => s
    .replaceAll('~', String.fromCharCode(0x00A0))
    .replaceAll('_', String.fromCharCode(0x2212));

void main() {
  const es = QuoinFormat('es');
  const en = QuoinFormat('en');

  // Expected strings are what Node's Intl (ICU 78) writes for es-ES and en-GB.
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
    expect(es.money(Money.parse('0.004'), floorNonZero: true), intl('<0,01~€'));
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

  test('percent', () {
    final signed = {
      '0.1234': ('+12,3~%', '+12.3%'),
      '-0.0004': ('0,0~%', '0.0%'),
      '0': ('0,0~%', '0.0%'),
      '-0.123': ('-12,3~%', '-12.3%'),
      '12.3456': ('+1234,6~%', '+1,234.6%'),
    };
    for (final MapEntry(key: value, value: (inEs, inEn)) in signed.entries) {
      expect(es.percent(Dec.parse(value), signed: true), intl(inEs));
      expect(en.percent(Dec.parse(value), signed: true), inEn);
    }
    expect(es.percent(Dec.parse('-0.0004')), intl('-0,0~%'));
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
