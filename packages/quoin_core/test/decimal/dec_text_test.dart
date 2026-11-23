import 'package:quoin_core/quoin_core.dart';
import 'package:test/test.dart';

void main() {
  test('a parsed value keeps its text; arithmetic writes its own', () {
    final rate = Dec.parse('1.0500');
    expect(rate.text, '1.0500');
    expect(rate.toString(), '1.05');
    expect(rate, Dec.parse('1.05'));
    expect(rate.hashCode, Dec.parse('1.05').hashCode);
    expect(Dec.parse('100').abs().text, '100');
    expect(Dec.parse('-100.50').abs().text, '100.5');
    expect((rate + Dec.zero).text, '1.05');
    expect(Money.parse('50.50').text, '50.50');
    expect(Money.of(Dec.parse('2') * Dec.parse('0.50')).text, '1');
  });
}
