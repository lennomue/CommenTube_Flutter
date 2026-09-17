import 'package:flutter_test/flutter_test.dart';
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
}
