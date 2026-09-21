import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/playlist.dart';

abstract interface class PublicPlaylistRepository {
  Future<List<PublicPlaylist>> getPublicPlaylists();
}

class AssetPublicPlaylistRepository implements PublicPlaylistRepository {
  const AssetPublicPlaylistRepository({
    this.assetPath = 'assets/mock_data/public_playlists.json',
  });

  final String assetPath;

  @override
  Future<List<PublicPlaylist>> getPublicPlaylists() async {
    final source = await rootBundle.loadString(assetPath);
    return (jsonDecode(source) as List<dynamic>)
        .map((item) => PublicPlaylist.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}
