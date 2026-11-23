# Quoin mobile

The Android (and later iOS) app of [Quoin](https://github.com/aritzmmartinez/quoin),
an open-source portfolio tracker. It runs on its own: the database and every
calculation stay on the device. It has no account, no server and no
analytics. It talks to two places only: the European Central Bank, for its
public exchange rates (it sends the currency code it needs), and, once you
pair them, Quoin on your own PC over the local network, through HTTPS pinned
to the PC's certificate. What goes where and why:
[docs/privacy.md](docs/privacy.md).

Early days: the app shows a portfolio from its own store, imports Trade
Republic and Kraken CSVs, and syncs with the desktop app; analysis is still
to come.

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
