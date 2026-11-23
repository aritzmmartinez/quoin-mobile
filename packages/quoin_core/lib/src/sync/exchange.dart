import 'package:quoin_core/src/sync/hlc.dart';

/// The sync format version this port reads and writes, as Quoin's `exchange.ts`.
const syncSchemaVersion = 1;

/// The only entity a tombstone buries.
const targetEntity = 'PortfolioTarget';

/// A file whose `schemaVersion` this version does not read.
class UnsupportedSchemaVersion implements Exception {
  const UnsupportedSchemaVersion(this.found);

  final Object? found;

  @override
  String toString() =>
      'This file is sync format version $found; this version of Quoin reads '
      'version $syncSchemaVersion only.';
}

/// A file or state that breaks the format: a missing or mistyped field, or a
/// rule across rows (a duplicated key, a swap with one leg...).
class InvalidExchange implements Exception {
  const InvalidExchange(this.issue);

  final String issue;

  @override
  String toString() => 'InvalidExchange: $issue';
}

/// A file exported by this same database.
class SameDevice implements Exception {
  const SameDevice(this.deviceId);

  final String deviceId;

  @override
  String toString() =>
      'The file was exported by this same database ($deviceId). A copied '
      'database file keeps its device id; it cannot sync with its own copy.';
}

/// The key a ledger row merges on, `source::externalId`.
String ledgerKey(String source, String externalId) => '$source::$externalId';

/// A ledger row as the exchange carries it: every amount keeps its text and
/// `ts` the text it was written with (compared as an instant, never as text).
final class LedgerRecord {
  const LedgerRecord({
    required this.source,
    required this.externalId,
    required this.ts,
    required this.type,
    this.instrumentId,
    this.quantity,
    this.price,
    required this.grossAmount,
    this.fees = '0',
    this.taxWithheld = '0',
    required this.currency,
    this.fxSource = 'IDENTITY',
    this.fxDate,
    this.fxRate,
    this.fxDirection,
    this.originalAmount,
    this.originalCurrency,
    this.valuationSource,
    this.linkId,
    this.linkKind,
    this.funding = 'CASH',
    required this.account,
    this.note,
  });

  factory LedgerRecord.fromJson(Object? raw, [String path = 'ledger']) {
    final f = _Fields(raw, path);
    return LedgerRecord(
      source: f.string('source', nonEmpty: true),
      externalId: f.string('externalId', nonEmpty: true),
      ts: f.instant('ts'),
      type: f.oneOf('type', _ledgerTypes),
      instrumentId: f.text('instrumentId'),
      quantity: f.text('quantity'),
      price: f.text('price'),
      grossAmount: f.string('grossAmount'),
      fees: f.string('fees', orElse: '0'),
      taxWithheld: f.string('taxWithheld', orElse: '0'),
      currency: f.string('currency'),
      fxSource: f.string('fxSource', orElse: 'IDENTITY'),
      fxDate: f.text('fxDate'),
      fxRate: f.text('fxRate'),
      fxDirection: f.text('fxDirection'),
      originalAmount: f.text('originalAmount'),
      originalCurrency: f.text('originalCurrency'),
      valuationSource: f.text('valuationSource'),
      linkId: f.text('linkId'),
      linkKind: f.text('linkKind'),
      funding: f.oneOf('funding', const ['CASH', 'IN_KIND'], orElse: 'CASH'),
      account: f.string('account'),
      note: f.text('note'),
    );
  }

  final String source;
  final String externalId;
  final String ts;
  final String type;
  final String? instrumentId;
  final String? quantity;
  final String? price;
  final String grossAmount;
  final String fees;
  final String taxWithheld;
  final String currency;
  final String fxSource;
  final String? fxDate;
  final String? fxRate;
  final String? fxDirection;
  final String? originalAmount;
  final String? originalCurrency;
  final String? valuationSource;
  final String? linkId;
  final String? linkKind;
  final String funding;
  final String account;
  final String? note;

  String get key => ledgerKey(source, externalId);

  Map<String, Object?> toJson() => {
        'source': source,
        'externalId': externalId,
        'ts': ts,
        'type': type,
        'instrumentId': instrumentId,
        'quantity': quantity,
        'price': price,
        'grossAmount': grossAmount,
        'fees': fees,
        'taxWithheld': taxWithheld,
        'currency': currency,
        'fxSource': fxSource,
        'fxDate': fxDate,
        'fxRate': fxRate,
        'fxDirection': fxDirection,
        'originalAmount': originalAmount,
        'originalCurrency': originalCurrency,
        'valuationSource': valuationSource,
        'linkId': linkId,
        'linkKind': linkKind,
        'funding': funding,
        'account': account,
        'note': note,
      };
}

