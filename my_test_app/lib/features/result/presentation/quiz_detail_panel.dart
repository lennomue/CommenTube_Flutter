import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/favorite.dart';
import '../../../core/models/quiz.dart';
import '../../../core/repositories/favorite_providers.dart';
import '../../../core/repositories/quiz_providers.dart';
import '../../../core/repositories/quiz_history_providers.dart';
import '../../../core/utils/display_formatters.dart';
import '../../../core/utils/youtube_link.dart';
import '../../../core/widgets/minimizable_page_surface.dart';
import '../../../core/widgets/quiz_song_tile.dart';

class QuizDetailPanel extends ConsumerWidget {
  const QuizDetailPanel({
    super.key,
    required this.quiz,
    required this.leading,
    this.bottomPadding = 24,
    this.onArtistOpen,
    this.onQuizOpen,
    this.minimizeController,
    this.onMinimize,
    this.bodyOverlay,
    this.animateFromMinimized = false,
  });

  final QuizWithLiveStats quiz;
  final Widget leading;
  final double bottomPadding;
  final ValueChanged<String>? onArtistOpen;
  final ValueChanged<String>? onQuizOpen;
  final MinimizablePageController? minimizeController;
  final VoidCallback? onMinimize;
  final Widget? bodyOverlay;
  final bool animateFromMinimized;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = quiz.quiz;
    final allQuizzes = ref.watch(quizzesProvider).value ?? const [];
    final favoriteIds =
        ref
            .watch(favoritesProvider)
            .value
            ?.map((favorite) => favorite.id)
            .toSet() ??
        const <String>{};
    final songFavorite = SavedFavorite.song(
      videoId: data.videoId,
      title: data.title,
    );

    final top = ColoredBox(
      color: const Color(0xFF090909),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            key: const ValueKey('quiz-detail-minimize-area'),
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading,
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 25,
                            height: 1.08,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        _ArtistLinks(
                          artists: data.artistNames,
                          onArtistOpen: onArtistOpen,
                        ),
                      ],
                    ),
                  ),
                ),
                _FavoriteIconButton(
                  key: ValueKey('favorite-song-${data.videoId}'),
                  tooltip: '作品をお気に入り',
                  selected: favoriteIds.contains(songFavorite.id),
                  onPressed: () => _toggleFavorite(ref, songFavorite),
                ),
                IconButton(
                  key: ValueKey('detail-playlist-${data.videoId}'),
                  tooltip: '再生リストに追加',
                  onPressed: () => showAddToPlaylistSheet(
                    context,
                    ref,
                    videoId: data.videoId,
                  ),
                  icon: const Icon(Icons.bookmark_add_outlined),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.separated(
              key: const ValueKey('artist-favorite-scroll'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(18, 7, 18, 0),
              itemCount: data.artistNames.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final artist = data.artistNames[index];
                return ActionChip(
                  key: ValueKey('favorite-artist-$artist'),
                  avatar: Icon(
                    favoriteIds.contains(SavedFavorite.artist(artist).id)
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 17,
                  ),
                  label: Text(artist),
                  onPressed: () =>
                      _toggleFavorite(ref, SavedFavorite.artist(artist)),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 5),
            child: _MediaActionRow(quiz: data),
          ),
          _ResultStats(quiz: quiz),
          const SizedBox(height: 6),
          const TabBar(
            key: ValueKey('result-detail-tabs'),
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(icon: Icon(Icons.chat_bubble_outline_rounded), text: 'コメント'),
              Tab(icon: Icon(Icons.music_note_rounded), text: '歌詞'),
              Tab(icon: Icon(Icons.info_outline_rounded), text: '作品情報'),
              Tab(icon: Icon(Icons.link_rounded), text: '関連'),
            ],
          ),
        ],
      ),
    );
    final tabBody = TabBarView(
      children: [
        _DetailList(
          bottomPadding: bottomPadding,
          children: [
            for (final comment in quiz.comments)
              _FavoriteCard(
                text: comment.comment.content,
                footer:
                    '♡ ${formatCompactCount(comment.likeCount)}  ${formatRelativeDate(comment.comment.commentedAt)}',
                favorite: SavedFavorite.comment(
                  videoId: data.videoId,
                  commentId: comment.comment.commentId,
                  content: comment.comment.content,
                ),
                favoriteIds: favoriteIds,
                buttonKey: 'favorite-comment-${comment.comment.commentId}',
                onFavorite: (favorite) => _toggleFavorite(ref, favorite),
              ),
          ],
        ),
        _DetailList(
          bottomPadding: bottomPadding,
          children: [
            for (final indexed in data.musicLyrics.indexed)
              _FavoriteCard(
                text: indexed.$2,
                favorite: SavedFavorite.lyric(
                  videoId: data.videoId,
                  index: indexed.$1,
                  content: indexed.$2,
                ),
                favoriteIds: favoriteIds,
                buttonKey: 'favorite-lyric-${indexed.$1}',
                onFavorite: (favorite) => _toggleFavorite(ref, favorite),
              ),
          ],
        ),
        _DetailList(
          bottomPadding: bottomPadding,
          children: [
            _InfoCard(
              label: 'ジャンル',
              value: data.contentGenres.map(genreLabel).join(' / '),
            ),
            _InfoCard(label: '動画種別', value: videoGenreLabel(data.videoGenre)),
            _InfoCard(
              label: '言語',
              value: data.languages.map(languageLabel).join(' / '),
            ),
            _InfoCard(
              label: 'リリース',
              value: formatPartialDate(data.musicReleasedAt),
            ),
          ],
        ),
        _RelatedVideosTab(
          relations: data.relatedVideos,
          allQuizzes: allQuizzes,
          bottomPadding: bottomPadding,
          onQuizOpen: onQuizOpen,
        ),
      ],
    );
    final body = ColoredBox(
      color: const Color(0xFF090909),
      child: bodyOverlay == null
          ? tabBody
          : Stack(children: [tabBody, bodyOverlay!]),
    );
    return DefaultTabController(
      length: 4,
      child: minimizeController == null
          ? Column(
              children: [
                top,
                Expanded(child: body),
              ],
            )
          : MinimizablePageSurface(
              controller: minimizeController!,
              top: top,
              body: body,
              topHeight: 348,
              onMinimize: onMinimize!,
              animateFromMinimized: animateFromMinimized,
            ),
    );
  }

  Future<void> _toggleFavorite(WidgetRef ref, SavedFavorite favorite) {
    return ref.read(favoriteRepositoryProvider).toggleFavorite(favorite);
  }
}

