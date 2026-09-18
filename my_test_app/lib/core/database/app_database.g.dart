// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $FavoriteEntriesTable extends FavoriteEntries
    with TableInfo<$FavoriteEntriesTable, FavoriteEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoriteEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _itemKeyMeta = const VerificationMeta(
    'itemKey',
  );
  @override
  late final GeneratedColumn<String> itemKey = GeneratedColumn<String>(
    'item_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayTextMeta = const VerificationMeta(
    'displayText',
  );
  @override
  late final GeneratedColumn<String> displayText = GeneratedColumn<String>(
    'display_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    videoId,
    itemKey,
    displayText,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorite_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavoriteEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    }
    if (data.containsKey('item_key')) {
      context.handle(
        _itemKeyMeta,
        itemKey.isAcceptableOrUnknown(data['item_key']!, _itemKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_itemKeyMeta);
    }
    if (data.containsKey('display_text')) {
      context.handle(
        _displayTextMeta,
        displayText.isAcceptableOrUnknown(
          data['display_text']!,
          _displayTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayTextMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FavoriteEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_id'],
      ),
      itemKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_key'],
      )!,
      displayText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_text'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FavoriteEntriesTable createAlias(String alias) {
    return $FavoriteEntriesTable(attachedDatabase, alias);
  }
}

