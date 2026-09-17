String formatCompactCount(int count) {
  if (count >= 100000000) {
    return '${_compactDecimal(count / 100000000)}億';
  }
  if (count >= 10000) {
    return '${_compactDecimal(count / 10000)}万';
  }
  return '$count';
}

String formatRelativeDate(DateTime date, {DateTime? now}) {
  final days = (now ?? DateTime.now()).difference(date).inDays;
  if (days < 30) {
    return '${days.clamp(0, 29)}日前';
  }
  if (days < 365) {
    return '${days ~/ 30}か月前';
  }
  return '${days ~/ 365}年前';
}

String formatDate(DateTime date) {
  return '${date.year}年${date.month}月${date.day}日';
}

String genreLabel(String genre) {
  return switch (genre) {
    'j_pop' => 'J-Pop',
    'k_pop' => 'K-Pop',
    'pop' => 'ポップ',
    'rock' => 'ロック',
    'r_and_b_soul' => 'R&B・ソウル',
    'anime_soundtrack' => 'アニメ・サントラ',
    'hiphop' => 'ヒップホップ',
    'latin' => 'ラテン',
    _ => genre,
  };
}

String videoGenreLabel(String genre) {
  return switch (genre) {
    'music_video' => '楽曲',
    'lyric_video' => '歌詞動画',
    'live_performance_video' => 'ライブ映像',
    'fan_made_video' => '合成MAD',
    'non_music' => '非音楽',
    _ => genre,
  };
}

String languageLabel(String language) {
  return switch (language) {
    'japanese' => '日本語',
    'english' => '英語',
    'korean' => '韓国語',
    'spanish' => 'スペイン語',
    _ => language,
  };
}

String _compactDecimal(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}
