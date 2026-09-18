enum FavoriteKind { comment, lyric, song, artist }

class SavedFavorite {
  const SavedFavorite({
    required this.id,
    required this.kind,
    required this.itemKey,
    required this.displayText,
    required this.createdAt,
    this.videoId,
  });

  factory SavedFavorite.song({required String videoId, required String title}) {
    return SavedFavorite(
      id: 'song:$videoId',
      kind: FavoriteKind.song,
      videoId: videoId,
      itemKey: videoId,
      displayText: title,
      createdAt: DateTime.now(),
    );
  }

  factory SavedFavorite.comment({
    required String videoId,
    required String commentId,
    required String content,
  }) {
    return SavedFavorite(
      id: 'comment:$videoId:$commentId',
      kind: FavoriteKind.comment,
      videoId: videoId,
      itemKey: commentId,
      displayText: content,
      createdAt: DateTime.now(),
    );
  }

  factory SavedFavorite.lyric({
    required String videoId,
    required int index,
    required String content,
  }) {
    return SavedFavorite(
      id: 'lyric:$videoId:$index',
      kind: FavoriteKind.lyric,
      videoId: videoId,
      itemKey: '$index',
      displayText: content,
      createdAt: DateTime.now(),
    );
  }

  factory SavedFavorite.artist(String artist) {
    return SavedFavorite(
      id: 'artist:$artist',
      kind: FavoriteKind.artist,
      itemKey: artist,
      displayText: artist,
      createdAt: DateTime.now(),
    );
  }

  final String id;
  final FavoriteKind kind;
  final String? videoId;
  final String itemKey;
  final String displayText;
  final DateTime createdAt;
}
