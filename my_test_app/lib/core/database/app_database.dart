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

@DriftDatabase(tables: [FavoriteEntries])
final class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.defaults() : super(driftDatabase(name: 'commentube'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(favoriteEntries);
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
}
