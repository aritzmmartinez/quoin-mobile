# Privacy

What leaves the phone, where it goes, why and how. This page is the source
for the privacy policy on the landing page and for Google Play's Data safety
form; when the app starts sending anything new, this page changes first.

The app has no account, no server of its own, no analytics, no ads and no
crash reporting. The portfolio, its database and every calculation stay on
the phone. Only two things go out, both started by the user or by data the
user put there.

## The European Central Bank

- **What:** a request for one currency's euro reference rates. It carries the
  currency code (`USD`) and the range of days the app is missing; nothing
  about the portfolio or the user.
- **Where:** `data-api.ecb.europa.eu`, over HTTPS with the system's trusted
  certificates.
- **Why:** a row in another currency is booked and valued at the ECB's rate
  of its day.
- **When:** after an import or a sync brings a currency whose rates are not
  stored yet, or are out of date.

The ECB sees the phone's IP address, as any website does. Its own terms
apply to what it logs.

## The user's PCs, over the local network

Only once the user pairs the phone with Quoin on their own PC. The phone can
be paired with several of the user's PCs; each one receives what is below,
and the phone carries each PC's changes to the others.

- **What:** the whole portfolio state that the PC needs to keep the same
  portfolio: the ledger, instruments, plan versions, fund compositions,
  identities, the tax residence and the sync marks. To pair, the phone also
  sends its device id and the name the user gives it («Mi móvil» by
  default). To get prices it sends, per instrument, its id, the version of
  the series it holds and the last day in it. The PC answers with its own
  state and the price histories.
- **Where:** the address in the QR the PC shows, normally the PC's address on
  the home Wi‑Fi. Nothing goes through the internet or any third party.
- **Why:** so the phone and the PC show the same portfolio without a server.
- **When:** when the user pairs, pulls to refresh Inicio or Cartera, taps
  «Sync now», and in the background each time the app opens, to each PC
  whose first sync was confirmed. A PC set aside because it shares its sync
  identity with another paired PC receives nothing. Prices are asked of one
  PC per sync.
- **How:** HTTPS with the PC's certificate pinned: the QR carries the
  certificate's SHA-256 and the phone talks only to a server presenting that
  certificate, with no other trusted root. If another computer answers at
  that address, the phone sends nothing and says so. The PC also shows a
  six-digit code that the user compares with the phone's before the PC
  accepts it. Each request carries the device token the PC issued; revoking
  the phone on the PC ends it.

On the phone each pairing (the PC's address and certificate pin, the device
token, the PC's name and sync identity) is kept in Android's encrypted storage
(`flutter_secure_storage`, its key in the Android Keystore).

## The camera

Only to read the pairing QR, and only after the user allows it (Android asks
at that moment; the camera is not required to install the app). The QR is
decoded on the phone by ZXing (`qrscan`), with no Google ML Kit and no network
access. No frame is stored or sent; only the text of the QR is kept, as
described above.

## Android backup

Android may copy the app's data to the user's Google account (only when the
backup is end-to-end encrypted) or to a new phone. The portfolio travels; three
things never do:

| Left out | Why |
| --- | --- |
| `files/install_id` | A restored copy must know it is a copy and take a device id of its own, so two phones never sign as one. |
| `shared_prefs/FlutterSecureStorage.xml`, `FlutterSecureKeyStorage.xml` | The pairing and its device token. A restored phone is a new device and pairs again; it never arrives paired. |
| `files/prices/` | The price histories, a cache the restored phone gets again from the PC. |

The rules are `android/app/src/main/res/xml/data_extraction_rules.xml`
(Android 12 and later) and `backup_rules.xml` (Android 11 and earlier).

## Permissions

- `INTERNET`: the ECB and the PC.
- `CAMERA`, asked at run time: the pairing QR.

The scanner's library also declares `VIBRATE` and `FLASHLIGHT`; the manifest
removes both, since the app uses neither.

## For Google Play's Data safety form

From the above, to be checked against Play's definitions when the form is
filled in:

- Data collected: none. Nothing reaches the developer or a third party; the
  sync goes only to the user's own PC, at their request.
- Data shared: none. The ECB request carries a currency code and dates, no
  user data.
- Data encrypted in transit: yes (HTTPS to the ECB; pinned HTTPS to the PC).
- Data deletion: everything is on the phone; uninstalling or clearing the
  app's data deletes it. Unpairing a PC deletes its pairing and its token on the
  phone; the PC keeps listing the phone until it is revoked there.
