import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/result.dart';

abstract interface class ResidenceRepository {
  /// As stored: one a newer Quoin wrote comes back as it came.
  Future<Result<String>> get();

  Future<Result<void>> set(Residence residence);
}
