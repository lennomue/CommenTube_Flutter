import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/quiz.dart';
import '../models/quiz_filter.dart';

abstract interface class QuizRepository {
  Future<List<QuizWithLiveStats>> getQuizzes({
    QuizFilter filter = QuizFilter.empty,
  });

  Future<QuizWithLiveStats?> getQuiz(String videoId);
}

class AssetQuizRepository implements QuizRepository {
  AssetQuizRepository({
    this.quizAssetPath = 'assets/mock_data/quizzes.json',
    this.artistsAssetPath = 'assets/mock_data/artists.json',
    this.artistVideosAssetPath = 'assets/mock_data/artist_videos_junction.json',
    this.videosJunctionAssetPath = 'assets/mock_data/videos_junction.json',
    this.youtubeStatsAssetPath = 'assets/mock_data/youtube_api_mock.json',
  });

  final String quizAssetPath;
  final String artistsAssetPath;
  final String artistVideosAssetPath;
  final String videosJunctionAssetPath;
  final String youtubeStatsAssetPath;
  Future<List<QuizWithLiveStats>>? _cache;

  @override
  Future<List<QuizWithLiveStats>> getQuizzes({
    QuizFilter filter = QuizFilter.empty,
  }) async {
    final quizzes = await (_cache ??= _loadQuizzes());
    if (filter.isEmpty) {
      return quizzes;
    }

    // This in-memory filter only validates the mock UX. Phase 7 replaces the
    // implementation with a Supabase RPC while preserving this interface.
    return quizzes
        .where((item) => _matches(item.quiz, filter))
        .toList(growable: false);
  }

  @override
  Future<QuizWithLiveStats?> getQuiz(String videoId) async {
    final quizzes = await getQuizzes();
    for (final quiz in quizzes) {
      if (quiz.quiz.videoId == videoId) {
        return quiz;
      }
    }
    return null;
  }

  bool _matches(Quiz quiz, QuizFilter filter) {
    final matchesContentGenre =
        filter.contentGenres.isEmpty ||
        quiz.contentGenres.any(filter.contentGenres.contains);
    final matchesLanguage =
        filter.languages.isEmpty ||
        quiz.languages.any(filter.languages.contains);
    final matchesVideoGenre =
        filter.videoGenres.isEmpty ||
        filter.videoGenres.contains(quiz.videoGenre);
    final matchesArtist =
        filter.artists.isEmpty || quiz.artistNames.any(filter.artists.contains);
    final publishedYear = quiz.postedAt.year;
    final matchesFromYear =
        filter.publishedFromYear == null ||
        publishedYear >= filter.publishedFromYear!;
    final matchesToYear =
        filter.publishedToYear == null ||
        publishedYear <= filter.publishedToYear!;
    return matchesContentGenre &&
        matchesLanguage &&
        matchesVideoGenre &&
        matchesArtist &&
        matchesFromYear &&
        matchesToYear;
  }

