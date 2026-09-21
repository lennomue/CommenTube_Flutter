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

class $QuizHistoryEntriesTable extends QuizHistoryEntries
    with TableInfo<$QuizHistoryEntriesTable, QuizHistoryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuizHistoryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playedAtMeta = const VerificationMeta(
    'playedAt',
  );
  @override
  late final GeneratedColumn<DateTime> playedAt = GeneratedColumn<DateTime>(
    'played_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [videoId, playedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quiz_history_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuizHistoryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('played_at')) {
      context.handle(
        _playedAtMeta,
        playedAt.isAcceptableOrUnknown(data['played_at']!, _playedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_playedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {videoId};
  @override
  QuizHistoryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuizHistoryEntry(
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_id'],
      )!,
      playedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}played_at'],
      )!,
    );
  }

  @override
  $QuizHistoryEntriesTable createAlias(String alias) {
    return $QuizHistoryEntriesTable(attachedDatabase, alias);
  }
}

class QuizHistoryEntry extends DataClass
    implements Insertable<QuizHistoryEntry> {
  final String videoId;
  final DateTime playedAt;
  const QuizHistoryEntry({required this.videoId, required this.playedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['video_id'] = Variable<String>(videoId);
    map['played_at'] = Variable<DateTime>(playedAt);
    return map;
  }

  QuizHistoryEntriesCompanion toCompanion(bool nullToAbsent) {
    return QuizHistoryEntriesCompanion(
      videoId: Value(videoId),
      playedAt: Value(playedAt),
    );
  }

  factory QuizHistoryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuizHistoryEntry(
      videoId: serializer.fromJson<String>(json['videoId']),
      playedAt: serializer.fromJson<DateTime>(json['playedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'videoId': serializer.toJson<String>(videoId),
      'playedAt': serializer.toJson<DateTime>(playedAt),
    };
  }

  QuizHistoryEntry copyWith({String? videoId, DateTime? playedAt}) =>
      QuizHistoryEntry(
        videoId: videoId ?? this.videoId,
        playedAt: playedAt ?? this.playedAt,
      );
  QuizHistoryEntry copyWithCompanion(QuizHistoryEntriesCompanion data) {
    return QuizHistoryEntry(
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      playedAt: data.playedAt.present ? data.playedAt.value : this.playedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuizHistoryEntry(')
          ..write('videoId: $videoId, ')
          ..write('playedAt: $playedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(videoId, playedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuizHistoryEntry &&
          other.videoId == this.videoId &&
          other.playedAt == this.playedAt);
}

class QuizHistoryEntriesCompanion extends UpdateCompanion<QuizHistoryEntry> {
  final Value<String> videoId;
  final Value<DateTime> playedAt;
  final Value<int> rowid;
  const QuizHistoryEntriesCompanion({
    this.videoId = const Value.absent(),
    this.playedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuizHistoryEntriesCompanion.insert({
    required String videoId,
    required DateTime playedAt,
    this.rowid = const Value.absent(),
  }) : videoId = Value(videoId),
       playedAt = Value(playedAt);
  static Insertable<QuizHistoryEntry> custom({
    Expression<String>? videoId,
    Expression<DateTime>? playedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (videoId != null) 'video_id': videoId,
      if (playedAt != null) 'played_at': playedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuizHistoryEntriesCompanion copyWith({
    Value<String>? videoId,
    Value<DateTime>? playedAt,
    Value<int>? rowid,
  }) {
    return QuizHistoryEntriesCompanion(
      videoId: videoId ?? this.videoId,
      playedAt: playedAt ?? this.playedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (playedAt.present) {
      map['played_at'] = Variable<DateTime>(playedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuizHistoryEntriesCompanion(')
          ..write('videoId: $videoId, ')
          ..write('playedAt: $playedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaylistRecordsTable extends PlaylistRecords
    with TableInfo<$PlaylistRecordsTable, PlaylistRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPublicMeta = const VerificationMeta(
    'isPublic',
  );
  @override
  late final GeneratedColumn<bool> isPublic = GeneratedColumn<bool>(
    'is_public',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_public" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _allowsCollaborationMeta =
      const VerificationMeta('allowsCollaboration');
  @override
  late final GeneratedColumn<bool> allowsCollaboration = GeneratedColumn<bool>(
    'allows_collaboration',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("allows_collaboration" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isOwnedMeta = const VerificationMeta(
    'isOwned',
  );
  @override
  late final GeneratedColumn<bool> isOwned = GeneratedColumn<bool>(
    'is_owned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_owned" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _sourcePlaylistIdMeta = const VerificationMeta(
    'sourcePlaylistId',
  );
  @override
  late final GeneratedColumn<String> sourcePlaylistId = GeneratedColumn<String>(
    'source_playlist_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    isPublic,
    description,
    allowsCollaboration,
    isOwned,
    sourcePlaylistId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaylistRecord> instance, {
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
    if (data.containsKey('is_public')) {
      context.handle(
        _isPublicMeta,
        isPublic.isAcceptableOrUnknown(data['is_public']!, _isPublicMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('allows_collaboration')) {
      context.handle(
        _allowsCollaborationMeta,
        allowsCollaboration.isAcceptableOrUnknown(
          data['allows_collaboration']!,
          _allowsCollaborationMeta,
        ),
      );
    }
    if (data.containsKey('is_owned')) {
      context.handle(
        _isOwnedMeta,
        isOwned.isAcceptableOrUnknown(data['is_owned']!, _isOwnedMeta),
      );
    }
    if (data.containsKey('source_playlist_id')) {
      context.handle(
        _sourcePlaylistIdMeta,
        sourcePlaylistId.isAcceptableOrUnknown(
          data['source_playlist_id']!,
          _sourcePlaylistIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaylistRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isPublic: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_public'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      allowsCollaboration: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}allows_collaboration'],
      )!,
      isOwned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_owned'],
      )!,
      sourcePlaylistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_playlist_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PlaylistRecordsTable createAlias(String alias) {
    return $PlaylistRecordsTable(attachedDatabase, alias);
  }
}

class PlaylistRecord extends DataClass implements Insertable<PlaylistRecord> {
  final String id;
  final String name;
  final bool isPublic;
  final String description;
  final bool allowsCollaboration;
  final bool isOwned;
  final String? sourcePlaylistId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PlaylistRecord({
    required this.id,
    required this.name,
    required this.isPublic,
    required this.description,
    required this.allowsCollaboration,
    required this.isOwned,
    this.sourcePlaylistId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['is_public'] = Variable<bool>(isPublic);
    map['description'] = Variable<String>(description);
    map['allows_collaboration'] = Variable<bool>(allowsCollaboration);
    map['is_owned'] = Variable<bool>(isOwned);
    if (!nullToAbsent || sourcePlaylistId != null) {
      map['source_playlist_id'] = Variable<String>(sourcePlaylistId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PlaylistRecordsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistRecordsCompanion(
      id: Value(id),
      name: Value(name),
      isPublic: Value(isPublic),
      description: Value(description),
      allowsCollaboration: Value(allowsCollaboration),
      isOwned: Value(isOwned),
      sourcePlaylistId: sourcePlaylistId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourcePlaylistId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PlaylistRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistRecord(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      isPublic: serializer.fromJson<bool>(json['isPublic']),
      description: serializer.fromJson<String>(json['description']),
      allowsCollaboration: serializer.fromJson<bool>(
        json['allowsCollaboration'],
      ),
      isOwned: serializer.fromJson<bool>(json['isOwned']),
      sourcePlaylistId: serializer.fromJson<String?>(json['sourcePlaylistId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'isPublic': serializer.toJson<bool>(isPublic),
      'description': serializer.toJson<String>(description),
      'allowsCollaboration': serializer.toJson<bool>(allowsCollaboration),
      'isOwned': serializer.toJson<bool>(isOwned),
      'sourcePlaylistId': serializer.toJson<String?>(sourcePlaylistId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PlaylistRecord copyWith({
    String? id,
    String? name,
    bool? isPublic,
    String? description,
    bool? allowsCollaboration,
    bool? isOwned,
    Value<String?> sourcePlaylistId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PlaylistRecord(
    id: id ?? this.id,
    name: name ?? this.name,
    isPublic: isPublic ?? this.isPublic,
    description: description ?? this.description,
    allowsCollaboration: allowsCollaboration ?? this.allowsCollaboration,
    isOwned: isOwned ?? this.isOwned,
    sourcePlaylistId: sourcePlaylistId.present
        ? sourcePlaylistId.value
        : this.sourcePlaylistId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PlaylistRecord copyWithCompanion(PlaylistRecordsCompanion data) {
    return PlaylistRecord(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      isPublic: data.isPublic.present ? data.isPublic.value : this.isPublic,
      description: data.description.present
          ? data.description.value
          : this.description,
      allowsCollaboration: data.allowsCollaboration.present
          ? data.allowsCollaboration.value
          : this.allowsCollaboration,
      isOwned: data.isOwned.present ? data.isOwned.value : this.isOwned,
      sourcePlaylistId: data.sourcePlaylistId.present
          ? data.sourcePlaylistId.value
          : this.sourcePlaylistId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistRecord(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isPublic: $isPublic, ')
          ..write('description: $description, ')
          ..write('allowsCollaboration: $allowsCollaboration, ')
          ..write('isOwned: $isOwned, ')
          ..write('sourcePlaylistId: $sourcePlaylistId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    isPublic,
    description,
    allowsCollaboration,
    isOwned,
    sourcePlaylistId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistRecord &&
          other.id == this.id &&
          other.name == this.name &&
          other.isPublic == this.isPublic &&
          other.description == this.description &&
          other.allowsCollaboration == this.allowsCollaboration &&
          other.isOwned == this.isOwned &&
          other.sourcePlaylistId == this.sourcePlaylistId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PlaylistRecordsCompanion extends UpdateCompanion<PlaylistRecord> {
  final Value<String> id;
  final Value<String> name;
  final Value<bool> isPublic;
  final Value<String> description;
  final Value<bool> allowsCollaboration;
  final Value<bool> isOwned;
  final Value<String?> sourcePlaylistId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PlaylistRecordsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.isPublic = const Value.absent(),
    this.description = const Value.absent(),
    this.allowsCollaboration = const Value.absent(),
    this.isOwned = const Value.absent(),
    this.sourcePlaylistId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistRecordsCompanion.insert({
    required String id,
    required String name,
    this.isPublic = const Value.absent(),
    this.description = const Value.absent(),
    this.allowsCollaboration = const Value.absent(),
    this.isOwned = const Value.absent(),
    this.sourcePlaylistId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<PlaylistRecord> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<bool>? isPublic,
    Expression<String>? description,
    Expression<bool>? allowsCollaboration,
    Expression<bool>? isOwned,
    Expression<String>? sourcePlaylistId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (isPublic != null) 'is_public': isPublic,
      if (description != null) 'description': description,
      if (allowsCollaboration != null)
        'allows_collaboration': allowsCollaboration,
      if (isOwned != null) 'is_owned': isOwned,
      if (sourcePlaylistId != null) 'source_playlist_id': sourcePlaylistId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<bool>? isPublic,
    Value<String>? description,
    Value<bool>? allowsCollaboration,
    Value<bool>? isOwned,
    Value<String?>? sourcePlaylistId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PlaylistRecordsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      isPublic: isPublic ?? this.isPublic,
      description: description ?? this.description,
      allowsCollaboration: allowsCollaboration ?? this.allowsCollaboration,
      isOwned: isOwned ?? this.isOwned,
      sourcePlaylistId: sourcePlaylistId ?? this.sourcePlaylistId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (isPublic.present) {
      map['is_public'] = Variable<bool>(isPublic.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (allowsCollaboration.present) {
      map['allows_collaboration'] = Variable<bool>(allowsCollaboration.value);
    }
    if (isOwned.present) {
      map['is_owned'] = Variable<bool>(isOwned.value);
    }
    if (sourcePlaylistId.present) {
      map['source_playlist_id'] = Variable<String>(sourcePlaylistId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistRecordsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isPublic: $isPublic, ')
          ..write('description: $description, ')
          ..write('allowsCollaboration: $allowsCollaboration, ')
          ..write('isOwned: $isOwned, ')
          ..write('sourcePlaylistId: $sourcePlaylistId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaylistItemEntriesTable extends PlaylistItemEntries
    with TableInfo<$PlaylistItemEntriesTable, PlaylistItemEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistItemEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES playlist_records (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  @override
  List<GeneratedColumn> get $columns => [
    playlistId,
    videoId,
    position,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist_item_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaylistItemEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playlistId, videoId};
  @override
  PlaylistItemEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistItemEntry(
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_id'],
      )!,
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $PlaylistItemEntriesTable createAlias(String alias) {
    return $PlaylistItemEntriesTable(attachedDatabase, alias);
  }
}

class PlaylistItemEntry extends DataClass
    implements Insertable<PlaylistItemEntry> {
  final String playlistId;
  final String videoId;
  final int position;
  final DateTime addedAt;
  const PlaylistItemEntry({
    required this.playlistId,
    required this.videoId,
    required this.position,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['playlist_id'] = Variable<String>(playlistId);
    map['video_id'] = Variable<String>(videoId);
    map['position'] = Variable<int>(position);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  PlaylistItemEntriesCompanion toCompanion(bool nullToAbsent) {
    return PlaylistItemEntriesCompanion(
      playlistId: Value(playlistId),
      videoId: Value(videoId),
      position: Value(position),
      addedAt: Value(addedAt),
    );
  }

  factory PlaylistItemEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistItemEntry(
      playlistId: serializer.fromJson<String>(json['playlistId']),
      videoId: serializer.fromJson<String>(json['videoId']),
      position: serializer.fromJson<int>(json['position']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playlistId': serializer.toJson<String>(playlistId),
      'videoId': serializer.toJson<String>(videoId),
      'position': serializer.toJson<int>(position),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  PlaylistItemEntry copyWith({
    String? playlistId,
    String? videoId,
    int? position,
    DateTime? addedAt,
  }) => PlaylistItemEntry(
    playlistId: playlistId ?? this.playlistId,
    videoId: videoId ?? this.videoId,
    position: position ?? this.position,
    addedAt: addedAt ?? this.addedAt,
  );
  PlaylistItemEntry copyWithCompanion(PlaylistItemEntriesCompanion data) {
    return PlaylistItemEntry(
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      position: data.position.present ? data.position.value : this.position,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistItemEntry(')
          ..write('playlistId: $playlistId, ')
          ..write('videoId: $videoId, ')
          ..write('position: $position, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playlistId, videoId, position, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistItemEntry &&
          other.playlistId == this.playlistId &&
          other.videoId == this.videoId &&
          other.position == this.position &&
          other.addedAt == this.addedAt);
}

class PlaylistItemEntriesCompanion extends UpdateCompanion<PlaylistItemEntry> {
  final Value<String> playlistId;
  final Value<String> videoId;
  final Value<int> position;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const PlaylistItemEntriesCompanion({
    this.playlistId = const Value.absent(),
    this.videoId = const Value.absent(),
    this.position = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistItemEntriesCompanion.insert({
    required String playlistId,
    required String videoId,
    required int position,
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : playlistId = Value(playlistId),
       videoId = Value(videoId),
       position = Value(position);
  static Insertable<PlaylistItemEntry> custom({
    Expression<String>? playlistId,
    Expression<String>? videoId,
    Expression<int>? position,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playlistId != null) 'playlist_id': playlistId,
      if (videoId != null) 'video_id': videoId,
      if (position != null) 'position': position,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistItemEntriesCompanion copyWith({
    Value<String>? playlistId,
    Value<String>? videoId,
    Value<int>? position,
    Value<DateTime>? addedAt,
    Value<int>? rowid,
  }) {
    return PlaylistItemEntriesCompanion(
      playlistId: playlistId ?? this.playlistId,
      videoId: videoId ?? this.videoId,
      position: position ?? this.position,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistItemEntriesCompanion(')
          ..write('playlistId: $playlistId, ')
          ..write('videoId: $videoId, ')
          ..write('position: $position, ')
          ..write('addedAt: $addedAt, ')
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
  late final $QuizHistoryEntriesTable quizHistoryEntries =
      $QuizHistoryEntriesTable(this);
  late final $PlaylistRecordsTable playlistRecords = $PlaylistRecordsTable(
    this,
  );
  late final $PlaylistItemEntriesTable playlistItemEntries =
      $PlaylistItemEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    favoriteEntries,
    quizHistoryEntries,
    playlistRecords,
    playlistItemEntries,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlist_records',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playlist_item_entries', kind: UpdateKind.delete)],
    ),
  ]);
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
typedef $$QuizHistoryEntriesTableCreateCompanionBuilder =
    QuizHistoryEntriesCompanion Function({
      required String videoId,
      required DateTime playedAt,
      Value<int> rowid,
    });
typedef $$QuizHistoryEntriesTableUpdateCompanionBuilder =
    QuizHistoryEntriesCompanion Function({
      Value<String> videoId,
      Value<DateTime> playedAt,
      Value<int> rowid,
    });

class $$QuizHistoryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $QuizHistoryEntriesTable> {
  $$QuizHistoryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuizHistoryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $QuizHistoryEntriesTable> {
  $$QuizHistoryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuizHistoryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuizHistoryEntriesTable> {
  $$QuizHistoryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<DateTime> get playedAt =>
      $composableBuilder(column: $table.playedAt, builder: (column) => column);
}

class $$QuizHistoryEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuizHistoryEntriesTable,
          QuizHistoryEntry,
          $$QuizHistoryEntriesTableFilterComposer,
          $$QuizHistoryEntriesTableOrderingComposer,
          $$QuizHistoryEntriesTableAnnotationComposer,
          $$QuizHistoryEntriesTableCreateCompanionBuilder,
          $$QuizHistoryEntriesTableUpdateCompanionBuilder,
          (
            QuizHistoryEntry,
            BaseReferences<
              _$AppDatabase,
              $QuizHistoryEntriesTable,
              QuizHistoryEntry
            >,
          ),
          QuizHistoryEntry,
          PrefetchHooks Function()
        > {
  $$QuizHistoryEntriesTableTableManager(
    _$AppDatabase db,
    $QuizHistoryEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuizHistoryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuizHistoryEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuizHistoryEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> videoId = const Value.absent(),
                Value<DateTime> playedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuizHistoryEntriesCompanion(
                videoId: videoId,
                playedAt: playedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String videoId,
                required DateTime playedAt,
                Value<int> rowid = const Value.absent(),
              }) => QuizHistoryEntriesCompanion.insert(
                videoId: videoId,
                playedAt: playedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QuizHistoryEntriesTable, QuizHistoryEntry>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $QuizHistoryEntriesTable,
                    QuizHistoryEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuizHistoryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuizHistoryEntriesTable,
      QuizHistoryEntry,
      $$QuizHistoryEntriesTableFilterComposer,
      $$QuizHistoryEntriesTableOrderingComposer,
      $$QuizHistoryEntriesTableAnnotationComposer,
      $$QuizHistoryEntriesTableCreateCompanionBuilder,
      $$QuizHistoryEntriesTableUpdateCompanionBuilder,
      (
        QuizHistoryEntry,
        BaseReferences<
          _$AppDatabase,
          $QuizHistoryEntriesTable,
          QuizHistoryEntry
        >,
      ),
      QuizHistoryEntry,
      PrefetchHooks Function()
    >;
typedef $$PlaylistRecordsTableCreateCompanionBuilder =
    PlaylistRecordsCompanion Function({
      required String id,
      required String name,
      Value<bool> isPublic,
      Value<String> description,
      Value<bool> allowsCollaboration,
      Value<bool> isOwned,
      Value<String?> sourcePlaylistId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$PlaylistRecordsTableUpdateCompanionBuilder =
    PlaylistRecordsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<bool> isPublic,
      Value<String> description,
      Value<bool> allowsCollaboration,
      Value<bool> isOwned,
      Value<String?> sourcePlaylistId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$PlaylistRecordsTableReferences
    extends
        BaseReferences<_$AppDatabase, $PlaylistRecordsTable, PlaylistRecord> {
  $$PlaylistRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$PlaylistItemEntriesTable, List<PlaylistItemEntry>>
  _playlistItemEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.playlistItemEntries,
        aliasName: 'playlist_records__id__playlist_item_entries__playlist_id',
      );

  $$PlaylistItemEntriesTableProcessedTableManager get playlistItemEntriesRefs {
    final manager = $$PlaylistItemEntriesTableTableManager(
      $_db,
      $_db.playlistItemEntries,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _playlistItemEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlaylistRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistRecordsTable> {
  $$PlaylistRecordsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPublic => $composableBuilder(
    column: $table.isPublic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allowsCollaboration => $composableBuilder(
    column: $table.allowsCollaboration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOwned => $composableBuilder(
    column: $table.isOwned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourcePlaylistId => $composableBuilder(
    column: $table.sourcePlaylistId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> playlistItemEntriesRefs(
    Expression<bool> Function($$PlaylistItemEntriesTableFilterComposer f) f,
  ) {
    final $$PlaylistItemEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistItemEntries,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistItemEntriesTableFilterComposer(
            $db: $db,
            $table: $db.playlistItemEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistRecordsTable> {
  $$PlaylistRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPublic => $composableBuilder(
    column: $table.isPublic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allowsCollaboration => $composableBuilder(
    column: $table.allowsCollaboration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOwned => $composableBuilder(
    column: $table.isOwned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourcePlaylistId => $composableBuilder(
    column: $table.sourcePlaylistId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaylistRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistRecordsTable> {
  $$PlaylistRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isPublic =>
      $composableBuilder(column: $table.isPublic, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get allowsCollaboration => $composableBuilder(
    column: $table.allowsCollaboration,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isOwned =>
      $composableBuilder(column: $table.isOwned, builder: (column) => column);

  GeneratedColumn<String> get sourcePlaylistId => $composableBuilder(
    column: $table.sourcePlaylistId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> playlistItemEntriesRefs<T extends Object>(
    Expression<T> Function($$PlaylistItemEntriesTableAnnotationComposer a) f,
  ) {
    final $$PlaylistItemEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.playlistItemEntries,
          getReferencedColumn: (t) => t.playlistId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PlaylistItemEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.playlistItemEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PlaylistRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistRecordsTable,
          PlaylistRecord,
          $$PlaylistRecordsTableFilterComposer,
          $$PlaylistRecordsTableOrderingComposer,
          $$PlaylistRecordsTableAnnotationComposer,
          $$PlaylistRecordsTableCreateCompanionBuilder,
          $$PlaylistRecordsTableUpdateCompanionBuilder,
          (PlaylistRecord, $$PlaylistRecordsTableReferences),
          PlaylistRecord,
          PrefetchHooks Function({bool playlistItemEntriesRefs})
        > {
  $$PlaylistRecordsTableTableManager(
    _$AppDatabase db,
    $PlaylistRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isPublic = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<bool> allowsCollaboration = const Value.absent(),
                Value<bool> isOwned = const Value.absent(),
                Value<String?> sourcePlaylistId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistRecordsCompanion(
                id: id,
                name: name,
                isPublic: isPublic,
                description: description,
                allowsCollaboration: allowsCollaboration,
                isOwned: isOwned,
                sourcePlaylistId: sourcePlaylistId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<bool> isPublic = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<bool> allowsCollaboration = const Value.absent(),
                Value<bool> isOwned = const Value.absent(),
                Value<String?> sourcePlaylistId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistRecordsCompanion.insert(
                id: id,
                name: name,
                isPublic: isPublic,
                description: description,
                allowsCollaboration: allowsCollaboration,
                isOwned: isOwned,
                sourcePlaylistId: sourcePlaylistId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaylistRecordsTable, PlaylistRecord>(table),
                  $$PlaylistRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistItemEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (playlistItemEntriesRefs) db.playlistItemEntries,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (playlistItemEntriesRefs)
                    await $_getPrefetchedData<
                      PlaylistRecord,
                      $PlaylistRecordsTable,
                      PlaylistItemEntry
                    >(
                      currentTable: table,
                      referencedTable: $$PlaylistRecordsTableReferences
                          ._playlistItemEntriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PlaylistRecordsTableReferences(
                            db,
                            table,
                            p0,
                          ).playlistItemEntriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.playlistId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PlaylistRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistRecordsTable,
      PlaylistRecord,
      $$PlaylistRecordsTableFilterComposer,
      $$PlaylistRecordsTableOrderingComposer,
      $$PlaylistRecordsTableAnnotationComposer,
      $$PlaylistRecordsTableCreateCompanionBuilder,
      $$PlaylistRecordsTableUpdateCompanionBuilder,
      (PlaylistRecord, $$PlaylistRecordsTableReferences),
      PlaylistRecord,
      PrefetchHooks Function({bool playlistItemEntriesRefs})
    >;
typedef $$PlaylistItemEntriesTableCreateCompanionBuilder =
    PlaylistItemEntriesCompanion Function({
      required String playlistId,
      required String videoId,
      required int position,
      Value<DateTime> addedAt,
      Value<int> rowid,
    });
typedef $$PlaylistItemEntriesTableUpdateCompanionBuilder =
    PlaylistItemEntriesCompanion Function({
      Value<String> playlistId,
      Value<String> videoId,
      Value<int> position,
      Value<DateTime> addedAt,
      Value<int> rowid,
    });

final class $$PlaylistItemEntriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PlaylistItemEntriesTable,
          PlaylistItemEntry
        > {
  $$PlaylistItemEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlaylistRecordsTable _playlistIdTable(_$AppDatabase db) => db
      .playlistRecords
      .createAlias('playlist_item_entries__playlist_id__playlist_records__id');

  $$PlaylistRecordsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<String>('playlist_id')!;

    final manager = $$PlaylistRecordsTableTableManager(
      $_db,
      $_db.playlistRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlaylistItemEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistItemEntriesTable> {
  $$PlaylistItemEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PlaylistRecordsTableFilterComposer get playlistId {
    final $$PlaylistRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlistRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistRecordsTableFilterComposer(
            $db: $db,
            $table: $db.playlistRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistItemEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistItemEntriesTable> {
  $$PlaylistItemEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaylistRecordsTableOrderingComposer get playlistId {
    final $$PlaylistRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlistRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.playlistRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistItemEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistItemEntriesTable> {
  $$PlaylistItemEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  $$PlaylistRecordsTableAnnotationComposer get playlistId {
    final $$PlaylistRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlistRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlistRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistItemEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistItemEntriesTable,
          PlaylistItemEntry,
          $$PlaylistItemEntriesTableFilterComposer,
          $$PlaylistItemEntriesTableOrderingComposer,
          $$PlaylistItemEntriesTableAnnotationComposer,
          $$PlaylistItemEntriesTableCreateCompanionBuilder,
          $$PlaylistItemEntriesTableUpdateCompanionBuilder,
          (PlaylistItemEntry, $$PlaylistItemEntriesTableReferences),
          PlaylistItemEntry,
          PrefetchHooks Function({bool playlistId})
        > {
  $$PlaylistItemEntriesTableTableManager(
    _$AppDatabase db,
    $PlaylistItemEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistItemEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistItemEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PlaylistItemEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> playlistId = const Value.absent(),
                Value<String> videoId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistItemEntriesCompanion(
                playlistId: playlistId,
                videoId: videoId,
                position: position,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String playlistId,
                required String videoId,
                required int position,
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistItemEntriesCompanion.insert(
                playlistId: playlistId,
                videoId: videoId,
                position: position,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaylistItemEntriesTable, PlaylistItemEntry>(
                    table,
                  ),
                  $$PlaylistItemEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (playlistId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playlistId,
                                referencedTable:
                                    $$PlaylistItemEntriesTableReferences
                                        ._playlistIdTable(db),
                                referencedColumn:
                                    $$PlaylistItemEntriesTableReferences
                                        ._playlistIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlaylistItemEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistItemEntriesTable,
      PlaylistItemEntry,
      $$PlaylistItemEntriesTableFilterComposer,
      $$PlaylistItemEntriesTableOrderingComposer,
      $$PlaylistItemEntriesTableAnnotationComposer,
      $$PlaylistItemEntriesTableCreateCompanionBuilder,
      $$PlaylistItemEntriesTableUpdateCompanionBuilder,
      (PlaylistItemEntry, $$PlaylistItemEntriesTableReferences),
      PlaylistItemEntry,
      PrefetchHooks Function({bool playlistId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FavoriteEntriesTableTableManager get favoriteEntries =>
      $$FavoriteEntriesTableTableManager(_db, _db.favoriteEntries);
  $$QuizHistoryEntriesTableTableManager get quizHistoryEntries =>
      $$QuizHistoryEntriesTableTableManager(_db, _db.quizHistoryEntries);
  $$PlaylistRecordsTableTableManager get playlistRecords =>
      $$PlaylistRecordsTableTableManager(_db, _db.playlistRecords);
  $$PlaylistItemEntriesTableTableManager get playlistItemEntries =>
      $$PlaylistItemEntriesTableTableManager(_db, _db.playlistItemEntries);
}
