import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:quoin/src/features/settings/domain/entities/preferences.dart';
import 'package:quoin/src/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._source);

  final SettingsLocalDataSource _source;

  @override
  Result<Preferences> get() {
    try {
      return Ok(_source.read().toEntity());
    } on StorageException {
      return const Err(StorageFailure());
    }
  }

  @override
  Future<Result<void>> setTheme(ThemePreference theme) =>
      _write(() => _source.writeTheme(theme.name));

  @override
  Future<Result<void>> setLanguage(LanguagePreference language) => _write(
    () => _source.writeLanguage(
      language == LanguagePreference.system ? null : language.name,
    ),
  );

  Future<Result<void>> _write(Future<void> Function() body) async {
    try {
      await body();
      return const Ok(null);
    } on StorageException {
      return const Err(StorageFailure());
    }
  }
}