  Future<List<QuizWithLiveStats>> _loadQuizzes() async {
    final sources = await Future.wait([
      rootBundle.loadString(quizAssetPath),
      rootBundle.loadString(artistsAssetPath),
      rootBundle.loadString(artistVideosAssetPath),
      rootBundle.loadString(videosJunctionAssetPath),
      rootBundle.loadString(youtubeStatsAssetPath),
    ]);
    final quizzesJson = jsonDecode(sources[0]) as List<dynamic>;
    final artistsJson = jsonDecode(sources[1]) as List<dynamic>;
    final artistVideosJson = jsonDecode(sources[2]) as List<dynamic>;
    final videosJunctionJson = jsonDecode(sources[3]) as List<dynamic>;
    final apiJson = jsonDecode(sources[4]) as Map<String, dynamic>;
    final quizIds = quizzesJson
        .map((item) => (item as Map<String, dynamic>)['video_id'] as String)
        .toSet();
    final artistsById = {
      for (final item in artistsJson)
        (item as Map<String, dynamic>)['artist_id'] as String: Artist.fromJson(
          item,
        ),
    };
    final artistsByVideo = <String, List<Artist>>{};
    for (final item in artistVideosJson) {
      final row = item as Map<String, dynamic>;
      final videoId = row['video_id'] as String;
      final artistId = row['artist_id'] as String;
      if (!quizIds.contains(videoId)) {
        throw FormatException('artist_videos_junctionの動画がありません: $videoId');
      }
      final artist = artistsById[artistId];
      if (artist == null) {
        throw FormatException('artist_videos_junctionのアーティストがありません: $artistId');
      }
      artistsByVideo.putIfAbsent(videoId, () => []).add(artist);
    }
    final relatedByVideo = <String, List<RelatedVideo>>{};
    final relationKeys = <String>{};
    for (final item in videosJunctionJson) {
      final row = item as Map<String, dynamic>;
      final videoIdA = row['video_id_a'] as String;
      final videoIdB = row['video_id_b'] as String;
      final relationType = row['relation_type'] as String;
      if (!quizIds.contains(videoIdA) || !quizIds.contains(videoIdB)) {
        throw FormatException(
          'videos_junctionの動画がありません: $videoIdA / $videoIdB',
        );
      }
      if (videoIdA == videoIdB) {
        throw FormatException('videos_junctionに自己参照があります: $videoIdA');
      }
      if (!const {
        'same_music',
        'seriese',
        'cover',
        'part_of',
      }.contains(relationType)) {
        throw FormatException('未定義のrelation_typeです: $relationType');
      }
      final orderedIds = [videoIdA, videoIdB]..sort();
      final relationKey = '${orderedIds[0]}:${orderedIds[1]}';
      if (!relationKeys.add(relationKey)) {
        throw FormatException('videos_junctionに重複があります: $relationKey');
      }
      relatedByVideo
          .putIfAbsent(videoIdA, () => [])
          .add(RelatedVideo(videoId: videoIdB, relationType: relationType));
      relatedByVideo
          .putIfAbsent(videoIdB, () => [])
          .add(RelatedVideo(videoId: videoIdA, relationType: relationType));
    }
    final videoStats = _parseVideoStats(apiJson);
    final commentLikes = _parseCommentLikes(apiJson);

    return quizzesJson
        .map((item) {
          final json = item as Map<String, dynamic>;
          final videoId = json['video_id'] as String;
          final artists = artistsByVideo[videoId] ?? const <Artist>[];
          if (artists.isEmpty) {
            throw FormatException('アーティストまたは制作者がありません: $videoId');
          }
          final quiz = Quiz.fromJson(
            json,
            artists: artists,
            relatedVideos: relatedByVideo[videoId] ?? const <RelatedVideo>[],
          );
          final stats = videoStats[quiz.videoId];
          if (stats == null) {
            throw FormatException('動画統計がありません: ${quiz.videoId}');
          }
          if (quiz.thumbnailHint == null) {
            throw FormatException('thumbnail_hintの参照先がありません: ${quiz.videoId}');
          }
          final comments = quiz.comments
              .map(
                (comment) => QuizCommentWithStats(
                  comment: comment,
                  likeCount: commentLikes[comment.commentId] ?? 0,
                ),
              )
              .toList(growable: false);
          return QuizWithLiveStats(
            quiz: quiz,
            videoStats: stats,
            comments: comments,
          );
        })
        .toList(growable: false);
  }

  Map<String, VideoLiveStats> _parseVideoStats(Map<String, dynamic> apiJson) {
    final response = apiJson['videos'] as Map<String, dynamic>;
    final items = response['items'] as List<dynamic>;
    return {
      for (final item in items)
        (item as Map<String, dynamic>)['id'] as String: VideoLiveStats.fromJson(
          item['statistics'] as Map<String, dynamic>,
        ),
    };
  }

  Map<String, int> _parseCommentLikes(Map<String, dynamic> apiJson) {
    final comments = apiJson['comments'] as Map<String, dynamic>;
    return comments.map((commentId, value) {
      final comment = value as Map<String, dynamic>;
      final snippet = comment['snippet'] as Map<String, dynamic>;
      return MapEntry(commentId, snippet['likeCount'] as int);
    });
  }
}
