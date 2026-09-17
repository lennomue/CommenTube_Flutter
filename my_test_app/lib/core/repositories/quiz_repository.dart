import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/quiz.dart';

abstract interface class QuizRepository {
  Future<List<QuizWithLiveStats>> getQuizzes();

  Future<QuizWithLiveStats?> getQuiz(String videoId);
}

class AssetQuizRepository implements QuizRepository {
  AssetQuizRepository({
    this.quizAssetPath = 'assets/mock_data/quizzes.json',
    this.youtubeStatsAssetPath = 'assets/mock_data/youtube_api_mock.json',
  });

  final String quizAssetPath;
  final String youtubeStatsAssetPath;
  Future<List<QuizWithLiveStats>>? _cache;

  @override
  Future<List<QuizWithLiveStats>> getQuizzes() {
    return _cache ??= _loadQuizzes();
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

  Future<List<QuizWithLiveStats>> _loadQuizzes() async {
    final sources = await Future.wait([
      rootBundle.loadString(quizAssetPath),
      rootBundle.loadString(youtubeStatsAssetPath),
    ]);
    final quizzesJson = jsonDecode(sources[0]) as List<dynamic>;
    final apiJson = jsonDecode(sources[1]) as Map<String, dynamic>;
    final videoStats = _parseVideoStats(apiJson);
    final commentLikes = _parseCommentLikes(apiJson);

    return quizzesJson
        .map((item) {
          final quiz = Quiz.fromJson(item as Map<String, dynamic>);
          final stats = videoStats[quiz.videoId];
          if (stats == null) {
            throw FormatException('動画統計がありません: ${quiz.videoId}');
          }
          final comments = quiz.videoComments
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
