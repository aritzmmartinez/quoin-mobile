# Privacy

What leaves the phone, where it goes, why and how. This page is the source
for the privacy policy on the landing page and for Google Play's Data safety
form; when the app starts sending anything new, this page changes first.

The app has no account, no server of its own, no analytics, no ads and no
crash reporting. The portfolio, its database and every calculation stay on
the phone. Only three things go out, each started by the user or by data the
user put there; the third only once the user turns it on.

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

## Kraken, only when the user turns it on

Off by default. Settings → Crypto prices explains what is below before it can
be turned on; turning it off deletes every price that came from Kraken.

- **What:** requests to Kraken's public market data, with no account and no
  key: the daily closes (`OHLC`) and the last trade (`Trades`) of a pair. Each
  request carries the pair's name (`BTC/EUR`) and, for closes, the time from
  which they are wanted; nothing else about the portfolio or the user (no
  quantity, amount, trade, instrument name or device id).
- **Which pairs:** one per crypto in the portfolio, the one chosen for it on
  the PC or else its code against the euro (`USDG/USD` where Kraken has no euro
  pair), except a crypto whose prices a paired PC sent with a close from the
  last week.
- **Where:** `api.kraken.com`, over HTTPS with the system's trusted
  certificates.
- **Why:** to value crypto without a PC.
- **When:** each time the app opens and on pull to refresh, one request a
  second; closes once a day per pair, the last trade at most every five
  minutes, a pair Kraken does not list at most every twelve hours.

Kraken sees the phone's IP address and which pairs it asks for, and so which
crypto the user is likely to hold. Its own terms apply to what it logs. The
prices are kept with the rest of the price histories (`files/prices/`) and,
as Kraken asks, never leave the phone: they are not sent to the PC. Where a
price from Kraken is shown, the app says «Market Data: Kraken».

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

**Finding a PC that changed address.** When a PC does not answer at its saved
address and the user pulls to refresh, taps «Sync now» or «Search the
network» on that PC, the phone looks for it on its own local network. Never
in the background sync when the app opens.

- **What:** a TLS handshake and, only to a server presenting the
  certificate of a PC already paired, `GET /v1/hello`, which carries no token
  and no portfolio data. With any other certificate the handshake is
  abandoned and nothing of the request is sent.
- **Where:** the addresses of the phone's own /24 that holds the PC's saved
  address (up to 253 hosts, on the PC's saved port), only on the local
  network; never another subnet, mobile data or a VPN.
- **When:** at most once per pass; a PC not found is not looked for again by
  a pull while the phone's addresses stay the same, for up to 30 minutes.
- **What is kept:** the new address replaces the old one in that PC's
  pairing. Which PCs were missed lives in memory only.

On the phone each pairing (the PC's address and certificate pin, the device
token, the PC's name and sync identity) is kept in Android's encrypted storage
(`flutter_secure_storage`, its key in the Android Keystore). So is what the
last sync with each PC wrote on each side, by name and count (instruments,
targets, fund compositions, movements by type), never amounts; it goes when
the PC is unpaired or replaced, and never leaves the phone.

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
| `files/prices/` | The price histories, a cache the restored phone gets again from the PC or Kraken. |

The rules are `android/app/src/main/res/xml/data_extraction_rules.xml`
(Android 12 and later) and `backup_rules.xml` (Android 11 and earlier).

## Permissions

- `INTERNET`: the ECB, Kraken (when turned on) and the PC.
- `CAMERA`, asked at run time: the pairing QR.

Searching the local network needs no other permission on the Android versions
the app targets. Where the system denies the local network, the search stops
at the first refused connection and says so.

The scanner's library also declares `VIBRATE` and `FLASHLIGHT`; the manifest
removes both, since the app uses neither.

## For Google Play's Data safety form

From the above, to be checked against Play's definitions when the form is
filled in:

- Data collected and shared: nothing reaches the developer; the sync goes
  only to the user's own PC, at their request. The ECB request carries a
  currency code and dates, no user data. With Kraken turned on, Kraken
  receives the phone's IP address and the names of the pairs asked for, as
  described above; how that is declared is decided when the form is filled
  in.
- Data encrypted in transit: yes (HTTPS to the ECB and Kraken; pinned HTTPS
  to the PC).
- Data deletion: everything is on the phone; uninstalling or clearing the
  app's data deletes it. Unpairing a PC deletes its pairing and its token on the
  phone; the PC keeps listing the phone until it is revoked there.
