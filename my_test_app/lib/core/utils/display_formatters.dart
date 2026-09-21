import '../models/quiz.dart';

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

String formatRelativeTime(DateTime date, {DateTime? now}) {
  final difference = (now ?? DateTime.now()).difference(date);
  if (difference.isNegative || difference.inMinutes < 1) {
    return 'たった今';
  }
  if (difference.inHours < 1) {
    return '${difference.inMinutes}分前';
  }
  if (difference.inDays < 1) {
    return '${difference.inHours}時間前';
  }
  return formatRelativeDate(date, now: now);
}

String formatDate(DateTime date) {
  return '${date.year}年${date.month}月${date.day}日';
}

String formatPartialDate(PartialDate? value) {
  if (value == null) {
    return '不明';
  }
  return switch (value.precision) {
    DatePrecision.year => '${value.date.year}年',
    DatePrecision.month => '${value.date.year}年${value.date.month}月',
    DatePrecision.day => formatDate(value.date),
  };
}

String genreLabel(String genre) {
  final decade = RegExp(r'^decade_(\d{4}s)$').firstMatch(genre);
  if (decade != null) {
    return decade.group(1)!;
  }
  return switch (genre) {
    'j_pop' => 'J-Pop',
    'k_pop' => 'K-Pop',
    'pop' => 'ポップ',
    'rock' => 'ロック',
    'r_and_b_soul' => 'R&B・ソウル',
    'anime_soundtrack' => 'アニメ・サントラ',
    'hiphop' => 'ヒップホップ',
    'latin' => 'ラテン',
    'dance_electronic' => 'ダンス・エレクトロニック',
    'vocaloid_utaite' => 'ボカロ・歌い手',
    'non_music' => 'その他',
    _ => genre,
  };
}

String videoGenreLabel(String genre) {
  return switch (genre) {
    'release' => '楽曲',
    'music_video' => 'ミュージックビデオ',
    'cover_video' => 'カバー動画',
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
