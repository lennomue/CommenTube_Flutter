import '../database/app_database.dart';
import '../models/quiz_history.dart';

abstract interface class QuizHistoryRepository {
  Stream<List<QuizHistoryRecord>> watchHistory();

  Future<void> recordPlay(String videoId, {DateTime? playedAt});
}

class DriftQuizHistoryRepository implements QuizHistoryRepository {
  const DriftQuizHistoryRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<List<QuizHistoryRecord>> watchHistory() {
    return _database.watchQuizHistory().map(
      (rows) => rows
          .map(
            (row) =>
                QuizHistoryRecord(videoId: row.videoId, playedAt: row.playedAt),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<void> recordPlay(String videoId, {DateTime? playedAt}) {
    return _database.recordQuizPlay(videoId, playedAt ?? DateTime.now());
  }
}
