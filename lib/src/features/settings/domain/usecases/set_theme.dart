import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/settings/domain/entities/preferences.dart';
import 'package:quoin/src/features/settings/domain/repositories/settings_repository.dart';

class SetTheme {
  const SetTheme(this._repository);

  final SettingsRepository _repository;

  Future<Result<void>> call(ThemePreference theme) =>
      _repository.setTheme(theme);
}
