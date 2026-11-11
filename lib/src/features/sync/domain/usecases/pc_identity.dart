import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/domain/entities/sync_outcome.dart';
import 'package:quoin/src/features/sync/domain/repositories/sync_repository.dart';

sealed class Identity {
  const Identity();
}

final class OwnIdentity extends Identity {
  const OwnIdentity();
}

final class SharedIdentity extends Identity {
  const SharedIdentity(this.other);

  final Pairing other;
}

final class UnknownIdentity extends Identity {
  const UnknownIdentity(this.other);

  final Pairing other;
}

class PcIdentity {
  const PcIdentity(this._repository);

  final SyncRepository _repository;

  Future<Result<Identity>> check(
    Pairing pc,
    String seen, {
    required String phoneId,
  }) async {
    if (pc.pcDeviceId == seen) return const Ok(OwnIdentity());
    return _settle(pc, seen, phoneId: phoneId);
  }

  Future<Result<void>> checkAgain(String sha256) async {
    final String phoneId;
    switch (await _repository.claim()) {
      case Ok(:final value):
        phoneId = value;
      case Err(:final failure):
        return Err(failure);
    }
    final Pairing pc;
    switch (await _repository.pairings()) {
      case Ok(:final value) when value.of(sha256) != null:
        pc = value.of(sha256)!;
      case Ok():
        return const Err(NotPairedFailure());
      case Err(:final failure):
        return Err(failure);
    }
    final String seen;
    switch (await _repository.fetch(pc, phoneId)) {
      case Ok(:final value):
        seen = value.exchange.deviceId;
      case Err(:final failure):
        return Err(failure);
    }
    return switch (await _settle(pc, seen, phoneId: phoneId)) {
      Ok(value: OwnIdentity()) => const Ok(null),
      Ok(
        value: SharedIdentity(:final other) || UnknownIdentity(:final other),
      ) =>
        Err(SharedIdentityFailure(other.pcName)),
      Err(:final failure) => Err(failure),
    };
  }

  Future<Result<void>> resolve(
    String sha256,
    SyncSameIdentity question, {
    required bool samePc,
  }) async {
    final Pairings pairings;
    switch (await _repository.pairings()) {
      case Ok(:final value):
        pairings = value;
      case Err(:final failure):
        return Err(failure);
    }
    final pc = pairings.of(sha256);
    if (pc == null) return const Err(NotPairedFailure());
    final mine = pc.copy(pcDeviceId: question.deviceId);
    return _repository.savePairings(
      samePc
          ? pairings.without(question.other.sha256).put(mine)
          : pairings.put(mine.copy(shared: true)),
    );
  }

  Future<Result<Identity>> _settle(
    Pairing pc,
    String seen, {
    required String phoneId,
  }) async {
    Pairings pairings;
    switch (await _repository.pairings()) {
      case Ok(:final value):
        pairings = value;
      case Err(:final failure):
        return Err(failure);
    }
    final mine = pairings.of(pc.sha256) ?? pc;
    final other = pairings.pcs
        .where(
          (p) => p.sha256 != pc.sha256 && !p.shared && p.pcDeviceId == seen,
        )
        .firstOrNull;
    if (other != null) {
      switch (await _repository.fetch(other, phoneId)) {
        case Ok(:final value) when value.exchange.deviceId == seen:
          final saved = await _repository.savePairings(
            pairings.put(mine.copy(pcDeviceId: seen, shared: true)),
          );
          return switch (saved) {
            Ok() => Ok(SharedIdentity(other)),
            Err(:final failure) => Err(failure),
          };
        case Ok(:final value):
          pairings = pairings.put(
            other.copy(pcDeviceId: value.exchange.deviceId),
          );
        case Err():
          return Ok(UnknownIdentity(other));
      }
    }
    final saved = await _repository.savePairings(
      pairings.put(mine.copy(pcDeviceId: seen, shared: false)),
    );
    return switch (saved) {
      Ok() => const Ok(OwnIdentity()),
      Err(:final failure) => Err(failure),
    };
  }
}
