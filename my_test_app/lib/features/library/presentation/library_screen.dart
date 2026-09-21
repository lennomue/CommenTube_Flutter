import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/favorite.dart';
import '../../../core/models/quiz.dart';
import '../../../core/models/quiz_history.dart';
import '../../../core/models/playlist.dart';
import '../../../core/models/quiz_filter.dart';
import '../../../core/repositories/favorite_providers.dart';
import '../../../core/repositories/playlist_providers.dart';
import '../../../core/repositories/quiz_history_providers.dart';
import '../../../core/repositories/quiz_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/state/quiz_experience_controller.dart';
import '../../../core/utils/display_formatters.dart';
import '../../../core/widgets/quiz_song_tile.dart';
import '../../../core/widgets/work_collection_toolbar.dart';
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
    (FavoriteKind.song, Icons.album_outlined, '作品'),
    (FavoriteKind.artist, Icons.person_outline_rounded, 'アーティスト'),
  ];

  final _searchController = TextEditingController();
  String _query = '';
  bool _showsPlaylists = false;
  QuizFilter _workFilter = QuizFilter.empty;
  WorkOrder _workOrder = WorkOrder.views;

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
    final playlists = ref.watch(playlistsProvider);
    return SafeArea(
      bottom: false,
      child: DefaultTabController(
        length: _favoriteTabs.length + 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Library',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _LibrarySectionSwitch(
                    showsPlaylists: _showsPlaylists,
                    onChanged: (value) =>
                        setState(() => _showsPlaylists = value),
                  ),
                ],
              ),
            ),
            if (_showsPlaylists)
              Expanded(
                child: _PlaylistLibrary(
                  playlists: playlists,
                  quizzes: quizzes,
                  onOpen: context.openPlaylist,
                  onPlay: _startPlaylist,
                ),
              )
            else ...[
              favorites.when(
                data: (items) => quizzes.when(
                  data: (quizItems) => _FavoriteQuizLauncher(
                    enabled: _favoriteVideoIds(items, quizItems).isNotEmpty,
                    onPressed: () =>
                        _startFavoriteQuiz(items, quizItems, shuffle: false),
                    onShuffle: () =>
                        _startFavoriteQuiz(items, quizItems, shuffle: true),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                ),
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
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
                        data: (items) => tab.$1 == FavoriteKind.song
                            ? quizzes.when(
                                data: (quizItems) => _FavoriteWorksTab(
                                  favorites: _matchingFavorites(
                                    items,
                                    FavoriteKind.song,
                                  ),
                                  quizzes: quizItems,
                                  filter: _workFilter,
                                  order: _workOrder,
                                  onFilterChanged: (value) =>
                                      setState(() => _workFilter = value),
                                  onOrderChanged: (value) =>
                                      setState(() => _workOrder = value),
                                  onOpen: (videoId) =>
                                      _showQuizDetail(context, ref, videoId),
                                ),
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                error: (error, stackTrace) =>
                                    const _LibraryError(),
                              )
                            : _FavoriteList(
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
          ],
        ),
      ),
    );
  }

  void _openHistoryQuiz(String videoId) {
    ref.read(artistQuizSessionProvider.notifier).clear();
    ref.read(playlistQuizSessionProvider.notifier).clear();
    ref.read(minimizedQuizExperienceProvider.notifier).clear();
    context.openGame(videoId);
  }

  void _startPlaylist(UserPlaylist playlist, List<QuizWithLiveStats> quizzes) {
    final availableIds = quizzes.map((item) => item.quiz.videoId).toSet();
    final videoIds = playlist.videoIds
        .where(availableIds.contains)
        .toList(growable: false);
    if (videoIds.isEmpty) {
      return;
    }
    ref.read(artistQuizSessionProvider.notifier).clear();
    ref.read(playlistQuizSessionProvider.notifier).start(playlist.id, videoIds);
    ref.read(minimizedQuizExperienceProvider.notifier).clear();
    context.openGame(videoIds.first);
  }

  List<String> _favoriteVideoIds(
    List<SavedFavorite> favorites,
    List<QuizWithLiveStats> quizzes,
  ) {
    final availableIds = quizzes.map((item) => item.quiz.videoId).toSet();
    return favorites
        .map((item) => item.videoId)
        .whereType<String>()
        .where(availableIds.contains)
        .toSet()
        .toList(growable: false);
  }

  void _startFavoriteQuiz(
    List<SavedFavorite> favorites,
    List<QuizWithLiveStats> quizzes, {
    required bool shuffle,
  }) {
    final videoIds = _favoriteVideoIds(favorites, quizzes);
    if (shuffle) {
      videoIds.shuffle();
    }
    if (videoIds.isEmpty) {
      return;
    }
    ref.read(artistQuizSessionProvider.notifier).clear();
    ref
        .read(playlistQuizSessionProvider.notifier)
        .start('favorite-videos', videoIds);
    ref.read(minimizedQuizExperienceProvider.notifier).clear();
    context.openGame(videoIds.first);
  }

  Future<void> _showQuizDetail(
    BuildContext context,
    WidgetRef ref,
    String videoId,
  ) async {
    final action = await showModalBottomSheet<_LibraryDetailAction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF171717),
      builder: (context) => _LibraryQuizDetail(videoId: videoId),
    );
    if (action == null || !context.mounted) {
      return;
    }
    if (action.artist case final artist?) {
      context.openArtist(artist);
    } else if (action.videoId case final relatedVideoId?) {
      ref.read(artistQuizSessionProvider.notifier).clear();
      ref.read(playlistQuizSessionProvider.notifier).clear();
      ref.read(minimizedQuizExperienceProvider.notifier).clear();
      context.openGame(relatedVideoId);
    }
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

