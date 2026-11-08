import 'package:quoin_core/quoin_core.dart' show syncSchemaVersion;

import 'package:quoin/src/core/error/failures.dart';

UpdateRequiredFailure? versionGap(List<int> versions) =>
    versions.contains(syncSchemaVersion)
    ? null
    : UpdateRequiredFailure(
        versions.any((v) => v > syncSchemaVersion)
            ? UpdateSide.app
            : UpdateSide.quoin,
      );
