// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pot_database.dart';

// ignore_for_file: type=lint
class $PotProbeRecordsTable extends PotProbeRecords
    with TableInfo<$PotProbeRecordsTable, PotProbeRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PotProbeRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentinelTextMeta = const VerificationMeta(
    'sentinelText',
  );
  @override
  late final GeneratedColumn<String> sentinelText = GeneratedColumn<String>(
    'sentinel_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localeSampleArMeta = const VerificationMeta(
    'localeSampleAr',
  );
  @override
  late final GeneratedColumn<String> localeSampleAr = GeneratedColumn<String>(
    'locale_sample_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localeSampleFrMeta = const VerificationMeta(
    'localeSampleFr',
  );
  @override
  late final GeneratedColumn<String> localeSampleFr = GeneratedColumn<String>(
    'locale_sample_fr',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localeSampleEnMeta = const VerificationMeta(
    'localeSampleEn',
  );
  @override
  late final GeneratedColumn<String> localeSampleEn = GeneratedColumn<String>(
    'locale_sample_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountDzdMeta = const VerificationMeta(
    'amountDzd',
  );
  @override
  late final GeneratedColumn<int> amountDzd = GeneratedColumn<int>(
    'amount_dzd',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<String> createdAtUtc = GeneratedColumn<String>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sentinelText,
    localeSampleAr,
    localeSampleFr,
    localeSampleEn,
    amountDzd,
    createdAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pot_probe_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<PotProbeRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sentinel_text')) {
      context.handle(
        _sentinelTextMeta,
        sentinelText.isAcceptableOrUnknown(
          data['sentinel_text']!,
          _sentinelTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sentinelTextMeta);
    }
    if (data.containsKey('locale_sample_ar')) {
      context.handle(
        _localeSampleArMeta,
        localeSampleAr.isAcceptableOrUnknown(
          data['locale_sample_ar']!,
          _localeSampleArMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localeSampleArMeta);
    }
    if (data.containsKey('locale_sample_fr')) {
      context.handle(
        _localeSampleFrMeta,
        localeSampleFr.isAcceptableOrUnknown(
          data['locale_sample_fr']!,
          _localeSampleFrMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localeSampleFrMeta);
    }
    if (data.containsKey('locale_sample_en')) {
      context.handle(
        _localeSampleEnMeta,
        localeSampleEn.isAcceptableOrUnknown(
          data['locale_sample_en']!,
          _localeSampleEnMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localeSampleEnMeta);
    }
    if (data.containsKey('amount_dzd')) {
      context.handle(
        _amountDzdMeta,
        amountDzd.isAcceptableOrUnknown(data['amount_dzd']!, _amountDzdMeta),
      );
    } else if (isInserting) {
      context.missing(_amountDzdMeta);
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PotProbeRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PotProbeRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sentinelText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sentinel_text'],
      )!,
      localeSampleAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locale_sample_ar'],
      )!,
      localeSampleFr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locale_sample_fr'],
      )!,
      localeSampleEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locale_sample_en'],
      )!,
      amountDzd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_dzd'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at_utc'],
      )!,
    );
  }

  @override
  $PotProbeRecordsTable createAlias(String alias) {
    return $PotProbeRecordsTable(attachedDatabase, alias);
  }
}

class PotProbeRecord extends DataClass implements Insertable<PotProbeRecord> {
  /// UUIDv4 primary key.
  final String id;

  /// Known high-entropy UTF-8 sentinel string scanned for in raw on-disk
  /// byte inspection (`FR-008`, `SC-002`).
  final String sentinelText;

  /// Arabic (`ar-DZ` RTL) UTF-8 probe text (`Principle IV`).
  final String localeSampleAr;

  /// French (`fr-DZ` LTR) UTF-8 probe text (`Principle IV`).
  final String localeSampleFr;

  /// English (`en` LTR) UTF-8 probe text (`Principle IV`).
  final String localeSampleEn;

  /// Whole-integer Algerian Dinar amount (`BIGINT` / `INTEGER` `DZD`,
  /// `Principle VI`).
  final int amountDzd;

