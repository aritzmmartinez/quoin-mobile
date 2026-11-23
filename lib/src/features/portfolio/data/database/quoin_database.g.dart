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
  static const VerificationMeta _quoteSymbolHlcMeta = const VerificationMeta(
    'quoteSymbolHlc',
  );
  late final GeneratedColumn<String> quoteSymbolHlc = GeneratedColumn<String>(
    'quoteSymbolHlc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _exposureHlcMeta = const VerificationMeta(
    'exposureHlc',
  );
  late final GeneratedColumn<String> exposureHlc = GeneratedColumn<String>(
    'exposureHlc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _terHlcMeta = const VerificationMeta('terHlc');
  late final GeneratedColumn<String> terHlc = GeneratedColumn<String>(
    'terHlc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _hedgedToBaseHlcMeta = const VerificationMeta(
    'hedgedToBaseHlc',
  );
  late final GeneratedColumn<String> hedgedToBaseHlc = GeneratedColumn<String>(
    'hedgedToBaseHlc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _thesisHlcMeta = const VerificationMeta(
    'thesisHlc',
  );
  late final GeneratedColumn<String> thesisHlc = GeneratedColumn<String>(
    'thesisHlc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
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
    quoteSymbolHlc,
    exposureHlc,
    terHlc,
    hedgedToBaseHlc,
    thesisHlc,
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
    if (data.containsKey('quoteSymbolHlc')) {
      context.handle(
        _quoteSymbolHlcMeta,
        quoteSymbolHlc.isAcceptableOrUnknown(
          data['quoteSymbolHlc']!,
          _quoteSymbolHlcMeta,
        ),
      );
    }
    if (data.containsKey('exposureHlc')) {
      context.handle(
        _exposureHlcMeta,
        exposureHlc.isAcceptableOrUnknown(
          data['exposureHlc']!,
          _exposureHlcMeta,
        ),
      );
    }
    if (data.containsKey('terHlc')) {
      context.handle(
        _terHlcMeta,
        terHlc.isAcceptableOrUnknown(data['terHlc']!, _terHlcMeta),
      );
    }
    if (data.containsKey('hedgedToBaseHlc')) {
      context.handle(
        _hedgedToBaseHlcMeta,
        hedgedToBaseHlc.isAcceptableOrUnknown(
          data['hedgedToBaseHlc']!,
          _hedgedToBaseHlcMeta,
        ),
      );
    }
    if (data.containsKey('thesisHlc')) {
      context.handle(
        _thesisHlcMeta,
        thesisHlc.isAcceptableOrUnknown(data['thesisHlc']!, _thesisHlcMeta),
      );
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
      quoteSymbolHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quoteSymbolHlc'],
      ),
      exposureHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exposureHlc'],
      ),
      terHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}terHlc'],
      ),
      hedgedToBaseHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hedgedToBaseHlc'],
      ),
      thesisHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thesisHlc'],
      ),
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

  /// The sync mark of each hand-set field (the exposure pair shares one).
  /// Null: not changed since the column was added.
  final String? quoteSymbolHlc;
  final String? exposureHlc;
  final String? terHlc;
  final String? hedgedToBaseHlc;
  final String? thesisHlc;
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
    this.quoteSymbolHlc,
    this.exposureHlc,
    this.terHlc,
    this.hedgedToBaseHlc,
    this.thesisHlc,
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
    if (!nullToAbsent || quoteSymbolHlc != null) {
      map['quoteSymbolHlc'] = Variable<String>(quoteSymbolHlc);
    }
    if (!nullToAbsent || exposureHlc != null) {
      map['exposureHlc'] = Variable<String>(exposureHlc);
    }
    if (!nullToAbsent || terHlc != null) {
      map['terHlc'] = Variable<String>(terHlc);
    }
    if (!nullToAbsent || hedgedToBaseHlc != null) {
      map['hedgedToBaseHlc'] = Variable<String>(hedgedToBaseHlc);
    }
    if (!nullToAbsent || thesisHlc != null) {
      map['thesisHlc'] = Variable<String>(thesisHlc);
    }
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
      quoteSymbolHlc: quoteSymbolHlc == null && nullToAbsent
          ? const Value.absent()
          : Value(quoteSymbolHlc),
      exposureHlc: exposureHlc == null && nullToAbsent
          ? const Value.absent()
          : Value(exposureHlc),
      terHlc: terHlc == null && nullToAbsent
          ? const Value.absent()
          : Value(terHlc),
      hedgedToBaseHlc: hedgedToBaseHlc == null && nullToAbsent
          ? const Value.absent()
          : Value(hedgedToBaseHlc),
      thesisHlc: thesisHlc == null && nullToAbsent
          ? const Value.absent()
          : Value(thesisHlc),
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
      quoteSymbolHlc: serializer.fromJson<String?>(json['quoteSymbolHlc']),
      exposureHlc: serializer.fromJson<String?>(json['exposureHlc']),
      terHlc: serializer.fromJson<String?>(json['terHlc']),
      hedgedToBaseHlc: serializer.fromJson<String?>(json['hedgedToBaseHlc']),
      thesisHlc: serializer.fromJson<String?>(json['thesisHlc']),
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
      'quoteSymbolHlc': serializer.toJson<String?>(quoteSymbolHlc),
      'exposureHlc': serializer.toJson<String?>(exposureHlc),
      'terHlc': serializer.toJson<String?>(terHlc),
      'hedgedToBaseHlc': serializer.toJson<String?>(hedgedToBaseHlc),
      'thesisHlc': serializer.toJson<String?>(thesisHlc),
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
    Value<String?> quoteSymbolHlc = const Value.absent(),
    Value<String?> exposureHlc = const Value.absent(),
    Value<String?> terHlc = const Value.absent(),
    Value<String?> hedgedToBaseHlc = const Value.absent(),
    Value<String?> thesisHlc = const Value.absent(),
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
    quoteSymbolHlc: quoteSymbolHlc.present
        ? quoteSymbolHlc.value
        : this.quoteSymbolHlc,
    exposureHlc: exposureHlc.present ? exposureHlc.value : this.exposureHlc,
    terHlc: terHlc.present ? terHlc.value : this.terHlc,
    hedgedToBaseHlc: hedgedToBaseHlc.present
        ? hedgedToBaseHlc.value
        : this.hedgedToBaseHlc,
    thesisHlc: thesisHlc.present ? thesisHlc.value : this.thesisHlc,
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
      quoteSymbolHlc: data.quoteSymbolHlc.present
          ? data.quoteSymbolHlc.value
          : this.quoteSymbolHlc,
      exposureHlc: data.exposureHlc.present
          ? data.exposureHlc.value
          : this.exposureHlc,
      terHlc: data.terHlc.present ? data.terHlc.value : this.terHlc,
      hedgedToBaseHlc: data.hedgedToBaseHlc.present
          ? data.hedgedToBaseHlc.value
          : this.hedgedToBaseHlc,
      thesisHlc: data.thesisHlc.present ? data.thesisHlc.value : this.thesisHlc,
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
          ..write('createdAt: $createdAt, ')
          ..write('quoteSymbolHlc: $quoteSymbolHlc, ')
          ..write('exposureHlc: $exposureHlc, ')
          ..write('terHlc: $terHlc, ')
          ..write('hedgedToBaseHlc: $hedgedToBaseHlc, ')
          ..write('thesisHlc: $thesisHlc')
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
    quoteSymbolHlc,
    exposureHlc,
    terHlc,
    hedgedToBaseHlc,
    thesisHlc,
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
          other.createdAt == this.createdAt &&
          other.quoteSymbolHlc == this.quoteSymbolHlc &&
          other.exposureHlc == this.exposureHlc &&
          other.terHlc == this.terHlc &&
          other.hedgedToBaseHlc == this.hedgedToBaseHlc &&
          other.thesisHlc == this.thesisHlc);
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
  final Value<String?> quoteSymbolHlc;
  final Value<String?> exposureHlc;
  final Value<String?> terHlc;
  final Value<String?> hedgedToBaseHlc;
  final Value<String?> thesisHlc;
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
    this.quoteSymbolHlc = const Value.absent(),
    this.exposureHlc = const Value.absent(),
    this.terHlc = const Value.absent(),
    this.hedgedToBaseHlc = const Value.absent(),
    this.thesisHlc = const Value.absent(),
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
    this.quoteSymbolHlc = const Value.absent(),
    this.exposureHlc = const Value.absent(),
    this.terHlc = const Value.absent(),
    this.hedgedToBaseHlc = const Value.absent(),
    this.thesisHlc = const Value.absent(),
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
    Expression<String>? quoteSymbolHlc,
    Expression<String>? exposureHlc,
    Expression<String>? terHlc,
    Expression<String>? hedgedToBaseHlc,
    Expression<String>? thesisHlc,
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
      if (quoteSymbolHlc != null) 'quoteSymbolHlc': quoteSymbolHlc,
      if (exposureHlc != null) 'exposureHlc': exposureHlc,
      if (terHlc != null) 'terHlc': terHlc,
      if (hedgedToBaseHlc != null) 'hedgedToBaseHlc': hedgedToBaseHlc,
      if (thesisHlc != null) 'thesisHlc': thesisHlc,
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
    Value<String?>? quoteSymbolHlc,
    Value<String?>? exposureHlc,
    Value<String?>? terHlc,
    Value<String?>? hedgedToBaseHlc,
    Value<String?>? thesisHlc,
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
      quoteSymbolHlc: quoteSymbolHlc ?? this.quoteSymbolHlc,
      exposureHlc: exposureHlc ?? this.exposureHlc,
      terHlc: terHlc ?? this.terHlc,
      hedgedToBaseHlc: hedgedToBaseHlc ?? this.hedgedToBaseHlc,
      thesisHlc: thesisHlc ?? this.thesisHlc,
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
    if (quoteSymbolHlc.present) {
      map['quoteSymbolHlc'] = Variable<String>(quoteSymbolHlc.value);
    }
    if (exposureHlc.present) {
      map['exposureHlc'] = Variable<String>(exposureHlc.value);
    }
    if (terHlc.present) {
      map['terHlc'] = Variable<String>(terHlc.value);
    }
    if (hedgedToBaseHlc.present) {
      map['hedgedToBaseHlc'] = Variable<String>(hedgedToBaseHlc.value);
    }
    if (thesisHlc.present) {
      map['thesisHlc'] = Variable<String>(thesisHlc.value);
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
          ..write('quoteSymbolHlc: $quoteSymbolHlc, ')
          ..write('exposureHlc: $exposureHlc, ')
          ..write('terHlc: $terHlc, ')
          ..write('hedgedToBaseHlc: $hedgedToBaseHlc, ')
          ..write('thesisHlc: $thesisHlc, ')
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
  static const VerificationMeta _residenceHlcMeta = const VerificationMeta(
    'residenceHlc',
  );
  late final GeneratedColumn<String> residenceHlc = GeneratedColumn<String>(
    'residenceHlc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [id, residence, residenceHlc];
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
    if (data.containsKey('residenceHlc')) {
      context.handle(
        _residenceHlcMeta,
        residenceHlc.isAcceptableOrUnknown(
          data['residenceHlc']!,
          _residenceHlcMeta,
        ),
      );
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
      residenceHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}residenceHlc'],
      ),
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
  final String? residenceHlc;
  const SettingsRow({
    required this.id,
    required this.residence,
    this.residenceHlc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['residence'] = Variable<String>(residence);
    if (!nullToAbsent || residenceHlc != null) {
      map['residenceHlc'] = Variable<String>(residenceHlc);
    }
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      residence: Value(residence),
      residenceHlc: residenceHlc == null && nullToAbsent
          ? const Value.absent()
          : Value(residenceHlc),
    );
  }

  factory SettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRow(
      id: serializer.fromJson<int>(json['id']),
      residence: serializer.fromJson<String>(json['residence']),
      residenceHlc: serializer.fromJson<String?>(json['residenceHlc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'residence': serializer.toJson<String>(residence),
      'residenceHlc': serializer.toJson<String?>(residenceHlc),
    };
  }

  SettingsRow copyWith({
    int? id,
    String? residence,
    Value<String?> residenceHlc = const Value.absent(),
  }) => SettingsRow(
    id: id ?? this.id,
    residence: residence ?? this.residence,
    residenceHlc: residenceHlc.present ? residenceHlc.value : this.residenceHlc,
  );
  SettingsRow copyWithCompanion(SettingsCompanion data) {
    return SettingsRow(
      id: data.id.present ? data.id.value : this.id,
      residence: data.residence.present ? data.residence.value : this.residence,
      residenceHlc: data.residenceHlc.present
          ? data.residenceHlc.value
          : this.residenceHlc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
          ..write('id: $id, ')
          ..write('residence: $residence, ')
          ..write('residenceHlc: $residenceHlc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, residence, residenceHlc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.id == this.id &&
          other.residence == this.residence &&
          other.residenceHlc == this.residenceHlc);
}

class SettingsCompanion extends UpdateCompanion<SettingsRow> {
  final Value<int> id;
  final Value<String> residence;
  final Value<String?> residenceHlc;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.residence = const Value.absent(),
    this.residenceHlc = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    required String residence,
    this.residenceHlc = const Value.absent(),
  }) : residence = Value(residence);
  static Insertable<SettingsRow> custom({
    Expression<int>? id,
    Expression<String>? residence,
    Expression<String>? residenceHlc,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (residence != null) 'residence': residence,
      if (residenceHlc != null) 'residenceHlc': residenceHlc,
    });
  }

  SettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? residence,
    Value<String?>? residenceHlc,
  }) {
    return SettingsCompanion(
      id: id ?? this.id,
      residence: residence ?? this.residence,
      residenceHlc: residenceHlc ?? this.residenceHlc,
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
    if (residenceHlc.present) {
      map['residenceHlc'] = Variable<String>(residenceHlc.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('residence: $residence, ')
          ..write('residenceHlc: $residenceHlc')
          ..write(')'))
        .toString();
  }
}

class EtfHolding extends Table with TableInfo<EtfHolding, EtfHoldingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  EtfHolding(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _identityMeta = const VerificationMeta(
    'identity',
  );
  late final GeneratedColumn<String> identity = GeneratedColumn<String>(
    'identity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _identityKindMeta = const VerificationMeta(
    'identityKind',
  );
  late final GeneratedColumn<String> identityKind = GeneratedColumn<String>(
    'identityKind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
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
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  late final GeneratedColumn<String> weight = GeneratedColumn<String>(
    'weight',
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
    instrumentId,
    identity,
    identityKind,
    name,
    weight,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'EtfHolding';
  @override
  VerificationContext validateIntegrity(
    Insertable<EtfHoldingRow> instance, {
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
    if (data.containsKey('identity')) {
      context.handle(
        _identityMeta,
        identity.isAcceptableOrUnknown(data['identity']!, _identityMeta),
      );
    } else if (isInserting) {
      context.missing(_identityMeta);
    }
    if (data.containsKey('identityKind')) {
      context.handle(
        _identityKindMeta,
        identityKind.isAcceptableOrUnknown(
          data['identityKind']!,
          _identityKindMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_identityKindMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    } else if (isInserting) {
      context.missing(_weightMeta);
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
  EtfHoldingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EtfHoldingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      instrumentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instrumentId'],
      )!,
      identity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identity'],
      )!,
      identityKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identityKind'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weight'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}createdAt'],
      )!,
    );
  }

  @override
  EtfHolding createAlias(String alias) {
    return EtfHolding(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class EtfHoldingRow extends DataClass implements Insertable<EtfHoldingRow> {
  final String id;
  final String instrumentId;
  final String identity;
  final String identityKind;
  final String name;
  final String weight;
  final DateTime createdAt;
  const EtfHoldingRow({
    required this.id,
    required this.instrumentId,
    required this.identity,
    required this.identityKind,
    required this.name,
    required this.weight,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['instrumentId'] = Variable<String>(instrumentId);
    map['identity'] = Variable<String>(identity);
    map['identityKind'] = Variable<String>(identityKind);
    map['name'] = Variable<String>(name);
    map['weight'] = Variable<String>(weight);
    map['createdAt'] = Variable<DateTime>(createdAt);
    return map;
  }

  EtfHoldingCompanion toCompanion(bool nullToAbsent) {
    return EtfHoldingCompanion(
      id: Value(id),
      instrumentId: Value(instrumentId),
      identity: Value(identity),
      identityKind: Value(identityKind),
      name: Value(name),
      weight: Value(weight),
      createdAt: Value(createdAt),
    );
  }

  factory EtfHoldingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EtfHoldingRow(
      id: serializer.fromJson<String>(json['id']),
      instrumentId: serializer.fromJson<String>(json['instrumentId']),
      identity: serializer.fromJson<String>(json['identity']),
      identityKind: serializer.fromJson<String>(json['identityKind']),
      name: serializer.fromJson<String>(json['name']),
      weight: serializer.fromJson<String>(json['weight']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'instrumentId': serializer.toJson<String>(instrumentId),
      'identity': serializer.toJson<String>(identity),
      'identityKind': serializer.toJson<String>(identityKind),
      'name': serializer.toJson<String>(name),
      'weight': serializer.toJson<String>(weight),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  EtfHoldingRow copyWith({
    String? id,
    String? instrumentId,
    String? identity,
    String? identityKind,
    String? name,
    String? weight,
    DateTime? createdAt,
  }) => EtfHoldingRow(
    id: id ?? this.id,
    instrumentId: instrumentId ?? this.instrumentId,
    identity: identity ?? this.identity,
    identityKind: identityKind ?? this.identityKind,
    name: name ?? this.name,
    weight: weight ?? this.weight,
    createdAt: createdAt ?? this.createdAt,
  );
  EtfHoldingRow copyWithCompanion(EtfHoldingCompanion data) {
    return EtfHoldingRow(
      id: data.id.present ? data.id.value : this.id,
      instrumentId: data.instrumentId.present
          ? data.instrumentId.value
          : this.instrumentId,
      identity: data.identity.present ? data.identity.value : this.identity,
      identityKind: data.identityKind.present
          ? data.identityKind.value
          : this.identityKind,
      name: data.name.present ? data.name.value : this.name,
      weight: data.weight.present ? data.weight.value : this.weight,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EtfHoldingRow(')
          ..write('id: $id, ')
          ..write('instrumentId: $instrumentId, ')
          ..write('identity: $identity, ')
          ..write('identityKind: $identityKind, ')
          ..write('name: $name, ')
          ..write('weight: $weight, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    instrumentId,
    identity,
    identityKind,
    name,
    weight,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EtfHoldingRow &&
          other.id == this.id &&
          other.instrumentId == this.instrumentId &&
          other.identity == this.identity &&
          other.identityKind == this.identityKind &&
          other.name == this.name &&
          other.weight == this.weight &&
          other.createdAt == this.createdAt);
}

class EtfHoldingCompanion extends UpdateCompanion<EtfHoldingRow> {
  final Value<String> id;
  final Value<String> instrumentId;
  final Value<String> identity;
  final Value<String> identityKind;
  final Value<String> name;
  final Value<String> weight;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const EtfHoldingCompanion({
    this.id = const Value.absent(),
    this.instrumentId = const Value.absent(),
    this.identity = const Value.absent(),
    this.identityKind = const Value.absent(),
    this.name = const Value.absent(),
    this.weight = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EtfHoldingCompanion.insert({
    required String id,
    required String instrumentId,
    required String identity,
    required String identityKind,
    required String name,
    required String weight,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       instrumentId = Value(instrumentId),
       identity = Value(identity),
       identityKind = Value(identityKind),
       name = Value(name),
       weight = Value(weight),
       createdAt = Value(createdAt);
  static Insertable<EtfHoldingRow> custom({
    Expression<String>? id,
    Expression<String>? instrumentId,
    Expression<String>? identity,
    Expression<String>? identityKind,
    Expression<String>? name,
    Expression<String>? weight,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (instrumentId != null) 'instrumentId': instrumentId,
      if (identity != null) 'identity': identity,
      if (identityKind != null) 'identityKind': identityKind,
      if (name != null) 'name': name,
      if (weight != null) 'weight': weight,
      if (createdAt != null) 'createdAt': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EtfHoldingCompanion copyWith({
    Value<String>? id,
    Value<String>? instrumentId,
    Value<String>? identity,
    Value<String>? identityKind,
    Value<String>? name,
    Value<String>? weight,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return EtfHoldingCompanion(
      id: id ?? this.id,
      instrumentId: instrumentId ?? this.instrumentId,
      identity: identity ?? this.identity,
      identityKind: identityKind ?? this.identityKind,
      name: name ?? this.name,
      weight: weight ?? this.weight,
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
    if (identity.present) {
      map['identity'] = Variable<String>(identity.value);
    }
    if (identityKind.present) {
      map['identityKind'] = Variable<String>(identityKind.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (weight.present) {
      map['weight'] = Variable<String>(weight.value);
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
    return (StringBuffer('EtfHoldingCompanion(')
          ..write('id: $id, ')
          ..write('instrumentId: $instrumentId, ')
          ..write('identity: $identity, ')
          ..write('identityKind: $identityKind, ')
          ..write('name: $name, ')
          ..write('weight: $weight, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class EtfHoldingBlock extends Table
    with TableInfo<EtfHoldingBlock, EtfHoldingBlockRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  EtfHoldingBlock(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _instrumentIdMeta = const VerificationMeta(
    'instrumentId',
  );
  late final GeneratedColumn<String> instrumentId = GeneratedColumn<String>(
    'instrumentId',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY REFERENCES Instrument(id)ON UPDATE CASCADE ON DELETE RESTRICT',
  );
  static const VerificationMeta _asOfMeta = const VerificationMeta('asOf');
  late final GeneratedColumn<String> asOf = GeneratedColumn<String>(
    'asOf',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (asOf GLOB \'[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]\')',
  );
  static const VerificationMeta _asOfInferredMeta = const VerificationMeta(
    'asOfInferred',
  );
  late final GeneratedColumn<bool> asOfInferred = GeneratedColumn<bool>(
    'asOfInferred',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [instrumentId, asOf, asOfInferred, hlc];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'EtfHoldingBlock';
  @override
  VerificationContext validateIntegrity(
    Insertable<EtfHoldingBlockRow> instance, {
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
    if (data.containsKey('asOf')) {
      context.handle(
        _asOfMeta,
        asOf.isAcceptableOrUnknown(data['asOf']!, _asOfMeta),
      );
    } else if (isInserting) {
      context.missing(_asOfMeta);
    }
    if (data.containsKey('asOfInferred')) {
      context.handle(
        _asOfInferredMeta,
        asOfInferred.isAcceptableOrUnknown(
          data['asOfInferred']!,
          _asOfInferredMeta,
        ),
      );
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {instrumentId};
  @override
  EtfHoldingBlockRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EtfHoldingBlockRow(
      instrumentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instrumentId'],
      )!,
      asOf: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asOf'],
      )!,
      asOfInferred: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}asOfInferred'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      ),
    );
  }

  @override
  EtfHoldingBlock createAlias(String alias) {
    return EtfHoldingBlock(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class EtfHoldingBlockRow extends DataClass
    implements Insertable<EtfHoldingBlockRow> {
  final String instrumentId;
  final String asOf;
  final bool asOfInferred;
  final String? hlc;
  const EtfHoldingBlockRow({
    required this.instrumentId,
    required this.asOf,
    required this.asOfInferred,
    this.hlc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['instrumentId'] = Variable<String>(instrumentId);
    map['asOf'] = Variable<String>(asOf);
    map['asOfInferred'] = Variable<bool>(asOfInferred);
    if (!nullToAbsent || hlc != null) {
      map['hlc'] = Variable<String>(hlc);
    }
    return map;
  }

  EtfHoldingBlockCompanion toCompanion(bool nullToAbsent) {
    return EtfHoldingBlockCompanion(
      instrumentId: Value(instrumentId),
      asOf: Value(asOf),
      asOfInferred: Value(asOfInferred),
      hlc: hlc == null && nullToAbsent ? const Value.absent() : Value(hlc),
    );
  }

  factory EtfHoldingBlockRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EtfHoldingBlockRow(
      instrumentId: serializer.fromJson<String>(json['instrumentId']),
      asOf: serializer.fromJson<String>(json['asOf']),
      asOfInferred: serializer.fromJson<bool>(json['asOfInferred']),
      hlc: serializer.fromJson<String?>(json['hlc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'instrumentId': serializer.toJson<String>(instrumentId),
      'asOf': serializer.toJson<String>(asOf),
      'asOfInferred': serializer.toJson<bool>(asOfInferred),
      'hlc': serializer.toJson<String?>(hlc),
    };
  }

  EtfHoldingBlockRow copyWith({
    String? instrumentId,
    String? asOf,
    bool? asOfInferred,
    Value<String?> hlc = const Value.absent(),
  }) => EtfHoldingBlockRow(
    instrumentId: instrumentId ?? this.instrumentId,
    asOf: asOf ?? this.asOf,
    asOfInferred: asOfInferred ?? this.asOfInferred,
    hlc: hlc.present ? hlc.value : this.hlc,
  );
  EtfHoldingBlockRow copyWithCompanion(EtfHoldingBlockCompanion data) {
    return EtfHoldingBlockRow(
      instrumentId: data.instrumentId.present
          ? data.instrumentId.value
          : this.instrumentId,
      asOf: data.asOf.present ? data.asOf.value : this.asOf,
      asOfInferred: data.asOfInferred.present
          ? data.asOfInferred.value
          : this.asOfInferred,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EtfHoldingBlockRow(')
          ..write('instrumentId: $instrumentId, ')
          ..write('asOf: $asOf, ')
          ..write('asOfInferred: $asOfInferred, ')
          ..write('hlc: $hlc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(instrumentId, asOf, asOfInferred, hlc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EtfHoldingBlockRow &&
          other.instrumentId == this.instrumentId &&
          other.asOf == this.asOf &&
          other.asOfInferred == this.asOfInferred &&
          other.hlc == this.hlc);
}

class EtfHoldingBlockCompanion extends UpdateCompanion<EtfHoldingBlockRow> {
  final Value<String> instrumentId;
  final Value<String> asOf;
  final Value<bool> asOfInferred;
  final Value<String?> hlc;
  final Value<int> rowid;
  const EtfHoldingBlockCompanion({
    this.instrumentId = const Value.absent(),
    this.asOf = const Value.absent(),
    this.asOfInferred = const Value.absent(),
    this.hlc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EtfHoldingBlockCompanion.insert({
    required String instrumentId,
    required String asOf,
    this.asOfInferred = const Value.absent(),
    this.hlc = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : instrumentId = Value(instrumentId),
       asOf = Value(asOf);
  static Insertable<EtfHoldingBlockRow> custom({
    Expression<String>? instrumentId,
    Expression<String>? asOf,
    Expression<bool>? asOfInferred,
    Expression<String>? hlc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (instrumentId != null) 'instrumentId': instrumentId,
      if (asOf != null) 'asOf': asOf,
      if (asOfInferred != null) 'asOfInferred': asOfInferred,
      if (hlc != null) 'hlc': hlc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EtfHoldingBlockCompanion copyWith({
    Value<String>? instrumentId,
    Value<String>? asOf,
    Value<bool>? asOfInferred,
    Value<String?>? hlc,
    Value<int>? rowid,
  }) {
    return EtfHoldingBlockCompanion(
      instrumentId: instrumentId ?? this.instrumentId,
      asOf: asOf ?? this.asOf,
      asOfInferred: asOfInferred ?? this.asOfInferred,
      hlc: hlc ?? this.hlc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (instrumentId.present) {
      map['instrumentId'] = Variable<String>(instrumentId.value);
    }
    if (asOf.present) {
      map['asOf'] = Variable<String>(asOf.value);
    }
    if (asOfInferred.present) {
      map['asOfInferred'] = Variable<bool>(asOfInferred.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EtfHoldingBlockCompanion(')
          ..write('instrumentId: $instrumentId, ')
          ..write('asOf: $asOf, ')
          ..write('asOfInferred: $asOfInferred, ')
          ..write('hlc: $hlc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class PortfolioTarget extends Table
    with TableInfo<PortfolioTarget, PortfolioTargetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  PortfolioTarget(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _activeFromMeta = const VerificationMeta(
    'activeFrom',
  );
  late final GeneratedColumn<String> activeFrom = GeneratedColumn<String>(
    'activeFrom',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (activeFrom IS NULL OR activeFrom GLOB \'[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]\')',
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, note, createdAt, activeFrom];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'PortfolioTarget';
  @override
  VerificationContext validateIntegrity(
    Insertable<PortfolioTargetRow> instance, {
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
    if (data.containsKey('activeFrom')) {
      context.handle(
        _activeFromMeta,
        activeFrom.isAcceptableOrUnknown(data['activeFrom']!, _activeFromMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PortfolioTargetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PortfolioTargetRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}createdAt'],
      )!,
      activeFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activeFrom'],
      ),
    );
  }

  @override
  PortfolioTarget createAlias(String alias) {
    return PortfolioTarget(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class PortfolioTargetRow extends DataClass
    implements Insertable<PortfolioTargetRow> {
  final String id;
  final String name;
  final String? note;
  final DateTime createdAt;
  final String? activeFrom;
  const PortfolioTargetRow({
    required this.id,
    required this.name,
    this.note,
    required this.createdAt,
    this.activeFrom,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['createdAt'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || activeFrom != null) {
      map['activeFrom'] = Variable<String>(activeFrom);
    }
    return map;
  }

  PortfolioTargetCompanion toCompanion(bool nullToAbsent) {
    return PortfolioTargetCompanion(
      id: Value(id),
      name: Value(name),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      activeFrom: activeFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(activeFrom),
    );
  }

  factory PortfolioTargetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PortfolioTargetRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      activeFrom: serializer.fromJson<String?>(json['activeFrom']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'activeFrom': serializer.toJson<String?>(activeFrom),
    };
  }

  PortfolioTargetRow copyWith({
    String? id,
    String? name,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
    Value<String?> activeFrom = const Value.absent(),
  }) => PortfolioTargetRow(
    id: id ?? this.id,
    name: name ?? this.name,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    activeFrom: activeFrom.present ? activeFrom.value : this.activeFrom,
  );
  PortfolioTargetRow copyWithCompanion(PortfolioTargetCompanion data) {
    return PortfolioTargetRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      activeFrom: data.activeFrom.present
          ? data.activeFrom.value
          : this.activeFrom,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PortfolioTargetRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('activeFrom: $activeFrom')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, note, createdAt, activeFrom);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PortfolioTargetRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.activeFrom == this.activeFrom);
}

class PortfolioTargetCompanion extends UpdateCompanion<PortfolioTargetRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<String?> activeFrom;
  final Value<int> rowid;
  const PortfolioTargetCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.activeFrom = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PortfolioTargetCompanion.insert({
    required String id,
    required String name,
    this.note = const Value.absent(),
    required DateTime createdAt,
    this.activeFrom = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<PortfolioTargetRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<String>? activeFrom,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (note != null) 'note': note,
      if (createdAt != null) 'createdAt': createdAt,
      if (activeFrom != null) 'activeFrom': activeFrom,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PortfolioTargetCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<String?>? activeFrom,
    Value<int>? rowid,
  }) {
    return PortfolioTargetCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      activeFrom: activeFrom ?? this.activeFrom,
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
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['createdAt'] = Variable<DateTime>(createdAt.value);
    }
    if (activeFrom.present) {
      map['activeFrom'] = Variable<String>(activeFrom.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PortfolioTargetCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('activeFrom: $activeFrom, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class PortfolioTargetLine extends Table
    with TableInfo<PortfolioTargetLine, PortfolioTargetLineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  PortfolioTargetLine(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'targetId',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES PortfolioTarget(id)ON UPDATE CASCADE ON DELETE CASCADE',
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
  static const VerificationMeta _monthlyAmountMeta = const VerificationMeta(
    'monthlyAmount',
  );
  late final GeneratedColumn<String> monthlyAmount = GeneratedColumn<String>(
    'monthlyAmount',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    targetId,
    instrumentId,
    monthlyAmount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'PortfolioTargetLine';
  @override
  VerificationContext validateIntegrity(
    Insertable<PortfolioTargetLineRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('targetId')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['targetId']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
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
    if (data.containsKey('monthlyAmount')) {
      context.handle(
        _monthlyAmountMeta,
        monthlyAmount.isAcceptableOrUnknown(
          data['monthlyAmount']!,
          _monthlyAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_monthlyAmountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PortfolioTargetLineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PortfolioTargetLineRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}targetId'],
      )!,
      instrumentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instrumentId'],
      )!,
      monthlyAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}monthlyAmount'],
      )!,
    );
  }

  @override
  PortfolioTargetLine createAlias(String alias) {
    return PortfolioTargetLine(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class PortfolioTargetLineRow extends DataClass
    implements Insertable<PortfolioTargetLineRow> {
  final String id;
  final String targetId;
  final String instrumentId;
  final String monthlyAmount;
  const PortfolioTargetLineRow({
    required this.id,
    required this.targetId,
    required this.instrumentId,
    required this.monthlyAmount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['targetId'] = Variable<String>(targetId);
    map['instrumentId'] = Variable<String>(instrumentId);
    map['monthlyAmount'] = Variable<String>(monthlyAmount);
    return map;
  }

  PortfolioTargetLineCompanion toCompanion(bool nullToAbsent) {
    return PortfolioTargetLineCompanion(
      id: Value(id),
      targetId: Value(targetId),
      instrumentId: Value(instrumentId),
      monthlyAmount: Value(monthlyAmount),
    );
  }

  factory PortfolioTargetLineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PortfolioTargetLineRow(
      id: serializer.fromJson<String>(json['id']),
      targetId: serializer.fromJson<String>(json['targetId']),
      instrumentId: serializer.fromJson<String>(json['instrumentId']),
      monthlyAmount: serializer.fromJson<String>(json['monthlyAmount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'targetId': serializer.toJson<String>(targetId),
      'instrumentId': serializer.toJson<String>(instrumentId),
      'monthlyAmount': serializer.toJson<String>(monthlyAmount),
    };
  }

  PortfolioTargetLineRow copyWith({
    String? id,
    String? targetId,
    String? instrumentId,
    String? monthlyAmount,
  }) => PortfolioTargetLineRow(
    id: id ?? this.id,
    targetId: targetId ?? this.targetId,
    instrumentId: instrumentId ?? this.instrumentId,
    monthlyAmount: monthlyAmount ?? this.monthlyAmount,
  );
  PortfolioTargetLineRow copyWithCompanion(PortfolioTargetLineCompanion data) {
    return PortfolioTargetLineRow(
      id: data.id.present ? data.id.value : this.id,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      instrumentId: data.instrumentId.present
          ? data.instrumentId.value
          : this.instrumentId,
      monthlyAmount: data.monthlyAmount.present
          ? data.monthlyAmount.value
          : this.monthlyAmount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PortfolioTargetLineRow(')
          ..write('id: $id, ')
          ..write('targetId: $targetId, ')
          ..write('instrumentId: $instrumentId, ')
          ..write('monthlyAmount: $monthlyAmount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, targetId, instrumentId, monthlyAmount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PortfolioTargetLineRow &&
          other.id == this.id &&
          other.targetId == this.targetId &&
          other.instrumentId == this.instrumentId &&
          other.monthlyAmount == this.monthlyAmount);
}

class PortfolioTargetLineCompanion
    extends UpdateCompanion<PortfolioTargetLineRow> {
  final Value<String> id;
  final Value<String> targetId;
  final Value<String> instrumentId;
  final Value<String> monthlyAmount;
  final Value<int> rowid;
  const PortfolioTargetLineCompanion({
    this.id = const Value.absent(),
    this.targetId = const Value.absent(),
    this.instrumentId = const Value.absent(),
    this.monthlyAmount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PortfolioTargetLineCompanion.insert({
    required String id,
    required String targetId,
    required String instrumentId,
    required String monthlyAmount,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       targetId = Value(targetId),
       instrumentId = Value(instrumentId),
       monthlyAmount = Value(monthlyAmount);
  static Insertable<PortfolioTargetLineRow> custom({
    Expression<String>? id,
    Expression<String>? targetId,
    Expression<String>? instrumentId,
    Expression<String>? monthlyAmount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetId != null) 'targetId': targetId,
      if (instrumentId != null) 'instrumentId': instrumentId,
      if (monthlyAmount != null) 'monthlyAmount': monthlyAmount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PortfolioTargetLineCompanion copyWith({
    Value<String>? id,
    Value<String>? targetId,
    Value<String>? instrumentId,
    Value<String>? monthlyAmount,
    Value<int>? rowid,
  }) {
    return PortfolioTargetLineCompanion(
      id: id ?? this.id,
      targetId: targetId ?? this.targetId,
      instrumentId: instrumentId ?? this.instrumentId,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (targetId.present) {
      map['targetId'] = Variable<String>(targetId.value);
    }
    if (instrumentId.present) {
      map['instrumentId'] = Variable<String>(instrumentId.value);
    }
    if (monthlyAmount.present) {
      map['monthlyAmount'] = Variable<String>(monthlyAmount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PortfolioTargetLineCompanion(')
          ..write('id: $id, ')
          ..write('targetId: $targetId, ')
          ..write('instrumentId: $instrumentId, ')
          ..write('monthlyAmount: $monthlyAmount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SecurityIdentity extends Table
    with TableInfo<SecurityIdentity, SecurityIdentityRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SecurityIdentity(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _identityMeta = const VerificationMeta(
    'identity',
  );
  late final GeneratedColumn<String> identity = GeneratedColumn<String>(
    'identity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _identityKindMeta = const VerificationMeta(
    'identityKind',
  );
  late final GeneratedColumn<String> identityKind = GeneratedColumn<String>(
    'identityKind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _canonicalIdMeta = const VerificationMeta(
    'canonicalId',
  );
  late final GeneratedColumn<String> canonicalId = GeneratedColumn<String>(
    'canonicalId',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
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
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  late final GeneratedColumn<DateTime> resolvedAt = GeneratedColumn<DateTime>(
    'resolvedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _exchCodeMeta = const VerificationMeta(
    'exchCode',
  );
  late final GeneratedColumn<String> exchCode = GeneratedColumn<String>(
    'exchCode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    identity,
    identityKind,
    canonicalId,
    status,
    source,
    resolvedAt,
    exchCode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'SecurityIdentity';
  @override
  VerificationContext validateIntegrity(
    Insertable<SecurityIdentityRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('identity')) {
      context.handle(
        _identityMeta,
        identity.isAcceptableOrUnknown(data['identity']!, _identityMeta),
      );
    } else if (isInserting) {
      context.missing(_identityMeta);
    }
    if (data.containsKey('identityKind')) {
      context.handle(
        _identityKindMeta,
        identityKind.isAcceptableOrUnknown(
          data['identityKind']!,
          _identityKindMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_identityKindMeta);
    }
    if (data.containsKey('canonicalId')) {
      context.handle(
        _canonicalIdMeta,
        canonicalId.isAcceptableOrUnknown(
          data['canonicalId']!,
          _canonicalIdMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('resolvedAt')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolvedAt']!, _resolvedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_resolvedAtMeta);
    }
    if (data.containsKey('exchCode')) {
      context.handle(
        _exchCodeMeta,
        exchCode.isAcceptableOrUnknown(data['exchCode']!, _exchCodeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {identity};
  @override
  SecurityIdentityRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SecurityIdentityRow(
      identity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identity'],
      )!,
      identityKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identityKind'],
      )!,
      canonicalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canonicalId'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resolvedAt'],
      )!,
      exchCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exchCode'],
      ),
    );
  }

  @override
  SecurityIdentity createAlias(String alias) {
    return SecurityIdentity(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SecurityIdentityRow extends DataClass
    implements Insertable<SecurityIdentityRow> {
  final String identity;
  final String identityKind;
  final String? canonicalId;
  final String status;
  final String source;
  final DateTime resolvedAt;
  final String? exchCode;
  const SecurityIdentityRow({
    required this.identity,
    required this.identityKind,
    this.canonicalId,
    required this.status,
    required this.source,
    required this.resolvedAt,
    this.exchCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['identity'] = Variable<String>(identity);
    map['identityKind'] = Variable<String>(identityKind);
    if (!nullToAbsent || canonicalId != null) {
      map['canonicalId'] = Variable<String>(canonicalId);
    }
    map['status'] = Variable<String>(status);
    map['source'] = Variable<String>(source);
    map['resolvedAt'] = Variable<DateTime>(resolvedAt);
    if (!nullToAbsent || exchCode != null) {
      map['exchCode'] = Variable<String>(exchCode);
    }
    return map;
  }

  SecurityIdentityCompanion toCompanion(bool nullToAbsent) {
    return SecurityIdentityCompanion(
      identity: Value(identity),
      identityKind: Value(identityKind),
      canonicalId: canonicalId == null && nullToAbsent
          ? const Value.absent()
          : Value(canonicalId),
      status: Value(status),
      source: Value(source),
      resolvedAt: Value(resolvedAt),
      exchCode: exchCode == null && nullToAbsent
          ? const Value.absent()
          : Value(exchCode),
    );
  }

  factory SecurityIdentityRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SecurityIdentityRow(
      identity: serializer.fromJson<String>(json['identity']),
      identityKind: serializer.fromJson<String>(json['identityKind']),
      canonicalId: serializer.fromJson<String?>(json['canonicalId']),
      status: serializer.fromJson<String>(json['status']),
      source: serializer.fromJson<String>(json['source']),
      resolvedAt: serializer.fromJson<DateTime>(json['resolvedAt']),
      exchCode: serializer.fromJson<String?>(json['exchCode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'identity': serializer.toJson<String>(identity),
      'identityKind': serializer.toJson<String>(identityKind),
      'canonicalId': serializer.toJson<String?>(canonicalId),
      'status': serializer.toJson<String>(status),
      'source': serializer.toJson<String>(source),
      'resolvedAt': serializer.toJson<DateTime>(resolvedAt),
      'exchCode': serializer.toJson<String?>(exchCode),
    };
  }

  SecurityIdentityRow copyWith({
    String? identity,
    String? identityKind,
    Value<String?> canonicalId = const Value.absent(),
    String? status,
    String? source,
    DateTime? resolvedAt,
    Value<String?> exchCode = const Value.absent(),
  }) => SecurityIdentityRow(
    identity: identity ?? this.identity,
    identityKind: identityKind ?? this.identityKind,
    canonicalId: canonicalId.present ? canonicalId.value : this.canonicalId,
    status: status ?? this.status,
    source: source ?? this.source,
    resolvedAt: resolvedAt ?? this.resolvedAt,
    exchCode: exchCode.present ? exchCode.value : this.exchCode,
  );
  SecurityIdentityRow copyWithCompanion(SecurityIdentityCompanion data) {
    return SecurityIdentityRow(
      identity: data.identity.present ? data.identity.value : this.identity,
      identityKind: data.identityKind.present
          ? data.identityKind.value
          : this.identityKind,
      canonicalId: data.canonicalId.present
          ? data.canonicalId.value
          : this.canonicalId,
      status: data.status.present ? data.status.value : this.status,
      source: data.source.present ? data.source.value : this.source,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
      exchCode: data.exchCode.present ? data.exchCode.value : this.exchCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SecurityIdentityRow(')
          ..write('identity: $identity, ')
          ..write('identityKind: $identityKind, ')
          ..write('canonicalId: $canonicalId, ')
          ..write('status: $status, ')
          ..write('source: $source, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('exchCode: $exchCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    identity,
    identityKind,
    canonicalId,
    status,
    source,
    resolvedAt,
    exchCode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SecurityIdentityRow &&
          other.identity == this.identity &&
          other.identityKind == this.identityKind &&
          other.canonicalId == this.canonicalId &&
          other.status == this.status &&
          other.source == this.source &&
          other.resolvedAt == this.resolvedAt &&
          other.exchCode == this.exchCode);
}

class SecurityIdentityCompanion extends UpdateCompanion<SecurityIdentityRow> {
  final Value<String> identity;
  final Value<String> identityKind;
  final Value<String?> canonicalId;
  final Value<String> status;
  final Value<String> source;
  final Value<DateTime> resolvedAt;
  final Value<String?> exchCode;
  final Value<int> rowid;
  const SecurityIdentityCompanion({
    this.identity = const Value.absent(),
    this.identityKind = const Value.absent(),
    this.canonicalId = const Value.absent(),
    this.status = const Value.absent(),
    this.source = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.exchCode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SecurityIdentityCompanion.insert({
    required String identity,
    required String identityKind,
    this.canonicalId = const Value.absent(),
    required String status,
    required String source,
    required DateTime resolvedAt,
    this.exchCode = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : identity = Value(identity),
       identityKind = Value(identityKind),
       status = Value(status),
       source = Value(source),
       resolvedAt = Value(resolvedAt);
  static Insertable<SecurityIdentityRow> custom({
    Expression<String>? identity,
    Expression<String>? identityKind,
    Expression<String>? canonicalId,
    Expression<String>? status,
    Expression<String>? source,
    Expression<DateTime>? resolvedAt,
    Expression<String>? exchCode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (identity != null) 'identity': identity,
      if (identityKind != null) 'identityKind': identityKind,
      if (canonicalId != null) 'canonicalId': canonicalId,
      if (status != null) 'status': status,
      if (source != null) 'source': source,
      if (resolvedAt != null) 'resolvedAt': resolvedAt,
      if (exchCode != null) 'exchCode': exchCode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SecurityIdentityCompanion copyWith({
    Value<String>? identity,
    Value<String>? identityKind,
    Value<String?>? canonicalId,
    Value<String>? status,
    Value<String>? source,
    Value<DateTime>? resolvedAt,
    Value<String?>? exchCode,
    Value<int>? rowid,
  }) {
    return SecurityIdentityCompanion(
      identity: identity ?? this.identity,
      identityKind: identityKind ?? this.identityKind,
      canonicalId: canonicalId ?? this.canonicalId,
      status: status ?? this.status,
      source: source ?? this.source,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      exchCode: exchCode ?? this.exchCode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (identity.present) {
      map['identity'] = Variable<String>(identity.value);
    }
    if (identityKind.present) {
      map['identityKind'] = Variable<String>(identityKind.value);
    }
    if (canonicalId.present) {
      map['canonicalId'] = Variable<String>(canonicalId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (resolvedAt.present) {
      map['resolvedAt'] = Variable<DateTime>(resolvedAt.value);
    }
    if (exchCode.present) {
      map['exchCode'] = Variable<String>(exchCode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SecurityIdentityCompanion(')
          ..write('identity: $identity, ')
          ..write('identityKind: $identityKind, ')
          ..write('canonicalId: $canonicalId, ')
          ..write('status: $status, ')
          ..write('source: $source, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('exchCode: $exchCode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SyncDevice extends Table with TableInfo<SyncDevice, SyncDeviceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SyncDevice(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'deviceId',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _lastHlcMeta = const VerificationMeta(
    'lastHlc',
  );
  late final GeneratedColumn<String> lastHlc = GeneratedColumn<String>(
    'lastHlc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [id, deviceId, name, lastHlc];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'SyncDevice';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncDeviceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('deviceId')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['deviceId']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('lastHlc')) {
      context.handle(
        _lastHlcMeta,
        lastHlc.isAcceptableOrUnknown(data['lastHlc']!, _lastHlcMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncDeviceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncDeviceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deviceId'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      lastHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lastHlc'],
      ),
    );
  }

  @override
  SyncDevice createAlias(String alias) {
    return SyncDevice(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SyncDeviceRow extends DataClass implements Insertable<SyncDeviceRow> {
  final int id;
  final String deviceId;
  final String? name;
  final String? lastHlc;
  const SyncDeviceRow({
    required this.id,
    required this.deviceId,
    this.name,
    this.lastHlc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['deviceId'] = Variable<String>(deviceId);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || lastHlc != null) {
      map['lastHlc'] = Variable<String>(lastHlc);
    }
    return map;
  }

  SyncDeviceCompanion toCompanion(bool nullToAbsent) {
    return SyncDeviceCompanion(
      id: Value(id),
      deviceId: Value(deviceId),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      lastHlc: lastHlc == null && nullToAbsent
          ? const Value.absent()
          : Value(lastHlc),
    );
  }

  factory SyncDeviceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncDeviceRow(
      id: serializer.fromJson<int>(json['id']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      name: serializer.fromJson<String?>(json['name']),
      lastHlc: serializer.fromJson<String?>(json['lastHlc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deviceId': serializer.toJson<String>(deviceId),
      'name': serializer.toJson<String?>(name),
      'lastHlc': serializer.toJson<String?>(lastHlc),
    };
  }

  SyncDeviceRow copyWith({
    int? id,
    String? deviceId,
    Value<String?> name = const Value.absent(),
    Value<String?> lastHlc = const Value.absent(),
  }) => SyncDeviceRow(
    id: id ?? this.id,
    deviceId: deviceId ?? this.deviceId,
    name: name.present ? name.value : this.name,
    lastHlc: lastHlc.present ? lastHlc.value : this.lastHlc,
  );
  SyncDeviceRow copyWithCompanion(SyncDeviceCompanion data) {
    return SyncDeviceRow(
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      name: data.name.present ? data.name.value : this.name,
      lastHlc: data.lastHlc.present ? data.lastHlc.value : this.lastHlc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncDeviceRow(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('name: $name, ')
          ..write('lastHlc: $lastHlc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, deviceId, name, lastHlc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncDeviceRow &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.name == this.name &&
          other.lastHlc == this.lastHlc);
}

class SyncDeviceCompanion extends UpdateCompanion<SyncDeviceRow> {
  final Value<int> id;
  final Value<String> deviceId;
  final Value<String?> name;
  final Value<String?> lastHlc;
  const SyncDeviceCompanion({
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.name = const Value.absent(),
    this.lastHlc = const Value.absent(),
  });
  SyncDeviceCompanion.insert({
    this.id = const Value.absent(),
    required String deviceId,
    this.name = const Value.absent(),
    this.lastHlc = const Value.absent(),
  }) : deviceId = Value(deviceId);
  static Insertable<SyncDeviceRow> custom({
    Expression<int>? id,
    Expression<String>? deviceId,
    Expression<String>? name,
    Expression<String>? lastHlc,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceId != null) 'deviceId': deviceId,
      if (name != null) 'name': name,
      if (lastHlc != null) 'lastHlc': lastHlc,
    });
  }

  SyncDeviceCompanion copyWith({
    Value<int>? id,
    Value<String>? deviceId,
    Value<String?>? name,
    Value<String?>? lastHlc,
  }) {
    return SyncDeviceCompanion(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      lastHlc: lastHlc ?? this.lastHlc,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deviceId.present) {
      map['deviceId'] = Variable<String>(deviceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (lastHlc.present) {
      map['lastHlc'] = Variable<String>(lastHlc.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncDeviceCompanion(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('name: $name, ')
          ..write('lastHlc: $lastHlc')
          ..write(')'))
        .toString();
  }
}

class SyncPeer extends Table with TableInfo<SyncPeer, SyncPeerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SyncPeer(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'deviceId',
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
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _seenMeta = const VerificationMeta('seen');
  late final GeneratedColumn<String> seen = GeneratedColumn<String>(
    'seen',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'lastSyncedAt',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [deviceId, name, seen, lastSyncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'SyncPeer';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncPeerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('deviceId')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['deviceId']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('seen')) {
      context.handle(
        _seenMeta,
        seen.isAcceptableOrUnknown(data['seen']!, _seenMeta),
      );
    } else if (isInserting) {
      context.missing(_seenMeta);
    }
    if (data.containsKey('lastSyncedAt')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['lastSyncedAt']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  SyncPeerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncPeerRow(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deviceId'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      seen: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seen'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}lastSyncedAt'],
      ),
    );
  }

  @override
  SyncPeer createAlias(String alias) {
    return SyncPeer(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SyncPeerRow extends DataClass implements Insertable<SyncPeerRow> {
  final String deviceId;
  final String? name;
  final String seen;
  final DateTime? lastSyncedAt;
  const SyncPeerRow({
    required this.deviceId,
    this.name,
    required this.seen,
    this.lastSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['deviceId'] = Variable<String>(deviceId);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['seen'] = Variable<String>(seen);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['lastSyncedAt'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  SyncPeerCompanion toCompanion(bool nullToAbsent) {
    return SyncPeerCompanion(
      deviceId: Value(deviceId),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      seen: Value(seen),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory SyncPeerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncPeerRow(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      name: serializer.fromJson<String?>(json['name']),
      seen: serializer.fromJson<String>(json['seen']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'name': serializer.toJson<String?>(name),
      'seen': serializer.toJson<String>(seen),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  SyncPeerRow copyWith({
    String? deviceId,
    Value<String?> name = const Value.absent(),
    String? seen,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
  }) => SyncPeerRow(
    deviceId: deviceId ?? this.deviceId,
    name: name.present ? name.value : this.name,
    seen: seen ?? this.seen,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
  );
  SyncPeerRow copyWithCompanion(SyncPeerCompanion data) {
    return SyncPeerRow(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      name: data.name.present ? data.name.value : this.name,
      seen: data.seen.present ? data.seen.value : this.seen,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncPeerRow(')
          ..write('deviceId: $deviceId, ')
          ..write('name: $name, ')
          ..write('seen: $seen, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deviceId, name, seen, lastSyncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncPeerRow &&
          other.deviceId == this.deviceId &&
          other.name == this.name &&
          other.seen == this.seen &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class SyncPeerCompanion extends UpdateCompanion<SyncPeerRow> {
  final Value<String> deviceId;
  final Value<String?> name;
  final Value<String> seen;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> rowid;
  const SyncPeerCompanion({
    this.deviceId = const Value.absent(),
    this.name = const Value.absent(),
    this.seen = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncPeerCompanion.insert({
    required String deviceId,
    this.name = const Value.absent(),
    required String seen,
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       seen = Value(seen);
  static Insertable<SyncPeerRow> custom({
    Expression<String>? deviceId,
    Expression<String>? name,
    Expression<String>? seen,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'deviceId': deviceId,
      if (name != null) 'name': name,
      if (seen != null) 'seen': seen,
      if (lastSyncedAt != null) 'lastSyncedAt': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncPeerCompanion copyWith({
    Value<String>? deviceId,
    Value<String?>? name,
    Value<String>? seen,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return SyncPeerCompanion(
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      seen: seen ?? this.seen,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['deviceId'] = Variable<String>(deviceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (seen.present) {
      map['seen'] = Variable<String>(seen.value);
    }
    if (lastSyncedAt.present) {
      map['lastSyncedAt'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncPeerCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('name: $name, ')
          ..write('seen: $seen, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SyncTombstone extends Table
    with TableInfo<SyncTombstone, SyncTombstoneRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SyncTombstone(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [entity, key, hlc];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'SyncTombstone';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncTombstoneRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entity, key};
  @override
  SyncTombstoneRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncTombstoneRow(
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
    );
  }

  @override
  SyncTombstone createAlias(String alias) {
    return SyncTombstone(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(entity, "key")'];
  @override
  bool get dontWriteConstraints => true;
}

class SyncTombstoneRow extends DataClass
    implements Insertable<SyncTombstoneRow> {
  final String entity;
  final String key;
  final String hlc;
  const SyncTombstoneRow({
    required this.entity,
    required this.key,
    required this.hlc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity'] = Variable<String>(entity);
    map['key'] = Variable<String>(key);
    map['hlc'] = Variable<String>(hlc);
    return map;
  }

  SyncTombstoneCompanion toCompanion(bool nullToAbsent) {
    return SyncTombstoneCompanion(
      entity: Value(entity),
      key: Value(key),
      hlc: Value(hlc),
    );
  }

  factory SyncTombstoneRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncTombstoneRow(
      entity: serializer.fromJson<String>(json['entity']),
      key: serializer.fromJson<String>(json['key']),
      hlc: serializer.fromJson<String>(json['hlc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entity': serializer.toJson<String>(entity),
      'key': serializer.toJson<String>(key),
      'hlc': serializer.toJson<String>(hlc),
    };
  }

  SyncTombstoneRow copyWith({String? entity, String? key, String? hlc}) =>
      SyncTombstoneRow(
        entity: entity ?? this.entity,
        key: key ?? this.key,
        hlc: hlc ?? this.hlc,
      );
  SyncTombstoneRow copyWithCompanion(SyncTombstoneCompanion data) {
    return SyncTombstoneRow(
      entity: data.entity.present ? data.entity.value : this.entity,
      key: data.key.present ? data.key.value : this.key,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncTombstoneRow(')
          ..write('entity: $entity, ')
          ..write('key: $key, ')
          ..write('hlc: $hlc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entity, key, hlc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncTombstoneRow &&
          other.entity == this.entity &&
          other.key == this.key &&
          other.hlc == this.hlc);
}

class SyncTombstoneCompanion extends UpdateCompanion<SyncTombstoneRow> {
  final Value<String> entity;
  final Value<String> key;
  final Value<String> hlc;
  final Value<int> rowid;
  const SyncTombstoneCompanion({
    this.entity = const Value.absent(),
    this.key = const Value.absent(),
    this.hlc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncTombstoneCompanion.insert({
    required String entity,
    required String key,
    required String hlc,
    this.rowid = const Value.absent(),
  }) : entity = Value(entity),
       key = Value(key),
       hlc = Value(hlc);
  static Insertable<SyncTombstoneRow> custom({
    Expression<String>? entity,
    Expression<String>? key,
    Expression<String>? hlc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entity != null) 'entity': entity,
      if (key != null) 'key': key,
      if (hlc != null) 'hlc': hlc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncTombstoneCompanion copyWith({
    Value<String>? entity,
    Value<String>? key,
    Value<String>? hlc,
    Value<int>? rowid,
  }) {
    return SyncTombstoneCompanion(
      entity: entity ?? this.entity,
      key: key ?? this.key,
      hlc: hlc ?? this.hlc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncTombstoneCompanion(')
          ..write('entity: $entity, ')
          ..write('key: $key, ')
          ..write('hlc: $hlc, ')
          ..write('rowid: $rowid')
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
  late final EtfHolding etfHolding = EtfHolding(this);
  late final Index etfHoldingInstrumentIdIdentityKey = Index(
    'EtfHolding_instrumentId_identity_key',
    'CREATE UNIQUE INDEX EtfHolding_instrumentId_identity_key ON EtfHolding (instrumentId, identity)',
  );
  late final Index etfHoldingInstrumentIdIdx = Index(
    'EtfHolding_instrumentId_idx',
    'CREATE INDEX EtfHolding_instrumentId_idx ON EtfHolding (instrumentId)',
  );
  late final EtfHoldingBlock etfHoldingBlock = EtfHoldingBlock(this);
  late final PortfolioTarget portfolioTarget = PortfolioTarget(this);
  late final Index portfolioTargetActiveFromKey = Index(
    'PortfolioTarget_activeFrom_key',
    'CREATE UNIQUE INDEX PortfolioTarget_activeFrom_key ON PortfolioTarget (activeFrom)',
  );
  late final PortfolioTargetLine portfolioTargetLine = PortfolioTargetLine(
    this,
  );
  late final Index portfolioTargetLineTargetIdIdx = Index(
    'PortfolioTargetLine_targetId_idx',
    'CREATE INDEX PortfolioTargetLine_targetId_idx ON PortfolioTargetLine (targetId)',
  );
  late final Index portfolioTargetLineTargetIdInstrumentIdKey = Index(
    'PortfolioTargetLine_targetId_instrumentId_key',
    'CREATE UNIQUE INDEX PortfolioTargetLine_targetId_instrumentId_key ON PortfolioTargetLine (targetId, instrumentId)',
  );
  late final SecurityIdentity securityIdentity = SecurityIdentity(this);
  late final Index securityIdentityCanonicalIdIdx = Index(
    'SecurityIdentity_canonicalId_idx',
    'CREATE INDEX SecurityIdentity_canonicalId_idx ON SecurityIdentity (canonicalId)',
  );
  late final SyncDevice syncDevice = SyncDevice(this);
  late final SyncPeer syncPeer = SyncPeer(this);
  late final SyncTombstone syncTombstone = SyncTombstone(this);
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
    fxRate,
    fxRateQuoteIdx,
    fxRateSourceBaseQuoteDayKey,
    settings,
    etfHolding,
    etfHoldingInstrumentIdIdentityKey,
    etfHoldingInstrumentIdIdx,
    etfHoldingBlock,
    portfolioTarget,
    portfolioTargetActiveFromKey,
    portfolioTargetLine,
    portfolioTargetLineTargetIdIdx,
    portfolioTargetLineTargetIdInstrumentIdKey,
    securityIdentity,
    securityIdentityCanonicalIdIdx,
    syncDevice,
    syncPeer,
    syncTombstone,
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
      result: [TableUpdate('EtfHolding', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'Instrument',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('EtfHoldingBlock', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'PortfolioTarget',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('PortfolioTargetLine', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'PortfolioTarget',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('PortfolioTargetLine', kind: UpdateKind.update)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}
