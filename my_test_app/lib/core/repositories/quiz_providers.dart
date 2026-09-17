import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quiz.dart';
import 'quiz_repository.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return AssetQuizRepository();
});

final quizzesProvider = FutureProvider<List<QuizWithLiveStats>>((ref) {
  return ref.watch(quizRepositoryProvider).getQuizzes();
});

final quizProvider = FutureProvider.family<QuizWithLiveStats?, String>((
  ref,
  videoId,
) {
  return ref.watch(quizRepositoryProvider).getQuiz(videoId);
});