class FavoriteEntry extends DataClass implements Insertable<FavoriteEntry> {
  final String id;
  final String kind;
  final String? videoId;
  final String itemKey;
  final String displayText;
  final DateTime createdAt;
  const FavoriteEntry({
    required this.id,
    required this.kind,
    this.videoId,
    required this.itemKey,
    required this.displayText,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || videoId != null) {
      map['video_id'] = Variable<String>(videoId);
    }
    map['item_key'] = Variable<String>(itemKey);
    map['display_text'] = Variable<String>(displayText);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FavoriteEntriesCompanion toCompanion(bool nullToAbsent) {
    return FavoriteEntriesCompanion(
      id: Value(id),
      kind: Value(kind),
      videoId: videoId == null && nullToAbsent
          ? const Value.absent()
          : Value(videoId),
      itemKey: Value(itemKey),
      displayText: Value(displayText),
      createdAt: Value(createdAt),
    );
  }

  factory FavoriteEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteEntry(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      videoId: serializer.fromJson<String?>(json['videoId']),
      itemKey: serializer.fromJson<String>(json['itemKey']),
      displayText: serializer.fromJson<String>(json['displayText']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'videoId': serializer.toJson<String?>(videoId),
      'itemKey': serializer.toJson<String>(itemKey),
      'displayText': serializer.toJson<String>(displayText),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FavoriteEntry copyWith({
    String? id,
    String? kind,
    Value<String?> videoId = const Value.absent(),
    String? itemKey,
    String? displayText,
    DateTime? createdAt,
  }) => FavoriteEntry(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    videoId: videoId.present ? videoId.value : this.videoId,
    itemKey: itemKey ?? this.itemKey,
    displayText: displayText ?? this.displayText,
    createdAt: createdAt ?? this.createdAt,
  );
  FavoriteEntry copyWithCompanion(FavoriteEntriesCompanion data) {
    return FavoriteEntry(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      itemKey: data.itemKey.present ? data.itemKey.value : this.itemKey,
      displayText: data.displayText.present
          ? data.displayText.value
          : this.displayText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteEntry(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('videoId: $videoId, ')
          ..write('itemKey: $itemKey, ')
          ..write('displayText: $displayText, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, kind, videoId, itemKey, displayText, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteEntry &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.videoId == this.videoId &&
          other.itemKey == this.itemKey &&
          other.displayText == this.displayText &&
          other.createdAt == this.createdAt);
}

class FavoriteEntriesCompanion extends UpdateCompanion<FavoriteEntry> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String?> videoId;
  final Value<String> itemKey;
  final Value<String> displayText;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const FavoriteEntriesCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.videoId = const Value.absent(),
    this.itemKey = const Value.absent(),
    this.displayText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoriteEntriesCompanion.insert({
    required String id,
    required String kind,
    this.videoId = const Value.absent(),
    required String itemKey,
    required String displayText,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       itemKey = Value(itemKey),
       displayText = Value(displayText);
  static Insertable<FavoriteEntry> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? videoId,
    Expression<String>? itemKey,
    Expression<String>? displayText,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (videoId != null) 'video_id': videoId,
      if (itemKey != null) 'item_key': itemKey,
      if (displayText != null) 'display_text': displayText,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoriteEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String?>? videoId,
    Value<String>? itemKey,
    Value<String>? displayText,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return FavoriteEntriesCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      videoId: videoId ?? this.videoId,
      itemKey: itemKey ?? this.itemKey,
      displayText: displayText ?? this.displayText,
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
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (itemKey.present) {
      map['item_key'] = Variable<String>(itemKey.value);
    }
    if (displayText.present) {
      map['display_text'] = Variable<String>(displayText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteEntriesCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('videoId: $videoId, ')
          ..write('itemKey: $itemKey, ')
          ..write('displayText: $displayText, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FavoriteEntriesTable favoriteEntries = $FavoriteEntriesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [favoriteEntries];
}

typedef $$FavoriteEntriesTableCreateCompanionBuilder =
    FavoriteEntriesCompanion Function({
      required String id,
      required String kind,
      Value<String?> videoId,
      required String itemKey,
      required String displayText,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$FavoriteEntriesTableUpdateCompanionBuilder =
    FavoriteEntriesCompanion Function({
      Value<String> id,
      Value<String> kind,
      Value<String?> videoId,
      Value<String> itemKey,
      Value<String> displayText,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$FavoriteEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $FavoriteEntriesTable> {
  $$FavoriteEntriesTableFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemKey => $composableBuilder(
    column: $table.itemKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayText => $composableBuilder(
    column: $table.displayText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FavoriteEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoriteEntriesTable> {
  $$FavoriteEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemKey => $composableBuilder(
    column: $table.itemKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayText => $composableBuilder(
    column: $table.displayText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavoriteEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoriteEntriesTable> {
  $$FavoriteEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<String> get itemKey =>
      $composableBuilder(column: $table.itemKey, builder: (column) => column);

  GeneratedColumn<String> get displayText => $composableBuilder(
    column: $table.displayText,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FavoriteEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoriteEntriesTable,
          FavoriteEntry,
          $$FavoriteEntriesTableFilterComposer,
          $$FavoriteEntriesTableOrderingComposer,
          $$FavoriteEntriesTableAnnotationComposer,
          $$FavoriteEntriesTableCreateCompanionBuilder,
          $$FavoriteEntriesTableUpdateCompanionBuilder,
          (
            FavoriteEntry,
            BaseReferences<_$AppDatabase, $FavoriteEntriesTable, FavoriteEntry>,
          ),
          FavoriteEntry,
          PrefetchHooks Function()
        > {
  $$FavoriteEntriesTableTableManager(
    _$AppDatabase db,
    $FavoriteEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoriteEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoriteEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoriteEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> videoId = const Value.absent(),
                Value<String> itemKey = const Value.absent(),
                Value<String> displayText = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavoriteEntriesCompanion(
                id: id,
                kind: kind,
                videoId: videoId,
                itemKey: itemKey,
                displayText: displayText,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                Value<String?> videoId = const Value.absent(),
                required String itemKey,
                required String displayText,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavoriteEntriesCompanion.insert(
                id: id,
                kind: kind,
                videoId: videoId,
                itemKey: itemKey,
                displayText: displayText,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FavoriteEntriesTable, FavoriteEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FavoriteEntriesTable,
                    FavoriteEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FavoriteEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoriteEntriesTable,
      FavoriteEntry,
      $$FavoriteEntriesTableFilterComposer,
      $$FavoriteEntriesTableOrderingComposer,
      $$FavoriteEntriesTableAnnotationComposer,
      $$FavoriteEntriesTableCreateCompanionBuilder,
      $$FavoriteEntriesTableUpdateCompanionBuilder,
      (
        FavoriteEntry,
        BaseReferences<_$AppDatabase, $FavoriteEntriesTable, FavoriteEntry>,
      ),
      FavoriteEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FavoriteEntriesTableTableManager get favoriteEntries =>
      $$FavoriteEntriesTableTableManager(_db, _db.favoriteEntries);
}
