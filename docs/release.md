# Before publishing on Google Play

## Before the closed beta

The first build that reaches anyone outside development, closed testing
included, ships these. Production needs them too.

- **Third-party licences.** Settings → Licencias de terceros shows the pub
  packages (`qrscan`'s MIT included) and the fonts, but not the Java
  libraries `qrscan` brings from Maven, all Apache-2.0: ZXing core 3.5.3,
  Guava 33.3.1 and CameraX 1.4.1. Add them as the fonts are: bundle the
  Apache-2.0 text in `assets/licenses/Apache-2.0.txt` and register one entry
  in `main.dart` with `LicenseRegistry.addLicense` for `ZXing`, `Guava` and
  `CameraX`. Check the list again whenever an Android dependency changes
  (`./gradlew app:dependencies`).
- **Data safety form and privacy policy:** from `docs/privacy.md`; Play asks
  for both before any testing track goes out.

## Before production

- **Backup:** the `bmgr` restore check of `install_id`, the secure storage
  files and `prices/` (`docs/privacy.md`, Android backup) on a release build.
  A debug build cannot be backed up as it is: Flutter extracts about 150 MB
  into `app_flutter/flutter_assets` and the transport refuses it for size;
  for a test on debug, exclude that folder temporarily and revert it.
