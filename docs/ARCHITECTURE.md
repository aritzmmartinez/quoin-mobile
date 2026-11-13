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
it uses. Today `settings`, `portfolio`, `import` and `sync` have all three;
`tax` has `domain` and `presentation`; `analysis` has only `presentation/pages`.

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

Its golden cases, `test/contract/*.json`, are Quoin's, never edited here.
`dart run tool/sync_contracts.dart [../quoin]` copies them from a clean Quoin
checkout (LF line ends) and writes the commit they come from to
`test/contract/SOURCE`; CI fetches that commit of `aritzmmartinez/quoin` and
runs the script with `--check`, failing when a file is missing, extra or
different.

## Local store

`features/portfolio/data/database` holds the drift database. `schema.drift`
declares the tables of `../quoin/prisma/schema.prisma` that the app reads or
syncs (the ledger and its instruments, prices and rates, the residence, plan
versions, fund compositions, identities and the sync tables) with the same
names, CHECKs and unique keys, so sync can map rows one to one. Amounts are
decimal text, days `YYYY-MM-DD`, instants ISO-8601 UTC text.

The price histories live apart, in `PricesDatabase` (`prices.drift`, under
`files/prices/`): `PriceSnapshot` with Quoin's columns and unique key but no
foreign key to `Instrument`, and `PriceSeries`, the version of each series as
the PC named it. They are a cache: derived, fetched again from the PC, never
synced, and left out of every Android backup, which a separate file makes a
single rule. Version 3 of the main database drops its `PriceSnapshot`.

Migrations are hand-written steps in `QuoinDatabase.migration`, one per
version, each against that version's frozen schema (`quoin_database.steps.dart`),
never the live tables. To add a version, raise `schemaVersion` and run
`dart run drift_dev make-migrations`: it saves the schema in `drift_schemas/`
(never edited afterwards), regenerates the steps and `test/drift/`, and the
step is then written by hand. The generated `.g.dart` is committed and CI
fails if regenerating it changes anything.

Every screen computed from the store reads it once: `LoadLedger` fills
`ledgerProvider` with the ledger, the latest price of each instrument and the
ECB rates, and each screen's provider derives from it with a pure function, so
a write invalidates `ledgerProvider` alone. Home and Cartera run the web's home
chain through `quoin_core` (`overviewOf`): positions, prices in euros, market
values, summary, allocation and top positions. Movimientos (`movementsOf`) and
the instrument page (`instrumentDetailOf`) read the same ledger; Realizado
(`features/tax`, `realizedReportOf`) puts the AVCO sales next to the Bizkaia
tax history, and builds a fiscal year's view when it is chosen.

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
Quoin. It asks the ECB only for what may be new (`ecbFetchFrom` in
quoin_core): a series that already holds the newest day out (16:30 on
Frankfurt clocks, on TARGET business days) asks nothing; an answer that
lacks the expected day (a late publication, a closing outside the calendar)
holds that currency for 15 minutes, in memory only (`EcbHold`). The sync
reads no rate book back (`withBook: false`). Tests answer for the ECB with
`MockClient`. Public data in, nothing out but the currency code and the days;
the only other traffic is the sync with the user's PC (`docs/privacy.md`).
Kraken rewards and swaps without Kraken's own USD figure are valued from
stored prices only; the price histories come from the PC.

## Sync

Two devices, the phone and the PC (`../quoin`), keep one portfolio without a
server. Each is a complete node: it holds the whole user state (ledger,
instruments with the mark of each hand-set field, plan versions and their
tombstones, fund compositions, identities, residence) and the marks of what it
has seen from the others. A file carries that state; moving it is the
transport, described below. Merge, its plan and the model of applying it
are pure Dart in `quoin_core` (`merge`, `applyPlan`, `planCounts`), ported
from Quoin's `core/sync` and checked case by case against `sync.json` (merges,
refusals and two-device scenarios) in `sync_contract_test.dart`.