class _FavoriteQuizLauncher extends StatelessWidget {
  const _FavoriteQuizLauncher({
    required this.enabled,
    required this.onPressed,
    required this.onShuffle,
  });

  final bool enabled;
  final VoidCallback onPressed;
  final VoidCallback onShuffle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              key: const ValueKey('start-favorite-quiz'),
              onPressed: enabled ? onPressed : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('お気に入りでクイズ'),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            key: const ValueKey('shuffle-favorite-quiz'),
            tooltip: 'シャッフル再生',
            onPressed: enabled ? onShuffle : null,
            icon: const Icon(Icons.shuffle_rounded),
          ),
        ],
      ),
    );
  }
}

class _LibrarySectionSwitch extends StatelessWidget {
  const _LibrarySectionSwitch({
    required this.showsPlaylists,
    required this.onChanged,
  });

  final bool showsPlaylists;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('library-section-switch'),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SwitchButton(
            key: const ValueKey('show-library-favorites'),
            selected: !showsPlaylists,
            icon: Icons.favorite_rounded,
            tooltip: 'お気に入り',
            onPressed: () => onChanged(false),
          ),
          _SwitchButton(
            key: const ValueKey('show-library-playlists'),
            selected: showsPlaylists,
            icon: Icons.bookmark_rounded,
            tooltip: '再生リスト',
            onPressed: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _SwitchButton extends StatelessWidget {
  const _SwitchButton({
    super.key,
    required this.selected,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final bool selected;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 40,
          height: 32,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            icon,
            color: selected ? Colors.black : const Color(0xFF888888),
            size: 21,
          ),
        ),
      ),
    );
  }
}

enum _PlaylistLibrarySection { mine, saved, related }

class _PlaylistLibrary extends ConsumerStatefulWidget {
  const _PlaylistLibrary({
    required this.playlists,
    required this.quizzes,
    required this.onOpen,
    required this.onPlay,
  });

  final AsyncValue<List<UserPlaylist>> playlists;
  final AsyncValue<List<QuizWithLiveStats>> quizzes;
  final ValueChanged<String> onOpen;
  final void Function(UserPlaylist, List<QuizWithLiveStats>) onPlay;

  @override
  ConsumerState<_PlaylistLibrary> createState() => _PlaylistLibraryState();
}

