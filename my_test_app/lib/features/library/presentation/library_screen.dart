import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/favorite.dart';
import '../../../core/repositories/favorite_providers.dart';
import '../../../core/repositories/quiz_providers.dart';
import '../../../core/router/app_router.dart';
import '../../result/presentation/quiz_detail_panel.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  static const _tabs = [
    (FavoriteKind.comment, Icons.chat_bubble_outline_rounded, 'コメント'),
    (FavoriteKind.lyric, Icons.music_note_rounded, '歌詞'),
    (FavoriteKind.song, Icons.album_outlined, '楽曲'),
    (FavoriteKind.artist, Icons.person_outline_rounded, 'アーティスト'),
  ];

  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    return SafeArea(
      bottom: false,
      child: DefaultTabController(
        length: _tabs.length,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Text(
                'Library',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                key: const ValueKey('library-search-field'),
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'お気に入りを検索',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: '検索をクリア',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: const Color(0xFF1B1B1B),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                    borderSide: BorderSide.none,
                  ),
                ),
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
                        favorites: _matchingFavorites(items, tab.$1),
                        hasQuery: _query.trim().isNotEmpty,
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

  List<SavedFavorite> _matchingFavorites(
    List<SavedFavorite> items,
    FavoriteKind kind,
  ) {
    final query = _query.trim().toLowerCase();
    return items
        .where(
          (item) =>
              item.kind == kind &&
              (query.isEmpty || item.displayText.toLowerCase().contains(query)),
        )
        .toList(growable: false);
  }
}

class _FavoriteList extends StatelessWidget {
  const _FavoriteList({
    required this.kind,
    required this.favorites,
    required this.hasQuery,
  });

  final FavoriteKind kind;
  final List<SavedFavorite> favorites;
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    if (favorites.isEmpty) {
      return _EmptyFavorites(kind: kind, hasQuery: hasQuery);
    }
    return ListView.separated(
      key: PageStorageKey('favorite-list-${kind.name}'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: favorites.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final favorite = favorites[index];
        return Material(
          color: const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('library-favorite-${favorite.id}'),
            onTap: () => _openFavorite(context, favorite),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Icon(_kindIcon(favorite.kind), color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      favorite.displayText,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openFavorite(BuildContext context, SavedFavorite favorite) {
    if (favorite.kind == FavoriteKind.artist) {
      context.openArtist(favorite.itemKey);
      return;
    }
    final videoId = favorite.videoId;
    if (videoId != null) {
      _showQuizDetail(context, videoId);
    }
  }

  Future<void> _showQuizDetail(BuildContext context, String videoId) async {
    final artist = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF171717),
      builder: (context) => _LibraryQuizDetail(videoId: videoId),
    );
    if (artist != null && context.mounted) {
      context.openArtist(artist);
    }
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites({required this.kind, required this.hasQuery});

  final FavoriteKind kind;
  final bool hasQuery;

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
            Text(
              hasQuery
                  ? '検索に一致する${_kindLabel(kind)}はありません'
                  : 'お気に入りの${_kindLabel(kind)}はまだありません',
            ),
            if (!hasQuery) ...[
              const SizedBox(height: 6),
              const Text(
                'Result画面から追加できます',
                style: TextStyle(color: Color(0xFFAAAAAA)),
              ),
            ],
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
      heightFactor: 0.92,
      child: quiz.when(
        data: (item) => item == null
            ? _DetailMessage(onClose: () => Navigator.pop(context))
            : QuizDetailPanel(
                quiz: item,
                onArtistOpen: (artist) => Navigator.pop(context, artist),
                leading: IconButton(
                  key: const ValueKey('close-library-detail'),
                  tooltip: '閉じる',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            _DetailMessage(onClose: () => Navigator.pop(context)),
      ),
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
