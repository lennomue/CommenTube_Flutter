import 'dart:async';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_test_app/app.dart';
import 'package:my_test_app/core/models/favorite.dart';
import 'package:my_test_app/core/models/quiz.dart';
import 'package:my_test_app/core/models/quiz_filter.dart';
import 'package:my_test_app/core/models/quiz_history.dart';
import 'package:my_test_app/core/models/playlist.dart';
import 'package:my_test_app/core/repositories/favorite_providers.dart';
import 'package:my_test_app/core/repositories/favorite_repository.dart';
import 'package:my_test_app/core/repositories/quiz_history_providers.dart';
import 'package:my_test_app/core/repositories/quiz_history_repository.dart';
import 'package:my_test_app/core/repositories/playlist_providers.dart';
import 'package:my_test_app/core/repositories/playlist_repository.dart';
import 'package:my_test_app/core/repositories/quiz_providers.dart';
import 'package:my_test_app/core/repositories/quiz_repository.dart';
import 'package:my_test_app/core/router/app_router.dart';
import 'package:my_test_app/core/widgets/neon_accent.dart';
import 'package:my_test_app/features/library/presentation/playlist_screen.dart';

void main() {
  setUpAll(() {
    // Widget tests rebuild independent ProviderScopes against the same
    // temporary database executor; production keeps a single app scope.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });
  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  testWidgets('Home画面は30問から新規優先で10問を表示する', (tester) async {
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
    expect(find.byKey(const ValueKey('neon-new-outline')), findsWidgets);
    expect(
      tester
          .widget<ListView>(find.byKey(const ValueKey('home-quiz-feed')))
          .childrenDelegate
          .estimatedChildCount,
      19,
    );
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
    final selectedJPopChip = find.byKey(const ValueKey('quick-filter-j-pop'));
    expect(
      tester
          .widget<Text>(
            find.descendant(of: selectedJPopChip, matching: find.text('J-Pop')),
          )
          .style
          ?.color,
      Colors.black,
    );
    expect(
      tester.widget<FilterChip>(selectedJPopChip).selectedColor,
      Colors.white,
    );
    expect(
      tester
          .widget<ListView>(find.byKey(const ValueKey('home-quiz-feed')))
          .childrenDelegate
          .estimatedChildCount,
      lessThan(19),
    );

    await tester.tap(find.byKey(const ValueKey('quick-filter-j-pop')));
    await _pumpAsyncScreen(tester);
    expect(
      tester
          .widget<ListView>(find.byKey(const ValueKey('home-quiz-feed')))
          .childrenDelegate
          .estimatedChildCount,
      19,
    );

    await tester.tap(find.byKey(const ValueKey('open-detailed-filters')));
    await tester.pumpAndSettle();
    expect(find.text('詳細な絞り込み'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('動画ジャンル'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('楽曲'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('投稿年の範囲'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    expect(tester.widget<RangeSlider>(find.byType(RangeSlider)).min, 2005);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('apply-detailed-filters')));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).last, const Offset(0, 320));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ListView>(find.byKey(const ValueKey('home-quiz-feed')))
          .childrenDelegate
          .estimatedChildCount,
      19,
    );
    await tester.drag(
      find.byKey(const ValueKey('home-quiz-feed')),
      const Offset(0, -320),
    );
    await tester.pumpAndSettle();
    final homeController = tester
        .widget<ListView>(find.byKey(const ValueKey('home-quiz-feed')))
        .controller!;
    expect(homeController.offset, greaterThan(0));
    await tester.tap(find.byIcon(Icons.home_rounded));
    await tester.pumpAndSettle();
    expect(homeController.offset, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('homeとlibrary間でフッターを保ったまま切り替えられる', (tester) async {
    final quizRepository = _TestQuizRepository([
      _buildTestQuiz(
        videoId: 'y2bVIBwpCTA',
        title: 'I Want You Back',
        artist: 'The Jackson 5',
      ),
    ]);
    final favoriteRepository = _TestFavoriteRepository([
      SavedFavorite.comment(
        videoId: 'video-1',
        commentId: 'comment-1',
        content: 'ライブラリのコメント',
      ),
      SavedFavorite.lyric(videoId: 'video-1', index: 0, content: 'ライブラリの歌詞'),
      SavedFavorite.song(videoId: 'y2bVIBwpCTA', title: 'I Want You Back'),
      SavedFavorite.artist('ライブラリのアーティスト'),
    ]);
    final historyRepository = _TestQuizHistoryRepository();
    addTearDown(favoriteRepository.close);
    addTearDown(historyRepository.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizRepositoryProvider.overrideWithValue(quizRepository),
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
    final favoriteLauncher = find.byKey(const ValueKey('start-favorite-quiz'));
    expect(
      find.descendant(of: favoriteLauncher, matching: find.text('お気に入りでクイズ')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('shuffle-favorite-quiz')),
        matching: find.byIcon(Icons.shuffle_rounded),
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(Tab, '歌詞'));
    await tester.pumpAndSettle();
    expect(find.text('ライブラリの歌詞'), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, '作品'));
    await _pumpAsyncScreen(tester);
    expect(find.text('I Want You Back'), findsOneWidget);
    expect(find.byKey(const ValueKey('library-work-toolbar')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('work-collection-menu')));
    await tester.pumpAndSettle();
    expect(find.text('まとめて再生リストに追加する'), findsOneWidget);
    await tester.tap(find.text('まとめて再生リストに追加する'));
    await _pumpAsyncScreen(tester);
    expect(find.text('作品をまとめて追加'), findsOneWidget);
    Navigator.of(tester.element(find.text('作品をまとめて追加'))).pop();
    await _pumpAsyncScreen(tester);

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
    await tester.tap(find.widgetWithText(Tab, '作品'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('artist-work-toolbar')), findsOneWidget);
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

  testWidgets('歌詞thumbnail_hint_typeは歌詞タブを開き先頭歌詞だけを初期開放する', (tester) async {
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

    expect(find.text('短い歌詞ヒント'), findsWidgets);
    await tester.tap(
      find.byKey(const ValueKey('quiz-card-lyric-thumbnail-video')),
    );
    await _pumpAsyncScreen(tester);

    final gameTabs = find.byKey(const ValueKey('game-hint-tabs'));
    expect(DefaultTabController.of(tester.element(gameTabs)).index, 1);

    await tester.tap(find.widgetWithText(Tab, 'コメント'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey('unlock-comment:comment-lyric-thumbnail-video'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(Tab, '歌詞'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('unlock-lyric:0')), findsNothing);
    expect(find.text('短い歌詞ヒント'), findsWidgets);
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
    expect(find.text('作品情報'), findsOneWidget);
    expect(find.text('最初から見える代表コメントです。'), findsWidgets);
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

    expect(find.text('最初から見える代表コメントです。'), findsWidgets);
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
    final resultTabs = find.byKey(const ValueKey('result-detail-tabs'));
    expect(
      tester.widget<TabBar>(resultTabs).indicatorSize,
      TabBarIndicatorSize.tab,
    );
    expect(
      tester.getBottomLeft(resultTabs).dy,
      closeTo(tester.getTopLeft(find.byType(TabBarView)).dy, 0.1),
    );
    final nextLabelCenter = tester.getCenter(find.text('NEXT QUIZ'));
    final nextHandleCenter = tester.getCenter(
      find.byKey(const ValueKey('next-quiz-handle')),
    );
    expect(nextHandleCenter.dx, closeTo(nextLabelCenter.dx, 0.1));
    expect(nextHandleCenter.dy, lessThan(nextLabelCenter.dy));
    expect(
      tester
          .widget<GestureDetector>(
            find.byKey(const ValueKey('next-quiz-button')),
          )
          .onVerticalDragUpdate,
      isNotNull,
    );
    final nextHeight = tester
        .getSize(find.byKey(const ValueKey('next-quiz-stretch')))
        .height;
    final nextGesture = await tester.startGesture(nextLabelCenter);
    await nextGesture.moveBy(const Offset(0, -30));
    await tester.pump();
    await nextGesture.moveBy(const Offset(0, -30));
    await tester.pump();
    expect(
      tester.getSize(find.byKey(const ValueKey('next-quiz-stretch'))).height,
      greaterThan(nextHeight),
    );
    expect(
      tester.getCenter(find.text('NEXT QUIZ')).dy,
      lessThan(nextLabelCenter.dy),
    );
    await nextGesture.cancel();
    await tester.pumpAndSettle();
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
    await tester.tap(find.widgetWithText(Tab, '作品'));
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

  testWidgets('Gameをスクロールしてもヒントタブは固定し回答ボタンだけ縮退する', (tester) async {
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
    final normalAnswerRect = tester.getRect(
      find.byKey(const ValueKey('answer-button')),
    );
    final skipRect = tester.getRect(find.byKey(const ValueKey('skip-button')));
    expect(
      tester.getCenter(find.byKey(const ValueKey('answer-label'))).dy,
      closeTo(normalAnswerRect.center.dy, 0.1),
    );
    expect(skipRect.bottom, closeTo(normalAnswerRect.bottom, 0.1));
    expect(430 - skipRect.right, closeTo(24, 0.1));

    await tester.drag(find.byType(ListView).last, const Offset(0, -360));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('game-hint-tabs')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('answer-button'))).width,
      62,
    );
    expect(
      tester.getCenter(find.byKey(const ValueKey('answer-button'))).dx,
      closeTo(215, 0.1),
    );
    final compactAnswerRect = tester.getRect(
      find.byKey(const ValueKey('answer-button')),
    );
    expect(compactAnswerRect.bottom, closeTo(normalAnswerRect.bottom, 0.1));
    expect(
      tester.getCenter(find.byKey(const ValueKey('compact-answer-handle'))).dy,
      closeTo(compactAnswerRect.center.dy, 0.1),
    );

    await tester.drag(find.byType(ListView).last, const Offset(0, 360));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const ValueKey('answer-button'))).width,
      112,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('回答ボタンを上へスワイプすると検索入力を開き外側タップで戻る', (tester) async {
    final repository = _TestQuizRepository([
      _buildTestQuiz(
        videoId: 'answer-swipe',
        title: 'Answer Swipe',
        artist: 'Test Artist',
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
    await tester.tap(find.byKey(const ValueKey('quiz-card-answer-swipe')));
    await _pumpAsyncScreen(tester);

    await tester.drag(
      find.byKey(const ValueKey('answer-button')),
      const Offset(0, -80),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('answer-search-field')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('answer-button'))).width,
      276,
    );

    tester.view.viewInsets = const FakeViewPadding(bottom: 560);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    final answerButton = find.byKey(const ValueKey('answer-button'));
    final answerRect = tester.getRect(answerButton);
    final gameTabsRect = tester.getRect(
      find.byKey(const ValueKey('game-hint-tabs')),
    );
    final overlapTop = answerRect.top > gameTabsRect.top
        ? answerRect.top
        : gameTabsRect.top;
    final overlapBottom = answerRect.bottom < gameTabsRect.bottom
        ? answerRect.bottom
        : gameTabsRect.bottom;
    expect(overlapBottom, greaterThan(overlapTop));
    final overlapPoint = Offset(
      answerRect.center.dx,
      (overlapTop + overlapBottom) / 2,
    );
    final answerRenderObject = tester.renderObject(answerButton);
    final hitTest = tester.hitTestOnBinding(overlapPoint);
    expect(
      hitTest.path.map((entry) => entry.target),
      contains(answerRenderObject),
    );

    await tester.enterText(
      find.byKey(const ValueKey('answer-search-field')),
      'Radio Gaga',
    );
    await tester.pump();
    final youtubeIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const ValueKey('open-youtube-search')),
        matching: find.byIcon(Icons.smart_display_rounded),
      ),
    );
    expect(youtubeIcon.color, const Color(0xFFFF0033));

    await tester.tapAt(const Offset(24, 320));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('answer-search-field')), findsNothing);
    expect(tester.takeException(), isNull);
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

    await tester.tap(find.byKey(const ValueKey('minimize-result-button')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.byKey(const ValueKey('minimize-result-button')),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('minimized-experience-button')),
      findsOneWidget,
    );
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
        thumbnailHintType: ThumbnailHintType.lyric,
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
    final firstArtistQuiz = find.byKey(
      const ValueKey('artist-quiz-artist-first'),
    );
    final secondArtistQuiz = find.byKey(
      const ValueKey('artist-quiz-artist-second'),
    );
    expect(
      find.descendant(
        of: firstArtistQuiz,
        matching: find.byIcon(Icons.chat_bubble_outline_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: secondArtistQuiz,
        matching: find.byIcon(Icons.music_note_rounded),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Material>(
            find
                .ancestor(of: firstArtistQuiz, matching: find.byType(Material))
                .first,
          )
          .color,
      const HSLColor.fromAHSL(1, 140, 0.85, 0.06).toColor(),
    );
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
    await tester.fling(
      find.byKey(const ValueKey('next-quiz-button')),
      const Offset(0, -90),
      800,
    );
    await _pumpAsyncScreen(tester);
    expect(find.text('Second Song'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('skip-button')));
    await _pumpAsyncScreen(tester);

    expect(find.text('FINISH'), findsOneWidget);
    await tester.fling(
      find.byKey(const ValueKey('next-quiz-button')),
      const Offset(0, -90),
      800,
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester
          .widget<AnimatedSlide>(
            find.byKey(const ValueKey('result-finish-slide')),
          )
          .offset
          .dy,
      lessThan(0),
    );
    await _pumpAsyncScreen(tester);
    expect(find.byKey(const ValueKey('artist-back-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('app-navigation-bar')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('minimized-experience-button')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('履歴読込が遅くてもGameの新規判定を記録前に確定する', (tester) async {
    final repository = _TestQuizRepository([
      _buildTestQuiz(
        videoId: 'new-indicator-video',
        title: 'New Indicator',
        artist: 'Indicator Artist',
      ),
    ]);
    final favoriteRepository = _TestFavoriteRepository();
    final historyRepository = _DelayedQuizHistoryRepository();
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
    await tester.tap(
      find.byKey(const ValueKey('quiz-card-new-indicator-video')),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('game-hint-tabs')), findsNothing);

    historyRepository.emit(const []);
    await _pumpAsyncScreen(tester);
    final tabBar = tester.widget<TabBar>(
      find.descendant(
        of: find.byKey(const ValueKey('game-hint-tabs')),
        matching: find.byType(TabBar),
      ),
    );
    expect(tabBar.indicator, isA<NeonTabIndicator>());
    expect(tabBar.indicatorSize, TabBarIndicatorSize.tab);
    expect(historyRepository.records.single.videoId, 'new-indicator-video');
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
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('minimize-game-button')), findsOneWidget);
    expect(find.text('CommenTube'), findsOneWidget);
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

  testWidgets('再生リストを作成し楽曲追加後に連続クイズを開始できる', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _TestQuizRepository([
      _buildTestQuiz(
        videoId: 'playlist-video',
        title: 'Playlist Song',
        artist: 'Playlist Artist',
      ),
    ]);
    final favoriteRepository = _TestFavoriteRepository([
      SavedFavorite.artist('Playlist Artist'),
    ]);
    final historyRepository = _TestQuizHistoryRepository();
    final playlistRepository = _TestPlaylistRepository();
    addTearDown(favoriteRepository.close);
    addTearDown(historyRepository.close);
    addTearDown(playlistRepository.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizRepositoryProvider.overrideWithValue(repository),
          favoriteRepositoryProvider.overrideWithValue(favoriteRepository),
          quizHistoryRepositoryProvider.overrideWithValue(historyRepository),
          playlistRepositoryProvider.overrideWithValue(playlistRepository),
          publicPlaylistsProvider.overrideWith((ref) async => const []),
        ],
        child: const CommenTubeApp(),
      ),
    );
    await _pumpAsyncScreen(tester);
    await tester.tap(find.byIcon(Icons.video_library_outlined));
    await _pumpAsyncScreen(tester);
    await tester.tap(find.byKey(const ValueKey('show-library-playlists')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create-empty-playlist')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('playlist-name-field')),
      'テストリスト',
    );
    await tester.tap(find.byKey(const ValueKey('save-playlist-button')));
    await _pumpAsyncScreen(tester);
    expect(find.text('テストリスト'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('show-library-favorites')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, 'アーティスト'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('library-favorite-artist:Playlist Artist')),
    );
    await _pumpAsyncScreen(tester);
    await tester.tap(find.widgetWithText(Tab, '作品').last);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('song-playlist-playlist-video')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('playlist-picker-test-playlist-1')),
    );
    await tester.pumpAndSettle();
    expect(playlistRepository.playlists.single.videoIds, ['playlist-video']);
    await tester.tap(
      find.byKey(const ValueKey('song-playlist-playlist-video')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('playlist-picker-test-playlist-1')),
    );
    await tester.pumpAndSettle();
    expect(playlistRepository.playlists.single.videoIds, isEmpty);
    await tester.tap(
      find.byKey(const ValueKey('song-playlist-playlist-video')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('playlist-picker-test-playlist-1')),
    );
    await tester.pumpAndSettle();
    expect(playlistRepository.playlists.single.videoIds, ['playlist-video']);

    await tester.tap(find.byIcon(Icons.video_library_rounded));
    await _pumpAsyncScreen(tester);
    await tester.tap(find.byKey(const ValueKey('show-library-playlists')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('library-playlist-test-playlist-1')),
    );
    await _pumpAsyncScreen(tester);
    expect(find.byKey(const ValueKey('playlist-menu-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('shuffle-playlist-quiz')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('playlist-back-button')));
    await _pumpAsyncScreen(tester);
    expect(find.byKey(const ValueKey('playlist-menu-button')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(
      find.byKey(const ValueKey('library-playlist-test-playlist-1')),
    );
    await _pumpAsyncScreen(tester);
    await tester.tap(find.widgetWithText(Tab, '作品'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('toggle-playlist-reorder')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('app-navigation-bar')), findsNothing);
    expect(find.byKey(const ValueKey('playlist-menu-button')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('toggle-playlist-reorder')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('app-navigation-bar')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('start-playlist-quiz')));
    await _pumpAsyncScreen(tester);
    expect(find.byKey(const ValueKey('minimize-game-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home検索で作品とプレイリストを横断検索できる', (tester) async {
    final quizRepository = _TestQuizRepository([
      _buildTestQuiz(
        videoId: 'search-video',
        title: 'Searchable Work',
        artist: 'Search Artist',
        metaData: const {
          'keywords': ['secret-context-keyword'],
        },
      ),
    ]);
    final favoriteRepository = _TestFavoriteRepository();
    final historyRepository = _TestQuizHistoryRepository();
    final playlistRepository = _TestPlaylistRepository();
    addTearDown(favoriteRepository.close);
    addTearDown(historyRepository.close);
    addTearDown(playlistRepository.close);
    await playlistRepository.createPlaylist(
      const PlaylistDraft(name: '検索用リスト', isPublic: false),
      firstVideoId: 'search-video',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizRepositoryProvider.overrideWithValue(quizRepository),
          favoriteRepositoryProvider.overrideWithValue(favoriteRepository),
          quizHistoryRepositoryProvider.overrideWithValue(historyRepository),
          playlistRepositoryProvider.overrideWithValue(playlistRepository),
          publicPlaylistsProvider.overrideWith((ref) async => const []),
        ],
        child: const CommenTubeApp(),
      ),
    );
    await _pumpAsyncScreen(tester);

    await tester.tap(find.byKey(const ValueKey('home-search-button')));
    await _pumpAsyncScreen(tester);
    expect(find.byKey(const ValueKey('app-navigation-bar')), findsOneWidget);
    expect(
      tester.widget<AppBar>(find.byType(AppBar)).backgroundColor,
      const Color(0xFF090909),
    );
    await tester.tap(find.byKey(const ValueKey('search-back-button')));
    await tester.pump();
    expect(find.byKey(const ValueKey('global-search-field')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('global-search-field')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('global-search-field')),
      'Searchable',
    );
    await _pumpAsyncScreen(tester);
    expect(
      find.byKey(const ValueKey('search-quiz-search-video')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('global-search-field')),
      'Search Artist',
    );
    await _pumpAsyncScreen(tester);
    final artistResult = find.byKey(
      const ValueKey('search-artist-test-artist-0'),
    );
    final artistWork = find.byKey(const ValueKey('search-quiz-search-video'));
    expect(artistResult, findsOneWidget);
    expect(artistWork, findsOneWidget);
    expect(
      tester.getTopLeft(artistResult).dy,
      lessThan(tester.getTopLeft(artistWork).dy),
    );
    expect(
      find.byKey(const ValueKey('search-start-artist-quiz-test-artist-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('search-shuffle-artist-quiz-test-artist-0')),
      findsOneWidget,
    );
    await tester.tap(artistResult);
    await _pumpAsyncScreen(tester);
    expect(find.byKey(const ValueKey('artist-back-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('app-navigation-bar')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('artist-back-button')));
    await _pumpAsyncScreen(tester);
    expect(find.byKey(const ValueKey('global-search-field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('global-search-field')),
      'secret-context-keyword',
    );
    await _pumpAsyncScreen(tester);
    expect(
      find.byKey(const ValueKey('search-quiz-search-video')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('global-search-field')),
      '検索用',
    );
    await _pumpAsyncScreen(tester);
    expect(find.text('検索用リスト'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('global-search-field')),
      'Searchable',
    );
    await _pumpAsyncScreen(tester);
    await tester.tap(find.byKey(const ValueKey('search-quiz-search-video')));
    await _pumpAsyncScreen(tester);
    await tester.fling(
      find.byKey(const ValueKey('game-minimize-area')),
      const Offset(0, 220),
      1000,
    );
    await _pumpAsyncScreen(tester);
    expect(find.byKey(const ValueKey('global-search-field')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('minimized-experience-button')),
      findsOneWidget,
    );
    await tester.tap(find.byIcon(Icons.video_library_outlined));
    await _pumpAsyncScreen(tester);
    expect(find.text('Library'), findsOneWidget);
    expect(find.byKey(const ValueKey('global-search-field')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Libraryは初期状態でマイと保存済みを両方表示する', (tester) async {
    final quizRepository = _TestQuizRepository([
      _buildTestQuiz(
        videoId: 'filter-playlist-video',
        title: 'Filter Work',
        artist: 'Filter Artist',
      ),
    ]);
    final favoriteRepository = _TestFavoriteRepository();
    final historyRepository = _TestQuizHistoryRepository();
    final playlistRepository = _TestPlaylistRepository();
    addTearDown(favoriteRepository.close);
    addTearDown(historyRepository.close);
    addTearDown(playlistRepository.close);
    await playlistRepository.createPlaylist(
      const PlaylistDraft(name: '自分のリスト', isPublic: false),
      firstVideoId: 'filter-playlist-video',
    );
    await playlistRepository.copyPlaylist(
      UserPlaylist(
        id: 'public-source',
        name: '保存元リスト',
        isPublic: true,
        description: '',
        allowsCollaboration: false,
        isOwned: false,
        videoIds: const ['filter-playlist-video'],
        createdAt: DateTime.utc(2026, 9, 20),
        updatedAt: DateTime.utc(2026, 9, 20),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizRepositoryProvider.overrideWithValue(quizRepository),
          favoriteRepositoryProvider.overrideWithValue(favoriteRepository),
          quizHistoryRepositoryProvider.overrideWithValue(historyRepository),
          playlistRepositoryProvider.overrideWithValue(playlistRepository),
          publicPlaylistsProvider.overrideWith((ref) async => const []),
        ],
        child: const CommenTubeApp(),
      ),
    );
    await _pumpAsyncScreen(tester);
    await tester.tap(find.byIcon(Icons.video_library_outlined));
    await _pumpAsyncScreen(tester);
    await tester.tap(find.byKey(const ValueKey('show-library-playlists')));
    await tester.pumpAndSettle();

    expect(find.text('自分のリスト'), findsOneWidget);
    expect(find.text('保存元リスト のコピー'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('playlist-section-mine')));
    await tester.pumpAndSettle();
    expect(find.text('自分のリスト'), findsOneWidget);
    expect(find.text('保存元リスト のコピー'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Playlist編集は最初に選んだ作品の位置で選択順にまとめる', (tester) async {
    final quizzes = [
      for (final id in ['a', 'b', 'c', 'd'])
        _buildTestQuiz(videoId: id, title: 'Work $id', artist: 'Artist'),
    ];
    final quizRepository = _TestQuizRepository(quizzes);
    final favoriteRepository = _TestFavoriteRepository();
    final playlistRepository = _TestPlaylistRepository();
    addTearDown(favoriteRepository.close);
    addTearDown(playlistRepository.close);
    final playlistId = await playlistRepository.createPlaylist(
      const PlaylistDraft(name: '編集確認', isPublic: false),
      firstVideoId: 'a',
    );
    for (final id in ['b', 'c', 'd']) {
      await playlistRepository.toggleVideo(playlistId, id);
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizRepositoryProvider.overrideWithValue(quizRepository),
          favoriteRepositoryProvider.overrideWithValue(favoriteRepository),
          playlistRepositoryProvider.overrideWithValue(playlistRepository),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: PlaylistScreen(playlistId: playlistId),
        ),
      ),
    );
    await _pumpAsyncScreen(tester);
    await tester.tap(find.text('作品'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('toggle-playlist-reorder')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.drag_handle_rounded), findsNWidgets(4));
    await tester.tap(find.byKey(const ValueKey('select-playlist-item-c')));
    await tester.tap(find.byKey(const ValueKey('select-playlist-item-a')));
    await tester.pumpAndSettle();
    Finder handleFor(String id) => find.descendant(
      of: find.byKey(ValueKey('playlist-song-$id')),
      matching: find.byIcon(Icons.drag_handle_rounded),
    );
    expect(handleFor('c'), findsOneWidget);
    expect(handleFor('a'), findsNothing);
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('playlist-item-opacity-a')),
          )
          .opacity,
      0.42,
    );
    expect(
      find.byKey(const ValueKey('clear-playlist-selection')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('clear-playlist-selection')));
    await tester.pumpAndSettle();
    expect(find.text('2個選択中'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('select-playlist-item-c')));
    await tester.tap(find.byKey(const ValueKey('select-playlist-item-a')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('選択順に並べる'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.drag_handle_rounded), findsNothing);
    await tester.tap(find.byKey(const ValueKey('apply-playlist-selection')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('toggle-playlist-reorder')));
    await tester.pumpAndSettle();

    expect(playlistRepository.playlists.single.videoIds, ['b', 'c', 'a', 'd']);

    await tester.tap(find.byKey(const ValueKey('toggle-playlist-reorder')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('select-playlist-item-c')));
    await tester.tap(find.byKey(const ValueKey('select-playlist-item-d')));
    await tester.pumpAndSettle();
    expect(handleFor('b'), findsNothing);
    expect(handleFor('c'), findsOneWidget);
    expect(handleFor('a'), findsNothing);
    expect(handleFor('d'), findsNothing);
    final groupedStart = tester.getCenter(handleFor('c'));
    final groupedEnd = groupedStart + const Offset(0, 300);
    final dragGesture = await tester.startGesture(groupedStart);
    await dragGesture.moveBy(const Offset(0, 20));
    await tester.pump(const Duration(milliseconds: 160));
    final dropZone = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('playlist-reorder-drop-zone')),
    );
    expect(
      (dropZone.decoration as BoxDecoration?)?.color,
      const Color(0xFF16486E),
    );
    await dragGesture.moveTo(groupedEnd);
    await dragGesture.up();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('toggle-playlist-reorder')));
    await tester.pumpAndSettle();
    expect(playlistRepository.playlists.single.videoIds, ['b', 'a', 'c', 'd']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Libraryの関連は端末内再生リストに近い公開リストを優先する', (tester) async {
    final preferred = _buildTestQuiz(
      videoId: 'preferred-video',
      title: 'Preferred Work',
      artist: 'Preferred Artist',
    );
    final unrelated = _buildTestQuiz(
      videoId: 'unrelated-video',
      title: 'Unrelated Work',
      artist: 'Unrelated Artist',
    );
    final quizRepository = _TestQuizRepository([preferred, unrelated]);
    final favoriteRepository = _TestFavoriteRepository();
    final historyRepository = _TestQuizHistoryRepository();
    final playlistRepository = _TestPlaylistRepository();
    addTearDown(favoriteRepository.close);
    addTearDown(historyRepository.close);
    addTearDown(playlistRepository.close);
    await playlistRepository.createPlaylist(
      const PlaylistDraft(name: '好み', isPublic: false),
      firstVideoId: 'preferred-video',
    );
    final publicPlaylists = [
      PublicPlaylist(
        id: 'unrelated-public',
        ownerName: 'Other',
        name: '無関係な新しいリスト',
        description: '',
        videoIds: const ['unrelated-video'],
        updatedAt: DateTime.utc(2026, 9, 21),
        embedding: null,
      ),
      PublicPlaylist(
        id: 'preferred-public',
        ownerName: 'Related',
        name: '好みに近いリスト',
        description: '',
        videoIds: const ['preferred-video'],
        updatedAt: DateTime.utc(2026, 9, 20),
        embedding: null,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizRepositoryProvider.overrideWithValue(quizRepository),
          favoriteRepositoryProvider.overrideWithValue(favoriteRepository),
          quizHistoryRepositoryProvider.overrideWithValue(historyRepository),
          playlistRepositoryProvider.overrideWithValue(playlistRepository),
          publicPlaylistsProvider.overrideWith((ref) async => publicPlaylists),
        ],
        child: const CommenTubeApp(),
      ),
    );
    await _pumpAsyncScreen(tester);
    await tester.tap(find.byIcon(Icons.video_library_outlined));
    await _pumpAsyncScreen(tester);
    await tester.tap(find.byKey(const ValueKey('show-library-playlists')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('playlist-section-related')));
    await tester.pumpAndSettle();

    final preferredTop = tester.getTopLeft(
      find.byKey(const ValueKey('public-playlist-preferred-public')),
    );
    final unrelatedTop = tester.getTopLeft(
      find.byKey(const ValueKey('public-playlist-unrelated-public')),
    );
    expect(preferredTop.dy, lessThan(unrelatedTop.dy));
    await tester.tap(
      find.byKey(const ValueKey('public-playlist-preferred-public')),
    );
    await tester.pumpAndSettle();
    expect(find.text('好みに近いリスト'), findsOneWidget);
    expect(find.byKey(const ValueKey('playlist-menu-button')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('playlist-menu-button')));
    await tester.pumpAndSettle();
    expect(find.text('プレイリストを保存'), findsOneWidget);
    expect(find.text('編集'), findsNothing);
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

  @override
  Future<List<Artist>> getArtists() async {
    return {
      for (final quiz in quizzes)
        for (final artist in quiz.quiz.artists) artist.artistId: artist,
    }.values.toList(growable: false);
  }

  @override
  Future<List<Artist>> getRelatedArtists(String artistName) async => const [];
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

class _DelayedQuizHistoryRepository implements QuizHistoryRepository {
  final List<QuizHistoryRecord> records = [];
  final StreamController<List<QuizHistoryRecord>> _controller =
      StreamController<List<QuizHistoryRecord>>.broadcast();

  @override
  Stream<List<QuizHistoryRecord>> watchHistory() => _controller.stream;

  void emit(List<QuizHistoryRecord> value) {
    records
      ..clear()
      ..addAll(value);
    _controller.add(List.unmodifiable(records));
  }

  @override
  Future<void> recordPlay(String videoId, {DateTime? playedAt}) async {
    records.removeWhere((record) => record.videoId == videoId);
    records.insert(
      0,
      QuizHistoryRecord(videoId: videoId, playedAt: playedAt ?? DateTime.now()),
    );
    _controller.add(List.unmodifiable(records));
  }

  Future<void> close() => _controller.close();
}

class _TestPlaylistRepository implements PlaylistRepository {
  final List<UserPlaylist> playlists = [];
  final StreamController<List<UserPlaylist>> _controller =
      StreamController<List<UserPlaylist>>.broadcast();

  @override
  Stream<List<UserPlaylist>> watchPlaylists() async* {
    yield List.unmodifiable(playlists);
    yield* _controller.stream;
  }

  @override
  Future<String> createPlaylist(
    PlaylistDraft draft, {
    String? firstVideoId,
    String? sourcePlaylistId,
  }) async {
    final id = 'test-playlist-${playlists.length + 1}';
    final now = DateTime.utc(2026, 9, 20);
    playlists.add(
      UserPlaylist(
        id: id,
        name: draft.name,
        isPublic: draft.isPublic,
        description: draft.description,
        allowsCollaboration: draft.allowsCollaboration,
        isOwned: true,
        videoIds: [?firstVideoId],
        createdAt: now,
        updatedAt: now,
        sourcePlaylistId: sourcePlaylistId,
      ),
    );
    _emit();
    return id;
  }

  @override
  Future<void> updatePlaylist(String id, PlaylistDraft draft) async {
    final index = playlists.indexWhere((item) => item.id == id);
    final current = playlists[index];
    playlists[index] = _copy(
      current,
      name: draft.name,
      isPublic: draft.isPublic,
      description: draft.description,
      allowsCollaboration: draft.allowsCollaboration,
    );
    _emit();
  }

  @override
  Future<void> deletePlaylist(String id) async {
    playlists.removeWhere((item) => item.id == id);
    _emit();
  }

  @override
  Future<void> toggleVideo(String playlistId, String videoId) async {
    final index = playlists.indexWhere((item) => item.id == playlistId);
    final playlist = playlists[index];
    final videoIds = List.of(playlist.videoIds);
    videoIds.contains(videoId)
        ? videoIds.remove(videoId)
        : videoIds.add(videoId);
    playlists[index] = _copy(playlist, videoIds: videoIds);
    _emit();
  }

  @override
  Future<void> addVideos(String playlistId, List<String> videoIds) async {
    final index = playlists.indexWhere((item) => item.id == playlistId);
    final combined = List<String>.of(playlists[index].videoIds);
    for (final videoId in videoIds) {
      if (!combined.contains(videoId)) {
        combined.add(videoId);
      }
    }
    playlists[index] = _copy(playlists[index], videoIds: combined);
    _emit();
  }

  @override
  Future<void> moveVideos({
    required String sourcePlaylistId,
    required String targetPlaylistId,
    required List<String> videoIds,
  }) async {
    await addVideos(targetPlaylistId, videoIds);
    final sourceIndex = playlists.indexWhere(
      (item) => item.id == sourcePlaylistId,
    );
    final remaining = playlists[sourceIndex].videoIds
        .where((id) => !videoIds.contains(id))
        .toList(growable: false);
    playlists[sourceIndex] = _copy(playlists[sourceIndex], videoIds: remaining);
    _emit();
  }

  @override
  Future<void> reorderVideos(String playlistId, List<String> videoIds) async {
    final index = playlists.indexWhere((item) => item.id == playlistId);
    playlists[index] = _copy(playlists[index], videoIds: videoIds);
    _emit();
  }

  @override
  Future<String> copyPlaylist(UserPlaylist playlist) {
    return createPlaylist(
      PlaylistDraft(
        name: '${playlist.name} のコピー',
        isPublic: false,
        description: playlist.description,
      ),
      sourcePlaylistId: playlist.id,
    );
  }

  UserPlaylist _copy(
    UserPlaylist source, {
    String? name,
    bool? isPublic,
    String? description,
    bool? allowsCollaboration,
    List<String>? videoIds,
  }) {
    return UserPlaylist(
      id: source.id,
      name: name ?? source.name,
      isPublic: isPublic ?? source.isPublic,
      description: description ?? source.description,
      allowsCollaboration: allowsCollaboration ?? source.allowsCollaboration,
      isOwned: source.isOwned,
      videoIds: List.unmodifiable(videoIds ?? source.videoIds),
      createdAt: source.createdAt,
      updatedAt: DateTime.utc(2026, 9, 20),
      sourcePlaylistId: source.sourcePlaylistId,
    );
  }

  void _emit() => _controller.add(List.unmodifiable(playlists));

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
  Map<String, dynamic> metaData = const {},
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
            embedding: null,
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
      metaData: metaData,
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
