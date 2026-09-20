import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quiz_history.dart';
import 'favorite_providers.dart';
import 'quiz_history_repository.dart';

final quizHistoryRepositoryProvider = Provider<QuizHistoryRepository>((ref) {
  return DriftQuizHistoryRepository(ref.watch(appDatabaseProvider));
});

final quizHistoryProvider = StreamProvider<List<QuizHistoryRecord>>((ref) {
  return ref.watch(quizHistoryRepositoryProvider).watchHistory();
});
