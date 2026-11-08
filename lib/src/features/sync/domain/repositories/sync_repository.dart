import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/sync/domain/entities/exchange_import.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/domain/entities/pc_state.dart';

abstract interface class SyncRepository {
  Future<Result<Pairing?>> pairing();
  Future<Result<void>> savePairing(Pairing pairing);
  Future<Result<void>> unpair();
  Future<Result<String>> claim();
  Future<Result<List<int>>> hello(SyncEndpoint endpoint);
  Future<Result<String>> pair(
    PairingQr qr, {
    required String deviceId,
    required String name,
  });
  Future<Result<PcState>> fetch(Pairing pairing, String deviceId);
  Future<Result<ExchangeImport>> importExchange(
    Exchange incoming, {
    Resolutions resolutions,
    required bool dryRun,
  });
  Future<Result<Exchange>> export();
  Future<Result<PushResult>> push(
    Pairing pairing,
    String deviceId,
    Exchange exchange, {
    required String etag,
  });
  Future<Result<String>> zone();
  Future<Result<List<PriceHolding>>> priceHoldings();
  Future<Result<List<PriceAnswer>>> fetchPrices(
    Pairing pairing,
    String deviceId,
    List<PriceHolding> holdings,
  );
  Future<Result<Map<String, String>>> savePrices(List<PriceAnswer> answers);
  Future<Result<void>> dropPrices(String instrumentId);
}
