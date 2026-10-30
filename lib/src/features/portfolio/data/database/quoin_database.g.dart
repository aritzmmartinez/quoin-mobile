// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quoin_database.dart';

// ignore_for_file: type=lint
class Instrument extends Table with TableInfo<Instrument, InstrumentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Instrument(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _assetClassMeta = const VerificationMeta(
    'assetClass',
  );
  late final GeneratedColumn<String> assetClass = GeneratedColumn<String>(
    'assetClass',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _quoteSymbolMeta = const VerificationMeta(
    'quoteSymbol',
  );
  late final GeneratedColumn<String> quoteSymbol = GeneratedColumn<String>(
    'quoteSymbol',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _exposureKindMeta = const VerificationMeta(
    'exposureKind',
  );
  late final GeneratedColumn<String> exposureKind = GeneratedColumn<String>(
    'exposureKind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _exposureLeafIdMeta = const VerificationMeta(
    'exposureLeafId',
  );
  late final GeneratedColumn<String> exposureLeafId = GeneratedColumn<String>(
    'exposureLeafId',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _terMeta = const VerificationMeta('ter');
  late final GeneratedColumn<String> ter = GeneratedColumn<String>(
    'ter',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _hedgedToBaseMeta = const VerificationMeta(
    'hedgedToBase',
  );
  late final GeneratedColumn<bool> hedgedToBase = GeneratedColumn<bool>(
    'hedgedToBase',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _thesisMeta = const VerificationMeta('thesis');
  late final GeneratedColumn<String> thesis = GeneratedColumn<String>(
    'thesis',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'CORE\' CHECK (thesis IN (\'CORE\', \'CONVICTION\', \'TACTICAL\'))',
    defaultValue: const CustomExpression('\'CORE\''),
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
    name,
    type,
    assetClass,
    quoteSymbol,
    exposureKind,
    exposureLeafId,
    ter,
    hedgedToBase,
    thesis,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Instrument';
  @override
  VerificationContext validateIntegrity(
    Insertable<InstrumentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('assetClass')) {
      context.handle(
        _assetClassMeta,
        assetClass.isAcceptableOrUnknown(data['assetClass']!, _assetClassMeta),
      );
    }
    if (data.containsKey('quoteSymbol')) {
      context.handle(
        _quoteSymbolMeta,
        quoteSymbol.isAcceptableOrUnknown(
          data['quoteSymbol']!,
          _quoteSymbolMeta,
        ),
      );
    }
    if (data.containsKey('exposureKind')) {
      context.handle(
        _exposureKindMeta,
        exposureKind.isAcceptableOrUnknown(
          data['exposureKind']!,
          _exposureKindMeta,
        ),
      );
    }
    if (data.containsKey('exposureLeafId')) {
      context.handle(
        _exposureLeafIdMeta,
        exposureLeafId.isAcceptableOrUnknown(
          data['exposureLeafId']!,
          _exposureLeafIdMeta,
        ),
      );
    }
    if (data.containsKey('ter')) {
      context.handle(
        _terMeta,
        ter.isAcceptableOrUnknown(data['ter']!, _terMeta),
      );
    }
    if (data.containsKey('hedgedToBase')) {
      context.handle(
        _hedgedToBaseMeta,
        hedgedToBase.isAcceptableOrUnknown(
          data['hedgedToBase']!,
          _hedgedToBaseMeta,
        ),
      );
    }
    if (data.containsKey('thesis')) {
      context.handle(
        _thesisMeta,
        thesis.isAcceptableOrUnknown(data['thesis']!, _thesisMeta),
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
  InstrumentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstrumentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      assetClass: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assetClass'],
      ),
      quoteSymbol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quoteSymbol'],
      ),
      exposureKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exposureKind'],
      ),
      exposureLeafId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exposureLeafId'],
      ),
      ter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ter'],
      ),
      hedgedToBase: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hedgedToBase'],
      )!,
      thesis: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thesis'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}createdAt'],
      )!,
    );
  }

  @override
  Instrument createAlias(String alias) {
    return Instrument(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class InstrumentRow extends DataClass implements Insertable<InstrumentRow> {
  final String id;
  final String name;
  final String type;
  final String? assetClass;
  final String? quoteSymbol;
  final String? exposureKind;
  final String? exposureLeafId;
  final String? ter;
  final bool hedgedToBase;
  final String thesis;
  final DateTime createdAt;
  const InstrumentRow({
    required this.id,
    required this.name,
    required this.type,
    this.assetClass,
    this.quoteSymbol,
    this.exposureKind,
    this.exposureLeafId,
    this.ter,
    required this.hedgedToBase,
    required this.thesis,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || assetClass != null) {
      map['assetClass'] = Variable<String>(assetClass);
    }
    if (!nullToAbsent || quoteSymbol != null) {
      map['quoteSymbol'] = Variable<String>(quoteSymbol);
    }
    if (!nullToAbsent || exposureKind != null) {
      map['exposureKind'] = Variable<String>(exposureKind);
    }
    if (!nullToAbsent || exposureLeafId != null) {
      map['exposureLeafId'] = Variable<String>(exposureLeafId);
    }
    if (!nullToAbsent || ter != null) {
      map['ter'] = Variable<String>(ter);
    }
    map['hedgedToBase'] = Variable<bool>(hedgedToBase);
    map['thesis'] = Variable<String>(thesis);
    map['createdAt'] = Variable<DateTime>(createdAt);
    return map;
  }

  InstrumentCompanion toCompanion(bool nullToAbsent) {
    return InstrumentCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      assetClass: assetClass == null && nullToAbsent
          ? const Value.absent()
          : Value(assetClass),
      quoteSymbol: quoteSymbol == null && nullToAbsent
          ? const Value.absent()
          : Value(quoteSymbol),
      exposureKind: exposureKind == null && nullToAbsent
          ? const Value.absent()
          : Value(exposureKind),
      exposureLeafId: exposureLeafId == null && nullToAbsent
          ? const Value.absent()
          : Value(exposureLeafId),
      ter: ter == null && nullToAbsent ? const Value.absent() : Value(ter),
      hedgedToBase: Value(hedgedToBase),
      thesis: Value(thesis),
      createdAt: Value(createdAt),
    );
  }

  factory InstrumentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstrumentRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      assetClass: serializer.fromJson<String?>(json['assetClass']),
      quoteSymbol: serializer.fromJson<String?>(json['quoteSymbol']),
      exposureKind: serializer.fromJson<String?>(json['exposureKind']),
      exposureLeafId: serializer.fromJson<String?>(json['exposureLeafId']),
      ter: serializer.fromJson<String?>(json['ter']),
      hedgedToBase: serializer.fromJson<bool>(json['hedgedToBase']),
      thesis: serializer.fromJson<String>(json['thesis']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'assetClass': serializer.toJson<String?>(assetClass),
      'quoteSymbol': serializer.toJson<String?>(quoteSymbol),
      'exposureKind': serializer.toJson<String?>(exposureKind),
      'exposureLeafId': serializer.toJson<String?>(exposureLeafId),
      'ter': serializer.toJson<String?>(ter),
      'hedgedToBase': serializer.toJson<bool>(hedgedToBase),
      'thesis': serializer.toJson<String>(thesis),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  InstrumentRow copyWith({
    String? id,
    String? name,
    String? type,
    Value<String?> assetClass = const Value.absent(),
    Value<String?> quoteSymbol = const Value.absent(),
    Value<String?> exposureKind = const Value.absent(),
    Value<String?> exposureLeafId = const Value.absent(),
    Value<String?> ter = const Value.absent(),
    bool? hedgedToBase,
    String? thesis,
    DateTime? createdAt,
  }) => InstrumentRow(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    assetClass: assetClass.present ? assetClass.value : this.assetClass,
    quoteSymbol: quoteSymbol.present ? quoteSymbol.value : this.quoteSymbol,
    exposureKind: exposureKind.present ? exposureKind.value : this.exposureKind,
    exposureLeafId: exposureLeafId.present
        ? exposureLeafId.value
        : this.exposureLeafId,
    ter: ter.present ? ter.value : this.ter,
    hedgedToBase: hedgedToBase ?? this.hedgedToBase,
    thesis: thesis ?? this.thesis,
    createdAt: createdAt ?? this.createdAt,
  );
  InstrumentRow copyWithCompanion(InstrumentCompanion data) {
    return InstrumentRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      assetClass: data.assetClass.present
          ? data.assetClass.value
          : this.assetClass,
      quoteSymbol: data.quoteSymbol.present
          ? data.quoteSymbol.value
          : this.quoteSymbol,
      exposureKind: data.exposureKind.present
          ? data.exposureKind.value
          : this.exposureKind,
      exposureLeafId: data.exposureLeafId.present
          ? data.exposureLeafId.value
          : this.exposureLeafId,
      ter: data.ter.present ? data.ter.value : this.ter,
      hedgedToBase: data.hedgedToBase.present
          ? data.hedgedToBase.value
          : this.hedgedToBase,
      thesis: data.thesis.present ? data.thesis.value : this.thesis,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstrumentRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('assetClass: $assetClass, ')
          ..write('quoteSymbol: $quoteSymbol, ')
          ..write('exposureKind: $exposureKind, ')
          ..write('exposureLeafId: $exposureLeafId, ')
          ..write('ter: $ter, ')
          ..write('hedgedToBase: $hedgedToBase, ')
          ..write('thesis: $thesis, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    assetClass,
    quoteSymbol,
    exposureKind,
    exposureLeafId,
    ter,
    hedgedToBase,
    thesis,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstrumentRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.assetClass == this.assetClass &&
          other.quoteSymbol == this.quoteSymbol &&
          other.exposureKind == this.exposureKind &&
          other.exposureLeafId == this.exposureLeafId &&
          other.ter == this.ter &&
          other.hedgedToBase == this.hedgedToBase &&
          other.thesis == this.thesis &&
          other.createdAt == this.createdAt);
}

class InstrumentCompanion extends UpdateCompanion<InstrumentRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> type;
  final Value<String?> assetClass;
  final Value<String?> quoteSymbol;
  final Value<String?> exposureKind;
  final Value<String?> exposureLeafId;
  final Value<String?> ter;
  final Value<bool> hedgedToBase;
  final Value<String> thesis;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const InstrumentCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.assetClass = const Value.absent(),
    this.quoteSymbol = const Value.absent(),
    this.exposureKind = const Value.absent(),
    this.exposureLeafId = const Value.absent(),
    this.ter = const Value.absent(),
    this.hedgedToBase = const Value.absent(),
    this.thesis = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstrumentCompanion.insert({
    required String id,
    required String name,
    required String type,
    this.assetClass = const Value.absent(),
    this.quoteSymbol = const Value.absent(),
    this.exposureKind = const Value.absent(),
    this.exposureLeafId = const Value.absent(),
    this.ter = const Value.absent(),
    this.hedgedToBase = const Value.absent(),
    this.thesis = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type),
       createdAt = Value(createdAt);
  static Insertable<InstrumentRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? assetClass,
    Expression<String>? quoteSymbol,
    Expression<String>? exposureKind,
    Expression<String>? exposureLeafId,
    Expression<String>? ter,
    Expression<bool>? hedgedToBase,
    Expression<String>? thesis,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (assetClass != null) 'assetClass': assetClass,
      if (quoteSymbol != null) 'quoteSymbol': quoteSymbol,
      if (exposureKind != null) 'exposureKind': exposureKind,
      if (exposureLeafId != null) 'exposureLeafId': exposureLeafId,
      if (ter != null) 'ter': ter,
      if (hedgedToBase != null) 'hedgedToBase': hedgedToBase,
      if (thesis != null) 'thesis': thesis,
      if (createdAt != null) 'createdAt': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstrumentCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? type,
    Value<String?>? assetClass,
    Value<String?>? quoteSymbol,
    Value<String?>? exposureKind,
    Value<String?>? exposureLeafId,
    Value<String?>? ter,
    Value<bool>? hedgedToBase,
    Value<String>? thesis,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return InstrumentCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      assetClass: assetClass ?? this.assetClass,
      quoteSymbol: quoteSymbol ?? this.quoteSymbol,
      exposureKind: exposureKind ?? this.exposureKind,
      exposureLeafId: exposureLeafId ?? this.exposureLeafId,
      ter: ter ?? this.ter,
      hedgedToBase: hedgedToBase ?? this.hedgedToBase,
      thesis: thesis ?? this.thesis,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (assetClass.present) {
      map['assetClass'] = Variable<String>(assetClass.value);
    }
    if (quoteSymbol.present) {
      map['quoteSymbol'] = Variable<String>(quoteSymbol.value);
    }
    if (exposureKind.present) {
      map['exposureKind'] = Variable<String>(exposureKind.value);
    }
    if (exposureLeafId.present) {
      map['exposureLeafId'] = Variable<String>(exposureLeafId.value);
    }
    if (ter.present) {
      map['ter'] = Variable<String>(ter.value);
    }
    if (hedgedToBase.present) {
      map['hedgedToBase'] = Variable<bool>(hedgedToBase.value);
    }
    if (thesis.present) {
      map['thesis'] = Variable<String>(thesis.value);
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
    return (StringBuffer('InstrumentCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('assetClass: $assetClass, ')
          ..write('quoteSymbol: $quoteSymbol, ')
          ..write('exposureKind: $exposureKind, ')
          ..write('exposureLeafId: $exposureLeafId, ')
          ..write('ter: $ter, ')
          ..write('hedgedToBase: $hedgedToBase, ')
          ..write('thesis: $thesis, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class LedgerEntry extends Table with TableInfo<LedgerEntry, LedgerEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  LedgerEntry(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  late final GeneratedColumn<DateTime> ts = GeneratedColumn<DateTime>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _instrumentIdMeta = const VerificationMeta(
    'instrumentId',
  );
  late final GeneratedColumn<String> instrumentId = GeneratedColumn<String>(
    'instrumentId',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'REFERENCES Instrument(id)ON UPDATE CASCADE ON DELETE SET NULL',
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  late final GeneratedColumn<String> quantity = GeneratedColumn<String>(
    'quantity',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  late final GeneratedColumn<String> price = GeneratedColumn<String>(
    'price',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _grossAmountMeta = const VerificationMeta(
    'grossAmount',
  );
  late final GeneratedColumn<String> grossAmount = GeneratedColumn<String>(
    'grossAmount',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _feesMeta = const VerificationMeta('fees');
  late final GeneratedColumn<String> fees = GeneratedColumn<String>(
    'fees',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'0\'',
    defaultValue: const CustomExpression('\'0\''),
  );
  static const VerificationMeta _taxWithheldMeta = const VerificationMeta(
    'taxWithheld',
  );
  late final GeneratedColumn<String> taxWithheld = GeneratedColumn<String>(
    'taxWithheld',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'0\'',
    defaultValue: const CustomExpression('\'0\''),
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
  static const VerificationMeta _fxSourceMeta = const VerificationMeta(
    'fxSource',
  );
  late final GeneratedColumn<String> fxSource = GeneratedColumn<String>(
    'fxSource',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'IDENTITY\' CONSTRAINT LedgerEntry_fxSource_check CHECK (fxSource IN (\'IDENTITY\', \'BROKER\', \'ECB\', \'MARKET\', \'MANUAL\'))',
    defaultValue: const CustomExpression('\'IDENTITY\''),
  );
  static const VerificationMeta _fxDateMeta = const VerificationMeta('fxDate');
  late final GeneratedColumn<String> fxDate = GeneratedColumn<String>(
    'fxDate',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _fxRateMeta = const VerificationMeta('fxRate');
  late final GeneratedColumn<String> fxRate = GeneratedColumn<String>(
    'fxRate',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _fxDirectionMeta = const VerificationMeta(
    'fxDirection',
  );
  late final GeneratedColumn<String> fxDirection = GeneratedColumn<String>(
    'fxDirection',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CONSTRAINT LedgerEntry_fxDirection_check CHECK (fxDirection IN (\'QUOTE_PER_BASE\', \'BASE_PER_QUOTE\'))',
  );
  static const VerificationMeta _originalAmountMeta = const VerificationMeta(
    'originalAmount',
  );
  late final GeneratedColumn<String> originalAmount = GeneratedColumn<String>(
    'originalAmount',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _originalCurrencyMeta = const VerificationMeta(
    'originalCurrency',
  );
  late final GeneratedColumn<String> originalCurrency = GeneratedColumn<String>(
    'originalCurrency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _valuationSourceMeta = const VerificationMeta(
    'valuationSource',
  );
  late final GeneratedColumn<String> valuationSource = GeneratedColumn<String>(
    'valuationSource',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _linkIdMeta = const VerificationMeta('linkId');
  late final GeneratedColumn<String> linkId = GeneratedColumn<String>(
    'linkId',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _linkKindMeta = const VerificationMeta(
    'linkKind',
  );
  late final GeneratedColumn<String> linkKind = GeneratedColumn<String>(
    'linkKind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _fundingMeta = const VerificationMeta(
    'funding',
  );
  late final GeneratedColumn<String> funding = GeneratedColumn<String>(
    'funding',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'CASH\' CONSTRAINT LedgerEntry_funding_check CHECK (funding IN (\'CASH\', \'IN_KIND\'))',
    defaultValue: const CustomExpression('\'CASH\''),
  );
  static const VerificationMeta _accountMeta = const VerificationMeta(
    'account',
  );
  late final GeneratedColumn<String> account = GeneratedColumn<String>(
    'account',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'trade-republic\'',
    defaultValue: const CustomExpression('\'trade-republic\''),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'MANUAL\'',
    defaultValue: const CustomExpression('\'MANUAL\''),
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'externalId',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
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
    ts,
    type,
    instrumentId,
    quantity,
    price,
    grossAmount,
    fees,
    taxWithheld,
    currency,
    fxSource,
    fxDate,
    fxRate,
    fxDirection,
    originalAmount,
    originalCurrency,
    valuationSource,
    linkId,
    linkKind,
    funding,
    account,
    source,
    externalId,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'LedgerEntry';
  @override
  VerificationContext validateIntegrity(
    Insertable<LedgerEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('instrumentId')) {
      context.handle(
        _instrumentIdMeta,
        instrumentId.isAcceptableOrUnknown(
          data['instrumentId']!,
          _instrumentIdMeta,
        ),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    }
    if (data.containsKey('grossAmount')) {
      context.handle(
        _grossAmountMeta,
        grossAmount.isAcceptableOrUnknown(
          data['grossAmount']!,
          _grossAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_grossAmountMeta);
    }
    if (data.containsKey('fees')) {
      context.handle(
        _feesMeta,
        fees.isAcceptableOrUnknown(data['fees']!, _feesMeta),
      );
    }
    if (data.containsKey('taxWithheld')) {
      context.handle(
        _taxWithheldMeta,
        taxWithheld.isAcceptableOrUnknown(
          data['taxWithheld']!,
          _taxWithheldMeta,
        ),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('fxSource')) {
      context.handle(
        _fxSourceMeta,
        fxSource.isAcceptableOrUnknown(data['fxSource']!, _fxSourceMeta),
      );
    }
    if (data.containsKey('fxDate')) {
      context.handle(
        _fxDateMeta,
        fxDate.isAcceptableOrUnknown(data['fxDate']!, _fxDateMeta),
      );
    }
    if (data.containsKey('fxRate')) {
      context.handle(
        _fxRateMeta,
        fxRate.isAcceptableOrUnknown(data['fxRate']!, _fxRateMeta),
      );
    }
    if (data.containsKey('fxDirection')) {
      context.handle(
        _fxDirectionMeta,
        fxDirection.isAcceptableOrUnknown(
          data['fxDirection']!,
          _fxDirectionMeta,
        ),
      );
    }
    if (data.containsKey('originalAmount')) {
      context.handle(
        _originalAmountMeta,
        originalAmount.isAcceptableOrUnknown(
          data['originalAmount']!,
          _originalAmountMeta,
        ),
      );
    }
    if (data.containsKey('originalCurrency')) {
      context.handle(
        _originalCurrencyMeta,
        originalCurrency.isAcceptableOrUnknown(
          data['originalCurrency']!,
          _originalCurrencyMeta,
        ),
      );
    }
    if (data.containsKey('valuationSource')) {
      context.handle(
        _valuationSourceMeta,
        valuationSource.isAcceptableOrUnknown(
          data['valuationSource']!,
          _valuationSourceMeta,
        ),
      );
    }
    if (data.containsKey('linkId')) {
      context.handle(
        _linkIdMeta,
        linkId.isAcceptableOrUnknown(data['linkId']!, _linkIdMeta),
      );
    }
    if (data.containsKey('linkKind')) {
      context.handle(
        _linkKindMeta,
        linkKind.isAcceptableOrUnknown(data['linkKind']!, _linkKindMeta),
      );
    }
    if (data.containsKey('funding')) {
      context.handle(
        _fundingMeta,
        funding.isAcceptableOrUnknown(data['funding']!, _fundingMeta),
      );
    }
    if (data.containsKey('account')) {
      context.handle(
        _accountMeta,
        account.isAcceptableOrUnknown(data['account']!, _accountMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('externalId')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['externalId']!, _externalIdMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
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
  LedgerEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ts'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      instrumentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instrumentId'],
      ),
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quantity'],
      ),
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}price'],
      ),
      grossAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grossAmount'],
      )!,
      fees: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fees'],
      )!,
      taxWithheld: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}taxWithheld'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      fxSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fxSource'],
      )!,
      fxDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fxDate'],
      ),
      fxRate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fxRate'],
      ),
      fxDirection: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fxDirection'],
      ),
      originalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}originalAmount'],
      ),
      originalCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}originalCurrency'],
      ),
      valuationSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valuationSource'],
      ),
      linkId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linkId'],
      ),
      linkKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linkKind'],
      ),
      funding: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}funding'],
      )!,
      account: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}externalId'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}createdAt'],
      )!,
    );
  }

  @override
  LedgerEntry createAlias(String alias) {
    return LedgerEntry(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'CONSTRAINT LedgerEntry_type_check CHECK(type IN (\'BUY\', \'SELL\', \'DIVIDEND\', \'DEPOSIT\', \'WITHDRAWAL\', \'INTEREST\'))',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class LedgerEntryRow extends DataClass implements Insertable<LedgerEntryRow> {
  final String id;
  final DateTime ts;
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
  final String source;
  final String? externalId;
  final String? note;
  final DateTime createdAt;
  const LedgerEntryRow({
    required this.id,
    required this.ts,
    required this.type,
    this.instrumentId,
    this.quantity,
    this.price,
    required this.grossAmount,
    required this.fees,
    required this.taxWithheld,
    required this.currency,
    required this.fxSource,
    this.fxDate,
    this.fxRate,
    this.fxDirection,
    this.originalAmount,
    this.originalCurrency,
    this.valuationSource,
    this.linkId,
    this.linkKind,
    required this.funding,
    required this.account,
    required this.source,
    this.externalId,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['ts'] = Variable<DateTime>(ts);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || instrumentId != null) {
      map['instrumentId'] = Variable<String>(instrumentId);
    }
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<String>(quantity);
    }
    if (!nullToAbsent || price != null) {
      map['price'] = Variable<String>(price);
    }
    map['grossAmount'] = Variable<String>(grossAmount);
    map['fees'] = Variable<String>(fees);
    map['taxWithheld'] = Variable<String>(taxWithheld);
    map['currency'] = Variable<String>(currency);
    map['fxSource'] = Variable<String>(fxSource);
    if (!nullToAbsent || fxDate != null) {
      map['fxDate'] = Variable<String>(fxDate);
    }
    if (!nullToAbsent || fxRate != null) {
      map['fxRate'] = Variable<String>(fxRate);
    }
    if (!nullToAbsent || fxDirection != null) {
      map['fxDirection'] = Variable<String>(fxDirection);
    }
    if (!nullToAbsent || originalAmount != null) {
      map['originalAmount'] = Variable<String>(originalAmount);
    }
    if (!nullToAbsent || originalCurrency != null) {
      map['originalCurrency'] = Variable<String>(originalCurrency);
    }
    if (!nullToAbsent || valuationSource != null) {
      map['valuationSource'] = Variable<String>(valuationSource);
    }
    if (!nullToAbsent || linkId != null) {
      map['linkId'] = Variable<String>(linkId);
    }
    if (!nullToAbsent || linkKind != null) {
      map['linkKind'] = Variable<String>(linkKind);
    }
    map['funding'] = Variable<String>(funding);
    map['account'] = Variable<String>(account);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || externalId != null) {
      map['externalId'] = Variable<String>(externalId);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['createdAt'] = Variable<DateTime>(createdAt);
    return map;
  }

  LedgerEntryCompanion toCompanion(bool nullToAbsent) {
    return LedgerEntryCompanion(
      id: Value(id),
      ts: Value(ts),
      type: Value(type),
      instrumentId: instrumentId == null && nullToAbsent
          ? const Value.absent()
          : Value(instrumentId),
      quantity: quantity == null && nullToAbsent
          ? const Value.absent()
          : Value(quantity),
      price: price == null && nullToAbsent
          ? const Value.absent()
          : Value(price),
      grossAmount: Value(grossAmount),
      fees: Value(fees),
      taxWithheld: Value(taxWithheld),
      currency: Value(currency),
      fxSource: Value(fxSource),
      fxDate: fxDate == null && nullToAbsent
          ? const Value.absent()
          : Value(fxDate),
      fxRate: fxRate == null && nullToAbsent
          ? const Value.absent()
          : Value(fxRate),
      fxDirection: fxDirection == null && nullToAbsent
          ? const Value.absent()
          : Value(fxDirection),
      originalAmount: originalAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(originalAmount),
      originalCurrency: originalCurrency == null && nullToAbsent
          ? const Value.absent()
          : Value(originalCurrency),
      valuationSource: valuationSource == null && nullToAbsent
          ? const Value.absent()
          : Value(valuationSource),
      linkId: linkId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkId),
      linkKind: linkKind == null && nullToAbsent
          ? const Value.absent()
          : Value(linkKind),
      funding: Value(funding),
      account: Value(account),
      source: Value(source),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory LedgerEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerEntryRow(
      id: serializer.fromJson<String>(json['id']),
      ts: serializer.fromJson<DateTime>(json['ts']),
      type: serializer.fromJson<String>(json['type']),
      instrumentId: serializer.fromJson<String?>(json['instrumentId']),
      quantity: serializer.fromJson<String?>(json['quantity']),
      price: serializer.fromJson<String?>(json['price']),
      grossAmount: serializer.fromJson<String>(json['grossAmount']),
      fees: serializer.fromJson<String>(json['fees']),
      taxWithheld: serializer.fromJson<String>(json['taxWithheld']),
      currency: serializer.fromJson<String>(json['currency']),
      fxSource: serializer.fromJson<String>(json['fxSource']),
      fxDate: serializer.fromJson<String?>(json['fxDate']),
      fxRate: serializer.fromJson<String?>(json['fxRate']),
      fxDirection: serializer.fromJson<String?>(json['fxDirection']),
      originalAmount: serializer.fromJson<String?>(json['originalAmount']),
      originalCurrency: serializer.fromJson<String?>(json['originalCurrency']),
      valuationSource: serializer.fromJson<String?>(json['valuationSource']),
      linkId: serializer.fromJson<String?>(json['linkId']),
      linkKind: serializer.fromJson<String?>(json['linkKind']),
      funding: serializer.fromJson<String>(json['funding']),
      account: serializer.fromJson<String>(json['account']),
      source: serializer.fromJson<String>(json['source']),
      externalId: serializer.fromJson<String?>(json['externalId']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ts': serializer.toJson<DateTime>(ts),
      'type': serializer.toJson<String>(type),
      'instrumentId': serializer.toJson<String?>(instrumentId),
      'quantity': serializer.toJson<String?>(quantity),
      'price': serializer.toJson<String?>(price),
      'grossAmount': serializer.toJson<String>(grossAmount),
      'fees': serializer.toJson<String>(fees),
      'taxWithheld': serializer.toJson<String>(taxWithheld),
      'currency': serializer.toJson<String>(currency),
      'fxSource': serializer.toJson<String>(fxSource),
      'fxDate': serializer.toJson<String?>(fxDate),
      'fxRate': serializer.toJson<String?>(fxRate),
      'fxDirection': serializer.toJson<String?>(fxDirection),
      'originalAmount': serializer.toJson<String?>(originalAmount),
      'originalCurrency': serializer.toJson<String?>(originalCurrency),
      'valuationSource': serializer.toJson<String?>(valuationSource),
      'linkId': serializer.toJson<String?>(linkId),
      'linkKind': serializer.toJson<String?>(linkKind),
      'funding': serializer.toJson<String>(funding),
      'account': serializer.toJson<String>(account),
      'source': serializer.toJson<String>(source),
      'externalId': serializer.toJson<String?>(externalId),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LedgerEntryRow copyWith({
    String? id,
    DateTime? ts,
    String? type,
    Value<String?> instrumentId = const Value.absent(),
    Value<String?> quantity = const Value.absent(),
    Value<String?> price = const Value.absent(),
    String? grossAmount,
    String? fees,
    String? taxWithheld,
    String? currency,
    String? fxSource,
    Value<String?> fxDate = const Value.absent(),
    Value<String?> fxRate = const Value.absent(),
    Value<String?> fxDirection = const Value.absent(),
    Value<String?> originalAmount = const Value.absent(),
    Value<String?> originalCurrency = const Value.absent(),
    Value<String?> valuationSource = const Value.absent(),
    Value<String?> linkId = const Value.absent(),
    Value<String?> linkKind = const Value.absent(),
    String? funding,
    String? account,
    String? source,
    Value<String?> externalId = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => LedgerEntryRow(
    id: id ?? this.id,
    ts: ts ?? this.ts,
    type: type ?? this.type,
    instrumentId: instrumentId.present ? instrumentId.value : this.instrumentId,
    quantity: quantity.present ? quantity.value : this.quantity,
    price: price.present ? price.value : this.price,
    grossAmount: grossAmount ?? this.grossAmount,
    fees: fees ?? this.fees,
    taxWithheld: taxWithheld ?? this.taxWithheld,
    currency: currency ?? this.currency,
    fxSource: fxSource ?? this.fxSource,
    fxDate: fxDate.present ? fxDate.value : this.fxDate,
    fxRate: fxRate.present ? fxRate.value : this.fxRate,
    fxDirection: fxDirection.present ? fxDirection.value : this.fxDirection,
    originalAmount: originalAmount.present
        ? originalAmount.value
        : this.originalAmount,
    originalCurrency: originalCurrency.present
        ? originalCurrency.value
        : this.originalCurrency,
    valuationSource: valuationSource.present
        ? valuationSource.value
        : this.valuationSource,
    linkId: linkId.present ? linkId.value : this.linkId,
    linkKind: linkKind.present ? linkKind.value : this.linkKind,
    funding: funding ?? this.funding,
    account: account ?? this.account,
    source: source ?? this.source,
    externalId: externalId.present ? externalId.value : this.externalId,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  LedgerEntryRow copyWithCompanion(LedgerEntryCompanion data) {
    return LedgerEntryRow(
      id: data.id.present ? data.id.value : this.id,
      ts: data.ts.present ? data.ts.value : this.ts,
      type: data.type.present ? data.type.value : this.type,
      instrumentId: data.instrumentId.present
          ? data.instrumentId.value
          : this.instrumentId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      price: data.price.present ? data.price.value : this.price,
      grossAmount: data.grossAmount.present
          ? data.grossAmount.value
          : this.grossAmount,
      fees: data.fees.present ? data.fees.value : this.fees,
      taxWithheld: data.taxWithheld.present
          ? data.taxWithheld.value
          : this.taxWithheld,
      currency: data.currency.present ? data.currency.value : this.currency,
      fxSource: data.fxSource.present ? data.fxSource.value : this.fxSource,
      fxDate: data.fxDate.present ? data.fxDate.value : this.fxDate,
      fxRate: data.fxRate.present ? data.fxRate.value : this.fxRate,
      fxDirection: data.fxDirection.present
          ? data.fxDirection.value
          : this.fxDirection,
      originalAmount: data.originalAmount.present
          ? data.originalAmount.value
          : this.originalAmount,
      originalCurrency: data.originalCurrency.present
          ? data.originalCurrency.value
          : this.originalCurrency,
      valuationSource: data.valuationSource.present
          ? data.valuationSource.value
          : this.valuationSource,
      linkId: data.linkId.present ? data.linkId.value : this.linkId,
      linkKind: data.linkKind.present ? data.linkKind.value : this.linkKind,
      funding: data.funding.present ? data.funding.value : this.funding,
      account: data.account.present ? data.account.value : this.account,
      source: data.source.present ? data.source.value : this.source,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntryRow(')
          ..write('id: $id, ')
          ..write('ts: $ts, ')
          ..write('type: $type, ')
          ..write('instrumentId: $instrumentId, ')
          ..write('quantity: $quantity, ')
          ..write('price: $price, ')
          ..write('grossAmount: $grossAmount, ')
          ..write('fees: $fees, ')
          ..write('taxWithheld: $taxWithheld, ')
          ..write('currency: $currency, ')
          ..write('fxSource: $fxSource, ')
          ..write('fxDate: $fxDate, ')
          ..write('fxRate: $fxRate, ')
          ..write('fxDirection: $fxDirection, ')
          ..write('originalAmount: $originalAmount, ')
          ..write('originalCurrency: $originalCurrency, ')
          ..write('valuationSource: $valuationSource, ')
          ..write('linkId: $linkId, ')
          ..write('linkKind: $linkKind, ')
          ..write('funding: $funding, ')
          ..write('account: $account, ')
          ..write('source: $source, ')
          ..write('externalId: $externalId, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    ts,
    type,
    instrumentId,
    quantity,
    price,
    grossAmount,
    fees,
    taxWithheld,
    currency,
    fxSource,
    fxDate,
    fxRate,
    fxDirection,
    originalAmount,
    originalCurrency,
    valuationSource,
    linkId,
    linkKind,
    funding,
    account,
    source,
    externalId,
    note,
    createdAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerEntryRow &&
          other.id == this.id &&
          other.ts == this.ts &&
          other.type == this.type &&
          other.instrumentId == this.instrumentId &&
          other.quantity == this.quantity &&
          other.price == this.price &&
          other.grossAmount == this.grossAmount &&
          other.fees == this.fees &&
          other.taxWithheld == this.taxWithheld &&
          other.currency == this.currency &&
          other.fxSource == this.fxSource &&
          other.fxDate == this.fxDate &&
          other.fxRate == this.fxRate &&
          other.fxDirection == this.fxDirection &&
          other.originalAmount == this.originalAmount &&
          other.originalCurrency == this.originalCurrency &&
          other.valuationSource == this.valuationSource &&
          other.linkId == this.linkId &&
          other.linkKind == this.linkKind &&
          other.funding == this.funding &&
          other.account == this.account &&
          other.source == this.source &&
          other.externalId == this.externalId &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class LedgerEntryCompanion extends UpdateCompanion<LedgerEntryRow> {
  final Value<String> id;
  final Value<DateTime> ts;
  final Value<String> type;
  final Value<String?> instrumentId;
  final Value<String?> quantity;
  final Value<String?> price;
  final Value<String> grossAmount;
  final Value<String> fees;
  final Value<String> taxWithheld;
  final Value<String> currency;
  final Value<String> fxSource;
  final Value<String?> fxDate;
  final Value<String?> fxRate;
  final Value<String?> fxDirection;
  final Value<String?> originalAmount;
  final Value<String?> originalCurrency;
  final Value<String?> valuationSource;
  final Value<String?> linkId;
  final Value<String?> linkKind;
  final Value<String> funding;
  final Value<String> account;
  final Value<String> source;
  final Value<String?> externalId;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LedgerEntryCompanion({
    this.id = const Value.absent(),
    this.ts = const Value.absent(),
    this.type = const Value.absent(),
    this.instrumentId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.price = const Value.absent(),
    this.grossAmount = const Value.absent(),
    this.fees = const Value.absent(),
    this.taxWithheld = const Value.absent(),
    this.currency = const Value.absent(),
    this.fxSource = const Value.absent(),
    this.fxDate = const Value.absent(),
    this.fxRate = const Value.absent(),
    this.fxDirection = const Value.absent(),
    this.originalAmount = const Value.absent(),
    this.originalCurrency = const Value.absent(),
    this.valuationSource = const Value.absent(),
    this.linkId = const Value.absent(),
    this.linkKind = const Value.absent(),
    this.funding = const Value.absent(),
    this.account = const Value.absent(),
    this.source = const Value.absent(),
    this.externalId = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LedgerEntryCompanion.insert({
    required String id,
    required DateTime ts,
    required String type,
    this.instrumentId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.price = const Value.absent(),
    required String grossAmount,
    this.fees = const Value.absent(),
    this.taxWithheld = const Value.absent(),
    required String currency,
    this.fxSource = const Value.absent(),
    this.fxDate = const Value.absent(),
    this.fxRate = const Value.absent(),
    this.fxDirection = const Value.absent(),
    this.originalAmount = const Value.absent(),
    this.originalCurrency = const Value.absent(),
    this.valuationSource = const Value.absent(),
    this.linkId = const Value.absent(),
    this.linkKind = const Value.absent(),
    this.funding = const Value.absent(),
    this.account = const Value.absent(),
    this.source = const Value.absent(),
    this.externalId = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ts = Value(ts),
       type = Value(type),
       grossAmount = Value(grossAmount),
       currency = Value(currency),
       createdAt = Value(createdAt);
  static Insertable<LedgerEntryRow> custom({
    Expression<String>? id,
    Expression<DateTime>? ts,
    Expression<String>? type,
    Expression<String>? instrumentId,
    Expression<String>? quantity,
    Expression<String>? price,
    Expression<String>? grossAmount,
    Expression<String>? fees,
    Expression<String>? taxWithheld,
    Expression<String>? currency,
    Expression<String>? fxSource,
    Expression<String>? fxDate,
    Expression<String>? fxRate,
    Expression<String>? fxDirection,
    Expression<String>? originalAmount,
    Expression<String>? originalCurrency,
    Expression<String>? valuationSource,
    Expression<String>? linkId,
    Expression<String>? linkKind,
    Expression<String>? funding,
    Expression<String>? account,
    Expression<String>? source,
    Expression<String>? externalId,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ts != null) 'ts': ts,
      if (type != null) 'type': type,
      if (instrumentId != null) 'instrumentId': instrumentId,
      if (quantity != null) 'quantity': quantity,
      if (price != null) 'price': price,
      if (grossAmount != null) 'grossAmount': grossAmount,
      if (fees != null) 'fees': fees,
      if (taxWithheld != null) 'taxWithheld': taxWithheld,
      if (currency != null) 'currency': currency,
      if (fxSource != null) 'fxSource': fxSource,
      if (fxDate != null) 'fxDate': fxDate,
      if (fxRate != null) 'fxRate': fxRate,
      if (fxDirection != null) 'fxDirection': fxDirection,
      if (originalAmount != null) 'originalAmount': originalAmount,
      if (originalCurrency != null) 'originalCurrency': originalCurrency,
      if (valuationSource != null) 'valuationSource': valuationSource,
      if (linkId != null) 'linkId': linkId,
      if (linkKind != null) 'linkKind': linkKind,
      if (funding != null) 'funding': funding,
      if (account != null) 'account': account,
      if (source != null) 'source': source,
      if (externalId != null) 'externalId': externalId,
      if (note != null) 'note': note,
      if (createdAt != null) 'createdAt': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LedgerEntryCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? ts,
    Value<String>? type,
    Value<String?>? instrumentId,
    Value<String?>? quantity,
    Value<String?>? price,
    Value<String>? grossAmount,
    Value<String>? fees,
    Value<String>? taxWithheld,
    Value<String>? currency,
    Value<String>? fxSource,
    Value<String?>? fxDate,
    Value<String?>? fxRate,
    Value<String?>? fxDirection,
    Value<String?>? originalAmount,
    Value<String?>? originalCurrency,
    Value<String?>? valuationSource,
    Value<String?>? linkId,
    Value<String?>? linkKind,
    Value<String>? funding,
    Value<String>? account,
    Value<String>? source,
    Value<String?>? externalId,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LedgerEntryCompanion(
      id: id ?? this.id,
      ts: ts ?? this.ts,
      type: type ?? this.type,
      instrumentId: instrumentId ?? this.instrumentId,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      grossAmount: grossAmount ?? this.grossAmount,
      fees: fees ?? this.fees,
      taxWithheld: taxWithheld ?? this.taxWithheld,
      currency: currency ?? this.currency,
      fxSource: fxSource ?? this.fxSource,
      fxDate: fxDate ?? this.fxDate,
      fxRate: fxRate ?? this.fxRate,
      fxDirection: fxDirection ?? this.fxDirection,
      originalAmount: originalAmount ?? this.originalAmount,
      originalCurrency: originalCurrency ?? this.originalCurrency,
      valuationSource: valuationSource ?? this.valuationSource,
      linkId: linkId ?? this.linkId,
      linkKind: linkKind ?? this.linkKind,
      funding: funding ?? this.funding,
      account: account ?? this.account,
      source: source ?? this.source,
      externalId: externalId ?? this.externalId,
      note: note ?? this.note,
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
    if (ts.present) {
      map['ts'] = Variable<DateTime>(ts.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (instrumentId.present) {
      map['instrumentId'] = Variable<String>(instrumentId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<String>(quantity.value);
    }
    if (price.present) {
      map['price'] = Variable<String>(price.value);
    }
    if (grossAmount.present) {
      map['grossAmount'] = Variable<String>(grossAmount.value);
    }
    if (fees.present) {
      map['fees'] = Variable<String>(fees.value);
    }
    if (taxWithheld.present) {
      map['taxWithheld'] = Variable<String>(taxWithheld.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (fxSource.present) {
      map['fxSource'] = Variable<String>(fxSource.value);
    }
    if (fxDate.present) {
      map['fxDate'] = Variable<String>(fxDate.value);
    }
    if (fxRate.present) {
      map['fxRate'] = Variable<String>(fxRate.value);
    }
    if (fxDirection.present) {
      map['fxDirection'] = Variable<String>(fxDirection.value);
    }
    if (originalAmount.present) {
      map['originalAmount'] = Variable<String>(originalAmount.value);
    }
    if (originalCurrency.present) {
      map['originalCurrency'] = Variable<String>(originalCurrency.value);
    }
    if (valuationSource.present) {
      map['valuationSource'] = Variable<String>(valuationSource.value);
    }
    if (linkId.present) {
      map['linkId'] = Variable<String>(linkId.value);
    }
    if (linkKind.present) {
      map['linkKind'] = Variable<String>(linkKind.value);
    }
    if (funding.present) {
      map['funding'] = Variable<String>(funding.value);
    }
    if (account.present) {
      map['account'] = Variable<String>(account.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (externalId.present) {
      map['externalId'] = Variable<String>(externalId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
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
    return (StringBuffer('LedgerEntryCompanion(')
          ..write('id: $id, ')
          ..write('ts: $ts, ')
          ..write('type: $type, ')
          ..write('instrumentId: $instrumentId, ')
          ..write('quantity: $quantity, ')
          ..write('price: $price, ')
          ..write('grossAmount: $grossAmount, ')
          ..write('fees: $fees, ')
          ..write('taxWithheld: $taxWithheld, ')
          ..write('currency: $currency, ')
          ..write('fxSource: $fxSource, ')
          ..write('fxDate: $fxDate, ')
          ..write('fxRate: $fxRate, ')
          ..write('fxDirection: $fxDirection, ')
          ..write('originalAmount: $originalAmount, ')
          ..write('originalCurrency: $originalCurrency, ')
          ..write('valuationSource: $valuationSource, ')
          ..write('linkId: $linkId, ')
          ..write('linkKind: $linkKind, ')
          ..write('funding: $funding, ')
          ..write('account: $account, ')
          ..write('source: $source, ')
          ..write('externalId: $externalId, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

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
    $customConstraints: 'NOT NULL REFERENCES Instrument(id)ON UPDATE CASCADE ON DELETE RESTRICT',
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

class FxRate extends Table with TableInfo<FxRate, FxRateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  FxRate(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _baseMeta = const VerificationMeta('base');
  late final GeneratedColumn<String> base = GeneratedColumn<String>(
    'base',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _quoteMeta = const VerificationMeta('quote');
  late final GeneratedColumn<String> quote = GeneratedColumn<String>(
    'quote',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _rateMeta = const VerificationMeta('rate');
  late final GeneratedColumn<String> rate = GeneratedColumn<String>(
    'rate',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
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
    base,
    quote,
    day,
    rate,
    source,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'FxRate';
  @override
  VerificationContext validateIntegrity(
    Insertable<FxRateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('base')) {
      context.handle(
        _baseMeta,
        base.isAcceptableOrUnknown(data['base']!, _baseMeta),
      );
    } else if (isInserting) {
      context.missing(_baseMeta);
    }
    if (data.containsKey('quote')) {
      context.handle(
        _quoteMeta,
        quote.isAcceptableOrUnknown(data['quote']!, _quoteMeta),
      );
    } else if (isInserting) {
      context.missing(_quoteMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('rate')) {
      context.handle(
        _rateMeta,
        rate.isAcceptableOrUnknown(data['rate']!, _rateMeta),
      );
    } else if (isInserting) {
      context.missing(_rateMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
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
  FxRateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FxRateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      base: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base'],
      )!,
      quote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quote'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      rate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rate'],
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
  FxRate createAlias(String alias) {
    return FxRate(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class FxRateRow extends DataClass implements Insertable<FxRateRow> {
  final String id;
  final String base;
  final String quote;
  final String day;
  final String rate;
  final String source;
  final DateTime createdAt;
  const FxRateRow({
    required this.id,
    required this.base,
    required this.quote,
    required this.day,
    required this.rate,
    required this.source,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['base'] = Variable<String>(base);
    map['quote'] = Variable<String>(quote);
    map['day'] = Variable<String>(day);
    map['rate'] = Variable<String>(rate);
    map['source'] = Variable<String>(source);
    map['createdAt'] = Variable<DateTime>(createdAt);
    return map;
  }

  FxRateCompanion toCompanion(bool nullToAbsent) {
    return FxRateCompanion(
      id: Value(id),
      base: Value(base),
      quote: Value(quote),
      day: Value(day),
      rate: Value(rate),
      source: Value(source),
      createdAt: Value(createdAt),
    );
  }

  factory FxRateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FxRateRow(
      id: serializer.fromJson<String>(json['id']),
      base: serializer.fromJson<String>(json['base']),
      quote: serializer.fromJson<String>(json['quote']),
      day: serializer.fromJson<String>(json['day']),
      rate: serializer.fromJson<String>(json['rate']),
      source: serializer.fromJson<String>(json['source']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'base': serializer.toJson<String>(base),
      'quote': serializer.toJson<String>(quote),
      'day': serializer.toJson<String>(day),
      'rate': serializer.toJson<String>(rate),
      'source': serializer.toJson<String>(source),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FxRateRow copyWith({
    String? id,
    String? base,
    String? quote,
    String? day,
    String? rate,
    String? source,
    DateTime? createdAt,
  }) => FxRateRow(
    id: id ?? this.id,
    base: base ?? this.base,
    quote: quote ?? this.quote,
    day: day ?? this.day,
    rate: rate ?? this.rate,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
  );
  FxRateRow copyWithCompanion(FxRateCompanion data) {
    return FxRateRow(
      id: data.id.present ? data.id.value : this.id,
      base: data.base.present ? data.base.value : this.base,
      quote: data.quote.present ? data.quote.value : this.quote,
      day: data.day.present ? data.day.value : this.day,
      rate: data.rate.present ? data.rate.value : this.rate,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FxRateRow(')
          ..write('id: $id, ')
          ..write('base: $base, ')
          ..write('quote: $quote, ')
          ..write('day: $day, ')
          ..write('rate: $rate, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, base, quote, day, rate, source, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FxRateRow &&
          other.id == this.id &&
          other.base == this.base &&
          other.quote == this.quote &&
          other.day == this.day &&
          other.rate == this.rate &&
          other.source == this.source &&
          other.createdAt == this.createdAt);
}

class FxRateCompanion extends UpdateCompanion<FxRateRow> {
  final Value<String> id;
  final Value<String> base;
  final Value<String> quote;
  final Value<String> day;
  final Value<String> rate;
  final Value<String> source;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const FxRateCompanion({
    this.id = const Value.absent(),
    this.base = const Value.absent(),
    this.quote = const Value.absent(),
    this.day = const Value.absent(),
    this.rate = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FxRateCompanion.insert({
    required String id,
    required String base,
    required String quote,
    required String day,
    required String rate,
    required String source,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       base = Value(base),
       quote = Value(quote),
       day = Value(day),
       rate = Value(rate),
       source = Value(source),
       createdAt = Value(createdAt);
  static Insertable<FxRateRow> custom({
    Expression<String>? id,
    Expression<String>? base,
    Expression<String>? quote,
    Expression<String>? day,
    Expression<String>? rate,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (base != null) 'base': base,
      if (quote != null) 'quote': quote,
      if (day != null) 'day': day,
      if (rate != null) 'rate': rate,
      if (source != null) 'source': source,
      if (createdAt != null) 'createdAt': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FxRateCompanion copyWith({
    Value<String>? id,
    Value<String>? base,
    Value<String>? quote,
    Value<String>? day,
    Value<String>? rate,
    Value<String>? source,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return FxRateCompanion(
      id: id ?? this.id,
      base: base ?? this.base,
      quote: quote ?? this.quote,
      day: day ?? this.day,
      rate: rate ?? this.rate,
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
    if (base.present) {
      map['base'] = Variable<String>(base.value);
    }
    if (quote.present) {
      map['quote'] = Variable<String>(quote.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (rate.present) {
      map['rate'] = Variable<String>(rate.value);
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
    return (StringBuffer('FxRateCompanion(')
          ..write('id: $id, ')
          ..write('base: $base, ')
          ..write('quote: $quote, ')
          ..write('day: $day, ')
          ..write('rate: $rate, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Settings extends Table with TableInfo<Settings, SettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Settings(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY DEFAULT 1 CHECK (id = 1)',
    defaultValue: const CustomExpression('1'),
  );
  static const VerificationMeta _residenceMeta = const VerificationMeta(
    'residence',
  );
  late final GeneratedColumn<String> residence = GeneratedColumn<String>(
    'residence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [id, residence];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('residence')) {
      context.handle(
        _residenceMeta,
        residence.isAcceptableOrUnknown(data['residence']!, _residenceMeta),
      );
    } else if (isInserting) {
      context.missing(_residenceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      residence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}residence'],
      )!,
    );
  }

  @override
  Settings createAlias(String alias) {
    return Settings(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SettingsRow extends DataClass implements Insertable<SettingsRow> {
  final int id;
  final String residence;
  const SettingsRow({required this.id, required this.residence});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['residence'] = Variable<String>(residence);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(id: Value(id), residence: Value(residence));
  }

  factory SettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRow(
      id: serializer.fromJson<int>(json['id']),
      residence: serializer.fromJson<String>(json['residence']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'residence': serializer.toJson<String>(residence),
    };
  }

  SettingsRow copyWith({int? id, String? residence}) =>
      SettingsRow(id: id ?? this.id, residence: residence ?? this.residence);
  SettingsRow copyWithCompanion(SettingsCompanion data) {
    return SettingsRow(
      id: data.id.present ? data.id.value : this.id,
      residence: data.residence.present ? data.residence.value : this.residence,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
          ..write('id: $id, ')
          ..write('residence: $residence')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, residence);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.id == this.id &&
          other.residence == this.residence);
}

class SettingsCompanion extends UpdateCompanion<SettingsRow> {
  final Value<int> id;
  final Value<String> residence;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.residence = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    required String residence,
  }) : residence = Value(residence);
  static Insertable<SettingsRow> custom({
    Expression<int>? id,
    Expression<String>? residence,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (residence != null) 'residence': residence,
    });
  }

  SettingsCompanion copyWith({Value<int>? id, Value<String>? residence}) {
    return SettingsCompanion(
      id: id ?? this.id,
      residence: residence ?? this.residence,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (residence.present) {
      map['residence'] = Variable<String>(residence.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('residence: $residence')
          ..write(')'))
        .toString();
  }
}

abstract class _$QuoinDatabase extends GeneratedDatabase {
  _$QuoinDatabase(QueryExecutor e) : super(e);
  late final Instrument instrument = Instrument(this);
  late final LedgerEntry ledgerEntry = LedgerEntry(this);
  late final Index ledgerEntrySourceExternalIdKey = Index(
    'LedgerEntry_source_externalId_key',
    'CREATE UNIQUE INDEX LedgerEntry_source_externalId_key ON LedgerEntry (source, externalId)',
  );
  late final Index ledgerEntryTsIdx = Index(
    'LedgerEntry_ts_idx',
    'CREATE INDEX LedgerEntry_ts_idx ON LedgerEntry (ts)',
  );
  late final Index ledgerEntryInstrumentIdIdx = Index(
    'LedgerEntry_instrumentId_idx',
    'CREATE INDEX LedgerEntry_instrumentId_idx ON LedgerEntry (instrumentId)',
  );
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
  late final FxRate fxRate = FxRate(this);
  late final Index fxRateQuoteIdx = Index(
    'FxRate_quote_idx',
    'CREATE INDEX FxRate_quote_idx ON FxRate (quote)',
  );
  late final Index fxRateSourceBaseQuoteDayKey = Index(
    'FxRate_source_base_quote_day_key',
    'CREATE UNIQUE INDEX FxRate_source_base_quote_day_key ON FxRate (source, base, quote, day)',
  );
  late final Settings settings = Settings(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    instrument,
    ledgerEntry,
    ledgerEntrySourceExternalIdKey,
    ledgerEntryTsIdx,
    ledgerEntryInstrumentIdIdx,
    priceSnapshot,
    priceSnapshotInstrumentIdIdx,
    priceSnapshotAsOfIdx,
    priceSnapshotInstrumentIdAsOfKey,
    fxRate,
    fxRateQuoteIdx,
    fxRateSourceBaseQuoteDayKey,
    settings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'Instrument',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('LedgerEntry', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'Instrument',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('LedgerEntry', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'Instrument',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('PriceSnapshot', kind: UpdateKind.update)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}
