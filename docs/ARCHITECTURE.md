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
it uses. Today `settings`, `portfolio` and `import` have all three;
`analysis` has only `presentation/pages`.

## Layers

Dependencies point inwards: `presentation → domain ← data`.
`test/architecture_test.dart` fails if an import breaks that direction.

- **domain**: entities, abstract repositories and use cases. Plain Dart: it
  imports only `dart:` (not `dart:ui`), `quoin_core`, `core/error` and other
  features' domain. No Flutter, no Riverpod, no storage.
- **data**: implements the domain's repositories. Data sources talk to the
  platform (shared_preferences, drift, the file picker, the network) and throw
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

## Local store

`features/portfolio/data/database` holds the drift database. `schema.drift`
declares the tables of `../quoin/prisma/schema.prisma` that are read so far
(`Instrument`, `LedgerEntry`, `PriceSnapshot`, `FxRate`, `Settings`) with the
same names, CHECKs and unique keys, so sync can map rows one to one. Amounts
are decimal text, days `YYYY-MM-DD`, instants ISO-8601 UTC text. Migrations are
hand-written steps in `QuoinDatabase.migration`; the generated `.g.dart` is
committed and CI fails if regenerating it changes anything.

The portfolio screens read the ledger, the latest price of each instrument and
the ECB rates, and run the web's home chain through `quoin_core`
(`GetPortfolioOverview`): positions, prices in euros, market values, summary,
allocation and top positions.

## Import

`features/import` turns a broker's CSV into ledger rows. The file comes from
the system's document picker (`file_selector`: the Storage Access Framework on
Android, no storage permission) and is decoded as strict UTF-8, with or without
a BOM (`decodeCsv`). The broker is detected from the header (`detectBroker`),
never picked. The adapters live in `quoin_core` (`planIngest`, with
`trade_republic.dart` and `kraken.dart`), ported from Quoin and checked against
its ingest contract (`test/contract/ingest.json`) case by case: they read the
file as Quoin's Papa Parse does, map rows to events, set aside what the ledger
does not hold (with a reason and the row's detail), note what the user should
know, name the rows they cannot read, and refuse a file they cannot read at all.

An import is a `MappedBatch`. `PlanImport` reads what the adapters need from the
store (`IngestContext`: the residence's zone, the stored ECB rates, crypto price
histories, instrument names, Kraken refids booked as rewards), plans, and when
rows lack a rate fetches the missing series and plans again, as Quoin's
`planWithRates`. The wizard previews the batch (new and existing operations, by
`(source, externalId)`; discards, notices and row errors with their detail), and
only on confirmation `ImportLocalDataSource.write` stores it in one
transaction: instruments upserted without their manual fields, events not yet
stored inserted, and stored cash rows the batch knows to be in kind marked
`IN_KIND` (never back). `CommitImport` checks every event against the ledger's
write rules first. A refused file opens a modal that names the reason and says
the portfolio was not changed. The review shows dates in the residence's zone,
as the web does, not the device's. Debug builds can run the wizard over an
invented Trade Republic export, through the real adapter (Settings → Debug).

Amounts are stored as the text they were read from (`Dec.text`): a figure
copied from the file or the rate book keeps its digits («1.0500»), one computed
is written as decimal.js writes it, so both clients store the same row the same
way. Equality and arithmetic use the value.

Rows in another currency are booked at the ECB's rate of their day.
`EnsureRates` brings each currency's series up to date from the ECB data API
(one currency per request, CSV with the data only, through `http`) and stores
it in `FxRate`; a stored day is never overwritten (`planFxWrite`), and a
currency the service cannot give is listed, not an error: its rows stay
`fx-unavailable` and the review says so; so does a fetched series that
contradicts a stored rate, which is then not updated. Both rate books, for
booking and for valuation, read only the ECB's series (`ecbSource`), as in
Quoin. Tests answer for the ECB with
`MockClient`. This is the app's only network traffic: public data in, and
nothing out but the currency code. Kraken rewards and swaps without Kraken's
own USD figure are valued from stored prices only; the app does not download
price histories yet.

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
