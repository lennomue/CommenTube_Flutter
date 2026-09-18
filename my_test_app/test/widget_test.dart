import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_test_app/app.dart';
import 'package:my_test_app/core/models/quiz.dart';
import 'package:my_test_app/core/models/quiz_filter.dart';
import 'package:my_test_app/core/repositories/quiz_providers.dart';
import 'package:my_test_app/core/repositories/quiz_repository.dart';

void main() {
  testWidgets('Home画面に5問分のプレビューを表示する', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: CommenTubeApp()));
    await _pumpAsyncScreen(tester);

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

    await tester.tap(find.byKey(const ValueKey('quick-filter-j-pop')));
    await _pumpAsyncScreen(tester);
    expect(find.text('条件に合う問題がありません'), findsOneWidget);
    expect(find.byKey(const ValueKey('quiz-card-y2bVIBwpCTA')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('quick-filter-j-pop')));
    await _pumpAsyncScreen(tester);
    expect(find.byKey(const ValueKey('quiz-card-y2bVIBwpCTA')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('open-detailed-filters')));
    await tester.pumpAndSettle();
    expect(find.text('詳細な絞り込み'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('apply-detailed-filters')));
    await tester.pumpAndSettle();

    final lastCard = find.byKey(const ValueKey('quiz-card-JGwWNGJdvx8'));
    await tester.scrollUntilVisible(
      lastCard,
      500,
      scrollable: find.byType(Scrollable).last,
    );
    expect(lastCard, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('homeとlibrary間でフッターを保ったまま切り替えられる', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CommenTubeApp()));
    await _pumpAsyncScreen(tester);

    final navigationBar = tester.element(
      find.byKey(const ValueKey('app-navigation-bar')),
    );

    await tester.tap(find.byIcon(Icons.video_library_outlined));
    await _pumpAsyncScreen(tester);
    expect(find.text('ライブラリ画面'), findsOneWidget);
    expect(
      identical(
        navigationBar,
        tester.element(find.byKey(const ValueKey('app-navigation-bar'))),
      ),
      isTrue,
    );

    await tester.tap(find.byIcon(Icons.home_outlined));
    await _pumpAsyncScreen(tester);
    expect(find.text('CommenTube'), findsOneWidget);
    expect(
      identical(
        navigationBar,
        tester.element(find.byKey(const ValueKey('app-navigation-bar'))),
      ),
      isTrue,
    );
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
    expect(find.text('最初から見える代表コメントです。'), findsOneWidget);
    expect(find.text('コメント 2'), findsOneWidget);
    expect(find.textContaining('未開放'), findsNothing);
    expect(find.text('開放後に見える追加コメントです。'), findsNothing);

    await tester.tap(
      find.byKey(
        const ValueKey('unlock-comment:comment-secondary-y2bVIBwpCTA'),
      ),
    );
    await tester.pump();

    expect(find.text('開放後に見える追加コメントです。'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.home_rounded));
    await _pumpAsyncScreen(tester);
    await tester.tap(find.byKey(const ValueKey('quiz-card-y2bVIBwpCTA')));
    await _pumpAsyncScreen(tester);

    expect(find.text('最初から見える代表コメントです。'), findsOneWidget);
    expect(find.text('コメント 2'), findsOneWidget);
    expect(find.textContaining('未開放'), findsNothing);
    expect(find.text('開放後に見える追加コメントです。'), findsNothing);

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
  Future<List<QuizWithLiveStats>> getQuizzes({
    QuizFilter filter = QuizFilter.empty,
  }) async => quizzes;
}

QuizWithLiveStats _buildTestQuiz({
  required String videoId,
  required String title,
  required String artist,
}) {
  final representativeComment = QuizComment(
    commentId: 'comment-$videoId',
    commentedAt: DateTime.utc(2025, 1, 1),
    content: '最初から見える代表コメントです。',
  );
  final secondaryComment = QuizComment(
    commentId: 'comment-secondary-$videoId',
    commentedAt: DateTime.utc(2025, 2, 1),
    content: '開放後に見える追加コメントです。',
  );
  return QuizWithLiveStats(
    quiz: Quiz(
      videoId: videoId,
      thumbnailCommentId: representativeComment.commentId,
      musicGenres: const ['r_and_b_soul', 'pop'],
      videoGenre: 'music_video',
      musicTitle: title,
      musicArtists: [artist],
      musicLanguages: const ['english'],
      musicReleasedAt: DateTime.utc(1969, 10, 7),
      videoPublishedAt: DateTime.utc(2020, 6, 14),
      videoLyrics: const ['短い歌詞ヒント', 'もうひとつの歌詞ヒント'],
      videoComments: [representativeComment, secondaryComment],
    ),
    videoStats: const VideoLiveStats(viewCount: 117264772, likeCount: 1351220),
    comments: [
      QuizCommentWithStats(comment: representativeComment, likeCount: 77307),
      QuizCommentWithStats(comment: secondaryComment, likeCount: 1200),
    ],
  );
}
