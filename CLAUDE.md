# quoin-mobile

Android (later iOS) app for Quoin; own database and calculations. `../quoin`
(TypeScript) is the reference for colours, copy and domain rules. Layers and
flows: `docs/ARCHITECTURE.md`.

## Structure

- `lib/src/app`: startup, router, shell, `dependencies.dart` (composition root).
- `lib/src/core`: `error/` (exceptions, failures, Result), `theme/`, `l10n/`.
- `lib/src/ui`: shared widgets by atomic level: `atoms/`, `molecules/`, `organisms/`, `templates/`.
- `lib/src/features/<feature>/{data,domain,presentation}`: features are portfolio, import, analysis, tax, settings, sync.
- `packages/quoin_core`: pure Dart domain shared with `../quoin`: `Dec`, `Money`, calendar, ledger, fx, swap and the portfolio projections. Golden cases in `test/contract/` are copied from `../quoin/test/contract/` and never edited.

## Architecture

- Dependencies go `presentation → domain ← data`; `test/architecture_test.dart` checks imports.
- Domain imports only `dart:`, `quoin_core`, `core/error` and domain: no Flutter, Riverpod or storage.
- Presentation never imports data; only `app/` sees both.
- Shared domain logic goes in `quoin_core`; features use it, never copy it.
- `computePositions` holds the AVCO loop today; when realised gains arrive, extract `walkAvco` and share it between the two, as in Quoin.
- Create only the folders a feature uses; no empty folders.
- Data sources throw `core/error/exceptions.dart` types only.
- Repositories catch them and return `Result<T>` (`Ok`/`Err` with a sealed `Failure`); no dartz.
- Presentation handles a `Result` with an exhaustive `switch`.
- Models convert with `toEntity()` and never extend the entity.
- State and injection: Riverpod only (no get_it, bloc, provider), no code generation.
- One provider per link: data source → repository → use case → screen state.
- A repository's provider is typed abstract in presentation and bound in `app/dependencies.dart`.
- `ui/` widgets take data and callbacks: no features, providers or router.
- A widget used by one feature goes in its `presentation/widgets`.
- Pages are `presentation/pages/*_page.dart` with a `*Page` class.
- A `Failure` the user can act on is shown, translated (a SnackBar for a failed save).
- Imports are package imports (`always_use_package_imports`), so the layer test can read them.
- Routing: `go_router` with `StatefulShellRoute`.

## Money

- Amounts and quantities are `Dec` or `Money`, never `double`.
- Doubles only for chart coordinates and the projection loop, via `toDouble()` at the edge.
- Build them from text only (`Money.parse`, `Dec.parse`), never from a `double`.
- `Money` has no operators on purpose: operate through its methods. `Dec` is the numeric type and has them.
- Ratios (weights, returns) are `Dec` rounded to six places, as the web stores them.
- `Dec` is decimal.js (40 digits, ROUND_HALF_UP); if a case in `packages/quoin_core/test/contract/decimal.json` fails, the port is wrong.
- No real portfolio data in the repo: fixtures, tests or screenshots.

## UI

- Sizes only in `QuoinType` (`core/theme/quoin_type.dart`); no widget sets `fontSize` (a test checks it).
- Figures in Geist Mono with tabular digits, through a role's `.mono`.
- Fonts bundled in `assets/fonts` with `OFL.txt`; never `google_fonts` (runtime download breaks the privacy policy).
- Text scales with the system font; heights are minimums; a test at 200 % fails on overflow.
- Scaling exceptions, commented where they live: bottom bar clamps to 1.3; display figure, row figures and segment labels shrink to one line (`FittedBox`, scaleDown).
- From 1.5x font size, a settings row puts its value or badge under the label.
- Colours: `QuoinColors`, same names as `../quoin/app/app.css` (dark `@theme`, light `.light`); they win over the design's neutrals.
- Green and red are signals, never categories.
- Theme follows the system unless the user picks one.
- Layout reference: `docs/design/Quoin Terminal.dc.html`; its figures and names are invented.
- Shape set in the component themes in `quoin_theme.dart`, not per screen: pills (`StadiumBorder`) for buttons, chips, segmented, fields and bar; cards 24; sheets 28 on top (`QuoinRadius`).
- Icon tiles: circle for entities (position, broker), `RoundedSuperellipseBorder` for functions.
- Text input: `QuoinTextField` only; label above, required except `.search`; unit suffix in Geist Mono.
- A hint is short and never carries what the user needs; the search hint is «Buscar», its description is the accessibility label.
- Segmented controls: `QuoinSegmented` (honours reduce motion).
- No ink ripples (`NoSplash` in the theme): a pressed control changes colour (themed `highlightColor`, button overlays) or scales (`Pressable`).
- Icons: Hugeicons stroke rounded, stroke 1.5; declared in `core/theme/quoin_icons.dart`, drawn with `ui/atoms/quoin_icon.dart`; only those two import `hugeicons` (a test checks it).
- Bottom bar: our buttons and the central «+» on liquid glass (`liquid_glass_widgets` only in `QuoinBarSurface`); content scrolls under it (`QuoinPage.list`).
- The bar's glass is `GlassQuality.premium` (the standard shader keeps a hard rim over dark backdrops).
- Bottom bar active tab: accent icon and label plus a pill that springs under it (jumps with reduce motion); a tab scales to 0.92 when pressed and clicks with `HapticFeedback.selectionClick`.
- Navigation bar hidden natively in `MainActivity`, which passes its inset to Flutter; never `SystemChrome.setEnabledSystemUIMode`.
- Component gallery: debug only (`kDebugMode`, Settings → Debug), the only place for invented data, not localised.
- No visible string in code: Spanish template `app_es.arb`, full English; both ARBs have the same keys (a test checks it).
- `lib/src/core/l10n/gen/` is generated by `flutter pub get`; never commit it.
- Device preferences (theme, language) in `SharedPreferencesWithCache`, never synced, never in the database.

## Tooling

- Icon and splash sources live in `assets/branding/` (not app assets); never edit them or the generated `android/`/`ios/` icons and splash by hand.
- Regenerate the sources from `docs/design/logo/quoin-mark-light.svg`: `dart run tool/branding/generate.dart` (plain Dart, no packages).
- Regenerate icons: `dart run flutter_launcher_icons` (config in `flutter_launcher_icons.yaml`).
- Regenerate splash: `dart run flutter_native_splash:create` (config in `flutter_native_splash.yaml`).
- Strict analysis (`strict-casts`, `strict-inference`, `strict-raw-types`) in the app and in `quoin_core`.
- Use the dart-flutter plugin (MCP server and skills); if a skill contradicts this file or the prompt, this file and the prompt win, and say so.
- Before handing back: `dart analyze` and `dart test` in `packages/quoin_core`; `flutter analyze` and `flutter test` at the root.
- CI also runs `flutter build apk --debug`, on Flutter 3.47.8.
- No tool or assistant marks in code, comments or docs.
- Aritz makes the commits; write the message in `msg.txt` (ignored).
