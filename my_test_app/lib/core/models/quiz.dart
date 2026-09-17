class Quiz {
  const Quiz({
    required this.videoId,
    required this.thumbnailCommentId,
    required this.musicGenres,
    required this.videoGenre,
    required this.musicTitle,
    required this.musicArtists,
    required this.musicLanguages,
    required this.musicReleasedAt,
    required this.videoPublishedAt,
    required this.videoLyrics,
    required this.videoComments,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      videoId: json['video_id'] as String,
      thumbnailCommentId: json['thumbnail_comment_id'] as String?,
      musicGenres: _stringList(json['music_genre']),
      videoGenre: json['video_genre'] as String,
      musicTitle: json['music_title'] as String,
      musicArtists: _stringList(json['music_artists']),
      musicLanguages: _stringList(json['music_languages']),
      musicReleasedAt: DateTime.parse(json['music_released_at'] as String),
      videoPublishedAt: DateTime.parse(json['video_published_at'] as String),
      videoLyrics: _stringList(json['video_lyrics']),
      videoComments: (json['video_comments'] as List<dynamic>)
          .map((item) => QuizComment.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final String videoId;
  final String? thumbnailCommentId;
  final List<String> musicGenres;
  final String videoGenre;
  final String musicTitle;
  final List<String> musicArtists;
  final List<String> musicLanguages;
  final DateTime musicReleasedAt;
  final DateTime videoPublishedAt;
  final List<String> videoLyrics;
  final List<QuizComment> videoComments;

  QuizComment? get representativeComment {
    if (videoComments.isEmpty) {
      return null;
    }
    final selectedId = thumbnailCommentId;
    if (selectedId != null) {
      for (final comment in videoComments) {
        if (comment.commentId == selectedId) {
          return comment;
        }
      }
    }
    return videoComments.first;
  }

  static List<String> _stringList(Object? value) {
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
