import 'package:flutter_test/flutter_test.dart';
import 'package:my_test_app/core/models/quiz_filter.dart';
import 'package:my_test_app/core/repositories/quiz_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('クイズJSONとYouTube APIモックを結合する', () async {
    final repository = AssetQuizRepository();

    final quizzes = await repository.getQuizzes();
    final cachedQuizzes = await repository.getQuizzes();

    expect(quizzes, hasLength(5));
    expect(identical(quizzes, cachedQuizzes), isTrue);

    final first = quizzes.first;
    expect(first.quiz.videoId, 'y2bVIBwpCTA');
    expect(first.quiz.musicTitle, 'I Want You Back');
    expect(first.videoStats.viewCount, 117264772);
    expect(first.representativeComment?.likeCount, 77307);
    expect(first.quiz.musicGenres, ['r_and_b_soul', 'pop']);
  });

  test('動画IDで1問を取得し、不明なIDにはnullを返す', () async {
    final repository = AssetQuizRepository();

    expect(
      (await repository.getQuiz('JGwWNGJdvx8'))?.quiz.musicTitle,
      'Shape of You',
    );
    expect(await repository.getQuiz('missing-video'), isNull);
  });

  test('ジャンル・言語・投稿年をローカルで絞り込む', () async {
    final repository = AssetQuizRepository();

    final englishQuizzes = await repository.getQuizzes(
      filter: const QuizFilter(musicLanguages: ['english']),
    );
    expect(englishQuizzes, hasLength(3));

    final quizzesFrom2010s = await repository.getQuizzes(
      filter: const QuizFilter(publishedFromYear: 2010, publishedToYear: 2019),
    );
    expect(
      quizzesFrom2010s.map((item) => item.quiz.videoId),
      containsAll(['9bZkp7q19f0', 'kJQP7kiw5Fk', 'JGwWNGJdvx8']),
    );

    final koreanDanceQuiz = await repository.getQuizzes(
      filter: const QuizFilter(
        musicGenres: ['dance_electronic'],
        musicLanguages: ['korean'],
        videoGenres: ['music_video'],
      ),
    );
    expect(koreanDanceQuiz.single.quiz.musicTitle, 'GANGNAM STYLE');
  });
}
