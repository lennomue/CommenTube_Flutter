import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/favorite.dart';
import '../../../core/models/quiz.dart';
import '../../../core/repositories/favorite_providers.dart';
import '../../../core/repositories/quiz_providers.dart';
import '../../../core/utils/display_formatters.dart';
import '../../../core/utils/youtube_link.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  static const _tabs = [
    (FavoriteKind.comment, Icons.chat_bubble_outline_rounded, 'コメント'),
    (FavoriteKind.lyric, Icons.music_note_rounded, '歌詞'),
    (FavoriteKind.song, Icons.album_outlined, '楽曲'),
    (FavoriteKind.artist, Icons.person_outline_rounded, 'アーティスト'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    return SafeArea(
      bottom: false,
      child: DefaultTabController(
        length: _tabs.length,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Text(
                'Library',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
            ),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                for (final tab in _tabs) Tab(icon: Icon(tab.$2), text: tab.$3),
              ],
            ),
            Expanded(
              child: favorites.when(
                data: (items) => TabBarView(
                  children: [
                    for (final tab in _tabs)
                      _FavoriteList(
                        kind: tab.$1,
                        favorites: items
                            .where((item) => item.kind == tab.$1)
                            .toList(growable: false),
                      ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => const _LibraryError(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteList extends ConsumerWidget {
  const _FavoriteList({required this.kind, required this.favorites});

  final FavoriteKind kind;
  final List<SavedFavorite> favorites;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (favorites.isEmpty) {
      return _EmptyFavorites(kind: kind);
    }
    return ListView.separated(
      key: PageStorageKey('favorite-list-${kind.name}'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: favorites.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final favorite = favorites[index];
        final opensDetail = favorite.videoId != null;
        return Material(
          color: const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('library-favorite-${favorite.id}'),
            onTap: opensDetail
                ? () => _showQuizDetail(context, favorite.videoId!)
                : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  Icon(
                    _kindIcon(favorite.kind),
                    color: const Color(0xFFFF97D7),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      favorite.displayText,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (opensDetail)
                    const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  IconButton(
                    key: ValueKey('remove-favorite-${favorite.id}'),
                    tooltip: 'お気に入りから削除',
                    onPressed: () => ref
                        .read(favoriteRepositoryProvider)
                        .removeFavorite(favorite.id),
                    icon: const Icon(Icons.bookmark_remove_rounded),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showQuizDetail(BuildContext context, String videoId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF171717),
      builder: (context) => _LibraryQuizDetail(videoId: videoId),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites({required this.kind});

  final FavoriteKind kind;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_kindIcon(kind), size: 44, color: const Color(0xFF777777)),
            const SizedBox(height: 12),
            Text('お気に入りの${_kindLabel(kind)}はまだありません'),
            const SizedBox(height: 6),
            const Text(
              'Result画面から追加できます',
              style: TextStyle(color: Color(0xFFAAAAAA)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryQuizDetail extends ConsumerWidget {
  const _LibraryQuizDetail({required this.videoId});

  final String videoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quiz = ref.watch(quizProvider(videoId));
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: quiz.when(
        data: (item) => item == null
            ? _DetailMessage(onClose: () => Navigator.pop(context))
            : _DetailContent(quiz: item),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            _DetailMessage(onClose: () => Navigator.pop(context)),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.quiz});

  final QuizWithLiveStats quiz;

  @override
  Widget build(BuildContext context) {
    final data = quiz.quiz;
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.musicTitle,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.musicArtists.join(' / '),
                        style: const TextStyle(color: Color(0xFFBBBBBB)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const ValueKey('close-library-detail'),
                  tooltip: '閉じる',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '▷ ${formatCompactCount(quiz.videoStats.viewCount)}   '
                    '♡ ${formatCompactCount(quiz.videoStats.likeCount)}',
                  ),
                ),
                IconButton(
                  tooltip: 'YouTubeを開く',
                  onPressed: () => openYouTubeVideo(data.videoId),
                  icon: const Icon(Icons.play_circle_fill_rounded),
                ),
              ],
            ),
          ),
          const TabBar(
            tabs: [
              Tab(text: 'コメント'),
              Tab(text: '歌詞'),
              Tab(text: '楽曲情報'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _DetailList(
                  children: [
                    for (final comment in quiz.comments)
                      _DetailCard(text: comment.comment.content),
                  ],
                ),
                _DetailList(
                  children: [
                    for (final lyric in data.videoLyrics)
                      _DetailCard(text: lyric),
                  ],
                ),
                _DetailList(
                  children: [
                    _DetailCard(
                      text:
                          'ジャンル: ${data.musicGenres.map(genreLabel).join(' / ')}',
                    ),
                    _DetailCard(
                      text: '動画種別: ${videoGenreLabel(data.videoGenre)}',
                    ),
                    _DetailCard(
                      text:
                          '言語: ${data.musicLanguages.map(languageLabel).join(' / ')}',
                    ),
                    _DetailCard(
                      text: 'リリース: ${formatDate(data.musicReleasedAt)}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailList extends StatelessWidget {
  const _DetailList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: children,
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text),
    );
  }
}

class _DetailMessage extends StatelessWidget {
  const _DetailMessage({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(onPressed: onClose, child: const Text('閉じる')),
    );
  }
}

class _LibraryError extends StatelessWidget {
  const _LibraryError();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('お気に入りを読み込めませんでした'));
  }
}

IconData _kindIcon(FavoriteKind kind) {
  return switch (kind) {
    FavoriteKind.comment => Icons.chat_bubble_outline_rounded,
    FavoriteKind.lyric => Icons.music_note_rounded,
    FavoriteKind.song => Icons.album_outlined,
    FavoriteKind.artist => Icons.person_outline_rounded,
  };
}

String _kindLabel(FavoriteKind kind) {
  return switch (kind) {
    FavoriteKind.comment => 'コメント',
    FavoriteKind.lyric => '歌詞',
    FavoriteKind.song => '楽曲',
    FavoriteKind.artist => 'アーティスト',
  };
}