class _RelatedVideosTab extends ConsumerWidget {
  const _RelatedVideosTab({
    required this.relations,
    required this.allQuizzes,
    required this.bottomPadding,
    required this.onQuizOpen,
  });

  static const _relationOrder = ['same_music', 'seriese', 'cover', 'part_of'];

  final List<RelatedVideo> relations;
  final List<QuizWithLiveStats> allQuizzes;
  final double bottomPadding;
  final ValueChanged<String>? onQuizOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seenIds =
        ref
            .watch(quizHistoryProvider)
            .value
            ?.map((item) => item.videoId)
            .toSet() ??
        const <String>{};
    final quizzesById = {
      for (final quiz in allQuizzes) quiz.quiz.videoId: quiz,
    };
    final grouped = <String, List<QuizWithLiveStats>>{};
    for (final relation in relations) {
      final relatedQuiz = quizzesById[relation.videoId];
      if (relatedQuiz != null) {
        grouped.putIfAbsent(relation.relationType, () => []).add(relatedQuiz);
      }
    }
    final visibleTypes = _relationOrder
        .where((type) => grouped[type]?.isNotEmpty ?? false)
        .toList(growable: false);
    if (visibleTypes.isEmpty) {
      return const Center(
        child: Text('関連動画はありません', style: TextStyle(color: Color(0xFFAAAAAA))),
      );
    }
    return ListView(
      key: const ValueKey('related-videos-list'),
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
      children: [
        for (final type in visibleTypes) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: Text(
              _relationLabel(type),
              style: const TextStyle(
                color: Color(0xFFBDBDBD),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          for (final related in grouped[type]!)
            Container(
              padding: const EdgeInsets.only(bottom: 8),
              decoration: !seenIds.contains(related.quiz.videoId)
                  ? const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0x663BA7FF), width: 2),
                      ),
                    )
                  : null,
              child: QuizSongTile(
                key: ValueKey('related-video-${related.quiz.videoId}'),
                quiz: related,
                onOpen: onQuizOpen == null
                    ? () {}
                    : () => onQuizOpen!(related.quiz.videoId),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  String _relationLabel(String type) {
    return switch (type) {
      'same_music' => '同じ曲',
      'seriese' => 'シリーズ',
      'cover' => 'カバー',
      'part_of' => 'MAD・構成元',
      _ => type,
    };
  }
}

class _ArtistLinks extends StatelessWidget {
  const _ArtistLinks({required this.artists, required this.onArtistOpen});

  final List<String> artists;
  final ValueChanged<String>? onArtistOpen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: ListView.separated(
        key: const ValueKey('artist-link-scroll'),
        scrollDirection: Axis.horizontal,
        itemCount: artists.length,
        separatorBuilder: (_, _) =>
            const Text(' / ', style: TextStyle(color: Color(0xFF777777))),
        itemBuilder: (context, index) {
          final artist = artists[index];
          return TextButton(
            key: ValueKey('open-artist-$artist'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFBDBDBD),
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onArtistOpen == null
                ? null
                : () => onArtistOpen!(artist),
            child: Text(artist),
          );
        },
      ),
    );
  }
}

