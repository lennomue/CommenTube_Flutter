import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../models/favorite.dart';
import 'favorite_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase.defaults();
  ref.onDispose(database.close);
  return database;
});

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return DriftFavoriteRepository(ref.watch(appDatabaseProvider));
});

final favoritesProvider = StreamProvider<List<SavedFavorite>>((ref) {
  return ref.watch(favoriteRepositoryProvider).watchFavorites();
});
