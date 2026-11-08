// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prices_database.dart';

// ignore_for_file: type=lint
class PriceSnapshot extends Table
    with TableInfo<PriceSnapshot, PriceSnapshotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  PriceSnapshot(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _instrumentIdMeta = const VerificationMeta(
    'instrumentId',
  );
  late final GeneratedColumn<String> instrumentId = GeneratedColumn<String>(
    'instrumentId',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  late final GeneratedColumn<String> price = GeneratedColumn<String>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _asOfMeta = const VerificationMeta('asOf');
  late final GeneratedColumn<DateTime> asOf = GeneratedColumn<DateTime>(
    'asOf',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'YAHOO\'',
    defaultValue: const CustomExpression('\'YAHOO\''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'createdAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    instrumentId,
    price,
    currency,
    asOf,
    source,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'PriceSnapshot';
  @override
  VerificationContext validateIntegrity(
    Insertable<PriceSnapshotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('instrumentId')) {
      context.handle(
        _instrumentIdMeta,
        instrumentId.isAcceptableOrUnknown(
          data['instrumentId']!,
          _instrumentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_instrumentIdMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('asOf')) {
      context.handle(
        _asOfMeta,
        asOf.isAcceptableOrUnknown(data['asOf']!, _asOfMeta),
      );
    } else if (isInserting) {
      context.missing(_asOfMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('createdAt')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['createdAt']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PriceSnapshotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PriceSnapshotRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      instrumentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instrumentId'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}price'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      asOf: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}asOf'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}createdAt'],
      )!,
    );
  }

  @override
  PriceSnapshot createAlias(String alias) {
    return PriceSnapshot(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class PriceSnapshotRow extends DataClass
    implements Insertable<PriceSnapshotRow> {
  final String id;
  final String instrumentId;
  final String price;
  final String currency;
  final DateTime asOf;
  final String source;
  final DateTime createdAt;
  const PriceSnapshotRow({
    required this.id,
    required this.instrumentId,
    required this.price,
    required this.currency,
    required this.asOf,
    required this.source,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['instrumentId'] = Variable<String>(instrumentId);
    map['price'] = Variable<String>(price);
    map['currency'] = Variable<String>(currency);
    map['asOf'] = Variable<DateTime>(asOf);
    map['source'] = Variable<String>(source);
    map['createdAt'] = Variable<DateTime>(createdAt);
    return map;
  }

  PriceSnapshotCompanion toCompanion(bool nullToAbsent) {
    return PriceSnapshotCompanion(
      id: Value(id),
      instrumentId: Value(instrumentId),
      price: Value(price),
      currency: Value(currency),
      asOf: Value(asOf),
      source: Value(source),
      createdAt: Value(createdAt),
    );
  }

  factory PriceSnapshotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PriceSnapshotRow(
      id: serializer.fromJson<String>(json['id']),
      instrumentId: serializer.fromJson<String>(json['instrumentId']),
      price: serializer.fromJson<String>(json['price']),
      currency: serializer.fromJson<String>(json['currency']),
      asOf: serializer.fromJson<DateTime>(json['asOf']),
      source: serializer.fromJson<String>(json['source']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'instrumentId': serializer.toJson<String>(instrumentId),
      'price': serializer.toJson<String>(price),
      'currency': serializer.toJson<String>(currency),
      'asOf': serializer.toJson<DateTime>(asOf),
      'source': serializer.toJson<String>(source),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PriceSnapshotRow copyWith({
    String? id,
    String? instrumentId,
    String? price,
    String? currency,
    DateTime? asOf,
    String? source,
    DateTime? createdAt,
  }) => PriceSnapshotRow(
    id: id ?? this.id,
    instrumentId: instrumentId ?? this.instrumentId,
    price: price ?? this.price,
    currency: currency ?? this.currency,
    asOf: asOf ?? this.asOf,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
  );
  PriceSnapshotRow copyWithCompanion(PriceSnapshotCompanion data) {
    return PriceSnapshotRow(
      id: data.id.present ? data.id.value : this.id,
      instrumentId: data.instrumentId.present
          ? data.instrumentId.value
          : this.instrumentId,
      price: data.price.present ? data.price.value : this.price,
      currency: data.currency.present ? data.currency.value : this.currency,
      asOf: data.asOf.present ? data.asOf.value : this.asOf,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PriceSnapshotRow(')
          ..write('id: $id, ')
          ..write('instrumentId: $instrumentId, ')
          ..write('price: $price, ')
          ..write('currency: $currency, ')
          ..write('asOf: $asOf, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, instrumentId, price, currency, asOf, source, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PriceSnapshotRow &&
          other.id == this.id &&
          other.instrumentId == this.instrumentId &&
          other.price == this.price &&
          other.currency == this.currency &&
          other.asOf == this.asOf &&
          other.source == this.source &&
          other.createdAt == this.createdAt);
}

class PriceSnapshotCompanion extends UpdateCompanion<PriceSnapshotRow> {
  final Value<String> id;
  final Value<String> instrumentId;
  final Value<String> price;
  final Value<String> currency;
  final Value<DateTime> asOf;
  final Value<String> source;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PriceSnapshotCompanion({
    this.id = const Value.absent(),
    this.instrumentId = const Value.absent(),
    this.price = const Value.absent(),
    this.currency = const Value.absent(),
    this.asOf = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PriceSnapshotCompanion.insert({
    required String id,
    required String instrumentId,
    required String price,
    required String currency,
    required DateTime asOf,
    this.source = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       instrumentId = Value(instrumentId),
       price = Value(price),
       currency = Value(currency),
       asOf = Value(asOf),
       createdAt = Value(createdAt);
  static Insertable<PriceSnapshotRow> custom({
    Expression<String>? id,
    Expression<String>? instrumentId,
    Expression<String>? price,
    Expression<String>? currency,
    Expression<DateTime>? asOf,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (instrumentId != null) 'instrumentId': instrumentId,
      if (price != null) 'price': price,
      if (currency != null) 'currency': currency,
      if (asOf != null) 'asOf': asOf,
      if (source != null) 'source': source,
      if (createdAt != null) 'createdAt': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PriceSnapshotCompanion copyWith({
    Value<String>? id,
    Value<String>? instrumentId,
    Value<String>? price,
    Value<String>? currency,
    Value<DateTime>? asOf,
    Value<String>? source,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PriceSnapshotCompanion(
      id: id ?? this.id,
      instrumentId: instrumentId ?? this.instrumentId,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      asOf: asOf ?? this.asOf,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (instrumentId.present) {
      map['instrumentId'] = Variable<String>(instrumentId.value);
    }
    if (price.present) {
      map['price'] = Variable<String>(price.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (asOf.present) {
      map['asOf'] = Variable<DateTime>(asOf.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdAt.present) {
      map['createdAt'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PriceSnapshotCompanion(')
          ..write('id: $id, ')
          ..write('instrumentId: $instrumentId, ')
          ..write('price: $price, ')
          ..write('currency: $currency, ')
          ..write('asOf: $asOf, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class PriceSeries extends Table with TableInfo<PriceSeries, PriceSeriesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  PriceSeries(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _instrumentIdMeta = const VerificationMeta(
    'instrumentId',
  );
  late final GeneratedColumn<String> instrumentId = GeneratedColumn<String>(
    'instrumentId',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _seriesVersionMeta = const VerificationMeta(
    'seriesVersion',
  );
  late final GeneratedColumn<String> seriesVersion = GeneratedColumn<String>(
    'seriesVersion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [instrumentId, seriesVersion];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'PriceSeries';
  @override
  VerificationContext validateIntegrity(
    Insertable<PriceSeriesRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('instrumentId')) {
      context.handle(
        _instrumentIdMeta,
        instrumentId.isAcceptableOrUnknown(
          data['instrumentId']!,
          _instrumentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_instrumentIdMeta);
    }
    if (data.containsKey('seriesVersion')) {
      context.handle(
        _seriesVersionMeta,
        seriesVersion.isAcceptableOrUnknown(
          data['seriesVersion']!,
          _seriesVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_seriesVersionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {instrumentId};
  @override
  PriceSeriesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PriceSeriesRow(
      instrumentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instrumentId'],
      )!,
      seriesVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seriesVersion'],
      )!,
    );
  }

  @override
  PriceSeries createAlias(String alias) {
    return PriceSeries(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class PriceSeriesRow extends DataClass implements Insertable<PriceSeriesRow> {
  final String instrumentId;
  final String seriesVersion;
  const PriceSeriesRow({
    required this.instrumentId,
    required this.seriesVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['instrumentId'] = Variable<String>(instrumentId);
    map['seriesVersion'] = Variable<String>(seriesVersion);
    return map;
  }

  PriceSeriesCompanion toCompanion(bool nullToAbsent) {
    return PriceSeriesCompanion(
      instrumentId: Value(instrumentId),
      seriesVersion: Value(seriesVersion),
    );
  }

  factory PriceSeriesRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PriceSeriesRow(
      instrumentId: serializer.fromJson<String>(json['instrumentId']),
      seriesVersion: serializer.fromJson<String>(json['seriesVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'instrumentId': serializer.toJson<String>(instrumentId),
      'seriesVersion': serializer.toJson<String>(seriesVersion),
    };
  }

  PriceSeriesRow copyWith({String? instrumentId, String? seriesVersion}) =>
      PriceSeriesRow(
        instrumentId: instrumentId ?? this.instrumentId,
        seriesVersion: seriesVersion ?? this.seriesVersion,
      );
  PriceSeriesRow copyWithCompanion(PriceSeriesCompanion data) {
    return PriceSeriesRow(
      instrumentId: data.instrumentId.present
          ? data.instrumentId.value
          : this.instrumentId,
      seriesVersion: data.seriesVersion.present
          ? data.seriesVersion.value
          : this.seriesVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PriceSeriesRow(')
          ..write('instrumentId: $instrumentId, ')
          ..write('seriesVersion: $seriesVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(instrumentId, seriesVersion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PriceSeriesRow &&
          other.instrumentId == this.instrumentId &&
          other.seriesVersion == this.seriesVersion);
}

class PriceSeriesCompanion extends UpdateCompanion<PriceSeriesRow> {
  final Value<String> instrumentId;
  final Value<String> seriesVersion;
  final Value<int> rowid;
  const PriceSeriesCompanion({
    this.instrumentId = const Value.absent(),
    this.seriesVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PriceSeriesCompanion.insert({
    required String instrumentId,
    required String seriesVersion,
    this.rowid = const Value.absent(),
  }) : instrumentId = Value(instrumentId),
       seriesVersion = Value(seriesVersion);
  static Insertable<PriceSeriesRow> custom({
    Expression<String>? instrumentId,
    Expression<String>? seriesVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (instrumentId != null) 'instrumentId': instrumentId,
      if (seriesVersion != null) 'seriesVersion': seriesVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PriceSeriesCompanion copyWith({
    Value<String>? instrumentId,
    Value<String>? seriesVersion,
    Value<int>? rowid,
  }) {
    return PriceSeriesCompanion(
      instrumentId: instrumentId ?? this.instrumentId,
      seriesVersion: seriesVersion ?? this.seriesVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (instrumentId.present) {
      map['instrumentId'] = Variable<String>(instrumentId.value);
    }
    if (seriesVersion.present) {
      map['seriesVersion'] = Variable<String>(seriesVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PriceSeriesCompanion(')
          ..write('instrumentId: $instrumentId, ')
          ..write('seriesVersion: $seriesVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$PricesDatabase extends GeneratedDatabase {
  _$PricesDatabase(QueryExecutor e) : super(e);
  late final PriceSnapshot priceSnapshot = PriceSnapshot(this);
  late final Index priceSnapshotInstrumentIdIdx = Index(
    'PriceSnapshot_instrumentId_idx',
    'CREATE INDEX PriceSnapshot_instrumentId_idx ON PriceSnapshot (instrumentId)',
  );
  late final Index priceSnapshotAsOfIdx = Index(
    'PriceSnapshot_asOf_idx',
    'CREATE INDEX PriceSnapshot_asOf_idx ON PriceSnapshot (asOf)',
  );
  late final Index priceSnapshotInstrumentIdAsOfKey = Index(
    'PriceSnapshot_instrumentId_asOf_key',
    'CREATE UNIQUE INDEX PriceSnapshot_instrumentId_asOf_key ON PriceSnapshot (instrumentId, asOf)',
  );
  late final PriceSeries priceSeries = PriceSeries(this);
  Selectable<PriceSnapshotRow> latestPrices() {
    return customSelect(
      'SELECT p.* FROM PriceSnapshot AS p WHERE p.asOf = (SELECT MAX(asOf) FROM PriceSnapshot WHERE instrumentId = p.instrumentId)',
      variables: [],
      readsFrom: {this.priceSnapshot},
    ).asyncMap(this.priceSnapshot.mapFromRow);
  }

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    priceSnapshot,
    priceSnapshotInstrumentIdIdx,
    priceSnapshotAsOfIdx,
    priceSnapshotInstrumentIdAsOfKey,
    priceSeries,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}
