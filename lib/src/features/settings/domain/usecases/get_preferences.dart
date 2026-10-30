import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/settings/domain/entities/preferences.dart';
import 'package:quoin/src/features/settings/domain/repositories/settings_repository.dart';

class GetPreferences {
  const GetPreferences(this._repository);

  final SettingsRepository _repository;

  Result<Preferences> call() => _repository.get();
}
