# Before publishing on Google Play

## Before the closed beta

The first build that reaches anyone outside development, closed testing
included, ships these. Production needs them too.

- **Third-party licences.** Settings → Licencias de terceros shows the pub
  packages and, from `lib/src/app/licenses.dart`, the fonts and the Android
  libraries that come from Maven: Apache-2.0 for most (ZXing, Guava,
  CameraX, AndroidX, Kotlin, Tink, Gson, Okio…), MIT for checker-qual and
  BSD-3-Clause for the Protocol Buffers inside DataStore; the texts are in
  `assets/licenses/`. Whenever an Android dependency changes, list them
  again with `./gradlew :app:dependencies --configuration
  releaseRuntimeClasspath` (from `android/`) and add what is new.
- **Data safety form and privacy policy:** from `docs/privacy.md`; Play asks
  for both before any testing track goes out.

## Before production

- **Backup:** the `bmgr` restore check of `install_id`, the secure storage
  files and `prices/` (`docs/privacy.md`, Android backup) on a release build.
  A debug build cannot be backed up as it is: Flutter extracts about 150 MB
  into `app_flutter/flutter_assets` and the transport refuses it for size;
  for a test on debug, exclude that folder temporarily and revert it.
