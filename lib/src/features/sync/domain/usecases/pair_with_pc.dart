import 'package:quoin_core/quoin_core.dart' show pairingCode;

import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/domain/repositories/sync_repository.dart';
import 'package:quoin/src/features/sync/domain/usecases/exchange_versions.dart';

final class PairingStart {
  const PairingStart({
    required this.qr,
    required this.deviceId,
    required this.code,
    this.known,
  });

  final PairingQr qr;
  final String deviceId;
  final String code;
  final Pairing? known;
}

class PairWithPc {
  const PairWithPc(this._repository);

  final SyncRepository _repository;

  Future<Result<PairingStart>> start(
    String qrText, {
    bool repair = false,
  }) async {
    final qr = parsePairingQr(qrText);
    if (qr == null) return const Err(InvalidQrFailure());
    final String deviceId;
    switch (await _repository.claim()) {
      case Ok(:final value):
        deviceId = value;
      case Err(:final failure):
        return Err(failure);
    }
    switch (await _repository.hello(qr.endpoint)) {
      case Ok(:final value) when versionGap(value) != null:
        return Err(versionGap(value)!);
      case Ok():
        break;
      case Err(:final failure):
        return Err(failure);
    }
    final Pairings pairings;
    switch (await _repository.pairings()) {
      case Ok(:final value):
        pairings = value;
      case Err(:final failure):
        return Err(failure);
    }
    if (pairings.of(qr.endpoint.sha256) case final known? when !repair) {
      final moved = known.copy(endpoint: qr.endpoint, pcName: qr.name);
      return switch (await _repository.savePairings(pairings.put(moved))) {
        Ok() => Ok(
          PairingStart(qr: qr, deviceId: deviceId, code: '', known: moved),
        ),
        Err(:final failure) => Err(failure),
      };
    }
    return Ok(
      PairingStart(
        qr: qr,
        deviceId: deviceId,
        code: pairingCode(qr.token, deviceId),
      ),
    );
  }

  Future<Result<Pairing>> confirm(
    PairingStart start, {
    required String name,
    required DateTime now,
  }) async {
    final String token;
    switch (await _repository.pair(
      start.qr,
      deviceId: start.deviceId,
      name: name,
    )) {
      case Ok(:final value):
        token = value;
      case Err(:final failure):
        return Err(failure);
    }
    final pairing = Pairing(
      endpoint: start.qr.endpoint,
      token: token,
      pcName: start.qr.name,
      pairedAt: now.toUtc(),
    );
    return switch (await _repository.pairings()) {
      Ok(:final value) => switch (await _repository.savePairings(
        value.put(pairing),
      )) {
        Ok() => Ok(pairing),
        Err(:final failure) => Err(failure),
      },
      Err(:final failure) => Err(failure),
    };
  }
}
