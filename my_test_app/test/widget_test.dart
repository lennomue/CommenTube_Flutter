import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_test_app/app.dart';
import 'package:my_test_app/core/models/quiz.dart';
import 'package:my_test_app/core/repositories/quiz_providers.dart';
import 'package:my_test_app/core/repositories/quiz_repository.dart';

void main() {
  testWidgets('Home画面に5問分のプレビューを表示する', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: CommenTubeApp()));
    await tester.pumpAndSettle();

    expect(find.text('CommenTube'), findsOneWidget);
    expect(find.byKey(const ValueKey('quiz-card-y2bVIBwpCTA')), findsOneWidget);
    expect(
      find.text(
        'Imagine a 10 year old sounding better than most artists today.',
      ),
      findsOneWidget,
    );
    expect(find.text('1.2億回視聴'), findsOneWidget);
    expect(find.text('ホーム'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final lastCard = find.byKey(const ValueKey('quiz-card-JGwWNGJdvx8'));
    await tester.scrollUntilVisible(lastCard, 500);
    expect(lastCard, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ボトムナビゲーションでhomeとlibraryを行き来できる', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CommenTubeApp()));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.video_library_outlined));
    await tester.pumpAndSettle();
    expect(find.text('ライブラリ画面'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('CommenTube'), findsOneWidget);
  });

  testWidgets('HomeからGameとResultを経由してHomeへ戻れる', (tester) async {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _TestQuizRepository([
      _buildTestQuiz(
        videoId: 'y2bVIBwpCTA',
        title: 'I Want You Back',
        artist: 'The Jackson 5',
      ),
      _buildTestQuiz(
        videoId: 'dQw4w9WgXcQ',
        title: 'Never Gonna Give You Up',
        artist: 'Rick Astley',
      ),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [quizRepositoryProvider.overrideWithValue(repository)],
        child: const CommenTubeApp(),
      ),
    );
    await _pumpAsyncScreen(tester);

    await tester.tap(find.byKey(const ValueKey('quiz-card-y2bVIBwpCTA')));
    await _pumpAsyncScreen(tester);

    expect(find.text('R&B・ソウル'), findsOneWidget);
    expect(find.text('コメント'), findsOneWidget);
    expect(find.text('歌詞'), findsOneWidget);
    expect(find.text('楽曲情報'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('skip-button')));
    await _pumpAsyncScreen(tester);

    expect(find.text('I Want You Back'), findsOneWidget);
    expect(find.text('The Jackson 5'), findsOneWidget);
    expect(find.byKey(const ValueKey('next-quiz-button')), findsOneWidget);
    final nextButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('next-quiz-button')),
    );
    expect(nextButton.onPressed, isNotNull);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('result-home-button')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('CommenTube'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpAsyncScreen(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

class _TestQuizRepository implements QuizRepository {
  const _TestQuizRepository(this.quizzes);

  final List<QuizWithLiveStats> quizzes;

  @override
  Future<QuizWithLiveStats?> getQuiz(String videoId) async {
    for (final quiz in quizzes) {
      if (quiz.quiz.videoId == videoId) {
        return quiz;
      }
    }
    return null;
  }

  @override
  Future<List<QuizWithLiveStats>> getQuizzes() async => quizzes;
}

QuizWithLiveStats _buildTestQuiz({
  required String videoId,
  required String title,
  required String artist,
}) {
  final comment = QuizComment(
    commentId: 'comment-$videoId',
    commentedAt: DateTime.utc(2025, 1, 1),
    content: '世代を超えて楽しめる曲です。',
  );
  return QuizWithLiveStats(
    quiz: Quiz(
      videoId: videoId,
      thumbnailCommentId: comment.commentId,
      musicGenres: const ['r_and_b_soul', 'pop'],
      videoGenre: 'music_video',
      musicTitle: title,
      musicArtists: [artist],
      musicLanguages: const ['english'],
      musicReleasedAt: DateTime.utc(1969, 10, 7),
      videoPublishedAt: DateTime.utc(2020, 6, 14),
      videoLyrics: const ['短い歌詞ヒント', 'もうひとつの歌詞ヒント'],
      videoComments: [comment],
    ),
    videoStats: const VideoLiveStats(viewCount: 117264772, likeCount: 1351220),
    comments: [QuizCommentWithStats(comment: comment, likeCount: 77307)],
  );
}
