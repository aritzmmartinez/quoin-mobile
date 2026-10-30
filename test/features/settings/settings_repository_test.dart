import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:quoin/src/features/settings/data/models/preferences_model.dart';
import 'package:quoin/src/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:quoin/src/features/settings/domain/entities/preferences.dart';

class _BrokenSource implements SettingsLocalDataSource {
  @override
  PreferencesModel read() => throw const StorageException('read');

  @override
  Future<void> writeTheme(String name) async =>
      throw const StorageException('write');

  @override
  Future<void> writeLanguage(String? code) async =>
      throw const StorageException('write');
}

void main() {
  test('unknown stored values follow the system', () {
    final prefs = const PreferencesModel(
      theme: 'sepia',
      language: 'fr',
    ).toEntity();
    expect(prefs.theme, ThemePreference.system);
    expect(prefs.language, LanguagePreference.system);
  });

  test('storage exceptions come back as StorageFailure', () async {
    final repository = SettingsRepositoryImpl(_BrokenSource());
    for (final result in [
      repository.get(),
      await repository.setTheme(ThemePreference.dark),
      await repository.setLanguage(LanguagePreference.en),
    ]) {
      expect((result as Err).failure, isA<StorageFailure>());
    }
  });
}
