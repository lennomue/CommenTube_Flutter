import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/playlist.dart';
import '../../../core/models/quiz.dart';
import '../../../core/repositories/playlist_providers.dart';
import '../../../core/repositories/quiz_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/state/quiz_experience_controller.dart';
import '../../home/presentation/home_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizzes = ref.watch(quizzesProvider);
    final artists = ref.watch(artistsProvider);
    final playlists = ref.watch(playlistsProvider);
    final publicPlaylists = ref.watch(publicPlaylistsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF090909),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090909),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          key: const ValueKey('search-back-button'),
          onPressed: () {
            if (_focusNode.hasFocus) {
              _focusNode.unfocus();
              setState(() {});
              return;
            }
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        titleSpacing: 0,
        title: TextField(
          key: const ValueKey('global-search-field'),
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            hintText: '作品・アーティスト・プレイリストを検索',
            border: InputBorder.none,
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
      ),
      body: _query.trim().isEmpty
          ? const Center(child: Text('検索する言葉を入力してください'))
          : quizzes.when(
              data: (quizItems) => artists.when(
                data: (artistItems) => playlists.when(
                  data: (playlistItems) => publicPlaylists.when(
                    data: (publicItems) => _SearchResults(
                      query: _query,
                      quizzes: quizItems,
                      artists: artistItems,
                      playlists: playlistItems,
                      publicPlaylists: publicItems,
                      onQuizOpen: _openQuiz,
                      onArtistOpen: context.openArtist,
                      onArtistQuizStart: _startArtistQuiz,
                      onPlaylistOpen: context.openPlaylist,
                    ),
                    loading: _loading,
                    error: _error,
                  ),
                  loading: _loading,
                  error: _error,
                ),
                loading: _loading,
                error: _error,
              ),
              loading: _loading,
              error: _error,
            ),
    );
  }

  Widget _loading() => const Center(child: CircularProgressIndicator());

  Widget _error(Object error, StackTrace stackTrace) =>
      const Center(child: Text('検索データを読み込めませんでした'));

  void _openQuiz(String videoId) {
    ref.read(artistQuizSessionProvider.notifier).clear();
    ref.read(playlistQuizSessionProvider.notifier).clear();
    ref.read(minimizedQuizExperienceProvider.notifier).clear();
    context.openGame(videoId);
  }

  void _startArtistQuiz(
    Artist artist,
    List<QuizWithLiveStats> quizzes,
    bool shuffle,
  ) {
    final items = List<QuizWithLiveStats>.of(quizzes);
    if (shuffle) {
      items.shuffle();
    }
    final videoIds = items
        .map((item) => item.quiz.videoId)
        .toList(growable: false);
    if (videoIds.isEmpty) {
      return;
    }
    ref.read(artistQuizSessionProvider.notifier).start(artist.name, videoIds);
    ref.read(playlistQuizSessionProvider.notifier).clear();
    ref.read(minimizedQuizExperienceProvider.notifier).clear();
    context.openGame(videoIds.first);
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.query,
    required this.quizzes,
    required this.artists,
    required this.playlists,
    required this.publicPlaylists,
    required this.onQuizOpen,
    required this.onArtistOpen,
    required this.onArtistQuizStart,
    required this.onPlaylistOpen,
  });

  final String query;
  final List<QuizWithLiveStats> quizzes;
  final List<Artist> artists;
  final List<UserPlaylist> playlists;
  final List<PublicPlaylist> publicPlaylists;
  final ValueChanged<String> onQuizOpen;
  final ValueChanged<String> onArtistOpen;
  final void Function(Artist, List<QuizWithLiveStats>, bool) onArtistQuizStart;
  final ValueChanged<String> onPlaylistOpen;

  @override
  Widget build(BuildContext context) {
    final needle = query.trim().toLowerCase();
    final rankedQuizzes =
        quizzes
            .map(
              (item) => (item: item, rank: _quizMatchRank(item.quiz, needle)),
            )
            .where((entry) => entry.rank != null)
            .toList()
          ..sort((left, right) {
            final byRank = left.rank!.compareTo(right.rank!);
            return byRank != 0
                ? byRank
                : left.item.quiz.title.compareTo(right.item.quiz.title);
          });
    final titleMatchedQuizzes = rankedQuizzes
        .where((entry) => entry.rank == 0)
        .map((entry) => entry.item)
        .toList(growable: false);
    final contextMatchedQuizzes = rankedQuizzes
        .where((entry) => entry.rank != 0)
        .map((entry) => entry.item)
        .toList(growable: false);
    final matchedArtists =
        artists
            .where(
              (artist) =>
                  artist.name.toLowerCase().contains(needle) ||
                  artist.subNames.any(
                    (name) => name.toLowerCase().contains(needle),
                  ),
            )
            .toList()
          ..sort((left, right) {
            final leftRank = _artistMatchRank(left, needle);
            final rightRank = _artistMatchRank(right, needle);
            final byRank = leftRank.compareTo(rightRank);
            return byRank != 0 ? byRank : left.name.compareTo(right.name);
          });
    final matchedPlaylists = playlists
        .where((item) => item.name.toLowerCase().contains(needle))
        .toList(growable: false);
    final matchedPublic = publicPlaylists
        .where((item) => item.name.toLowerCase().contains(needle))
        .toList(growable: false);
    if (rankedQuizzes.isEmpty &&
        matchedArtists.isEmpty &&
        matchedPlaylists.isEmpty &&
        matchedPublic.isEmpty) {
      return const Center(child: Text('一致する結果はありません'));
    }
    final resultWidgets = <Widget>[];
    void addQuizSection(String label, List<QuizWithLiveStats> items) {
      if (items.isEmpty) {
        return;
      }
      resultWidgets.add(_ResultHeader(label));
      for (final indexed in items.indexed) {
        resultWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: HomeQuizPreviewCard(
              key: ValueKey('search-quiz-${indexed.$2.quiz.videoId}'),
              quiz: indexed.$2,
              colorIndex: indexed.$1,
              isNew: false,
              onTap: () => onQuizOpen(indexed.$2.quiz.videoId),
            ),
          ),
        );
      }
    }

    if (matchedArtists.isNotEmpty) {
      resultWidgets.add(const _ResultHeader('アーティスト'));
      for (final artist in matchedArtists) {
        final artistQuizzes = quizzes
            .where(
              (item) => item.quiz.artists.any(
                (itemArtist) => itemArtist.artistId == artist.artistId,
              ),
            )
            .toList(growable: false);
        resultWidgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: ListTile(
                  key: ValueKey('search-artist-${artist.artistId}'),
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_rounded),
                  ),
                  title: Text(artist.name),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => onArtistOpen(artist.name),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        key: ValueKey(
                          'search-start-artist-quiz-${artist.artistId}',
                        ),
                        onPressed: artistQuizzes.isEmpty
                            ? null
                            : () => onArtistQuizStart(
                                artist,
                                artistQuizzes,
                                false,
                              ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text('${artist.name}のクイズを始める'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      key: ValueKey(
                        'search-shuffle-artist-quiz-${artist.artistId}',
                      ),
                      tooltip: 'シャッフル再生',
                      onPressed: artistQuizzes.length < 2
                          ? null
                          : () =>
                                onArtistQuizStart(artist, artistQuizzes, true),
                      icon: const Icon(Icons.shuffle_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    }
    addQuizSection('作品', titleMatchedQuizzes);
    addQuizSection(
      titleMatchedQuizzes.isEmpty && matchedArtists.isEmpty ? '作品' : '関連する作品',
      contextMatchedQuizzes,
    );
    if (matchedPlaylists.isNotEmpty || matchedPublic.isNotEmpty) {
      resultWidgets.add(const _ResultHeader('プレイリスト'));
      for (final playlist in matchedPlaylists) {
        resultWidgets.add(
          Card(
            child: ListTile(
              key: ValueKey('search-playlist-${playlist.id}'),
              leading: const Icon(Icons.bookmark_rounded),
              title: Text(playlist.name),
              subtitle: Text('${playlist.videoIds.length}作品'),
              onTap: () => onPlaylistOpen(playlist.id),
            ),
          ),
        );
      }
      for (final playlist in matchedPublic) {
        resultWidgets.add(
          Card(
            child: ListTile(
              key: ValueKey('search-public-playlist-${playlist.id}'),
              leading: const Icon(Icons.public_rounded),
              title: Text(playlist.name),
              subtitle: Text(
                '${playlist.ownerName} ・ ${playlist.videoIds.length}作品',
              ),
            ),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: resultWidgets,
    );
  }

  int? _quizMatchRank(Quiz quiz, String needle) {
    if (quiz.title.toLowerCase().contains(needle)) {
      return 0;
    }
    if (quiz.artists.any(
      (artist) =>
          artist.name.toLowerCase().contains(needle) ||
          artist.subNames.any((name) => name.toLowerCase().contains(needle)),
    )) {
      return 1;
    }
    if (_flattenMetaData(quiz.metaData).contains(needle)) {
      return 2;
    }
    return null;
  }

  int _artistMatchRank(Artist artist, String needle) {
    final names = [
      artist.name,
      ...artist.subNames,
    ].map((name) => name.toLowerCase()).toList(growable: false);
    if (names.contains(needle)) {
      return 0;
    }
    if (names.any((name) => name.startsWith(needle))) {
      return 1;
    }
    return 2;
  }

  String _flattenMetaData(Object? value) {
    return switch (value) {
      Map<Object?, Object?> map => map.values.map(_flattenMetaData).join(' '),
      Iterable<Object?> values => values.map(_flattenMetaData).join(' '),
      null => '',
      _ => value.toString().toLowerCase(),
    };
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      ),
    );
  }
}