**Marks and `seen`.** A mark is `<ms>-<counter>-<deviceId>`, fixed-width, so
string order is time order. A device issues them with `tick`, which never goes
back whatever the clock says, and only compares a mark with others of its own
origin. `seen` is, per other device, the newest mark whose effect this side has
taken in. A mark is news for a side when it is another device's and newer than
what that side has seen of it; a field changed on both sides, each news to the
other, is a conflict. Otherwise the side that has news wins, with no human step.

**Resolutions.** A conflict is settled with `keep` or `take`, keyed by
`conflictKey` (instrument field, residence, composition, target version, two
versions on one day). `take` adopts the other value and its mark. `keep` leaves
the value and marks it afresh (`restamp`), so the next exchange carries it
across; plan versions have no mark and are never edited, so a resolution there
travels as a tombstone (a kept version with another content is reissued under
the tombstone's mark). A resolution that fits no conflict throws
`UnknownResolution`, and while any conflict is open nothing is applied.

**Ledger set aside.** A ledger row has no mark. When both sides hold a
`source::externalId` with another content (compared as the exact text of each
field, `ts` as an instant), the row is set aside, not conflicted: each side
keeps its own, the rest applies, and the row is listed. A linked operation
(a swap's legs) is set aside whole, by the link on either side; a Kraken reward
(two unlinked rows) is set aside in both rows. Amounts are never re-serialised
through `Dec`.

**Applying.** `SyncLocalDataSource.importExchange` reads, merges and writes in
one drift transaction, so a write from elsewhere waits for it and the plan is
made against the very state it is written to (tested with a write launched from
outside while the transaction is open). `apply` does what `applyPlan` models,
no more: the whole plan or nothing, with the fresh marks of `restamp` issued by
`stamp` in that transaction. A new `quoteSymbol` drops the instrument's price
series inside it, as Quoin does. `refuseOwnExport` runs before the merge.
The effects are not run there: the result carries them, and the caller runs
them after the commit with `RunEffects`. `rates` go to `EnsureRates` through
a port (`EnsureRatesFrom`) that `app/dependencies.dart` binds (`ratesForSync`),
so `sync` does not import `import`; a failure is reported for that effect and
never undoes the import. Price histories are not an effect the phone runs:
it asks the PC for them after each sync (below).

**A residence this version does not know.** Sync carries the residence as the
text it came as, so a territory a newer Quoin adds is stored and sent on
unchanged, and the node stays complete. `Residence` stays what Quoin defines
and no calendar zone is invented for the rest. Reading the ledger or planning an
import with such a residence gives `UnsupportedResidenceFailure`, never
Bizkaia: every ledger screen and the import say that the PC uses a tax
territory this version does not know and that the app must be updated.

**Guards.**

- *Sample data.* Every sync reads the state through one gate that refuses a
  state holding the invented debug data (`QSAMPLE`), whole: filtering it would
  leave references to what was filtered.
- *Device id.* A copied database keeps its device id, and two phones would sign
  as one. `DeviceIdentityDataSource.claim` compares the id with the one this
  install took (a file left out of every Android backup), gives the database a
  new id when they differ, and keeps the old id as a peer seen up to its last
  mark. A sync calls it first and stops if it fails.
- *Kraken.* A reward or swap without Kraken's own USD figure is valued on the
  PC only and arrives by sync, so each such row has one author and the two
  sides never book it at different prices.

**Transport.** The PC serves `../quoin/docs/sync-api.md` on the local
network; `SyncRemoteDataSource` is its client. Every request goes through
`PinnedClient`: `dart:io`'s `HttpClient` with no trusted roots, whose
`badCertificateCallback` accepts only a certificate whose DER hashes to the
pin from the QR. A mismatch is `PinMismatchException`, then
`CertificateMismatchFailure`, and nothing is sent. Bodies are gzipped JSON;
answers are parsed off the main isolate (`Isolate.run`). A 503 or 429 with a
`Retry-After` of five seconds or less is retried once; longer is a failure.

**Pairing** (`PairWithPc`). The PC's QR carries host, port, certificate pin,
a one-time token and the PC's name (`parsePairingQr`). The phone checks the
PC answers (`hello`), shows the six-digit `pairingCode` of the token and its
device id for the user to compare with the PC's, and posts both with its
name; the PC answers with a device token once the user accepts there. The
pairings are a list in `flutter_secure_storage` under `pairings` (left out of
backups: a restored phone pairs again); the single `pairing` of earlier
versions moves into it on first read, so a paired phone never pairs again. A
PC is its certificate's SHA-256; host and port are where it was last seen,
and scanning the QR of a PC already paired only saves its new address
(`PairingStart.known`). «Vincular de nuevo» after a revocation pairs again
(`repair`). The camera is used only here: `qrscan` (ZXing in Java,
its own camera screen) behind `scanQr` in `qr_scanner_view.dart`, the only file that
imports it, swapped for a fake in tests (`qrScannerProvider`).

**A sync** (`SyncNow`) is a pass over every paired PC: claim the device id;
`hello` to every PC at once, with a three-second wait; then, one PC after
another, `GET /v1/sync` for its state and ETag, its identity, `importExchange`
here, and `POST /v1/sync` with the merged state and `If-Match` (starting
that PC again once on 409). When a later PC brought changes, the PCs
synced before it get one more sync, so one pass carries each PC's changes to
the others. One PC's failure never stops the rest; «No encuentro tu Quoin»
only when none answered (`SyncPass.noneAnswered`). A PC's first sync is a dry
run that previews both directions (`SyncPreview`) until the user confirms
that PC. Open conflicts return `SyncConflicts` and write nothing; the screen
shows the PCs that wait one at a time and runs the pass again after each
answer, so the next PC's conflicts are worked out against what was just
written. The pass ends with the exchanges, and so do the pull and the result
screen; its follow-up (`FinishSync`: the merges' effects, then the price
histories and their rates) runs in the background with its own state
(`SyncStatus.finishing`, `followUp`) and reloads the ledger, so every
valuation updates without another pull. `SyncController` runs one pass at a
time: a plain sync asked during one joins it; one carrying a decision waits
and then runs; and no pass starts before the last one's follow-up is over,
so the two never write at once.

**Identity** (`PcIdentity`). Two PCs with one sync identity (a database
restored from one onto the other) must never both sync: their marks look
like one device's and values diverge silently. A PC's identity is learnt from
its exchange, before anything is merged. A new one under the same
certificate is the PC rotating its own, taken as it is. If another paired PC
has it, that PC is asked (`GET /v1/sync` with its own token; `hello` carries
no identity): answering with it makes the new PC a clone, set aside
(`shared`, `SharedIdentityFailure`) without asking; not answering asks the
user (`SyncSameIdentity`): the same PC with a new certificate replaces the
other entry, another PC is set aside. «Comprobar de nuevo» lets a set-aside
PC sync again once its identity is its own.

**Prices** (`PullPrices`). From one PC per pass: the one in
`Pairings.pricesFrom` while it syncs, else the first that did, which becomes
the source (never a shared or unpaired PC). Series versions are each PC's
own, so a new source is one full download (about 0.4 MB gzipped for 35
instruments and five years of closes). After the sync the phone posts, per instrument it
holds, the series version and last day it has (`holdingOf`); the PC answers
with a full series, the rows after that day, or `pending` while it is still
downloading. `PricesLocalDataSource` applies them (`applyPriceAnswer`): a
row's id is its instrument and instant, ordered and unique as the series
key is, and while whole series are written the two plain indexes are off and
rebuilt once after. Then
`EnsureRates` brings any new currency's rates. Pending instruments are asked
again a few times, three seconds apart; what is still pending is shown.

**When.** The Sync section in Settings lists each PC (`pcRow`: its name and
what it is doing, what stopped it or when it last synced); a PC's sheet
explains what stopped it and offers its way out and unpairing, which deletes
only the phone's token, so the PC must revoke it too. Inicio and Cartera
sync on pull to refresh; the app syncs silently when it opens, with the PCs
already confirmed.

**Failures.** Each refusal of the API is its own `Failure`: unreachable,
certificate mismatch, revoked, invalid or used or expired QR, rejected
pairing, update required (app or Quoin), PC busy, conflicts changed, refused
with a code. Unreachable, certificate and revoked offer to pair again, since
only a new QR carries a new address or certificate.

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
