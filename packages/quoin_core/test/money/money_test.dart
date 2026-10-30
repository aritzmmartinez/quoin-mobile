import 'package:quoin_core/quoin_core.dart';
import 'package:test/test.dart';

Money m(String text) => Money.parse(text);
Dec d(String text) => Dec.parse(text);

void main() {
  group('Money', () {
    test('round-trips a decimal string', () {
      expect(m('1234.56').toString(), '1234.56');
      expect(m('0').toString(), '0');
      expect(Money.zero.toString(), '0');
    });

    test('adds without floating-point error (the 0.1 + 0.2 trap)', () {
      expect(m('0.1').add(m('0.2')).toString(), '0.3');
    });

    test('subtracts, negates and scales exactly', () {
      expect(m('3000').subtract(m('1500')).toString(), '1500');
      expect(m('150').negate().toString(), '-150');
      expect(m('150').scaleBy(d('10')).toString(), '1500');
      expect(m('150').scaleBy(Dec.fromInt(12)).toString(), '1800');
    });

    test('divides to a per-unit amount and refuses division by zero', () {
      expect(m('3000').divideBy(d('20')).toString(), '150');
      expect(
        () => m('100').divideBy(d('0')),
        throwsA(isA<DivisionByZero>()),
      );
    });

    test('refuses invalid or non-finite input', () {
      for (final text in ['abc', '', '1.2.3', 'Infinity', 'NaN', '1,5']) {
        expect(() => m(text), throwsA(isA<InvalidDecimal>()), reason: text);
        expect(Money.tryParse(text), isNull, reason: text);
      }
    });

    test('compares and checks sign', () {
      expect(m('10').compareTo(m('20')), -1);
      expect(m('20').compareTo(m('20')), 0);
      expect(m('30').compareTo(m('20')), 1);
      expect(m('5'), m('5.00'));
      expect(m('5').hashCode, m('5.00').hashCode);
      expect(m('-1').isNegative, isTrue);
      expect(m('1').isPositive, isTrue);
      expect(Money.zero.isZero, isTrue);
    });

    test('zero is neither positive nor negative, however it was reached', () {
      for (final zero in [
        Money.zero,
        m('-0'),
        Money.zero.negate(),
        m('5').subtract(m('5')),
        m('-5').add(m('5')),
      ]) {
        expect(zero.isZero, isTrue);
        expect(zero.isPositive, isFalse);
        expect(zero.isNegative, isFalse);
        expect(zero, Money.zero);
        expect(zero.toString(), '0');
      }
    });

    test('keeps a sub-cent amount exactly', () {
      expect(m('0.0000000025').scaleBy(d('3')).toString(), '0.0000000075');
    });

    test('never prints an exponent', () {
      expect(m('1e-12').toString(), '0.000000000001');
      expect(m('2.5e3').toString(), '2500');
    });
  });

  group('Dec', () {
    test('rounds to cents half away from zero', () {
      expect(d('0.125').roundTo(2).toString(), '0.13');
      expect(d('-0.125').roundTo(2).toString(), '-0.13');
      expect(d('0.124').roundTo(2).toString(), '0.12');
      expect(d('1.2').roundTo(2).toString(), '1.2');
      expect(() => d('1').roundTo(-1), throwsRangeError);
    });

    test('keeps 40 significant digits in a quotient', () {
      expect(
        Dec.one.dividedBy(Dec.fromInt(3)).toString(),
        '0.${'3' * 40}',
      );
    });

    test('builds integers without a double', () {
      expect(Dec.fromInt(9007199254740993).toString(), '9007199254740993');
    });
  });
}
