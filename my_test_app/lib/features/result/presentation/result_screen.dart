import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/favorite.dart';
import '../../../core/models/quiz.dart';
import '../../../core/repositories/favorite_providers.dart';
import '../../../core/repositories/quiz_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/display_formatters.dart';
import '../../../core/utils/youtube_link.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, required this.videoId});

  final String videoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quiz = ref.watch(quizProvider(videoId));
    return quiz.when(
      data: (item) => item == null
          ? const _MissingResultScreen()
          : _ResultContent(quiz: item),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => const _MissingResultScreen(),
    );
  }
}

class _ResultContent extends ConsumerWidget {
  const _ResultContent({required this.quiz});

  final QuizWithLiveStats quiz;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = quiz.quiz;
    final allQuizzes = ref.watch(quizzesProvider).value;
    final nextVideoId = _nextVideoId(allQuizzes, data.videoId);
    final favoriteIds =
        ref
            .watch(favoritesProvider)
            .value
            ?.map((favorite) => favorite.id)
            .toSet() ??
        const <String>{};
    final songFavorite = SavedFavorite.song(
      videoId: data.videoId,
      title: data.musicTitle,
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            Row(
              children: [
                IconButton(
                  key: const ValueKey('result-home-button'),
                  tooltip: 'ホームに戻る',
                  onPressed: context.goHome,
                  icon: const Icon(Icons.home_rounded),
                ),
                const Spacer(),
                _FavoriteIconButton(
                  key: ValueKey('favorite-song-${data.videoId}'),
                  tooltip: '楽曲をお気に入り',
                  selected: favoriteIds.contains(songFavorite.id),
                  onPressed: () => _toggleFavorite(ref, songFavorite),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data.musicTitle,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final artist in data.musicArtists)
                  _ArtistFavoriteChip(
                    artist: artist,
                    selected: favoriteIds.contains(
                      SavedFavorite.artist(artist).id,
                    ),
                    onPressed: () =>
                        _toggleFavorite(ref, SavedFavorite.artist(artist)),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('open-youtube-button'),
                    onPressed: () => _openVideo(context, data.videoId),
                    icon: const Icon(Icons.play_circle_fill_rounded),
                    label: const Text('YouTube'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Builder(
                    builder: (buttonContext) => OutlinedButton.icon(
                      key: const ValueKey('share-song-button'),
                      onPressed: () => _shareSong(buttonContext, data),
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('共有'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ResultStats(quiz: quiz),
            const SizedBox(height: 18),
            _InfoRow(
              label: 'ジャンル',
              value: data.musicGenres.map(genreLabel).join(' / '),
            ),
            _InfoRow(label: '動画種別', value: videoGenreLabel(data.videoGenre)),
            _InfoRow(
              label: '言語',
              value: data.musicLanguages.map(languageLabel).join(' / '),
            ),
            _InfoRow(label: 'リリース', value: formatDate(data.musicReleasedAt)),
            const SizedBox(height: 18),
            const _SectionTitle(icon: Icons.chat_bubble_outline, title: 'コメント'),
            for (final comment in quiz.comments)
              _ResultCard(
                text: comment.comment.content,
                footer:
                    '♡ ${formatCompactCount(comment.likeCount)}  ${formatRelativeDate(comment.comment.commentedAt)}',
                favorite: SavedFavorite.comment(
                  videoId: data.videoId,
                  commentId: comment.comment.commentId,
                  content: comment.comment.content,
                ),
                selectedIds: favoriteIds,
                buttonKey: 'favorite-comment-${comment.comment.commentId}',
                onFavorite: (favorite) => _toggleFavorite(ref, favorite),
              ),
            const SizedBox(height: 10),
            const _SectionTitle(icon: Icons.music_note_rounded, title: '歌詞'),
            for (final indexed in data.videoLyrics.indexed)
              _ResultCard(
                text: indexed.$2,
                favorite: SavedFavorite.lyric(
                  videoId: data.videoId,
                  index: indexed.$1,
                  content: indexed.$2,
                ),
                selectedIds: favoriteIds,
                buttonKey: 'favorite-lyric-${indexed.$1}',
                onFavorite: (favorite) => _toggleFavorite(ref, favorite),
              ),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const ValueKey('next-quiz-button'),
              onPressed: nextVideoId == null
                  ? null
                  : () => context.goToGame(nextVideoId),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('次の問題へ'),
            ),
          ],
        ),
      ),
    );
  }

  String? _nextVideoId(List<QuizWithLiveStats>? quizzes, String currentId) {
    if (quizzes == null || quizzes.length < 2) {
      return null;
    }
    final index = quizzes.indexWhere((item) => item.quiz.videoId == currentId);
    return quizzes[(index + 1) % quizzes.length].quiz.videoId;
  }

  Future<void> _toggleFavorite(WidgetRef ref, SavedFavorite favorite) {
    return ref.read(favoriteRepositoryProvider).toggleFavorite(favorite);
  }

  Future<void> _openVideo(BuildContext context, String videoId) async {
    final opened = await openYouTubeVideo(videoId);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('YouTubeを開けませんでした')));
    }
  }

  Future<void> _shareSong(BuildContext context, Quiz data) {
    final box = context.findRenderObject() as RenderBox?;
    return SharePlus.instance.share(
      ShareParams(
        title: data.musicTitle,
        subject: 'CommenTube: ${data.musicTitle}',
        text:
            '${data.musicTitle} / ${data.musicArtists.join(' & ')}\n'
            '${youtubeWatchUri(data.videoId)}\n#CommenTube',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }
}

class _ArtistFavoriteChip extends StatelessWidget {
  const _ArtistFavoriteChip({
    required this.artist,
    required this.selected,
    required this.onPressed,
  });

  final String artist;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      key: ValueKey('favorite-artist-$artist'),
      avatar: Icon(
        selected ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: 18,
      ),
      label: Text(artist),
      onPressed: onPressed,
    );
  }
}

class _FavoriteIconButton extends StatelessWidget {
  const _FavoriteIconButton({
    super.key,
    required this.tooltip,
    required this.selected,
    required this.onPressed,
  });

  final String tooltip;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(
        selected ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
      ),
    );
  }
}

class _ResultStats extends StatelessWidget {
  const _ResultStats({required this.quiz});

  final QuizWithLiveStats quiz;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '▷ ${formatCompactCount(quiz.videoStats.viewCount)}',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              '♡ ${formatCompactCount(quiz.videoStats.likeCount)}',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              formatDate(quiz.quiz.videoPublishedAt),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFFAAAAAA)),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.text,
    required this.favorite,
    required this.selectedIds,
    required this.buttonKey,
    required this.onFavorite,
    this.footer,
  });

  final String text;
  final String? footer;
  final SavedFavorite favorite;
  final Set<String> selectedIds;
  final String buttonKey;
  final ValueChanged<SavedFavorite> onFavorite;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(text),
                ),
              ),
              IconButton(
                key: ValueKey(buttonKey),
                tooltip: 'お気に入り',
                onPressed: () => onFavorite(favorite),
                icon: Icon(
                  selectedIds.contains(favorite.id)
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                ),
              ),
            ],
          ),
          if (footer != null) ...[
            const SizedBox(height: 2),
            Text(
              footer!,
              style: const TextStyle(color: Color(0xFFB8B8B8), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _MissingResultScreen extends StatelessWidget {
  const _MissingResultScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: context.goHome,
          child: const Text('ホームに戻る'),
        ),
      ),
    );
  }
}