  /// ISO-8601 UTC timestamp string (`YYYY-MM-DDTHH:mm:ssZ`).
  final String createdAtUtc;
  const PotProbeRecord({
    required this.id,
    required this.sentinelText,
    required this.localeSampleAr,
    required this.localeSampleFr,
    required this.localeSampleEn,
    required this.amountDzd,
    required this.createdAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sentinel_text'] = Variable<String>(sentinelText);
    map['locale_sample_ar'] = Variable<String>(localeSampleAr);
    map['locale_sample_fr'] = Variable<String>(localeSampleFr);
    map['locale_sample_en'] = Variable<String>(localeSampleEn);
    map['amount_dzd'] = Variable<int>(amountDzd);
    map['created_at_utc'] = Variable<String>(createdAtUtc);
    return map;
  }

  PotProbeRecordsCompanion toCompanion(bool nullToAbsent) {
    return PotProbeRecordsCompanion(
      id: Value(id),
      sentinelText: Value(sentinelText),
      localeSampleAr: Value(localeSampleAr),
      localeSampleFr: Value(localeSampleFr),
      localeSampleEn: Value(localeSampleEn),
      amountDzd: Value(amountDzd),
      createdAtUtc: Value(createdAtUtc),
    );
  }

  factory PotProbeRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PotProbeRecord(
      id: serializer.fromJson<String>(json['id']),
      sentinelText: serializer.fromJson<String>(json['sentinelText']),
      localeSampleAr: serializer.fromJson<String>(json['localeSampleAr']),
      localeSampleFr: serializer.fromJson<String>(json['localeSampleFr']),
      localeSampleEn: serializer.fromJson<String>(json['localeSampleEn']),
      amountDzd: serializer.fromJson<int>(json['amountDzd']),
      createdAtUtc: serializer.fromJson<String>(json['createdAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sentinelText': serializer.toJson<String>(sentinelText),
      'localeSampleAr': serializer.toJson<String>(localeSampleAr),
      'localeSampleFr': serializer.toJson<String>(localeSampleFr),
      'localeSampleEn': serializer.toJson<String>(localeSampleEn),
      'amountDzd': serializer.toJson<int>(amountDzd),
      'createdAtUtc': serializer.toJson<String>(createdAtUtc),
    };
  }

  PotProbeRecord copyWith({
    String? id,
    String? sentinelText,
    String? localeSampleAr,
    String? localeSampleFr,
    String? localeSampleEn,
    int? amountDzd,
    String? createdAtUtc,
  }) => PotProbeRecord(
    id: id ?? this.id,
    sentinelText: sentinelText ?? this.sentinelText,
    localeSampleAr: localeSampleAr ?? this.localeSampleAr,
    localeSampleFr: localeSampleFr ?? this.localeSampleFr,
    localeSampleEn: localeSampleEn ?? this.localeSampleEn,
    amountDzd: amountDzd ?? this.amountDzd,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
  );
  PotProbeRecord copyWithCompanion(PotProbeRecordsCompanion data) {
    return PotProbeRecord(
      id: data.id.present ? data.id.value : this.id,
      sentinelText: data.sentinelText.present
          ? data.sentinelText.value
          : this.sentinelText,
      localeSampleAr: data.localeSampleAr.present
          ? data.localeSampleAr.value
          : this.localeSampleAr,
      localeSampleFr: data.localeSampleFr.present
          ? data.localeSampleFr.value
          : this.localeSampleFr,
      localeSampleEn: data.localeSampleEn.present
          ? data.localeSampleEn.value
          : this.localeSampleEn,
      amountDzd: data.amountDzd.present ? data.amountDzd.value : this.amountDzd,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PotProbeRecord(')
          ..write('id: $id, ')
          ..write('sentinelText: $sentinelText, ')
          ..write('localeSampleAr: $localeSampleAr, ')
          ..write('localeSampleFr: $localeSampleFr, ')
          ..write('localeSampleEn: $localeSampleEn, ')
          ..write('amountDzd: $amountDzd, ')
          ..write('createdAtUtc: $createdAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sentinelText,
    localeSampleAr,
    localeSampleFr,
    localeSampleEn,
    amountDzd,
    createdAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PotProbeRecord &&
          other.id == this.id &&
          other.sentinelText == this.sentinelText &&
          other.localeSampleAr == this.localeSampleAr &&
          other.localeSampleFr == this.localeSampleFr &&
          other.localeSampleEn == this.localeSampleEn &&
          other.amountDzd == this.amountDzd &&
          other.createdAtUtc == this.createdAtUtc);
}

class PotProbeRecordsCompanion extends UpdateCompanion<PotProbeRecord> {
  final Value<String> id;
  final Value<String> sentinelText;
  final Value<String> localeSampleAr;
  final Value<String> localeSampleFr;
  final Value<String> localeSampleEn;
  final Value<int> amountDzd;
  final Value<String> createdAtUtc;
  final Value<int> rowid;
  const PotProbeRecordsCompanion({
    this.id = const Value.absent(),
    this.sentinelText = const Value.absent(),
    this.localeSampleAr = const Value.absent(),
    this.localeSampleFr = const Value.absent(),
    this.localeSampleEn = const Value.absent(),
    this.amountDzd = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PotProbeRecordsCompanion.insert({
    required String id,
    required String sentinelText,
    required String localeSampleAr,
    required String localeSampleFr,
    required String localeSampleEn,
    required int amountDzd,
    required String createdAtUtc,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sentinelText = Value(sentinelText),
       localeSampleAr = Value(localeSampleAr),
       localeSampleFr = Value(localeSampleFr),
       localeSampleEn = Value(localeSampleEn),
       amountDzd = Value(amountDzd),
       createdAtUtc = Value(createdAtUtc);
  static Insertable<PotProbeRecord> custom({
    Expression<String>? id,
    Expression<String>? sentinelText,
    Expression<String>? localeSampleAr,
    Expression<String>? localeSampleFr,
    Expression<String>? localeSampleEn,
    Expression<int>? amountDzd,
    Expression<String>? createdAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sentinelText != null) 'sentinel_text': sentinelText,
      if (localeSampleAr != null) 'locale_sample_ar': localeSampleAr,
      if (localeSampleFr != null) 'locale_sample_fr': localeSampleFr,
      if (localeSampleEn != null) 'locale_sample_en': localeSampleEn,
      if (amountDzd != null) 'amount_dzd': amountDzd,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PotProbeRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? sentinelText,
    Value<String>? localeSampleAr,
    Value<String>? localeSampleFr,
    Value<String>? localeSampleEn,
    Value<int>? amountDzd,
    Value<String>? createdAtUtc,
    Value<int>? rowid,
  }) {
    return PotProbeRecordsCompanion(
      id: id ?? this.id,
      sentinelText: sentinelText ?? this.sentinelText,
      localeSampleAr: localeSampleAr ?? this.localeSampleAr,
      localeSampleFr: localeSampleFr ?? this.localeSampleFr,
      localeSampleEn: localeSampleEn ?? this.localeSampleEn,
      amountDzd: amountDzd ?? this.amountDzd,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sentinelText.present) {
      map['sentinel_text'] = Variable<String>(sentinelText.value);
    }
    if (localeSampleAr.present) {
      map['locale_sample_ar'] = Variable<String>(localeSampleAr.value);
    }
    if (localeSampleFr.present) {
      map['locale_sample_fr'] = Variable<String>(localeSampleFr.value);
    }
    if (localeSampleEn.present) {
      map['locale_sample_en'] = Variable<String>(localeSampleEn.value);
    }
    if (amountDzd.present) {
      map['amount_dzd'] = Variable<int>(amountDzd.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<String>(createdAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PotProbeRecordsCompanion(')
          ..write('id: $id, ')
          ..write('sentinelText: $sentinelText, ')
          ..write('localeSampleAr: $localeSampleAr, ')
          ..write('localeSampleFr: $localeSampleFr, ')
          ..write('localeSampleEn: $localeSampleEn, ')
          ..write('amountDzd: $amountDzd, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$PotDatabase extends GeneratedDatabase {
  _$PotDatabase(QueryExecutor e) : super(e);
  $PotDatabaseManager get managers => $PotDatabaseManager(this);
  late final $PotProbeRecordsTable potProbeRecords = $PotProbeRecordsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [potProbeRecords];
}

typedef $$PotProbeRecordsTableCreateCompanionBuilder =
    PotProbeRecordsCompanion Function({
      required String id,
      required String sentinelText,
      required String localeSampleAr,
      required String localeSampleFr,
      required String localeSampleEn,
      required int amountDzd,
      required String createdAtUtc,
      Value<int> rowid,
    });
typedef $$PotProbeRecordsTableUpdateCompanionBuilder =
    PotProbeRecordsCompanion Function({
      Value<String> id,
      Value<String> sentinelText,
      Value<String> localeSampleAr,
      Value<String> localeSampleFr,
      Value<String> localeSampleEn,
      Value<int> amountDzd,
      Value<String> createdAtUtc,
      Value<int> rowid,
    });

class $$PotProbeRecordsTableFilterComposer
    extends Composer<_$PotDatabase, $PotProbeRecordsTable> {
  $$PotProbeRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sentinelText => $composableBuilder(
    column: $table.sentinelText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localeSampleAr => $composableBuilder(
    column: $table.localeSampleAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localeSampleFr => $composableBuilder(
    column: $table.localeSampleFr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localeSampleEn => $composableBuilder(
    column: $table.localeSampleEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountDzd => $composableBuilder(
    column: $table.amountDzd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PotProbeRecordsTableOrderingComposer
    extends Composer<_$PotDatabase, $PotProbeRecordsTable> {
  $$PotProbeRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sentinelText => $composableBuilder(
    column: $table.sentinelText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localeSampleAr => $composableBuilder(
    column: $table.localeSampleAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localeSampleFr => $composableBuilder(
    column: $table.localeSampleFr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localeSampleEn => $composableBuilder(
    column: $table.localeSampleEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountDzd => $composableBuilder(
    column: $table.amountDzd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PotProbeRecordsTableAnnotationComposer
    extends Composer<_$PotDatabase, $PotProbeRecordsTable> {
  $$PotProbeRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sentinelText => $composableBuilder(
    column: $table.sentinelText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localeSampleAr => $composableBuilder(
    column: $table.localeSampleAr,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localeSampleFr => $composableBuilder(
    column: $table.localeSampleFr,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localeSampleEn => $composableBuilder(
    column: $table.localeSampleEn,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountDzd =>
      $composableBuilder(column: $table.amountDzd, builder: (column) => column);

  GeneratedColumn<String> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );
}

class $$PotProbeRecordsTableTableManager
    extends
        RootTableManager<
          _$PotDatabase,
          $PotProbeRecordsTable,
          PotProbeRecord,
          $$PotProbeRecordsTableFilterComposer,
          $$PotProbeRecordsTableOrderingComposer,
          $$PotProbeRecordsTableAnnotationComposer,
          $$PotProbeRecordsTableCreateCompanionBuilder,
          $$PotProbeRecordsTableUpdateCompanionBuilder,
          (
            PotProbeRecord,
            BaseReferences<
              _$PotDatabase,
              $PotProbeRecordsTable,
              PotProbeRecord
            >,
          ),
          PotProbeRecord,
          PrefetchHooks Function()
        > {
  $$PotProbeRecordsTableTableManager(
    _$PotDatabase db,
    $PotProbeRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PotProbeRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PotProbeRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PotProbeRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sentinelText = const Value.absent(),
                Value<String> localeSampleAr = const Value.absent(),
                Value<String> localeSampleFr = const Value.absent(),
                Value<String> localeSampleEn = const Value.absent(),
                Value<int> amountDzd = const Value.absent(),
                Value<String> createdAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PotProbeRecordsCompanion(
                id: id,
                sentinelText: sentinelText,
                localeSampleAr: localeSampleAr,
                localeSampleFr: localeSampleFr,
                localeSampleEn: localeSampleEn,
                amountDzd: amountDzd,
                createdAtUtc: createdAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sentinelText,
                required String localeSampleAr,
                required String localeSampleFr,
                required String localeSampleEn,
                required int amountDzd,
                required String createdAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => PotProbeRecordsCompanion.insert(
                id: id,
                sentinelText: sentinelText,
                localeSampleAr: localeSampleAr,
                localeSampleFr: localeSampleFr,
                localeSampleEn: localeSampleEn,
                amountDzd: amountDzd,
                createdAtUtc: createdAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PotProbeRecordsTable, PotProbeRecord>(table),
                  BaseReferences<
                    _$PotDatabase,
                    $PotProbeRecordsTable,
                    PotProbeRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PotProbeRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$PotDatabase,
      $PotProbeRecordsTable,
      PotProbeRecord,
      $$PotProbeRecordsTableFilterComposer,
      $$PotProbeRecordsTableOrderingComposer,
      $$PotProbeRecordsTableAnnotationComposer,
      $$PotProbeRecordsTableCreateCompanionBuilder,
      $$PotProbeRecordsTableUpdateCompanionBuilder,
      (
        PotProbeRecord,
        BaseReferences<_$PotDatabase, $PotProbeRecordsTable, PotProbeRecord>,
      ),
      PotProbeRecord,
      PrefetchHooks Function()
    >;

class $PotDatabaseManager {
  final _$PotDatabase _db;
  $PotDatabaseManager(this._db);
  $$PotProbeRecordsTableTableManager get potProbeRecords =>
      $$PotProbeRecordsTableTableManager(_db, _db.potProbeRecords);
}
