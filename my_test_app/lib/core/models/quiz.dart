enum ThumbnailHintType {
  comment,
  lyric;

  static ThumbnailHintType fromJson(String value) {
    return ThumbnailHintType.values.byName(value);
  }
}

enum DatePrecision {
  year,
  month,
  day;

  static DatePrecision fromJson(String value) {
    return DatePrecision.values.byName(value);
  }
}

class PartialDate {
  const PartialDate({required this.precision, required this.date});

  factory PartialDate.fromJson(Map<String, dynamic> json) {
    return PartialDate(
      precision: DatePrecision.fromJson(json['precision'] as String),
      date: DateTime.parse(json['date'] as String),
    );
  }

  final DatePrecision precision;
  final DateTime date;
}

class AtmosphereColor {
  const AtmosphereColor({
    required this.hue,
    required this.saturation,
    required this.lightness,
  });

  factory AtmosphereColor.fromJson(Map<String, dynamic> json) {
    return AtmosphereColor(
      hue: (json['h'] as num).toDouble(),
      saturation: (json['s'] as num).toDouble(),
      lightness: (json['l'] as num).toDouble(),
    );
  }

  final double hue;
  final double saturation;
  final double lightness;
}

class Artist {
  const Artist({
    required this.artistId,
    required this.name,
    required this.subNames,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      artistId: json['artist_id'] as String,
      name: json['name'] as String,
      subNames: Quiz.stringList(json['sub_names']),
    );
  }

  final String artistId;
  final String name;
  final List<String> subNames;
}

class RelatedVideo {
  const RelatedVideo({required this.videoId, required this.relationType});

  final String videoId;
  final String relationType;
}

class ThumbnailHint {
  const ThumbnailHint({required this.type, required this.content});

  final ThumbnailHintType type;
  final String content;
}

class Quiz {
  const Quiz({
    required this.videoId,
    required this.atmosphereColor,
    required this.thumbnailHintType,
    required this.contentGenres,
    required this.videoGenre,
    required this.title,
    required this.artists,
    required this.languages,
    required this.musicReleasedAt,
    required this.postedAt,
    required this.musicLyrics,
    required this.comments,
    required this.relatedVideos,
    required this.metaData,
    required this.embedding,
  });

  factory Quiz.fromJson(
    Map<String, dynamic> json, {
    required List<Artist> artists,
    required List<RelatedVideo> relatedVideos,
  }) {
    final thumbnailHint = json['thumbnail_hint'] as Map<String, dynamic>;
    final releasedAt = json['music_released_at'];
    final rawEmbedding = json['embedding'] as List<dynamic>?;
    return Quiz(
      videoId: json['video_id'] as String,
      atmosphereColor: AtmosphereColor.fromJson(
        json['video_atmosphere_color'] as Map<String, dynamic>,
      ),
      thumbnailHintType: ThumbnailHintType.fromJson(
        thumbnailHint['hint_type'] as String,
      ),
      contentGenres: stringList(json['content_genres']),
      videoGenre: json['video_genre'] as String,
      title: json['title'] as String,
      artists: List.unmodifiable(artists),
      languages: stringList(json['languages']),
      musicReleasedAt: releasedAt == null
          ? null
          : PartialDate.fromJson(releasedAt as Map<String, dynamic>),
      postedAt: DateTime.parse(json['posted_at'] as String),
      musicLyrics: stringList(json['music_lyrics']),
      comments: (json['comments'] as List<dynamic>? ?? const [])
          .map((item) => QuizComment.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      relatedVideos: List.unmodifiable(relatedVideos),
      metaData: Map.unmodifiable(
        json['meta_data'] as Map<String, dynamic>? ?? const {},
      ),
      embedding: rawEmbedding
          ?.map((value) => (value as num).toDouble())
          .toList(growable: false),
    );
  }

  final String videoId;
  final AtmosphereColor atmosphereColor;
  final ThumbnailHintType thumbnailHintType;
  final List<String> contentGenres;
  final String videoGenre;
  final String title;
  final List<Artist> artists;
  final List<String> languages;
  final PartialDate? musicReleasedAt;
  final DateTime postedAt;
  final List<String> musicLyrics;
  final List<QuizComment> comments;
  final List<RelatedVideo> relatedVideos;
  final Map<String, dynamic> metaData;
  final List<double>? embedding;

  List<String> get artistNames =>
      artists.map((artist) => artist.name).toList(growable: false);

  ThumbnailHint? get thumbnailHint {
    return switch (thumbnailHintType) {
      ThumbnailHintType.comment when comments.isNotEmpty => ThumbnailHint(
        type: ThumbnailHintType.comment,
        content: comments.first.content,
      ),
      ThumbnailHintType.lyric when musicLyrics.isNotEmpty => ThumbnailHint(
        type: ThumbnailHintType.lyric,
        content: musicLyrics.first,
      ),
      _ => null,
    };
  }

  QuizComment? get representativeComment {
    if (thumbnailHintType != ThumbnailHintType.comment || comments.isEmpty) {
      return null;
    }
    return comments.first;
  }

  static List<String> stringList(Object? value) {
    return (value as List<dynamic>? ?? const []).cast<String>();
  }
}

class QuizComment {
  const QuizComment({
    required this.commentId,
    required this.commentedAt,
    required this.content,
  });

  factory QuizComment.fromJson(Map<String, dynamic> json) {
    return QuizComment(
      commentId: json['comment_id'] as String,
      commentedAt: DateTime.parse(json['commented_at'] as String),
      content: json['content'] as String,
    );
  }

  final String commentId;
  final DateTime commentedAt;
  final String content;
}

class VideoLiveStats {
  const VideoLiveStats({required this.viewCount, required this.likeCount});

  factory VideoLiveStats.fromJson(Map<String, dynamic> json) {
    return VideoLiveStats(
      viewCount: int.parse(json['viewCount'] as String),
      likeCount: int.parse(json['likeCount'] as String),
    );
  }

  final int viewCount;
  final int likeCount;
}

class QuizCommentWithStats {
  const QuizCommentWithStats({required this.comment, required this.likeCount});

  final QuizComment comment;
  final int likeCount;
}

class QuizWithLiveStats {
  const QuizWithLiveStats({
    required this.quiz,
    required this.videoStats,
    required this.comments,
  });

  final Quiz quiz;
  final VideoLiveStats videoStats;
  final List<QuizCommentWithStats> comments;

  QuizCommentWithStats? get representativeComment {
    final selected = quiz.representativeComment;
    if (selected == null) {
      return null;
    }
    for (final comment in comments) {
      if (comment.comment.commentId == selected.commentId) {
        return comment;
      }
    }
    return QuizCommentWithStats(comment: selected, likeCount: 0);
  }
}