const _ledgerTypes = [
  'BUY',
  'SELL',
  'DIVIDEND',
  'DEPOSIT',
  'WITHDRAWAL',
  'INTEREST',
];

/// An instrument with each hand-set field's mark; the exposure pair shares one.
final class InstrumentRecord {
  const InstrumentRecord({
    required this.id,
    required this.name,
    required this.type,
    this.assetClass,
    this.quoteSymbol,
    this.quoteSymbolHlc,
    this.exposureKind,
    this.exposureLeafId,
    this.exposureHlc,
    this.ter,
    this.terHlc,
    this.hedgedToBase = false,
    this.hedgedToBaseHlc,
    this.thesis = 'CORE',
    this.thesisHlc,
  });

  factory InstrumentRecord.fromJson(Object? raw, [String path = 'instrument']) {
    final f = _Fields(raw, path);
    return InstrumentRecord(
      id: f.string('id', nonEmpty: true),
      name: f.string('name'),
      type: f.string('type'),
      assetClass: f.text('assetClass'),
      quoteSymbol: f.text('quoteSymbol'),
      quoteSymbolHlc: f.mark('quoteSymbolHlc'),
      exposureKind: f.text('exposureKind'),
      exposureLeafId: f.text('exposureLeafId'),
      exposureHlc: f.mark('exposureHlc'),
      ter: f.text('ter'),
      terHlc: f.mark('terHlc'),
      hedgedToBase: f.boolean('hedgedToBase', orElse: false),
      hedgedToBaseHlc: f.mark('hedgedToBaseHlc'),
      thesis: f.string('thesis', orElse: 'CORE'),
      thesisHlc: f.mark('thesisHlc'),
    );
  }

  final String id;
  final String name;
  final String type;
  final String? assetClass;
  final String? quoteSymbol;
  final String? quoteSymbolHlc;
  final String? exposureKind;
  final String? exposureLeafId;
  final String? exposureHlc;
  final String? ter;
  final String? terHlc;
  final bool hedgedToBase;
  final String? hedgedToBaseHlc;
  final String thesis;
  final String? thesisHlc;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'assetClass': assetClass,
        'quoteSymbol': quoteSymbol,
        'quoteSymbolHlc': quoteSymbolHlc,
        'exposureKind': exposureKind,
        'exposureLeafId': exposureLeafId,
        'exposureHlc': exposureHlc,
        'ter': ter,
        'terHlc': terHlc,
        'hedgedToBase': hedgedToBase,
        'hedgedToBaseHlc': hedgedToBaseHlc,
        'thesis': thesis,
        'thesisHlc': thesisHlc,
      };
}

/// One version of the savings plan with its lines.
final class TargetRecord {
  const TargetRecord({
    required this.id,
    required this.name,
    required this.activeFrom,
    this.note,
    required this.createdAt,
    required this.lines,
  });

  factory TargetRecord.fromJson(Object? raw, [String path = 'target']) {
    final f = _Fields(raw, path);
    return TargetRecord(
      id: f.string('id', nonEmpty: true),
      name: f.string('name'),
      activeFrom: f.day('activeFrom'),
      note: f.text('note'),
      createdAt: f.instant('createdAt'),
      lines: f.list('lines', TargetLine.fromJson, required: true),
    );
  }

  final String id;
  final String name;
  final String activeFrom;
  final String? note;
  final String createdAt;
  final List<TargetLine> lines;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'activeFrom': activeFrom,
        'note': note,
        'createdAt': createdAt,
        'lines': [for (final line in lines) line.toJson()],
      };
}

final class TargetLine {
  const TargetLine({required this.instrumentId, required this.monthlyAmount});

  factory TargetLine.fromJson(Object? raw, String path) {
    final f = _Fields(raw, path);
    return TargetLine(
      instrumentId: f.string('instrumentId'),
      monthlyAmount: f.string('monthlyAmount'),
    );
  }

  final String instrumentId;
  final String monthlyAmount;

  Map<String, Object?> toJson() =>
      {'instrumentId': instrumentId, 'monthlyAmount': monthlyAmount};
}

