import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/settings/domain/entities/preferences.dart';
import 'package:quoin/src/features/settings/domain/repositories/settings_repository.dart';

class SetLanguage {
  const SetLanguage(this._repository);

  final SettingsRepository _repository;

  Future<Result<void>> call(LanguagePreference language) =>
      _repository.setLanguage(language);
}
