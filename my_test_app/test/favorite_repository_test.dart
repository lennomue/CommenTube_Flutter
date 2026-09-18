import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_test_app/core/database/app_database.dart';
import 'package:my_test_app/core/models/favorite.dart';
import 'package:my_test_app/core/repositories/favorite_repository.dart';

void main() {
  test('お気に入りをDriftに保存し、再接続後も読み出す', () async {
    final directory = await Directory.systemTemp.createTemp(
      'commentube_favorites_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/favorites.sqlite');

    final firstDatabase = AppDatabase(NativeDatabase(file));
    final firstRepository = DriftFavoriteRepository(firstDatabase);
    await firstRepository.toggleFavorite(
      SavedFavorite.song(videoId: 'video-1', title: 'Song 1'),
    );
    await firstRepository.toggleFavorite(
      SavedFavorite.comment(
        videoId: 'video-1',
        commentId: 'comment-1',
        content: '記憶に残るコメント',
      ),
    );
    await firstRepository.toggleFavorite(
      SavedFavorite.lyric(videoId: 'video-1', index: 0, content: '歌詞ヒント'),
    );
    await firstRepository.toggleFavorite(SavedFavorite.artist('Artist 1'));
    await firstDatabase.close();

    final reopenedDatabase = AppDatabase(NativeDatabase(file));
    addTearDown(reopenedDatabase.close);
    final reopenedRepository = DriftFavoriteRepository(reopenedDatabase);
    final favorites = await reopenedRepository.watchFavorites().first;

    expect(favorites, hasLength(4));
    expect(
      favorites.map((favorite) => favorite.kind),
      containsAll(FavoriteKind.values),
    );
    expect(
      favorites
          .singleWhere((favorite) => favorite.kind == FavoriteKind.artist)
          .videoId,
      isNull,
    );
  });

  test('同じお気に入りを再度押すと解除する', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DriftFavoriteRepository(database);
    final favorite = SavedFavorite.song(videoId: 'video-1', title: 'Song 1');

    await repository.toggleFavorite(favorite);
    expect(await repository.watchFavorites().first, hasLength(1));

    await repository.toggleFavorite(favorite);
    expect(await repository.watchFavorites().first, isEmpty);
  });
}