/// A deleted target version, kept so a merge does not bring it back.
final class Tombstone {
  const Tombstone({required this.key, required this.hlc});

  factory Tombstone.fromJson(Object? raw, [String path = 'tombstone']) {
    final f = _Fields(raw, path);
    f.oneOf('entity', const [targetEntity]);
    return Tombstone(key: f.string('key', nonEmpty: true), hlc: f.hlc('hlc'));
  }

  final String key;
  final String hlc;

  String get entity => targetEntity;

  Map<String, Object?> toJson() => {'entity': entity, 'key': key, 'hlc': hlc};
}

/// A fund's composition as one block, the unit sync merges.
final class HoldingsBlock {
  const HoldingsBlock({
    required this.instrumentId,
    required this.asOf,
    required this.asOfInferred,
    this.hlc,
    required this.rows,
  });

  factory HoldingsBlock.fromJson(Object? raw, [String path = 'holdings']) {
    final f = _Fields(raw, path);
    return HoldingsBlock(
      instrumentId: f.string('instrumentId', nonEmpty: true),
      asOf: f.day('asOf'),
      asOfInferred: f.boolean('asOfInferred'),
      hlc: f.mark('hlc'),
      rows: f.list('rows', HoldingLine.fromJson, required: true),
    );
  }

  final String instrumentId;
  final String asOf;
  final bool asOfInferred;
  final String? hlc;
  final List<HoldingLine> rows;

  Map<String, Object?> toJson() => {
        'instrumentId': instrumentId,
        'asOf': asOf,
        'asOfInferred': asOfInferred,
        'hlc': hlc,
        'rows': [for (final row in rows) row.toJson()],
      };
}

final class HoldingLine {
  const HoldingLine({
    required this.identity,
    required this.identityKind,
    required this.name,
    required this.weight,
  });

  factory HoldingLine.fromJson(Object? raw, String path) {
    final f = _Fields(raw, path);
    return HoldingLine(
      identity: f.string('identity', nonEmpty: true),
      identityKind: f.oneOf('identityKind', _identityKinds),
      name: f.string('name'),
      weight: f.string('weight'),
    );
  }

  final String identity;
  final String identityKind;
  final String name;
  final String weight;

  Map<String, Object?> toJson() => {
        'identity': identity,
        'identityKind': identityKind,
        'name': name,
        'weight': weight,
      };
}

const _identityKinds = ['ISIN', 'TICKER'];

/// A cached resolution of a published identity to a canonical id.
final class IdentityRecord {
  const IdentityRecord({
    required this.identity,
    required this.identityKind,
    this.canonicalId,
    this.exchCode,
    required this.status,
    required this.source,
    required this.resolvedAt,
  });

  factory IdentityRecord.fromJson(Object? raw, [String path = 'identity']) {
    final f = _Fields(raw, path);
    return IdentityRecord(
      identity: f.string('identity', nonEmpty: true),
      identityKind: f.oneOf('identityKind', _identityKinds),
      canonicalId: f.text('canonicalId'),
      exchCode: f.text('exchCode'),
      status: f.oneOf('status', const ['resolved', 'not-found', 'ambiguous']),
      source: f.string('source'),
      resolvedAt: f.instant('resolvedAt'),
    );
  }

  final String identity;
  final String identityKind;
  final String? canonicalId;
  final String? exchCode;
  final String status;
  final String source;
  final String resolvedAt;

  Map<String, Object?> toJson() => {
        'identity': identity,
        'identityKind': identityKind,
        'canonicalId': canonicalId,
        'exchCode': exchCode,
        'status': status,
        'source': source,
        'resolvedAt': resolvedAt,
      };
}

final class SettingsRecord {
  const SettingsRecord({required this.residence, this.residenceHlc});

  factory SettingsRecord.fromJson(Object? raw, [String path = 'settings']) {
    final f = _Fields(raw, path);
    return SettingsRecord(
      residence: f.string('residence'),
      residenceHlc: f.mark('residenceHlc'),
    );
  }

  final String residence;
  final String? residenceHlc;

  Map<String, Object?> toJson() =>
      {'residence': residence, 'residenceHlc': residenceHlc};
}

/// A device merged from, and the newest mark of it whose effect was seen.
final class Peer {
  const Peer({required this.deviceId, required this.seen});

  factory Peer.fromJson(Object? raw, [String path = 'peer']) {
    final f = _Fields(raw, path);
    return Peer(
        deviceId: f.string('deviceId', nonEmpty: true), seen: f.hlc('seen'));
  }

