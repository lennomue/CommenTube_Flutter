import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/favorite.dart';
import '../../../core/models/quiz.dart';
import '../../../core/models/quiz_filter.dart';
import '../../../core/repositories/favorite_providers.dart';
import '../../../core/repositories/quiz_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/state/quiz_experience_controller.dart';
import '../../../core/utils/display_formatters.dart';

enum _SongOrder { views, newest }

class ArtistScreen extends ConsumerStatefulWidget {
  const ArtistScreen({super.key, required this.artist});

  final String artist;

  @override
  ConsumerState<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends ConsumerState<ArtistScreen> {
  String _query = '';
  _SongOrder _order = _SongOrder.views;

  @override
  Widget build(BuildContext context) {
    final quizzes = ref.watch(
      filteredQuizzesProvider(QuizFilter(artists: [widget.artist])),
    );
    final favoriteIds =
        ref
            .watch(favoritesProvider)
            .value
            ?.map((favorite) => favorite.id)
            .toSet() ??
        const <String>{};
    final artistFavorite = SavedFavorite.artist(widget.artist);

    return Scaffold(
      body: SafeArea(
        child: DefaultTabController(
          length: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 10, 4),
                child: Row(
                  children: [
                    IconButton(
                      key: const ValueKey('artist-back-button'),
                      tooltip: 'ライブラリに戻る',
                      onPressed: Navigator.of(context).pop,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    Expanded(
                      child: Text(
                        widget.artist,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      key: ValueKey('artist-page-favorite-${widget.artist}'),
                      tooltip: 'アーティストをお気に入り',
                      onPressed: () => ref
                          .read(favoriteRepositoryProvider)
                          .toggleFavorite(artistFavorite),
                      icon: Icon(
                        favoriteIds.contains(artistFavorite.id)
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                child: quizzes.when(
                  data: (items) => FilledButton.icon(
                    key: const ValueKey('start-artist-quiz'),
                    onPressed: items.isEmpty
                        ? null
                        : () => _startArtistQuiz(items),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('このアーティストのクイズを始める'),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (error, stackTrace) => const Text('問題を読み込めませんでした'),
                ),
              ),
              const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.grid_view_rounded), text: 'クイズ'),
                  Tab(icon: Icon(Icons.queue_music_rounded), text: '楽曲'),
                ],
              ),
              Expanded(
                child: quizzes.when(
                  data: (items) => TabBarView(
                    children: [
                      _ArtistQuizGrid(
                        quizzes: items,
                        onQuizSelected: _openSingleQuiz,
                      ),
                      _ArtistSongList(
                        quizzes: _filteredAndSorted(items),
                        query: _query,
                        order: _order,
                        onQueryChanged: (value) =>
                            setState(() => _query = value),
                        onOrderChanged: (value) =>
                            setState(() => _order = value),
                        onQuizSelected: _openSingleQuiz,
                      ),
                    ],
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) =>
                      const Center(child: Text('問題を読み込めませんでした')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<QuizWithLiveStats> _filteredAndSorted(List<QuizWithLiveStats> source) {
    final query = _query.trim().toLowerCase();
    final result = source
        .where(
          (item) =>
              query.isEmpty || item.quiz.title.toLowerCase().contains(query),
        )
        .toList(growable: false);
    result.sort((left, right) {
      return switch (_order) {
        _SongOrder.views => right.videoStats.viewCount.compareTo(
          left.videoStats.viewCount,
        ),
        _SongOrder.newest => right.quiz.postedAt.compareTo(left.quiz.postedAt),
      };
    });
    return result;
  }

  void _startArtistQuiz(List<QuizWithLiveStats> quizzes) {
    final videoIds = quizzes
        .map((item) => item.quiz.videoId)
        .toList(growable: false);
    ref.read(artistQuizSessionProvider.notifier).start(widget.artist, videoIds);
    ref.read(minimizedQuizExperienceProvider.notifier).clear();
    context.openGame(videoIds.first);
  }

  void _openSingleQuiz(String videoId) {
    ref.read(artistQuizSessionProvider.notifier).clear();
    ref.read(minimizedQuizExperienceProvider.notifier).clear();
    context.openGame(videoId);
  }
}

class _ArtistQuizGrid extends StatelessWidget {
  const _ArtistQuizGrid({required this.quizzes, required this.onQuizSelected});

  final List<QuizWithLiveStats> quizzes;
  final ValueChanged<String> onQuizSelected;

  @override
  Widget build(BuildContext context) {
    if (quizzes.isEmpty) {
      return const Center(child: Text('このアーティストの問題はまだありません'));
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 28),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: quizzes.length,
      itemBuilder: (context, index) {
        final quiz = quizzes[index];
        return Material(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('artist-quiz-${quiz.quiz.videoId}'),
            onTap: () => onQuizSelected(quiz.quiz.videoId),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0xFF565656), Color(0xFF111111)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Center(
                  child: Text(
                    quiz.quiz.thumbnailHint?.content ?? 'ヒントはありません',
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ArtistSongList extends StatelessWidget {
  const _ArtistSongList({
    required this.quizzes,
    required this.query,
    required this.order,
    required this.onQueryChanged,
    required this.onOrderChanged,
    required this.onQuizSelected,
  });

  final List<QuizWithLiveStats> quizzes;
  final String query;
  final _SongOrder order;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<_SongOrder> onOrderChanged;
  final ValueChanged<String> onQuizSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('artist-song-search'),
                  onChanged: onQueryChanged,
                  decoration: const InputDecoration(
                    hintText: '曲名を検索',
                    prefixIcon: Icon(Icons.search_rounded),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<_SongOrder>(
                key: const ValueKey('artist-song-order'),
                value: order,
                underline: const SizedBox.shrink(),
                onChanged: (value) {
                  if (value != null) {
                    onOrderChanged(value);
                  }
                },
                items: const [
                  DropdownMenuItem(value: _SongOrder.views, child: Text('再生順')),
                  DropdownMenuItem(
                    value: _SongOrder.newest,
                    child: Text('新しい順'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: quizzes.isEmpty
              ? Center(child: Text(query.isEmpty ? '楽曲がありません' : '該当する楽曲がありません'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                  itemCount: quizzes.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final quiz = quizzes[index];
                    return ListTile(
                      key: ValueKey('artist-song-${quiz.quiz.videoId}'),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      onTap: () => onQuizSelected(quiz.quiz.videoId),
                      title: Text(quiz.quiz.title),
                      subtitle: Text(
                        '${formatCompactCount(quiz.videoStats.viewCount)}回視聴 ・ '
                        '${formatDate(quiz.quiz.postedAt)}',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
