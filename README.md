# Quoin mobile

The Android (and later iOS) app of [Quoin](https://github.com/aritzmmartinez/quoin),
an open-source portfolio tracker. It runs on its own: the database and every
calculation stay on the device. Syncing with the desktop app over the local
network is planned.

Early days: the app is a skeleton (navigation, theme, languages) with no
portfolio features yet.

## Development

Flutter 3.47.8.

```sh
flutter pub get
flutter analyze
flutter test
flutter run

# Domain package
cd packages/quoin_core
dart pub get
dart analyze
dart test
```

## Licence

[AGPL-3.0](LICENSE). Geist and Geist Mono are under the
[SIL Open Font License](assets/fonts/OFL.txt).