  final String deviceId;
  final String seen;

  Map<String, Object?> toJson() => {'deviceId': deviceId, 'seen': seen};
}

/// One device's user state, what merge reads on each side.
class SyncState {
  const SyncState({
    required this.deviceId,
    this.peers = const [],
    this.ledger = const [],
    this.instruments = const [],
    this.targets = const [],
    this.tombstones = const [],
    this.holdings = const [],
    this.identities = const [],
    required this.settings,
  });

  factory SyncState.fromJson(Object? raw) {
    final f = _Fields(raw, 'state');
    return SyncState(
      deviceId: f.string('deviceId', nonEmpty: true),
      peers: f.list('peers', Peer.fromJson),
      ledger: f.list('ledger', LedgerRecord.fromJson),
      instruments: f.list('instruments', InstrumentRecord.fromJson),
      targets: f.list('targets', TargetRecord.fromJson),
      tombstones: f.list('tombstones', Tombstone.fromJson),
      holdings: f.list('holdings', HoldingsBlock.fromJson),
      identities: f.list('identities', IdentityRecord.fromJson),
      settings: SettingsRecord.fromJson(f.object('settings'), 'state.settings'),
    );
  }

  final String deviceId;
  final List<Peer> peers;
  final List<LedgerRecord> ledger;
  final List<InstrumentRecord> instruments;
  final List<TargetRecord> targets;
  final List<Tombstone> tombstones;
  final List<HoldingsBlock> holdings;
  final List<IdentityRecord> identities;
  final SettingsRecord settings;

  Map<String, Object?> toJson() => {
        'deviceId': deviceId,
        'peers': [for (final p in peers) p.toJson()],
        'ledger': [for (final r in ledger) r.toJson()],
        'instruments': [for (final i in instruments) i.toJson()],
        'targets': [for (final t in targets) t.toJson()],
        'tombstones': [for (final t in tombstones) t.toJson()],
        'holdings': [for (final h in holdings) h.toJson()],
        'identities': [for (final i in identities) i.toJson()],
        'settings': settings.toJson(),
      };
}

/// A device's state as a file or a request body: its state plus the mark it
/// was exported at.
final class Exchange extends SyncState {
  /// [state] exported at [exportHlc], read back through [parseExchange], so
  /// an export this side writes is refused here exactly as the other side
  /// would refuse it.
  factory Exchange.of(
    SyncState state, {
    String? deviceName,
    required String exportHlc,
  }) =>
      parseExchange(
        Exchange._(state, deviceName: deviceName, exportHlc: exportHlc)
            .toJson(),
      );

  Exchange._(
    SyncState state, {
    required this.deviceName,
    required this.exportHlc,
  }) : super(
          deviceId: state.deviceId,
          peers: state.peers,
          ledger: state.ledger,
          instruments: state.instruments,
          targets: state.targets,
          tombstones: state.tombstones,
          holdings: state.holdings,
          identities: state.identities,
          settings: state.settings,
        );

  final String? deviceName;
  final String exportHlc;

  int get schemaVersion => syncSchemaVersion;

  @override
  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'deviceName': deviceName,
        'exportHlc': exportHlc,
        ...super.toJson(),
      };
}

/// Reads a decoded JSON exchange: the version first, then every field strictly
/// typed (unknown keys are ignored, as zod does), then the rules across rows.
Exchange parseExchange(Object? raw) {
  final version = raw is Map && raw.containsKey('schemaVersion')
      ? raw['schemaVersion']
      : null;
  if (version != syncSchemaVersion) throw UnsupportedSchemaVersion(version);
  final f = _Fields(raw, 'file');
  final state = SyncState.fromJson(raw);
  return _checked(
    Exchange._(
      state,
      deviceName: f.text('deviceName'),
      exportHlc: f.hlc('exportHlc'),
    ),
  );
}

/// Refuses an [incoming] file this same database exported.
void refuseOwnExport(SyncState local, Exchange incoming) {
  if (incoming.deviceId == local.deviceId) throw SameDevice(local.deviceId);
}

