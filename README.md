# Quoin mobile

The Android (and later iOS) app of [Quoin](https://github.com/aritzmmartinez/quoin),
an open-source portfolio tracker. It runs on its own: the database and every
calculation stay on the device, and your data never leaves it. The only thing
the app downloads is public data, the European Central Bank's exchange rates;
all it sends is the code of the currency it needs. Syncing with the desktop
app over the local network is planned.

Early days: the app shows a portfolio from its own store and has the CSV
import wizard; the brokers' adapters, analysis, tax and sync are still to come.

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
