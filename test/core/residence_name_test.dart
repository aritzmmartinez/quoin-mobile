import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/l10n/residence_name.dart';

void main() {
  test('a residence is shown by its name; an unknown one as it came', () {
    for (final code in ['es', 'en']) {
      final l10n = lookupAppLocalizations(Locale(code));
      expect(residenceName(l10n, 'bizkaia'), 'Bizkaia');
      expect(residenceName(l10n, 'gipuzkoa'), 'gipuzkoa');
    }
  });
}