class _PlaylistLibraryState extends ConsumerState<_PlaylistLibrary> {
  _PlaylistLibrarySection? _section;

  @override
  Widget build(BuildContext context) {
    final publicPlaylists = ref.watch(publicPlaylistsProvider);
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            children: [
              _sectionChip('マイプレイリスト', _PlaylistLibrarySection.mine),
              _sectionChip('保存したプレイリスト', _PlaylistLibrarySection.saved),
              _sectionChip('関連', _PlaylistLibrarySection.related),
            ],
          ),
        ),
        Expanded(
          child: widget.playlists.when(
            data: (items) => widget.quizzes.when(
              data: (quizItems) => publicPlaylists.when(
                data: (publicItems) =>
                    _buildSection(items, publicItems, quizItems),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) =>
                    const Center(child: Text('関連を読み込めませんでした')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  const Center(child: Text('作品を読み込めませんでした')),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) =>
                const Center(child: Text('再生リストを読み込めませんでした')),
          ),
        ),
      ],
    );
  }

  Widget _sectionChip(String label, _PlaylistLibrarySection value) {
    final selected = _section == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        key: ValueKey('playlist-section-${value.name}'),
        label: Text(label),
        selected: selected,
        selectedColor: Colors.white,
        labelStyle: TextStyle(color: selected ? Colors.black : Colors.white),
        onSelected: (isSelected) =>
            setState(() => _section = isSelected ? value : null),
      ),
    );
  }

  Widget _buildSection(
    List<UserPlaylist> localItems,
    List<PublicPlaylist> publicItems,
    List<QuizWithLiveStats> quizzes,
  ) {
    final relatedPlaylists = _rankRelatedPlaylists(
      localItems,
      publicItems,
      quizzes,
    );
    if (_section == _PlaylistLibrarySection.related) {
      return _PublicPlaylistList(
        playlists: relatedPlaylists,
        quizzes: quizzes,
        onPlay: widget.onPlay,
        onOpen: context.openPublicPlaylist,
      );
    }
    final visible = localItems
        .where(
          (item) => switch (_section) {
            _PlaylistLibrarySection.saved => item.isSavedCopy,
            _PlaylistLibrarySection.mine => !item.isSavedCopy,
            _ => true,
          },
        )
        .toList(growable: false);
    return ListView(
      key: PageStorageKey('playlist-library-${_section?.name ?? 'all'}'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Text(
              _section == _PlaylistLibrarySection.saved
                  ? '保存したプレイリストはまだありません'
                  : _section == null
                  ? 'プレイリストはまだありません'
                  : 'マイプレイリストはまだありません',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFAAAAAA)),
            ),
          ),
        for (final playlist in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _PlaylistLibraryRow(
              playlist: playlist,
              onOpen: () => widget.onOpen(playlist.id),
              onPlay: () => widget.onPlay(playlist, quizzes),
            ),
          ),
        if (_section == null || _section == _PlaylistLibrarySection.mine) ...[
          TextButton.icon(
            key: const ValueKey('create-empty-playlist'),
            onPressed: () => _create(context, ref),
            icon: const Icon(Icons.add_rounded),
            label: const Text('新しい再生リスト'),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 20, 4, 10),
            child: Text(
              '関連',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          _PublicPlaylistList(
            playlists: relatedPlaylists.take(3).toList(growable: false),
            quizzes: quizzes,
            onPlay: widget.onPlay,
            onOpen: context.openPublicPlaylist,
            shrinkWrap: true,
          ),
        ],
      ],
    );
  }

  List<PublicPlaylist> _rankRelatedPlaylists(
    List<UserPlaylist> localItems,
    List<PublicPlaylist> publicItems,
    List<QuizWithLiveStats> quizzes,
  ) {
    final quizzesById = {
      for (final quiz in quizzes) quiz.quiz.videoId: quiz.quiz,
    };
    final recentVideoIds = localItems
        .expand((playlist) => playlist.videoIds)
        .toSet()
        .take(20);
    final preferredGenres = <String>{};
    final preferredArtists = <String>{};
    for (final videoId in recentVideoIds) {
      final quiz = quizzesById[videoId];
      if (quiz == null) {
        continue;
      }
      preferredGenres.addAll(quiz.contentGenres);
      preferredArtists.addAll(quiz.artistNames);
    }
    final ranked = List<PublicPlaylist>.of(publicItems);
    int score(PublicPlaylist playlist) {
      var value = 0;
      for (final videoId in playlist.videoIds) {
        final quiz = quizzesById[videoId];
        if (quiz == null) {
          continue;
        }
        value += quiz.contentGenres.where(preferredGenres.contains).length * 2;
        value += quiz.artistNames.where(preferredArtists.contains).length * 3;
      }
      return value;
    }

    ranked.sort((left, right) {
      final byScore = score(right).compareTo(score(left));
      return byScore != 0 ? byScore : right.updatedAt.compareTo(left.updatedAt);
    });
    return ranked;
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final draft = await showPlaylistEditor(context);
    if (draft != null) {
      await ref.read(playlistRepositoryProvider).createPlaylist(draft);
    }
  }
}

