import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/playlist.dart';

abstract interface class PlaylistRepository {
  Stream<List<UserPlaylist>> watchPlaylists();

  Future<String> createPlaylist(
    PlaylistDraft draft, {
    String? firstVideoId,
    String? sourcePlaylistId,
  });

  Future<void> updatePlaylist(String id, PlaylistDraft draft);

  Future<void> deletePlaylist(String id);

  Future<void> toggleVideo(String playlistId, String videoId);

  Future<void> addVideos(String playlistId, List<String> videoIds);

  Future<void> moveVideos({
    required String sourcePlaylistId,
    required String targetPlaylistId,
    required List<String> videoIds,
  });

  Future<void> reorderVideos(String playlistId, List<String> videoIds);

  Future<String> copyPlaylist(UserPlaylist playlist);
}

class DriftPlaylistRepository implements PlaylistRepository {
  const DriftPlaylistRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<List<UserPlaylist>> watchPlaylists() {
    return _database.watchPlaylistRows().map((rows) {
      final playlists = <String, _PlaylistAccumulator>{};
      for (final row in rows) {
        final playlist = row.readTable(_database.playlistRecords);
        final accumulator = playlists.putIfAbsent(
          playlist.id,
          () => _PlaylistAccumulator(playlist),
        );
        final item = row.readTableOrNull(_database.playlistItemEntries);
        if (item != null) {
          accumulator.items.add(item);
        }
      }
      return playlists.values
          .map((value) => value.build())
          .toList(growable: false);
    });
  }

  @override
  Future<String> createPlaylist(
    PlaylistDraft draft, {
    String? firstVideoId,
    String? sourcePlaylistId,
  }) async {
    final now = DateTime.now();
    final id = 'playlist-${now.microsecondsSinceEpoch}';
    await _database.createPlaylist(
      PlaylistRecordsCompanion.insert(
        id: id,
        name: draft.name.trim(),
        isPublic: Value(draft.isPublic),
        description: Value(draft.description.trim()),
        allowsCollaboration: Value(draft.allowsCollaboration),
        sourcePlaylistId: Value(sourcePlaylistId),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    if (firstVideoId != null) {
      await _database.addPlaylistItem(id, firstVideoId);
    }
    return id;
  }

  @override
  Future<void> updatePlaylist(String id, PlaylistDraft draft) {
    return _database.updatePlaylist(
      PlaylistRecordsCompanion(
        id: Value(id),
        name: Value(draft.name.trim()),
        isPublic: Value(draft.isPublic),
        description: Value(draft.description.trim()),
        allowsCollaboration: Value(draft.allowsCollaboration),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deletePlaylist(String id) {
    return _database.deletePlaylist(id);
  }

  @override
  Future<void> toggleVideo(String playlistId, String videoId) async {
    final playlists = await watchPlaylists().first;
    final playlist = playlists
        .where((item) => item.id == playlistId)
        .firstOrNull;
    if (playlist == null) {
      return;
    }
    if (playlist.containsVideo(videoId)) {
      await _database.removePlaylistItem(playlistId, videoId);
    } else {
      await _database.addPlaylistItem(playlistId, videoId);
    }
  }

  @override
  Future<void> addVideos(String playlistId, List<String> videoIds) {
    return _database.addPlaylistItems(playlistId, videoIds);
  }

  @override
  Future<void> moveVideos({
    required String sourcePlaylistId,
    required String targetPlaylistId,
    required List<String> videoIds,
  }) {
    return _database.movePlaylistItems(
      sourcePlaylistId: sourcePlaylistId,
      targetPlaylistId: targetPlaylistId,
      videoIds: videoIds,
    );
  }

  @override
  Future<void> reorderVideos(String playlistId, List<String> videoIds) {
    return _database.reorderPlaylistItems(playlistId, videoIds);
  }

  @override
  Future<String> copyPlaylist(UserPlaylist playlist) async {
    final id = await createPlaylist(
      PlaylistDraft(
        name: '${playlist.name} のコピー',
        isPublic: false,
        description: playlist.description,
      ),
      sourcePlaylistId: playlist.id,
    );
    for (final videoId in playlist.videoIds) {
      await _database.addPlaylistItem(id, videoId);
    }
    return id;
  }
}

class _PlaylistAccumulator {
  _PlaylistAccumulator(this.playlist);

  final PlaylistRecord playlist;
  final List<PlaylistItemEntry> items = [];

  UserPlaylist build() {
    items.sort((left, right) => left.position.compareTo(right.position));
    return UserPlaylist(
      id: playlist.id,
      name: playlist.name,
      isPublic: playlist.isPublic,
      description: playlist.description,
      allowsCollaboration: playlist.allowsCollaboration,
      isOwned: playlist.isOwned,
      videoIds: items.map((item) => item.videoId).toList(growable: false),
      createdAt: playlist.createdAt,
      updatedAt: playlist.updatedAt,
      sourcePlaylistId: playlist.sourcePlaylistId,
    );
  }
}
