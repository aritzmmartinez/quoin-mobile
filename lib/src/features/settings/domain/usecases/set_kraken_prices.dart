import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/portfolio/domain/repositories/kraken_repository.dart';
import 'package:quoin/src/features/settings/domain/repositories/settings_repository.dart';

class SetKrakenPrices {
  const SetKrakenPrices(this._settings, this._kraken);

  final SettingsRepository _settings;
  final KrakenRepository _kraken;

  /// Off deletes every series taken from Kraken, so no price stays frozen
  /// without saying so; the PC's are untouched.
  Future<Result<void>> call(bool on) async {
    final saved = await _settings.setKrakenPrices(on);
    if (on || saved is Err<void>) return saved;
    return _kraken.dropAll();
  }
}
