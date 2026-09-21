import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/playlist.dart';
import 'favorite_providers.dart';
import 'playlist_repository.dart';
import 'public_playlist_repository.dart';

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return DriftPlaylistRepository(ref.watch(appDatabaseProvider));
});

final playlistsProvider = StreamProvider<List<UserPlaylist>>((ref) {
  return ref.watch(playlistRepositoryProvider).watchPlaylists();
});

final playlistProvider = Provider.family<AsyncValue<UserPlaylist?>, String>((
  ref,
  playlistId,
) {
  return ref
      .watch(playlistsProvider)
      .whenData(
        (items) => items.where((item) => item.id == playlistId).firstOrNull,
      );
});

final publicPlaylistRepositoryProvider = Provider<PublicPlaylistRepository>((
  ref,
) {
  return const AssetPublicPlaylistRepository();
});

final publicPlaylistsProvider = FutureProvider<List<PublicPlaylist>>((ref) {
  return ref.watch(publicPlaylistRepositoryProvider).getPublicPlaylists();
});
