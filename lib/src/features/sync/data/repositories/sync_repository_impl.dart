import 'dart:async';

import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/sync/data/datasources/device_identity_datasource.dart';
import 'package:quoin/src/features/sync/data/datasources/pairing_local_datasource.dart';
import 'package:quoin/src/features/sync/data/datasources/prices_local_datasource.dart';
import 'package:quoin/src/features/sync/data/datasources/sync_local_datasource.dart';
import 'package:quoin/src/features/sync/data/datasources/sync_remote_datasource.dart';
import 'package:quoin/src/features/sync/data/models/pairing_model.dart';
import 'package:quoin/src/features/sync/domain/entities/exchange_import.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/domain/entities/pc_state.dart';
import 'package:quoin/src/features/sync/domain/repositories/sync_repository.dart';

class SyncRepositoryImpl implements SyncRepository {
  SyncRepositoryImpl({
    required this._pairings,
    required this._remote,
    required this._local,
    required this._identity,
    required this._prices,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final PairingLocalDataSource _pairings;
  final SyncRemoteDataSource _remote;
  final SyncLocalDataSource _local;
  final DeviceIdentityDataSource _identity;
  final PricesLocalDataSource _prices;
  final DateTime Function() _now;

  @override
  Future<Result<Pairings>> pairings() =>
      _run(() async => pairingsFromJson(await _pairings.read()));

  @override
  Future<Result<void>> savePairings(Pairings pairings) =>
      _run(() => _pairings.write(pairings.toJson()));

  @override
  Future<Result<String>> claim() async {
    try {
      return Ok(await _identity.claim());
    } on StorageException {
      return const Err(DeviceIdentityFailure());
    }
  }

  @override
  Future<Result<List<int>>> hello(SyncEndpoint endpoint) =>
      _run(() => _remote.hello(endpoint));

  @override
  Future<Result<String>> pair(
    PairingQr qr, {
    required String deviceId,
    required String name,
  }) => _run(() async {
    try {
      return await _remote.pair(
        qr.endpoint,
        token: qr.token,
        deviceId: deviceId,
        name: name,
      );
    } on NetworkException catch (e) {
      if (e.cause is TimeoutException) {
        throw const SyncHttpException(410, 'expired');
      }
      rethrow;
    }
  });

  @override
  Future<Result<PcState>> fetch(Pairing pairing, String deviceId) =>
      _run(() => _remote.fetch(pairing.endpoint, _who(pairing, deviceId)));

  @override
  Future<Result<ExchangeImport>> importExchange(
    Exchange incoming, {
    Resolutions resolutions = const {},
    required bool dryRun,
  }) => _run(
    () => _local.importExchange(
      incoming,
      resolutions: resolutions,
      dryRun: dryRun,
      nowMs: _now().millisecondsSinceEpoch,
    ),
  );

  @override
  Future<Result<Exchange>> export() => _run(_local.export);

  @override
  Future<Result<PushResult>> push(
    Pairing pairing,
    String deviceId,
    Exchange exchange, {
    required String etag,
  }) => _run(
    () => _remote.push(
      pairing.endpoint,
      _who(pairing, deviceId),
      exchange,
      etag: etag,
    ),
  );

  @override
  Future<Result<String>> zone() => _run(() async {
    final residence = await _local.residence();
    final known = Residence.values.asNameMap()[residence];
    if (known == null) throw UnsupportedResidenceException(residence);
    return jurisdictionOf(known).zone;
  });

  @override
  Future<Result<List<PriceHolding>>> priceHoldings() => _run(_prices.holdings);

  @override
  Future<Result<List<PriceAnswer>>> fetchPrices(
    Pairing pairing,
    String deviceId,
    List<PriceHolding> holdings,
  ) => _run(
    () => _remote.prices(pairing.endpoint, _who(pairing, deviceId), holdings),
  );

  @override
  Future<Result<Map<String, String>>> savePrices(List<PriceAnswer> answers) =>
      _run(() => _prices.save(answers));

  @override
  Future<Result<void>> dropPrices(String instrumentId) =>
      _run(() => _prices.drop(instrumentId));

  Credentials _who(Pairing pairing, String deviceId) =>
      (token: pairing.token, deviceId: deviceId);

  Future<Result<T>> _run<T>(Future<T> Function() body) async {
    try {
      return Ok(await body());
    } on PinMismatchException {
      return const Err(CertificateMismatchFailure());
    } on NetworkException {
      return const Err(PcUnreachableFailure());
    } on SyncHttpException catch (e) {
      return Err(syncFailureOf(e));
    } on SampleDataException {
      return const Err(SampleDataFailure());
    } on SameDevice {
      return const Err(PcRefusedFailure('same-device'));
    } on UnknownResolution {
      return const Err(ConflictsChangedFailure());
    } on UnsupportedResidenceException catch (e) {
      return Err(UnsupportedResidenceFailure(e.residence));
    } on StorageException {
      return const Err(StorageFailure());
    }
  }
}

SyncFailure syncFailureOf(SyncHttpException e) => switch ((e.status, e.code)) {
  (401, 'invalid-token') => const PairingTokenUsedFailure(),
  (401, _) || (403, 'revoked') => const PairingRevokedFailure(),
  (403, 'rejected') => const PairingRejectedFailure(),
  (410, _) => const PairingExpiredFailure(),
  (409, _) => const StateChangedFailure(),
  (_, 'unsupported-schema-version') => UpdateRequiredFailure(
    e.update == 'client' ? UpdateSide.app : UpdateSide.quoin,
  ),
  (503, _) || (429, _) => const PcBusyFailure(),
  (_, final code) => PcRefusedFailure(code),
};
