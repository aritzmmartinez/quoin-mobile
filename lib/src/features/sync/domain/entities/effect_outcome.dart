import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/failures.dart';

sealed class EffectOutcome {
  const EffectOutcome(this.effect);

  final Effect effect;
}

final class EffectDone extends EffectOutcome {
  const EffectDone(super.effect);
}

final class EffectFailed extends EffectOutcome {
  const EffectFailed(super.effect, this.failure);

  final Failure failure;
}
