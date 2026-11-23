import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/l10n/gen/app_localizations.dart';

String taxResidenceName(AppLocalizations l10n, Residence residence) =>
    switch (residence) {
      Residence.bizkaia => l10n.taxResidenceBizkaia,
      Residence.comun => l10n.taxResidenceComun,
      Residence.canarias => l10n.taxResidenceCanarias,
    };

String taxTerritoryName(AppLocalizations l10n, Territory territory) =>
    switch (territory) {
      Territory.bizkaia => l10n.taxResidenceBizkaia,
      Territory.comun => l10n.taxResidenceComun,
    };
