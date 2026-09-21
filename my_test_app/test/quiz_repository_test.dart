import 'package:flutter_test/flutter_test.dart';
import 'package:my_test_app/core/models/quiz.dart';
import 'package:my_test_app/core/models/quiz_filter.dart';
import 'package:my_test_app/core/repositories/quiz_repository.dart';
import 'package:my_test_app/core/repositories/public_playlist_repository.dart';
import 'package:my_test_app/core/utils/display_formatters.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('クイズJSONとYouTube APIモックを結合する', () async {
    final repository = AssetQuizRepository();

    final quizzes = await repository.getQuizzes();
    final cachedQuizzes = await repository.getQuizzes();

    expect(quizzes, hasLength(30));
    expect(identical(quizzes, cachedQuizzes), isTrue);

    final first = quizzes.first;
    expect(first.quiz.videoId, 'y2bVIBwpCTA');
    expect(first.quiz.title, 'I Want You Back');
    expect(first.videoStats.viewCount, 117264772);
    expect(first.representativeComment?.likeCount, 77307);
    expect(first.quiz.contentGenres, ['r_and_b_soul', 'pop', 'decade_1960s']);
    expect(first.quiz.artistNames, ['The Jackson 5', 'Michael Jackson']);
    expect(first.quiz.relatedVideos.single.videoId, 'UvynvnxZJ3Q');
    expect(first.quiz.relatedVideos.single.relationType, 'same_music');
    expect(first.quiz.metaData['keywords'], contains('Motown'));
  });

  test('動画IDで1問を取得し、不明なIDにはnullを返す', () async {
    final repository = AssetQuizRepository();

    expect(
      (await repository.getQuiz('JGwWNGJdvx8'))?.quiz.title,
      'Shape of You',
    );
    expect(await repository.getQuiz('missing-video'), isNull);
  });

  test('関連アーティストを無方向の中間テーブルから取得する', () async {
    final repository = AssetQuizRepository();

    final fromGroup = await repository.getRelatedArtists('The Jackson 5');
    final fromPerson = await repository.getRelatedArtists('Michael Jackson');

    expect(fromGroup.map((item) => item.name), contains('Michael Jackson'));
    expect(fromPerson.map((item) => item.name), contains('The Jackson 5'));
    expect((await repository.getArtists()), hasLength(31));
  });

  test('公開プレイリストJSONを検索・保存候補として読み込む', () async {
    const repository = AssetPublicPlaylistRepository();

    final playlists = await repository.getPublicPlaylists();

    expect(playlists, hasLength(3));
    expect(playlists.first.name, 'Motownから始める10分');
    expect(playlists.first.asUnownedPlaylist().isOwned, isFalse);
  });

  test('ジャンル・言語・投稿年をローカルで絞り込む', () async {
    final repository = AssetQuizRepository();

    final englishQuizzes = await repository.getQuizzes(
      filter: const QuizFilter(languages: ['english']),
    );
    expect(englishQuizzes.length, greaterThan(3));
    expect(
      englishQuizzes.map((item) => item.quiz.videoId),
      contains('jNQXAC9IVRw'),
    );

    final quizzesFrom2010s = await repository.getQuizzes(
      filter: const QuizFilter(publishedFromYear: 2010, publishedToYear: 2019),
    );
    expect(
      quizzesFrom2010s.map((item) => item.quiz.videoId),
      containsAll(['9bZkp7q19f0', 'kJQP7kiw5Fk', 'JGwWNGJdvx8']),
    );

    final koreanDanceQuiz = await repository.getQuizzes(
      filter: const QuizFilter(
        contentGenres: ['dance_electronic'],
        languages: ['korean'],
        videoGenres: ['music_video'],
      ),
    );
    expect(
      koreanDanceQuiz.map((item) => item.quiz.title),
      containsAll(['GANGNAM STYLE', 'GENTLEMAN']),
    );

    final artistQuizzes = await repository.getQuizzes(
      filter: const QuizFilter(artists: ['Rick Astley']),
    );
    expect(artistQuizzes.single.quiz.title, 'Never Gonna Give You Up');

    final psyQuizzes = await repository.getQuizzes(
      filter: const QuizFilter(artists: ['PSY']),
    );
    expect(
      psyQuizzes.map((item) => item.quiz.title),
      containsAll(['GANGNAM STYLE', 'GENTLEMAN']),
    );
  });

  test('中間テーブルを両方向に結合し全relation_typeを保持する', () async {
    final repository = AssetQuizRepository();

    final summer = (await repository.getQuiz('q0T7Ex7MkLM'))!.quiz;
    expect(
      summer.relatedVideos.map((item) => item.relationType),
      containsAll(['cover', 'seriese']),
    );

    final mad = (await repository.getQuiz('AbBaG-Bq6_E'))!.quiz;
    expect(mad.relatedVideos.single.videoId, '9Upo1ELtvhw');
    expect(mad.relatedVideos.single.relationType, 'part_of');

    final collaboration = (await repository.getQuiz('dkcdSj4qBWU'))!.quiz;
    expect(
      collaboration.artistNames,
      containsAll(['Freddie Mercury', 'Michael Jackson']),
    );
  });

  test('thumbnail_hint_typeは本文を重複保持せず先頭ヒントから解決する', () async {
    final repository = AssetQuizRepository();

    final lyricQuiz = (await repository.getQuiz('UvynvnxZJ3Q'))!.quiz;
    expect(lyricQuiz.thumbnailHintType, ThumbnailHintType.lyric);
    expect(lyricQuiz.thumbnailHint?.content, lyricQuiz.musicLyrics.first);

    final commentQuiz = (await repository.getQuiz('y2bVIBwpCTA'))!.quiz;
    expect(commentQuiz.thumbnailHintType, ThumbnailHintType.comment);
    expect(
      commentQuiz.thumbnailHint?.content,
      commentQuiz.comments.first.content,
    );
  });

  test('年代ジャンルは内部値ではなく年代だけを表示する', () {
    expect(genreLabel('decade_1950s'), '1950s');
    expect(genreLabel('decade_1980s'), '1980s');
  });

  test('直近のプレイ時刻は分・時間単位で表示する', () {
    final now = DateTime.utc(2026, 9, 20, 12);
    expect(
      formatRelativeTime(DateTime.utc(2026, 9, 20, 11, 45), now: now),
      '15分前',
    );
    expect(formatRelativeTime(DateTime.utc(2026, 9, 20, 8), now: now), '4時間前');
  });
}