class _MediaActionRow extends StatelessWidget {
  const _MediaActionRow({required this.quiz});

  final Quiz quiz;

  @override
  Widget build(BuildContext context) {
    final query = '${quiz.title} ${quiz.artistNames.join(' ')}';
    return Row(
      children: [
        IconButton(
          key: const ValueKey('open-youtube-button'),
          tooltip: 'YouTubeで開く',
          iconSize: 42,
          onPressed: () => _open(context, openYouTubeVideo(quiz.videoId)),
          icon: const Icon(Icons.play_circle_fill_rounded),
        ),
        Builder(
          builder: (buttonContext) => IconButton(
            key: const ValueKey('share-song-button'),
            tooltip: '共有',
            iconSize: 36,
            onPressed: () => _shareSong(buttonContext),
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ),
        const Spacer(),
        _ServiceButton(
          key: const ValueKey('youtube-music-button'),
          tooltip: 'YouTube Musicで検索',
          label: 'YT',
          onPressed: () => _open(
            context,
            openMusicService(MusicService.youtubeMusic, query),
          ),
        ),
        _ServiceButton(
          key: const ValueKey('spotify-button'),
          tooltip: 'Spotifyで検索',
          icon: Icons.graphic_eq_rounded,
          onPressed: () =>
              _open(context, openMusicService(MusicService.spotify, query)),
        ),
        _ServiceButton(
          key: const ValueKey('amazon-music-button'),
          tooltip: 'Amazon Musicで検索',
          label: 'a',
          onPressed: () =>
              _open(context, openMusicService(MusicService.amazonMusic, query)),
        ),
        _ServiceButton(
          key: const ValueKey('apple-music-button'),
          tooltip: 'Apple Musicで検索',
          icon: Icons.apple_rounded,
          onPressed: () =>
              _open(context, openMusicService(MusicService.appleMusic, query)),
        ),
      ],
    );
  }

  Future<void> _open(BuildContext context, Future<bool> launch) async {
    if (!await launch && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('リンクを開けませんでした')));
    }
  }

  Future<void> _shareSong(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    return SharePlus.instance.share(
      ShareParams(
        title: quiz.title,
        subject: 'CommenTube: ${quiz.title}',
        text:
            '${quiz.title} / ${quiz.artistNames.join(' & ')}\n'
            '${youtubeWatchUri(quiz.videoId)}\n#CommenTube',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }
}

class _ServiceButton extends StatelessWidget {
  const _ServiceButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    this.icon,
    this.label,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData? icon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
      icon: icon != null
          ? Icon(icon, size: 22)
          : Text(
              label!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
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
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(
        selected ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      ),
    );
  }
}

class _ResultStats extends StatelessWidget {
  const _ResultStats({required this.quiz});

  final QuizWithLiveStats quiz;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
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
              formatDate(quiz.quiz.postedAt),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailList extends StatelessWidget {
  const _DetailList({required this.children, required this.bottomPadding});

  final List<Widget> children;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
      children: children,
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.text,
    required this.favorite,
    required this.favoriteIds,
    required this.buttonKey,
    required this.onFavorite,
    this.footer,
  });

  final String text;
  final String? footer;
  final SavedFavorite favorite;
  final Set<String> favoriteIds;
  final String buttonKey;
  final ValueChanged<SavedFavorite> onFavorite;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF303030)),
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
                  favoriteIds.contains(favorite.id)
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                ),
              ),
            ],
          ),
          if (footer != null)
            Text(
              footer!,
              style: const TextStyle(color: Color(0xFFB8B8B8), fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF303030)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
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
