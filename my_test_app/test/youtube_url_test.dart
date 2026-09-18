import 'package:flutter_test/flutter_test.dart';
import 'package:my_test_app/core/utils/youtube_link.dart';
import 'package:my_test_app/core/utils/youtube_url.dart';

void main() {
  test('YouTube動画ページのURLからvideo_idを抽出する', () {
    expect(
      extractYouTubeVideoId(
        'https://m.youtube.com/watch?v=y2bVIBwpCTA&feature=share',
      ),
      'y2bVIBwpCTA',
    );
    expect(
      extractYouTubeVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
      'dQw4w9WgXcQ',
    );
  });

  test('検索ページやYouTube以外のURLは回答URLとして扱わない', () {
    expect(
      extractYouTubeVideoId('https://m.youtube.com/results?search_query=music'),
      isNull,
    );
    expect(
      extractYouTubeVideoId('https://example.com/watch?v=y2bVIBwpCTA'),
      isNull,
    );
    expect(isYouTubeWatchUrl(null), isFalse);
  });

  test('抽出したvideo_idで正誤判定する', () {
    const answerUrl = 'https://m.youtube.com/watch?v=y2bVIBwpCTA';

    expect(isCorrectYouTubeAnswer(answerUrl, 'y2bVIBwpCTA'), isTrue);
    expect(isCorrectYouTubeAnswer(answerUrl, 'dQw4w9WgXcQ'), isFalse);
    expect(isCorrectYouTubeAnswer(null, 'y2bVIBwpCTA'), isFalse);
  });

  test('動画IDから共有・外部リンク用URLを作る', () {
    expect(
      youtubeWatchUri('y2bVIBwpCTA').toString(),
      'https://www.youtube.com/watch?v=y2bVIBwpCTA',
    );
  });
}