Exchange _checked(Exchange file) {
  if (originOf(file.exportHlc) != file.deviceId) {
    throw const InvalidExchange('The export mark belongs to another device');
  }
  final keys = <String>{};
  final legs = <String, int>{};
  for (final row in file.ledger) {
    if (!keys.add(row.key)) {
      throw InvalidExchange('Ledger entry ${row.key} appears twice');
    }
    if (row.linkId case final linkId?) {
      final link = '${row.source}::$linkId';
      legs[link] = (legs[link] ?? 0) + 1;
    }
  }
  for (final MapEntry(key: link, value: count) in legs.entries) {
    if (count != 2) {
      throw InvalidExchange('Linked operation $link has $count legs, not 2');
    }
  }
  final instruments = {for (final i in file.instruments) i.id};
  for (final id in [
    for (final row in file.ledger)
      if (row.instrumentId case final id? when id.isNotEmpty) id,
    for (final block in file.holdings) block.instrumentId,
  ]) {
    if (!instruments.contains(id)) {
      throw InvalidExchange('Instrument $id is referenced but not included');
    }
  }
  return file;
}

// zod 4.6.7 `z.iso.date()` and `z.iso.datetime({ offset: true })`, verbatim.
const _date = r'(?:(?:\d\d[2468][048]|\d\d[13579][26]|\d\d0[48]|[02468][048]00'
    r'|[13579][26]00)-02-29|\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\d|3[01])'
    r'|(?:0[469]|11)-(?:0[1-9]|[12]\d|30)|(?:02)-(?:0[1-9]|1\d|2[0-8])))';
final _isoDay = RegExp('^$_date\$');
final _isoInstant = RegExp(
  '^${_date}T(?:(?:[01]\\d|2[0-3]):[0-5]\\d:[0-5]\\d(?:\\.\\d+)?'
  '(?:Z|([+-](?:[01]\\d|2[0-3]):[0-5]\\d)))\$',
);

/// Whether [value] is an ISO day as the exchange writes it (`YYYY-MM-DD`).
bool isIsoDay(String value) => _isoDay.hasMatch(value);

/// Whether [value] is an ISO instant with seconds and a zone, as the exchange
/// writes it. Only then is it handed to [DateTime.parse].
bool isIsoInstant(String value) => _isoInstant.hasMatch(value);

/// The fields of one JSON object, read with zod's rules: an absent key takes
/// its default, `null` is a value (and only nullable fields accept it).
final class _Fields {
  _Fields(Object? raw, this.path)
      : _map = raw is Map<String, Object?>
            ? raw
            : throw InvalidExchange('$path is not an object');

  final Map<String, Object?> _map;
  final String path;

  Never _fail(String key, String what) =>
      throw InvalidExchange('$path.$key: $what');

  String string(String key, {bool nonEmpty = false, String? orElse}) {
    if (!_map.containsKey(key) && orElse != null) return orElse;
    final value = _map[key];
    if (value is! String) _fail(key, 'expected a string');
    if (nonEmpty && value.isEmpty) _fail(key, 'must not be empty');
    return value;
  }

  String? text(String key) {
    final value = _map[key];
    if (value == null || value is String) return value as String?;
    _fail(key, 'expected a string or null');
  }

  String oneOf(String key, List<String> values, {String? orElse}) {
    final value = string(key, orElse: orElse);
    if (!values.contains(value)) _fail(key, 'expected one of $values');
    return value;
  }

  bool boolean(String key, {bool? orElse}) {
    if (!_map.containsKey(key) && orElse != null) return orElse;
    final value = _map[key];
    if (value is! bool) _fail(key, 'expected a boolean');
    return value;
  }

  String hlc(String key) {
    final value = string(key);
    if (!isHlc(value)) _fail(key, 'not a sync mark');
    return value;
  }

  String? mark(String key) {
    final value = text(key);
    if (value != null && !isHlc(value)) _fail(key, 'not a sync mark');
    return value;
  }

  String instant(String key) {
    final value = string(key);
    if (!isIsoInstant(value)) _fail(key, 'not an ISO instant');
    return value;
  }

  String day(String key) {
    final value = string(key);
    if (!isIsoDay(value)) _fail(key, 'not an ISO day');
    return value;
  }

  Object? object(String key) => _map[key];

  List<T> list<T>(
    String key,
    T Function(Object? raw, String path) each, {
    bool required = false,
  }) {
    if (!_map.containsKey(key) && !required) return const [];
    final value = _map[key];
    if (value is! List) _fail(key, 'expected a list');
    return [
      for (var i = 0; i < value.length; i += 1)
        each(value[i], '$path.$key[$i]'),
    ];
  }
}
