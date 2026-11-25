import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/portfolio/domain/entities/kraken_target.dart';

abstract interface class KrakenRepository {
  Future<Result<List<KrakenTarget>>> targets();

  Future<Result<String>> zone();

  Future<Result<List<KrakenQuote>>> candles(String symbol, DateTime? since);

  Future<Result<KrakenQuote?>> lastTrade(String symbol);

  Future<Result<Map<String, String>>> write(
    String instrumentId,
    KrakenStep step,
    List<KrakenQuote> candles,
    KrakenQuote? live,
  );

  Future<Result<void>> drop(String instrumentId);

  Future<Result<void>> dropAll();
}
