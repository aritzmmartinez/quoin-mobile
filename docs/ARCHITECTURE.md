# Architecture

Quoin mobile is split by feature, and each feature by layer. Shared domain
logic lives in a pure Dart package; shared widgets follow atomic design.

```
lib/
  main.dart              startup: fonts licence, preferences, ProviderScope
  src/
    app/                 MaterialApp, router, shell, dependencies.dart
    core/
      error/             exceptions.dart, failures.dart, result.dart
      theme/             colours, tokens, type scale, icon set
      l10n/              ARB files (gen/ is generated, not committed)
    ui/                  widgets with no business logic
      atoms/ molecules/ organisms/ templates/
    features/<feature>/
      data/              datasources/, models/, repositories/ (impl)
      domain/            entities/, repositories/ (abstract), usecases/
      presentation/      providers/, pages/, widgets/
packages/quoin_core/     Dec, Money and the domain rules shared with ../quoin
```

A folder exists only when it holds something: a feature has only the layers
it uses. Today `settings` has all three; `portfolio`, `analysis` and `import`
have only `presentation/pages`.

## Layers

Dependencies point inwards: `presentation → domain ← data`.
`test/architecture_test.dart` fails if an import breaks that direction.

- **domain**: entities, abstract repositories and use cases. Plain Dart: it
  imports only `dart:` (not `dart:ui`), `quoin_core`, `core/error` and other
  features' domain. No Flutter, no Riverpod, no storage.
- **data**: implements the domain's repositories. Data sources talk to the
  platform (shared_preferences now, drift and the network later) and throw
  typed exceptions. Models mirror what is stored and convert with
  `toEntity()`; they do not extend the entity.
- **presentation**: Riverpod providers, pages and feature widgets. It sees
  the domain, never data.
- **app**: the composition root. It is the only code that sees presentation
  and data together.

## quoin_core and the features

`packages/quoin_core` holds the domain logic shared with the desktop app:
`Dec` (a decimal.js port), `Money` and, as they are ported, the calculation
rules. Features import it and never copy it. A feature's own `domain/` holds
only what is specific to the app (preferences, screens' use cases), built on
top of quoin_core types.

## Errors

```
data source        repository              presentation
throws          →  catches, returns     →  switch over every case
StorageException   Err(StorageFailure)     Ok(:value) / Err(:failure)
```

- `core/error/exceptions.dart`: exceptions that only data sources throw.
- `core/error/failures.dart`: `sealed class Failure`, one subclass per kind
  of failure the user can be told about.
- `core/error/result.dart`: `sealed class Result<T>` with `Ok` and `Err`.

Repositories never let an exception through: every public method returns
`Result<T>` (or `Future<Result<T>>`). Presentation switches over it
exhaustively, so a new `Failure` is a compile error until every screen
handles it.

Example: when a theme or language cannot be saved, the notifier keeps the
new value in memory and returns the `Err`; the settings page shows a
translated SnackBar («No se ha podido guardar el ajuste»).

## Injection

Riverpod only: no get_it, bloc or provider. One provider per link of the
chain, from the platform to the screen:

```
sharedPreferencesProvider         data, overridden in main
settingsLocalDataSourceProvider   data
settingsRepositoryProvider        presentation, typed as the abstract
                                  repository; bound in app/dependencies.dart
getPreferencesProvider, …         presentation, one per use case
themeModeProvider, localeProvider presentation, the screens' state
```

The abstract repository's provider throws until `app/dependencies.dart`
overrides it with the data implementation. `main` and the test helper
(`pumpApp`) both start from `dependencies(prefs)`, so tests run the real
chain over in-memory preferences.

## ui/: atomic design

Widgets shared by more than one screen. They take data and callbacks and
know nothing of features, providers or the router (the architecture test
checks the imports).

- **atoms**: one visual element. `QuoinIcon`, `QuoinChip`, `QuoinCard`,
  `DisplayFigure`, `Pressable`.
- **molecules**: a few atoms with one job. `QuoinTextField`,
  `QuoinSegmented`, `IconTile`, `SettingsRow`, `EmptyState`.
- **organisms**: a section of a screen. `QuoinBottomBar`, `QuoinBarSurface`,
  `SettingsSection`.
- **templates**: page layouts with no content. `QuoinPage`.

Pages (the filled-in templates) live in each feature's `presentation/pages`.
A widget used by one feature only goes in that feature's
`presentation/widgets`.