class _PlaylistLibraryRow extends StatelessWidget {
  const _PlaylistLibraryRow({
    required this.playlist,
    required this.onOpen,
    required this.onPlay,
  });

  final UserPlaylist playlist;
  final VoidCallback onOpen;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1C1C1C),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('library-playlist-${playlist.id}'),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 7, 10),
          child: Row(
            children: [
              const Icon(Icons.bookmark_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${playlist.videoIds.length}作品 ・ '
                      '${playlist.isPublic ? '公開' : '非公開'}',
                      style: const TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('play-playlist-${playlist.id}'),
                tooltip: '順番にクイズを開始',
                onPressed: playlist.videoIds.isEmpty ? null : onPlay,
                icon: const Icon(Icons.play_arrow_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicPlaylistList extends ConsumerWidget {
  const _PublicPlaylistList({
    required this.playlists,
    required this.quizzes,
    required this.onPlay,
    required this.onOpen,
    this.shrinkWrap = false,
  });

  final List<PublicPlaylist> playlists;
  final List<QuizWithLiveStats> quizzes;
  final void Function(UserPlaylist, List<QuizWithLiveStats>) onPlay;
  final ValueChanged<PublicPlaylist> onOpen;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = [
      for (final playlist in playlists)
        Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Material(
            color: const Color(0xFF1C1C1C),
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              key: ValueKey('public-playlist-${playlist.id}'),
              onTap: () => onOpen(playlist),
              leading: const Icon(Icons.public_rounded),
              title: Text(playlist.name),
              subtitle: Text(
                '${playlist.ownerName} ・ ${playlist.videoIds.length}作品',
              ),
              trailing: Wrap(
                children: [
                  IconButton(
                    tooltip: 'プレイリストを保存',
                    onPressed: () => ref
                        .read(playlistRepositoryProvider)
                        .copyPlaylist(playlist.asUnownedPlaylist()),
                    icon: const Icon(Icons.bookmark_add_outlined),
                  ),
                  IconButton(
                    tooltip: 'クイズを開始',
                    onPressed: () =>
                        onPlay(playlist.asUnownedPlaylist(), quizzes),
                    icon: const Icon(Icons.play_arrow_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),
    ];
    if (shrinkWrap) {
      return Column(children: children);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: children,
    );
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

class _FavoriteWorksTab extends ConsumerWidget {
  const _FavoriteWorksTab({
    required this.favorites,
    required this.quizzes,
    required this.filter,
    required this.order,
    required this.onFilterChanged,
    required this.onOrderChanged,
    required this.onOpen,
  });

  final List<SavedFavorite> favorites;
  final List<QuizWithLiveStats> quizzes;
  final QuizFilter filter;
  final WorkOrder order;
  final ValueChanged<QuizFilter> onFilterChanged;
  final ValueChanged<WorkOrder> onOrderChanged;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = favorites.map((item) => item.videoId).toSet();
    final works =
        quizzes
            .where(
              (item) =>
                  favoriteIds.contains(item.quiz.videoId) &&
                  _matchesWorkFilter(item.quiz, filter),
            )
            .toList(growable: false)
          ..sort(
            (left, right) => switch (order) {
              WorkOrder.views => right.videoStats.viewCount.compareTo(
                left.videoStats.viewCount,
              ),
              WorkOrder.newest => right.quiz.postedAt.compareTo(
                left.quiz.postedAt,
              ),
              WorkOrder.oldest => left.quiz.postedAt.compareTo(
                right.quiz.postedAt,
              ),
            },
          );
    return Column(
      children: [
        WorkCollectionToolbar(
          key: const ValueKey('library-work-toolbar'),
          filter: filter,
          order: order,
          onFilterChanged: onFilterChanged,
          onOrderChanged: onOrderChanged,
          onBulkAdd: works.isEmpty
              ? null
              : () => showBatchPlaylistSheet(
                  context,
                  ref,
                  videoIds: works
                      .map((item) => item.quiz.videoId)
                      .toList(growable: false),
                ),
        ),
        Expanded(
          child: works.isEmpty
              ? const Center(child: Text('条件に合うお気に入り作品はありません'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                  itemCount: works.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final work = works[index];
                    return QuizSongTile(
                      key: ValueKey(
                        'library-favorite-song:${work.quiz.videoId}',
                      ),
                      quiz: work,
                      onOpen: () => onOpen(work.quiz.videoId),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

bool _matchesWorkFilter(Quiz quiz, QuizFilter filter) {
  return (filter.contentGenres.isEmpty ||
          quiz.contentGenres.any(filter.contentGenres.contains)) &&
      (filter.languages.isEmpty ||
          quiz.languages.any(filter.languages.contains)) &&
      (filter.videoGenres.isEmpty ||
          filter.videoGenres.contains(quiz.videoGenre)) &&
      (filter.publishedFromYear == null ||
          quiz.postedAt.year >= filter.publishedFromYear!) &&
      (filter.publishedToYear == null ||
          quiz.postedAt.year <= filter.publishedToYear!);
}

class _FavoriteList extends ConsumerWidget {
  const _FavoriteList({
    required this.kind,
    required this.favorites,
    required this.hasQuery,
  });

  final FavoriteKind kind;
  final List<SavedFavorite> favorites;
  final bool hasQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            onTap: () => _openFavorite(context, ref, favorite),
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

  void _openFavorite(
    BuildContext context,
    WidgetRef ref,
    SavedFavorite favorite,
  ) {
    if (favorite.kind == FavoriteKind.artist) {
      context.openArtist(favorite.itemKey);
      return;
    }
    final videoId = favorite.videoId;
    if (videoId != null) {
      _showQuizDetail(context, ref, videoId);
    }
  }

  Future<void> _showQuizDetail(
    BuildContext context,
    WidgetRef ref,
    String videoId,
  ) async {
    final action = await showModalBottomSheet<_LibraryDetailAction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF171717),
      builder: (context) => _LibraryQuizDetail(videoId: videoId),
    );
    if (action == null || !context.mounted) {
      return;
    }
    if (action.artist case final artist?) {
      context.openArtist(artist);
    } else if (action.videoId case final relatedVideoId?) {
      ref.read(artistQuizSessionProvider.notifier).clear();
      ref.read(playlistQuizSessionProvider.notifier).clear();
      ref.read(minimizedQuizExperienceProvider.notifier).clear();
      context.openGame(relatedVideoId);
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
                onArtistOpen: (artist) => Navigator.pop(
                  context,
                  _LibraryDetailAction(artist: artist),
                ),
                onQuizOpen: (videoId) => Navigator.pop(
                  context,
                  _LibraryDetailAction(videoId: videoId),
                ),
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

class _LibraryDetailAction {
  const _LibraryDetailAction({this.artist, this.videoId});

  final String? artist;
  final String? videoId;
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
    FavoriteKind.song => '作品',
    FavoriteKind.artist => 'アーティスト',
  };
}
