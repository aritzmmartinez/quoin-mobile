import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/features/portfolio/domain/entities/holding_order.dart';

void main() {
  test('names sort as Spanish: accents and case aside, ñ after n', () {
    final names = ['Ñandú', 'oro', 'Nube', 'Álamo', 'avión', 'nz'];
    expect(names..sort(compareNamesEs), [
      'Álamo',
      'avión',
      'Nube',
      'nz',
      'Ñandú',
      'oro',
    ]);
  });
}
