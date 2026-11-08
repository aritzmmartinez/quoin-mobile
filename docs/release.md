# Before publishing on Google Play

- **Third-party licences.** Settings → Licencias de terceros shows the pub
  packages (`qrscan`'s MIT included) and the fonts, but not the Java
  libraries `qrscan` brings from Maven, all Apache-2.0: ZXing core 3.5.3,
  Guava 33.3.1 and CameraX 1.4.1. Add them as the fonts are: bundle the
  Apache-2.0 text in `assets/licenses/Apache-2.0.txt` and register one entry
  in `main.dart` with `LicenseRegistry.addLicense` for `ZXing`, `Guava` and
  `CameraX`. Check the list again whenever an Android dependency changes
  (`./gradlew app:dependencies`).
- **Data safety form and privacy policy:** from `docs/privacy.md`.
- **Backup:** the `bmgr` restore check of `install_id`, the secure storage
  files and `prices/` (`docs/privacy.md`, Android backup) on a release build.
