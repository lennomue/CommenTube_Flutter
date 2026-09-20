import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_test_app/app.dart';
import 'package:my_test_app/core/models/favorite.dart';
import 'package:my_test_app/core/models/quiz.dart';
import 'package:my_test_app/core/models/quiz_filter.dart';
import 'package:my_test_app/core/models/quiz_history.dart';
import 'package:my_test_app/core/repositories/favorite_providers.dart';
import 'package:my_test_app/core/repositories/favorite_repository.dart';
import 'package:my_test_app/core/repositories/quiz_history_providers.dart';
import 'package:my_test_app/core/repositories/quiz_history_repository.dart';
import 'package:my_test_app/core/repositories/quiz_providers.dart';
import 'package:my_test_app/core/repositories/quiz_repository.dart';
import 'package:my_test_app/core/router/app_router.dart';

void main() {
  testWidgets('Home画面に20問分のプレビューを表示する', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final historyRepository = _TestQuizHistoryRepository();
    addTearDown(historyRepository.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizHistoryRepositoryProvider.overrideWithValue(historyRepository),
        ],
        child: const CommenTubeApp(),
      ),
    );
    await _pumpAsyncScreen(tester);

    expect(find.text('CommenTube'), findsOneWidget);
    expect(find.byKey(const ValueKey('quiz-card-y2bVIBwpCTA')), findsOneWidget);
    expect(
      find.text(
        'The energy of this young performance still reaches the audience.',
      ),
      findsOneWidget,
    );
    expect(find.text('1.2億回視聴'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('app-navigation-bar'))).height,
      40,
    );
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.video_library_outlined), findsOneWidget);
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('LIBRARY'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('quick-filter-j-pop')));
    await _pumpAsyncScreen(tester);
    expect(find.byKey(const ValueKey('quiz-card-q0T7Ex7MkLM')), findsOneWidget);
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
    final favoriteRepository = _TestFavoriteRepository([
      SavedFavorite.comment(
        videoId: 'video-1',
        commentId: 'comment-1',
        content: 'ライブラリのコメント',
      ),
      SavedFavorite.lyric(videoId: 'video-1', index: 0, content: 'ライブラリの歌詞'),
      SavedFavorite.song(videoId: 'video-1', title: 'ライブラリの楽曲'),
      SavedFavorite.artist('ライブラリのアーティスト'),
    ]);
    final historyRepository = _TestQuizHistoryRepository();
    addTearDown(favoriteRepository.close);
    addTearDown(historyRepository.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          favoriteRepositoryProvider.overrideWithValue(favoriteRepository),
          quizHistoryRepositoryProvider.overrideWithValue(historyRepository),
        ],
        child: const CommenTubeApp(),
      ),
    );
    await _pumpAsyncScreen(tester);

    final navigationBar = tester.element(
      find.byKey(const ValueKey('app-navigation-bar')),
    );

    await tester.tap(find.byIcon(Icons.video_library_outlined));
    await _pumpAsyncScreen(tester);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('ライブラリのコメント'), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byIcon(Icons.video_library_rounded), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, '歌詞'));
    await tester.pumpAndSettle();
    expect(find.text('ライブラリの歌詞'), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, '楽曲'));
    await tester.pumpAndSettle();
    expect(find.text('ライブラリの楽曲'), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, 'アーティスト'));
    await tester.pumpAndSettle();
    expect(find.text('ライブラリのアーティスト'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_remove_rounded), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('library-search-field')),
      '存在しない名前',
    );
    await tester.pump();
    expect(find.text('ライブラリのアーティスト'), findsNothing);
    expect(find.text('検索に一致するアーティストはありません'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('library-search-field')),
      '',
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('library-favorite-artist:ライブラリのアーティスト')),
    );
    await _pumpAsyncScreen(tester);
    expect(find.byKey(const ValueKey('artist-back-button')), findsOneWidget);
    expect(find.text('ライブラリのアーティスト'), findsOneWidget);
    expect(find.byKey(const ValueKey('app-navigation-bar')), findsOneWidget);
    await tester.tap(find.byIcon(Icons.video_library_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Library'), findsOneWidget);
    expect(find.byKey(const ValueKey('artist-back-button')), findsNothing);
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

  testWidgets('歌詞thumbnail_hintは先頭歌詞だけを初期開放する', (tester) async {
    final repository = _TestQuizRepository([
      _buildTestQuiz(
        videoId: 'lyric-thumbnail-video',
        title: '歌詞サムネテスト',
        artist: 'テストアーティスト',
        thumbnailHintType: ThumbnailHintType.lyric,
      ),
    ]);
    final favoriteRepository = _TestFavoriteRepository();
    final historyRepository = _TestQuizHistoryRepository();
    addTearDown(favoriteRepository.close);
    addTearDown(historyRepository.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizRepositoryProvider.overrideWithValue(repository),
          favoriteRepositoryProvider.overrideWithValue(favoriteRepository),
          quizHistoryRepositoryProvider.overrideWithValue(historyRepository),
        ],
        child: const CommenTubeApp(),
      ),
    );
    await _pumpAsyncScreen(tester);

    expect(find.text('短い歌詞ヒント'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('quiz-card-lyric-thumbnail-video')),
    );
    await _pumpAsyncScreen(tester);

    expect(
      find.byKey(
        const ValueKey('unlock-comment:comment-lyric-thumbnail-video'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(Tab, '歌詞'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('unlock-lyric:0')), findsNothing);
    expect(find.text('短い歌詞ヒント'), findsOneWidget);
    expect(find.byKey(const ValueKey('unlock-lyric:1')), findsOneWidget);
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
    final favoriteRepository = _TestFavoriteRepository();
    final historyRepository = _TestQuizHistoryRepository();
    addTearDown(favoriteRepository.close);
    addTearDown(historyRepository.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizRepositoryProvider.overrideWithValue(repository),
          favoriteRepositoryProvider.overrideWithValue(favoriteRepository),
          quizHistoryRepositoryProvider.overrideWithValue(historyRepository),
        ],
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

    await tester.fling(
      find.byKey(const ValueKey('game-minimize-area')),
      const Offset(0, 220),
      1000,
    );
    await _pumpAsyncScreen(tester);
    expect(find.text('CommenTube'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('minimized-experience-button')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('minimized-experience-button')));
    await _pumpAsyncScreen(tester);

    expect(find.text('最初から見える代表コメントです。'), findsOneWidget);
    expect(find.text('コメント 2'), findsOneWidget);
    expect(find.textContaining('未開放'), findsNothing);
    expect(find.text('開放後に見える追加コメントです。'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('skip-button')));
    await _pumpAsyncScreen(tester);

    expect(find.text('I Want You Back'), findsOneWidget);
    expect(find.text('The Jackson 5'), findsWidgets);
    expect(find.byKey(const ValueKey('share-song-button')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('favorite-song-y2bVIBwpCTA')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('favorite-artist-The Jackson 5')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('next-quiz-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('youtube-music-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('spotify-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('amazon-music-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('apple-music-button')), findsOneWidget);
    final nextButton = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const ValueKey('next-quiz-button')),
        matching: find.byType(InkWell),
      ),
    );
    expect(nextButton.onTap, isNotNull);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('open-artist-The Jackson 5')));
    await _pumpAsyncScreen(tester);
    expect(find.byKey(const ValueKey('artist-back-button')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('minimized-experience-button')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('minimized-experience-button')));
    await _pumpAsyncScreen(tester);

    await tester.tap(find.byKey(const ValueKey('favorite-song-y2bVIBwpCTA')));
    await tester.pump();

    await tester.fling(
      find.byKey(const ValueKey('quiz-detail-minimize-area')),
      const Offset(0, 220),
      1000,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(const ValueKey('artist-back-button')), findsOneWidget);
    await tester.tap(find.byIcon(Icons.home_rounded));
    await _pumpAsyncScreen(tester);
    expect(find.text('CommenTube'), findsOneWidget);
    expect(find.byKey(const ValueKey('artist-back-button')), findsNothing);
    expect(
      find.byKey(const ValueKey('minimized-experience-button')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.video_library_outlined));
    await _pumpAsyncScreen(tester);
    await tester.tap(find.widgetWithText(Tab, '楽曲'));
    await tester.pumpAndSettle();
    expect(find.text('I Want You Back'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('library-favorite-song:y2bVIBwpCTA')),
    );
    await _pumpAsyncScreen(tester);
    expect(find.text('I Want You Back'), findsWidgets);
    expect(find.byKey(const ValueKey('close-library-detail')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('open-artist-The Jackson 5')));
    await _pumpAsyncScreen(tester);
    expect(find.byKey(const ValueKey('close-library-detail')), findsNothing);
    expect(find.byKey(const ValueKey('artist-back-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('app-navigation-bar')), findsOneWidget);
  });

  testWidgets('Gameを下へ読むと回答ボタンとヒントタブが縮退する', (tester) async {
    tester.view.physicalSize = const Size(430, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _TestQuizRepository([
      _buildTestQuiz(
        videoId: 'scroll-test',
        title: 'Scroll Test',
        artist: 'Test Artist',
        extraCommentCount: 10,
      ),
    ]);
    final favoriteRepository = _TestFavoriteRepository();
    final historyRepository = _TestQuizHistoryRepository();
    addTearDown(favoriteRepository.close);
    addTearDown(historyRepository.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizRepositoryProvider.overrideWithValue(repository),
          favoriteRepositoryProvider.overrideWithValue(favoriteRepository),
          quizHistoryRepositoryProvider.overrideWithValue(historyRepository),
        ],
        child: const CommenTubeApp(),
      ),
    );
    await _pumpAsyncScreen(tester);
    await tester.tap(find.byKey(const ValueKey('quiz-card-scroll-test')));
    await _pumpAsyncScreen(tester);

    expect(find.byKey(const ValueKey('game-hint-tabs')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('answer-button'))).width,
      112,
    );

    await tester.drag(find.byType(ListView).last, const Offset(0, -360));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('game-hint-tabs')), findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey('answer-button'))).width,
      62,
    );
    expect(
      tester.getCenter(find.byKey(const ValueKey('answer-button'))).dx,
      closeTo(215, 0.1),
    );

    await tester.drag(find.byType(ListView).last, const Offset(0, 220));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('game-hint-tabs')), findsOneWidget);
  });

  testWidgets('小型画面でもResultの操作列が崩れない', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _TestQuizRepository([
      _buildTestQuiz(
        videoId: 'small-result',
        title: 'Small Result',
        artist: 'Test Artist',
        artists: const [
          'Very Long Primary Artist Name',
          'Second Collaboration Artist',
          'Third Featured Artist',
        ],
      ),
      _buildTestQuiz(
        videoId: 'next-result',
        title: 'Next Result',
        artist: 'Test Artist',
      ),
    ]);
    final favoriteRepository = _TestFavoriteRepository();
    final historyRepository = _TestQuizHistoryRepository();
    final router = createAppRouter();
    addTearDown(favoriteRepository.close);
    addTearDown(historyRepository.close);
    addTearDown(router.dispose);
    router.go('/result/small-result');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizRepositoryProvider.overrideWithValue(repository),
          favoriteRepositoryProvider.overrideWithValue(favoriteRepository),
          quizHistoryRepositoryProvider.overrideWithValue(historyRepository),
        ],
        child: CommenTubeApp(router: router),
      ),
    );
    await _pumpAsyncScreen(tester);

    expect(find.byKey(const ValueKey('share-song-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('apple-music-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('next-quiz-button')), findsOneWidget);
    final artistScroll = tester.widget<ListView>(
      find.byKey(const ValueKey('artist-favorite-scroll')),
    );
    expect(artistScroll.scrollDirection, Axis.horizontal);
    expect(tester.takeException(), isNull);
  });

  testWidgets('アーティスト連続クイズは画面を縮小でき最後にFINISHする', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _TestQuizRepository([
      _buildTestQuiz(
        videoId: 'artist-first',
        title: 'First Song',
        artist: 'Test Artist',
      ),
      _buildTestQuiz(
        videoId: 'artist-second',
        title: 'Second Song',
        artist: 'Test Artist',
      ),
    ]);
    final favoriteRepository = _TestFavoriteRepository([
      SavedFavorite.artist('Test Artist'),
    ]);
    final historyRepository = _TestQuizHistoryRepository();
    addTearDown(favoriteRepository.close);
    addTearDown(historyRepository.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizRepositoryProvider.overrideWithValue(repository),
          favoriteRepositoryProvider.overrideWithValue(favoriteRepository),
          quizHistoryRepositoryProvider.overrideWithValue(historyRepository),
        ],
        child: const CommenTubeApp(),
      ),
    );
    await _pumpAsyncScreen(tester);

    await tester.tap(find.byIcon(Icons.video_library_outlined));
    await _pumpAsyncScreen(tester);
    await tester.tap(find.widgetWithText(Tab, 'アーティスト'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('library-favorite-artist:Test Artist')),
    );
    await _pumpAsyncScreen(tester);

    expect(find.byKey(const ValueKey('app-navigation-bar')), findsOneWidget);
    expect(find.text('First Song'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('start-artist-quiz')));
    await _pumpAsyncScreen(tester);
    await tester.tap(find.byKey(const ValueKey('skip-button')));
    await _pumpAsyncScreen(tester);

    expect(find.text('NEXT QUIZ'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('open-artist-Test Artist')));
    await _pumpAsyncScreen(tester);
    expect(
      find.byKey(const ValueKey('minimized-experience-button')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('app-navigation-bar')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('minimized-experience-button')));
    await _pumpAsyncScreen(tester);
    expect(find.text('NEXT QUIZ'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('next-quiz-button')));
    await _pumpAsyncScreen(tester);
    expect(find.text('Second Song'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('skip-button')));
    await _pumpAsyncScreen(tester);

    expect(find.text('FINISH'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('next-quiz-button')));
    await _pumpAsyncScreen(tester);
    expect(find.byKey(const ValueKey('artist-back-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('app-navigation-bar')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('minimized-experience-button')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('クイズ開始履歴をLibraryから表示して再開できる', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _TestQuizRepository([
      _buildTestQuiz(
        videoId: 'history-video',
        title: 'History Song',
        artist: 'History Artist',
      ),
    ]);
    final favoriteRepository = _TestFavoriteRepository();
    final historyRepository = _TestQuizHistoryRepository();
    addTearDown(favoriteRepository.close);
    addTearDown(historyRepository.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizRepositoryProvider.overrideWithValue(repository),
          favoriteRepositoryProvider.overrideWithValue(favoriteRepository),
          quizHistoryRepositoryProvider.overrideWithValue(historyRepository),
        ],
        child: const CommenTubeApp(),
      ),
    );
    await _pumpAsyncScreen(tester);

    await tester.tap(find.byKey(const ValueKey('quiz-card-history-video')));
    await _pumpAsyncScreen(tester);
    expect(historyRepository.records.single.videoId, 'history-video');
    await tester.tap(find.byKey(const ValueKey('minimize-game-button')));
    await _pumpAsyncScreen(tester);
    await tester.tap(find.byIcon(Icons.video_library_outlined));
    await _pumpAsyncScreen(tester);
    await tester.tap(find.widgetWithText(Tab, '履歴'));
    await tester.pumpAndSettle();

    expect(find.text('History Song'), findsOneWidget);
    expect(find.textContaining('回視聴'), findsOneWidget);
    expect(find.textContaining('高評価'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('history-quiz-history-video')));
    await _pumpAsyncScreen(tester);
    expect(find.byKey(const ValueKey('minimize-game-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('関連動画を4種類の規定順でResultに表示する', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _TestQuizRepository([
      _buildTestQuiz(
        videoId: 'related-source',
        title: 'Related Source',
        artist: 'Source Artist',
        relatedVideos: const [
          RelatedVideo(videoId: 'same-video', relationType: 'same_music'),
          RelatedVideo(videoId: 'series-video', relationType: 'seriese'),
          RelatedVideo(videoId: 'cover-video', relationType: 'cover'),
          RelatedVideo(videoId: 'mad-video', relationType: 'part_of'),
        ],
      ),
      _buildTestQuiz(
        videoId: 'same-video',
        title: 'Same Song Video',
        artist: 'Same Artist',
      ),
      _buildTestQuiz(
        videoId: 'series-video',
        title: 'Series Song Video',
        artist: 'Series Artist',
      ),
      _buildTestQuiz(
        videoId: 'cover-video',
        title: 'Cover Song Video',
        artist: 'Cover Artist',
      ),
      _buildTestQuiz(
        videoId: 'mad-video',
        title: 'MAD Source Video',
        artist: 'MAD Artist',
      ),
    ]);
    final favoriteRepository = _TestFavoriteRepository();
    final historyRepository = _TestQuizHistoryRepository();
    final router = createAppRouter()..go('/result/related-source');
    addTearDown(favoriteRepository.close);
    addTearDown(historyRepository.close);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizRepositoryProvider.overrideWithValue(repository),
          favoriteRepositoryProvider.overrideWithValue(favoriteRepository),
          quizHistoryRepositoryProvider.overrideWithValue(historyRepository),
        ],
        child: CommenTubeApp(router: router),
      ),
    );
    await _pumpAsyncScreen(tester);
    await tester.tap(find.widgetWithText(Tab, '関連'));
    await tester.pumpAndSettle();

    final labels = ['同じ曲', 'シリーズ', 'カバー', 'MAD・構成元'];
    for (final label in labels) {
      expect(find.text(label), findsOneWidget);
    }
    for (var index = 1; index < labels.length; index++) {
      expect(
        tester.getTopLeft(find.text(labels[index - 1])).dy,
        lessThan(tester.getTopLeft(find.text(labels[index])).dy),
      );
    }
    expect(find.text('Same Song Video'), findsOneWidget);
    expect(find.textContaining('年前'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'iOSの左端スワイプでGameとResultを閉じない',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _TestQuizRepository([
        _buildTestQuiz(
          videoId: 'swipe-video',
          title: 'Swipe Song',
          artist: 'Swipe Artist',
        ),
      ]);
      final favoriteRepository = _TestFavoriteRepository();
      final historyRepository = _TestQuizHistoryRepository();
      addTearDown(favoriteRepository.close);
      addTearDown(historyRepository.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            quizRepositoryProvider.overrideWithValue(repository),
            favoriteRepositoryProvider.overrideWithValue(favoriteRepository),
            quizHistoryRepositoryProvider.overrideWithValue(historyRepository),
          ],
          child: const CommenTubeApp(),
        ),
      );
      await _pumpAsyncScreen(tester);
      await tester.tap(find.byKey(const ValueKey('quiz-card-swipe-video')));
      await _pumpAsyncScreen(tester);

      await tester.dragFrom(const Offset(1, 350), const Offset(300, 0));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('minimize-game-button')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('skip-button')));
      await _pumpAsyncScreen(tester);
      await tester.dragFrom(const Offset(1, 350), const Offset(300, 0));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('next-quiz-button')), findsOneWidget);
      expect(find.text('Swipe Song'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
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

class _TestFavoriteRepository implements FavoriteRepository {
  _TestFavoriteRepository([Iterable<SavedFavorite> favorites = const []]) {
    _favorites.addAll(favorites);
  }

  final List<SavedFavorite> _favorites = [];
  final StreamController<List<SavedFavorite>> _controller =
      StreamController<List<SavedFavorite>>.broadcast();

  @override
  Stream<List<SavedFavorite>> watchFavorites() async* {
    yield List.unmodifiable(_favorites);
    yield* _controller.stream;
  }

  @override
  Future<void> toggleFavorite(SavedFavorite favorite) async {
    final index = _favorites.indexWhere((item) => item.id == favorite.id);
    if (index == -1) {
      _favorites.add(favorite);
    } else {
      _favorites.removeAt(index);
    }
    _controller.add(List.unmodifiable(_favorites));
  }

  @override
  Future<void> removeFavorite(String id) async {
    _favorites.removeWhere((favorite) => favorite.id == id);
    _controller.add(List.unmodifiable(_favorites));
  }

  Future<void> close() => _controller.close();
}

class _TestQuizHistoryRepository implements QuizHistoryRepository {
  _TestQuizHistoryRepository([Iterable<QuizHistoryRecord> records = const []])
    : records = List.of(records);

  final List<QuizHistoryRecord> records;
  final StreamController<List<QuizHistoryRecord>> _controller =
      StreamController<List<QuizHistoryRecord>>.broadcast();

  @override
  Stream<List<QuizHistoryRecord>> watchHistory() async* {
    yield List.unmodifiable(records);
    yield* _controller.stream;
  }

  @override
  Future<void> recordPlay(String videoId, {DateTime? playedAt}) async {
    records.removeWhere((record) => record.videoId == videoId);
    records.insert(
      0,
      QuizHistoryRecord(videoId: videoId, playedAt: playedAt ?? DateTime.now()),
    );
    if (records.length > 50) {
      records.removeRange(50, records.length);
    }
    _controller.add(List.unmodifiable(records));
  }

  Future<void> close() => _controller.close();
}

QuizWithLiveStats _buildTestQuiz({
  required String videoId,
  required String title,
  required String artist,
  List<String>? artists,
  ThumbnailHintType thumbnailHintType = ThumbnailHintType.comment,
  int extraCommentCount = 0,
  List<RelatedVideo> relatedVideos = const [],
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
  final extraComments = List.generate(
    extraCommentCount,
    (index) => QuizComment(
      commentId: 'comment-extra-$index-$videoId',
      commentedAt: DateTime.utc(2025, 3, index + 1),
      content: 'スクロール確認用の追加コメント ${index + 1} です。',
    ),
  );
  final artistNames = artists ?? [artist];
  return QuizWithLiveStats(
    quiz: Quiz(
      videoId: videoId,
      atmosphereColor: const AtmosphereColor(
        hue: 140,
        saturation: 0.85,
        lightness: 0.06,
      ),
      thumbnailHintType: thumbnailHintType,
      contentGenres: const ['r_and_b_soul', 'pop'],
      videoGenre: 'music_video',
      title: title,
      artists: [
        for (final indexed in artistNames.indexed)
          Artist(
            artistId: 'test-artist-${indexed.$1}',
            name: indexed.$2,
            subNames: const [],
          ),
      ],
      languages: const ['english'],
      musicReleasedAt: PartialDate(
        precision: DatePrecision.day,
        date: DateTime.utc(1969, 10, 7),
      ),
      postedAt: DateTime.utc(2020, 6, 14),
      musicLyrics: const ['短い歌詞ヒント', 'もうひとつの歌詞ヒント'],
      comments: [representativeComment, secondaryComment, ...extraComments],
      relatedVideos: relatedVideos,
      metaData: const {},
      embedding: null,
    ),
    videoStats: const VideoLiveStats(viewCount: 117264772, likeCount: 1351220),
    comments: [
      QuizCommentWithStats(comment: representativeComment, likeCount: 77307),
      QuizCommentWithStats(comment: secondaryComment, likeCount: 1200),
      for (final comment in extraComments)
        QuizCommentWithStats(comment: comment, likeCount: 100),
    ],
  );
}
