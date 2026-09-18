import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/favorite.dart';

abstract interface class FavoriteRepository {
  Stream<List<SavedFavorite>> watchFavorites();

  Future<void> toggleFavorite(SavedFavorite favorite);

  Future<void> removeFavorite(String id);
}

class DriftFavoriteRepository implements FavoriteRepository {
  const DriftFavoriteRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<List<SavedFavorite>> watchFavorites() {
    return _database.watchFavorites().map(
      (rows) => rows.map(_toFavorite).toList(growable: false),
    );
  }

  @override
  Future<void> toggleFavorite(SavedFavorite favorite) async {
    if (await _database.containsFavorite(favorite.id)) {
      await _database.removeFavorite(favorite.id);
      return;
    }
    await _database.saveFavorite(
      FavoriteEntriesCompanion.insert(
        id: favorite.id,
        kind: favorite.kind.name,
        videoId: Value(favorite.videoId),
        itemKey: favorite.itemKey,
        displayText: favorite.displayText,
        createdAt: Value(favorite.createdAt),
      ),
    );
  }

  @override
  Future<void> removeFavorite(String id) => _database.removeFavorite(id);

  SavedFavorite _toFavorite(FavoriteEntry row) {
    return SavedFavorite(
      id: row.id,
      kind: FavoriteKind.values.byName(row.kind),
      videoId: row.videoId,
      itemKey: row.itemKey,
      displayText: row.displayText,
      createdAt: row.createdAt,
    );
  }
}
