class UserPlaylist {
  const UserPlaylist({
    required this.id,
    required this.name,
    required this.isPublic,
    required this.description,
    required this.allowsCollaboration,
    required this.isOwned,
    required this.videoIds,
    required this.createdAt,
    required this.updatedAt,
    this.sourcePlaylistId,
  });

  final String id;
  final String name;
  final bool isPublic;
  final String description;
  final bool allowsCollaboration;
  final bool isOwned;
  final List<String> videoIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? sourcePlaylistId;

  bool get isSavedCopy => sourcePlaylistId != null;

  bool containsVideo(String videoId) => videoIds.contains(videoId);
}

class PublicPlaylist {
  const PublicPlaylist({
    required this.id,
    required this.ownerName,
    required this.name,
    required this.description,
    required this.videoIds,
    required this.updatedAt,
    required this.embedding,
  });

  factory PublicPlaylist.fromJson(Map<String, dynamic> json) {
    return PublicPlaylist(
      id: json['playlist_id'] as String,
      ownerName: json['owner_name'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      videoIds: (json['video_ids'] as List<dynamic>).cast<String>(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      embedding: (json['embedding'] as List<dynamic>?)
          ?.map((value) => (value as num).toDouble())
          .toList(growable: false),
    );
  }

  final String id;
  final String ownerName;
  final String name;
  final String description;
  final List<String> videoIds;
  final DateTime updatedAt;
  final List<double>? embedding;

  UserPlaylist asUnownedPlaylist() => UserPlaylist(
    id: id,
    name: name,
    isPublic: true,
    description: description,
    allowsCollaboration: false,
    isOwned: false,
    videoIds: videoIds,
    createdAt: updatedAt,
    updatedAt: updatedAt,
  );
}

class PlaylistDraft {
  const PlaylistDraft({
    required this.name,
    required this.isPublic,
    this.description = '',
    this.allowsCollaboration = false,
  });

  final String name;
  final bool isPublic;
  final String description;
  final bool allowsCollaboration;
}
