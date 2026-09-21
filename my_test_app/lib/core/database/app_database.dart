import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class FavoriteEntries extends Table {
  TextColumn get id => text()();

  TextColumn get kind => text()();

  TextColumn get videoId => text().nullable()();

  TextColumn get itemKey => text()();

  TextColumn get displayText => text()();

  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class QuizHistoryEntries extends Table {
  TextColumn get videoId => text()();

  DateTimeColumn get playedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {videoId};
}

class PlaylistRecords extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  BoolColumn get isPublic => boolean().withDefault(const Constant(false))();

  TextColumn get description => text().withDefault(const Constant(''))();

  BoolColumn get allowsCollaboration =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get isOwned => boolean().withDefault(const Constant(true))();

  TextColumn get sourcePlaylistId => text().nullable()();

  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();

  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PlaylistItemEntries extends Table {
  TextColumn get playlistId =>
      text().references(PlaylistRecords, #id, onDelete: KeyAction.cascade)();

  TextColumn get videoId => text()();

  IntColumn get position => integer()();

  DateTimeColumn get addedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column<Object>> get primaryKey => {playlistId, videoId};
}

@DriftDatabase(
  tables: [
    FavoriteEntries,
    QuizHistoryEntries,
    PlaylistRecords,
    PlaylistItemEntries,
  ],
)
final class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.defaults() : super(driftDatabase(name: 'commentube'));

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(favoriteEntries);
      }
      if (from < 3) {
        await migrator.createTable(quizHistoryEntries);
      }
      if (from < 4) {
        await migrator.createTable(playlistRecords);
        await migrator.createTable(playlistItemEntries);
      }
      if (from < 5) {
        await migrator.addColumn(
          playlistRecords,
          playlistRecords.sourcePlaylistId,
        );
      }
      if (from < 7) {
        await _removeLegacyFavoritesPlaylist();
      }
    },
  );

  Stream<List<FavoriteEntry>> watchFavorites() {
    final query = select(favoriteEntries)
      ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]);
    return query.watch();
  }

  Future<bool> containsFavorite(String id) async {
    final query = select(favoriteEntries)..where((row) => row.id.equals(id));
    return await query.getSingleOrNull() != null;
  }

  Future<void> saveFavorite(FavoriteEntriesCompanion favorite) {
    return into(favoriteEntries).insertOnConflictUpdate(favorite);
  }

  Future<void> removeFavorite(String id) {
    return (delete(favoriteEntries)..where((row) => row.id.equals(id))).go();
  }

  Stream<List<QuizHistoryEntry>> watchQuizHistory() {
    final query = select(quizHistoryEntries)
      ..orderBy([(row) => OrderingTerm.desc(row.playedAt)]);
    return query.watch();
  }

  Future<void> recordQuizPlay(String videoId, DateTime playedAt) {
    return transaction(() async {
      await into(quizHistoryEntries).insertOnConflictUpdate(
        QuizHistoryEntriesCompanion.insert(
          videoId: videoId,
          playedAt: playedAt,
        ),
      );
      final orderedEntries = await (select(
        quizHistoryEntries,
      )..orderBy([(row) => OrderingTerm.desc(row.playedAt)])).get();
      final staleVideoIds = orderedEntries
          .skip(50)
          .map((entry) => entry.videoId)
          .toList(growable: false);
      if (staleVideoIds.isNotEmpty) {
        await (delete(
          quizHistoryEntries,
        )..where((row) => row.videoId.isIn(staleVideoIds))).go();
      }
    });
  }

  Stream<List<TypedResult>> watchPlaylistRows() {
    final query =
        select(playlistRecords).join([
          leftOuterJoin(
            playlistItemEntries,
            playlistItemEntries.playlistId.equalsExp(playlistRecords.id),
          ),
        ])..orderBy([
          OrderingTerm.desc(playlistRecords.updatedAt),
          OrderingTerm.asc(playlistItemEntries.position),
        ]);
    return query.watch();
  }

  Future<void> createPlaylist(PlaylistRecordsCompanion playlist) {
    return into(playlistRecords).insert(playlist);
  }

  Future<void> updatePlaylist(PlaylistRecordsCompanion playlist) {
    return (update(
      playlistRecords,
    )..where((row) => row.id.equals(playlist.id.value))).write(playlist);
  }

  Future<void> deletePlaylist(String playlistId) {
    return transaction(() async {
      await (delete(
        playlistItemEntries,
      )..where((row) => row.playlistId.equals(playlistId))).go();
      await (delete(
        playlistRecords,
      )..where((row) => row.id.equals(playlistId))).go();
    });
  }

  Future<void> addPlaylistItem(String playlistId, String videoId) {
    return transaction(() async {
      final existing =
          await (select(playlistItemEntries)..where(
                (row) =>
                    row.playlistId.equals(playlistId) &
                    row.videoId.equals(videoId),
              ))
              .getSingleOrNull();
      if (existing != null) {
        return;
      }
      final entries =
          await (select(playlistItemEntries)
                ..where((row) => row.playlistId.equals(playlistId))
                ..orderBy([(row) => OrderingTerm.desc(row.position)]))
              .get();
      await into(playlistItemEntries).insert(
        PlaylistItemEntriesCompanion.insert(
          playlistId: playlistId,
          videoId: videoId,
          position: entries.isEmpty ? 0 : entries.first.position + 1,
        ),
      );
      await _touchPlaylist(playlistId);
    });
  }

  Future<void> addPlaylistItems(String playlistId, List<String> videoIds) {
    return transaction(() async {
      for (final videoId in videoIds) {
        await addPlaylistItem(playlistId, videoId);
      }
    });
  }

  Future<void> movePlaylistItems({
    required String sourcePlaylistId,
    required String targetPlaylistId,
    required List<String> videoIds,
  }) {
    return transaction(() async {
      await addPlaylistItems(targetPlaylistId, videoIds);
      if (videoIds.isNotEmpty) {
        await (delete(playlistItemEntries)..where(
              (row) =>
                  row.playlistId.equals(sourcePlaylistId) &
                  row.videoId.isIn(videoIds),
            ))
            .go();
      }
      await _normalizePlaylistPositions(sourcePlaylistId);
      await _touchPlaylist(sourcePlaylistId);
    });
  }

  Future<void> removePlaylistItem(String playlistId, String videoId) {
    return transaction(() async {
      await (delete(playlistItemEntries)..where(
            (row) =>
                row.playlistId.equals(playlistId) & row.videoId.equals(videoId),
          ))
          .go();
      await _normalizePlaylistPositions(playlistId);
      await _touchPlaylist(playlistId);
    });
  }

  Future<void> reorderPlaylistItems(String playlistId, List<String> videoIds) {
    return transaction(() async {
      if (videoIds.isEmpty) {
        await (delete(
          playlistItemEntries,
        )..where((row) => row.playlistId.equals(playlistId))).go();
      } else {
        await (delete(playlistItemEntries)..where(
              (row) =>
                  row.playlistId.equals(playlistId) &
                  row.videoId.isNotIn(videoIds),
            ))
            .go();
      }
      for (final entry in videoIds.indexed) {
        await (update(playlistItemEntries)..where(
              (row) =>
                  row.playlistId.equals(playlistId) &
                  row.videoId.equals(entry.$2),
            ))
            .write(PlaylistItemEntriesCompanion(position: Value(entry.$1)));
      }
      await _touchPlaylist(playlistId);
    });
  }

  Future<void> _normalizePlaylistPositions(String playlistId) async {
    final entries =
        await (select(playlistItemEntries)
              ..where((row) => row.playlistId.equals(playlistId))
              ..orderBy([(row) => OrderingTerm.asc(row.position)]))
            .get();
    for (final entry in entries.indexed) {
      await (update(playlistItemEntries)..where(
            (row) =>
                row.playlistId.equals(playlistId) &
                row.videoId.equals(entry.$2.videoId),
          ))
          .write(PlaylistItemEntriesCompanion(position: Value(entry.$1)));
    }
  }

  Future<void> _touchPlaylist(String playlistId) {
    return (update(playlistRecords)..where((row) => row.id.equals(playlistId)))
        .write(PlaylistRecordsCompanion(updatedAt: Value(DateTime.now())));
  }

  Future<void> _removeLegacyFavoritesPlaylist() async {
    const legacyId = 'system-favorites';
    await (delete(
      playlistItemEntries,
    )..where((row) => row.playlistId.equals(legacyId))).go();
    await (delete(
      playlistRecords,
    )..where((row) => row.id.equals(legacyId))).go();
  }
}
