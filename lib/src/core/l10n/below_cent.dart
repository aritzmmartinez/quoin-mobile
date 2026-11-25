import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/l10n/quoin_format.dart';

/// «< 0,01 €», for an amount that is not zero but rounds to it (`isBelowCent`).
String belowCentText(AppLocalizations l10n, QuoinFormat format) =>
    l10n.belowCent(format.money(Money.parse('0.01')));
