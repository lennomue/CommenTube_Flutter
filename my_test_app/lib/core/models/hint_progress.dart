class HintProgress {
  const HintProgress({required this.unlockedHintKeys});

  final Set<String> unlockedHintKeys;

  bool isUnlocked(String hintKey) => unlockedHintKeys.contains(hintKey);
}

abstract final class HintKey {
  static String comment(String commentId) => 'comment:$commentId';

  static String lyric(int index) => 'lyric:$index';

  static const videoGenre = 'music_info:video_genre';
  static const contentGenres = 'video_info:content_genres';
  static const languages = 'video_info:languages';
  static const artists = 'video_info:artists';
  static const musicReleasedAt = 'music_info:music_released_at';
}
