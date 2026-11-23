import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/l10n/gen/app_localizations.dart';

String residenceName(AppLocalizations l10n, String stored) =>
    switch (Residence.values.asNameMap()[stored]) {
      Residence.bizkaia => l10n.residenceBizkaia,
      Residence.comun => l10n.residenceComun,
      Residence.canarias => l10n.residenceCanarias,
      null => stored,
    };
