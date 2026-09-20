import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/favorite.dart';
import '../../../core/models/quiz.dart';
import '../../../core/models/quiz_history.dart';
import '../../../core/repositories/favorite_providers.dart';
import '../../../core/repositories/quiz_history_providers.dart';
import '../../../core/repositories/quiz_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/state/quiz_experience_controller.dart';
import '../../../core/utils/display_formatters.dart';
import '../../result/presentation/quiz_detail_panel.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  static const _favoriteTabs = [
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
    final history = ref.watch(quizHistoryProvider);
    final quizzes = ref.watch(quizzesProvider);
    return SafeArea(
      bottom: false,
      child: DefaultTabController(
        length: _favoriteTabs.length + 1,
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
                  hintText: 'お気に入り・履歴を検索',
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
                for (final tab in _favoriteTabs)
                  Tab(icon: Icon(tab.$2), text: tab.$3),
                const Tab(icon: Icon(Icons.history_rounded), text: '履歴'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  for (final tab in _favoriteTabs)
                    favorites.when(
                      data: (items) => _FavoriteList(
                        kind: tab.$1,
                        favorites: _matchingFavorites(items, tab.$1),
                        hasQuery: _query.trim().isNotEmpty,
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stackTrace) => const _LibraryError(),
                    ),
                  history.when(
                    data: (records) => quizzes.when(
                      data: (items) => _HistoryList(
                        records: records,
                        quizzes: items,
                        query: _query,
                        onQuizSelected: _openHistoryQuiz,
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stackTrace) => const _HistoryError(),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) => const _HistoryError(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openHistoryQuiz(String videoId) {
    ref.read(artistQuizSessionProvider.notifier).clear();
    ref.read(minimizedQuizExperienceProvider.notifier).clear();
    context.openGame(videoId);
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

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.records,
    required this.quizzes,
    required this.query,
    required this.onQuizSelected,
  });

  final List<QuizHistoryRecord> records;
  final List<QuizWithLiveStats> quizzes;
  final String query;
  final ValueChanged<String> onQuizSelected;

  @override
  Widget build(BuildContext context) {
    final quizzesById = {for (final quiz in quizzes) quiz.quiz.videoId: quiz};
    final normalizedQuery = query.trim().toLowerCase();
    final visibleRecords = records
        .where((record) {
          final title = quizzesById[record.videoId]?.quiz.title;
          return title != null &&
              (normalizedQuery.isEmpty ||
                  title.toLowerCase().contains(normalizedQuery));
        })
        .toList(growable: false);
    if (visibleRecords.isEmpty) {
      return Center(
        child: Text(
          normalizedQuery.isEmpty ? 'クイズ履歴はまだありません' : '検索に一致する履歴はありません',
          style: const TextStyle(color: Color(0xFFAAAAAA)),
        ),
      );
    }
    return ListView.separated(
      key: const PageStorageKey('quiz-history-list'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: visibleRecords.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final record = visibleRecords[index];
        final quiz = quizzesById[record.videoId]!;
        return Material(
          color: const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('history-quiz-${record.videoId}'),
            onTap: () => onQuizSelected(record.videoId),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.quiz.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatCompactCount(quiz.videoStats.viewCount)}回視聴 ・ '
                          '高評価 ${formatCompactCount(quiz.videoStats.likeCount)} ・ '
                          '${formatRelativeTime(record.playedAt)}',
                          style: const TextStyle(
                            color: Color(0xFFAAAAAA),
                            fontSize: 12,
                          ),
                        ),
                      ],
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

class _HistoryError extends StatelessWidget {
  const _HistoryError();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('履歴を読み込めませんでした'));
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
