# Before publishing on Google Play

## Before the closed beta

The first build that reaches anyone outside development, closed testing
included, ships these. Production needs them too.

- **Third-party licences.** Settings → Licencias de terceros shows the pub
  packages the app runs with, Flutter's engine and, from
  `lib/src/app/licenses.dart`, the fonts and the Android libraries that come
  from Maven: Apache-2.0 for most (ZXing, Guava, CameraX, AndroidX, Kotlin,
  Tink, Gson, Okio…), MIT for checker-qual and BSD-3-Clause for the
  Protocol Buffers inside DataStore; the texts are in `assets/licenses/`.
  Whenever an Android dependency changes, list them again with
  `./gradlew :app:dependencies --configuration releaseRuntimeClasspath`
  (from `android/`) and add what is new. Whenever a pub dependency changes,
  run `dart run tool/licenses/generate.dart`: it rewrites
  `lib/src/app/runtime_packages.dart`, which keeps the packages only
  development needs off the page (CI fails if it is stale).
- **Data safety form and privacy policy:** from `docs/privacy.md`; Play asks
  for both before any testing track goes out.

## Before production

- **Backup:** the `bmgr` restore check of `install_id`, the secure storage
  files and `prices/` (`docs/privacy.md`, Android backup) on a release build.
  A debug build cannot be backed up as it is: Flutter extracts about 150 MB
  into `app_flutter/flutter_assets` and the transport refuses it for size;
  for a test on debug, exclude that folder temporarily and revert it.

## Signing

The real app (`dev.aritzmmartinez.quoin`) is signed with Quoin's own upload
key, the same on every PC. Android only lets an install be updated by an APK
with the same signature; with each PC's debug key the phone could not be
updated from the other PC without uninstalling, and uninstalling deletes the
portfolio. Debug and profile builds are always Quoin dev
(`dev.aritzmmartinez.quoin.dev`, debug key), and so is a release built with
`--android-project-arg=dev=true`. A release of the real app without a valid
`android/key.properties` fails; it never falls back to the debug key.

### Creating the key

Once, on one PC, with the keystore outside the repository:

```sh
keytool -genkeypair -v -storetype PKCS12 -keyalg RSA -keysize 4096 -validity 10000 -alias upload -keystore "D:/Keys/quoin/quoin-upload.jks"
```

`keytool` comes with the JDK (Android Studio's is in `jbr/bin`). It asks for
the store password and the name fields; the validity is about 27 years,
beyond what Play requires.

Then `android/key.properties` (ignored by git), with forward slashes, since a
backslash is an escape in a properties file:

```properties
storeFile=D:/Keys/quoin/quoin-upload.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

`storeFile` must be an absolute path outside the repository, or the build
stops.

### Copies and the second PC

Losing the keystore or its password means the installed app can never be
updated again without uninstalling it (on Play, see below). Keep the `.jks`
and both passwords in at least two places outside the repository, such as a
password manager and an encrypted drive kept offline, and check that a copy
opens: `keytool -list -v -keystore <copy>`.

On the second PC, copy the same `.jks` (never generate another one) to a path
outside its repository and write that PC's own `android/key.properties`
pointing to it.

### Installing the real app

```sh
flutter build apk --release
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

Never `flutter install`: it uninstalls before installing, and the data goes
with it. `-r` replaces the install and keeps its data. The two errors that
stop it, and leave the installed app untouched:

- `INSTALL_FAILED_UPDATE_INCOMPATIBLE`: the APK has another signature. Build
  with the upload key; do not uninstall to get past it.
- `INSTALL_FAILED_VERSION_DOWNGRADE`: the APK's `versionCode` (the number
  after `+` in `pubspec.yaml`'s `version`) is lower than the installed one.
  Raise it.

### The first install with the upload key

The phone's current install is signed with a PC's debug key, so the first
install with the upload key cannot replace it:

1. Sync with the PC.
2. On the phone, check that nothing is left to send and no conflict is open.
3. Uninstall one last time: `adb uninstall dev.aritzmmartinez.quoin`.
4. Install the release signed with the upload key (`adb install -r`).
5. Pair with the PC again and sync; the portfolio comes back from the PC and
   the price histories with the next sync.

From then on every update is `adb install -r`.

### Google Play, GitHub and F-Droid

- **Play:** this is the upload key. With Play App Signing, Google keeps the
  key that signs what users install, and a lost upload key can be reset from
  the Play Console. Play takes an app bundle: `flutter build appbundle`.
- **GitHub releases:** an APK published there is signed with this key itself;
  nothing replaces it if it is lost. It cannot update an install from Play,
  or the other way round, since Play's copy carries Google's signature.
- **F-Droid** signs with its own key unless the build is reproducible and it
  publishes ours; either way, installs from different sources cannot update
  each other.

## Database migrations

`PricesDatabase` is still at its first version and has no migration. Its v2
needs a `MigrationStrategy` with `stepByStep` (after `drift_dev
make-migrations`, as for the portfolio) and a test that inserts prices at v1
and checks they survive, as `test/drift/quoin/migration_test.dart` does.
