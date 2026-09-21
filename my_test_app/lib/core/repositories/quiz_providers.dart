import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quiz.dart';
import '../models/quiz_filter.dart';
import 'quiz_repository.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return AssetQuizRepository();
});

final quizzesProvider = FutureProvider<List<QuizWithLiveStats>>((ref) {
  return ref.watch(quizRepositoryProvider).getQuizzes();
});

final filteredQuizzesProvider =
    FutureProvider.family<List<QuizWithLiveStats>, QuizFilter>((ref, filter) {
      return ref.watch(quizRepositoryProvider).getQuizzes(filter: filter);
    });

final quizProvider = FutureProvider.family<QuizWithLiveStats?, String>((
  ref,
  videoId,
) {
  return ref.watch(quizRepositoryProvider).getQuiz(videoId);
});

final artistsProvider = FutureProvider<List<Artist>>((ref) {
  return ref.watch(quizRepositoryProvider).getArtists();
});

final relatedArtistsProvider = FutureProvider.family<List<Artist>, String>((
  ref,
  artistName,
) {
  return ref.watch(quizRepositoryProvider).getRelatedArtists(artistName);
});
