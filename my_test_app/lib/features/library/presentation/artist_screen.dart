import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/favorite.dart';
import '../../../core/models/quiz.dart';
import '../../../core/models/quiz_filter.dart';
import '../../../core/repositories/favorite_providers.dart';
import '../../../core/repositories/quiz_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/state/quiz_experience_controller.dart';
import '../../../core/widgets/quiz_song_tile.dart';
import '../../../core/widgets/work_collection_toolbar.dart';

class ArtistScreen extends ConsumerStatefulWidget {
  const ArtistScreen({super.key, required this.artist});

  final String artist;

  @override
  ConsumerState<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends ConsumerState<ArtistScreen> {
  QuizFilter _workFilter = QuizFilter.empty;
  WorkOrder _workOrder = WorkOrder.views;

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
    final relatedArtists = ref.watch(relatedArtistsProvider(widget.artist));

    return Scaffold(
      body: SafeArea(
        child: DefaultTabController(
          length: 3,
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
                  data: (items) => Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          key: const ValueKey('start-artist-quiz'),
                          onPressed: items.isEmpty
                              ? null
                              : () => _startArtistQuiz(items),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('クイズを始める'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        key: const ValueKey('shuffle-artist-quiz'),
                        tooltip: 'シャッフル再生',
                        onPressed: items.length < 2
                            ? null
                            : () => _startArtistQuiz(
                                List<QuizWithLiveStats>.of(items)..shuffle(),
                              ),
                        icon: const Icon(Icons.shuffle_rounded),
                      ),
                    ],
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (error, stackTrace) => const Text('問題を読み込めませんでした'),
                ),
              ),
              const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.grid_view_rounded), text: 'クイズ'),
                  Tab(icon: Icon(Icons.queue_music_rounded), text: '作品'),
                  Tab(icon: Icon(Icons.people_outline_rounded), text: '関連'),
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
                        quizzes: items,
                        filter: _workFilter,
                        order: _workOrder,
                        onFilterChanged: (value) =>
                            setState(() => _workFilter = value),
                        onOrderChanged: (value) =>
                            setState(() => _workOrder = value),
                        onQuizSelected: _openSingleQuiz,
                      ),
                      relatedArtists.when(
                        data: (artists) => _RelatedArtistsList(
                          artists: artists,
                          onOpen: context.openArtist,
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stackTrace) =>
                            const Center(child: Text('関連を読み込めませんでした')),
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

  void _startArtistQuiz(List<QuizWithLiveStats> quizzes) {
    final videoIds = quizzes
        .map((item) => item.quiz.videoId)
        .toList(growable: false);
    ref.read(artistQuizSessionProvider.notifier).start(widget.artist, videoIds);
    ref.read(playlistQuizSessionProvider.notifier).clear();
    ref.read(minimizedQuizExperienceProvider.notifier).clear();
    context.openGame(videoIds.first);
  }

  void _openSingleQuiz(String videoId) {
    ref.read(artistQuizSessionProvider.notifier).clear();
    ref.read(playlistQuizSessionProvider.notifier).clear();
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
        final atmosphere = quiz.quiz.atmosphereColor;
        final baseColor = HSLColor.fromAHSL(
          1,
          atmosphere.hue,
          atmosphere.saturation.clamp(0, 1).toDouble(),
          atmosphere.lightness.clamp(0, 1).toDouble(),
        );
        return Material(
          color: baseColor.toColor(),
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('artist-quiz-${quiz.quiz.videoId}'),
            onTap: () => onQuizSelected(quiz.quiz.videoId),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    baseColor
                        .withLightness(
                          (baseColor.lightness + 0.22).clamp(0, 1).toDouble(),
                        )
                        .toColor(),
                    baseColor.toColor(),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        quiz.quiz.thumbnailHintType == ThumbnailHintType.lyric
                            ? Icons.music_note_rounded
                            : Icons.chat_bubble_outline_rounded,
                        size: 24,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 9),
                      Text(
                        quiz.quiz.thumbnailHint?.content ?? 'ヒントはありません',
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
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

class _ArtistSongList extends ConsumerWidget {
  const _ArtistSongList({
    required this.quizzes,
    required this.filter,
    required this.order,
    required this.onFilterChanged,
    required this.onOrderChanged,
    required this.onQuizSelected,
  });

  final List<QuizWithLiveStats> quizzes;
  final QuizFilter filter;
  final WorkOrder order;
  final ValueChanged<QuizFilter> onFilterChanged;
  final ValueChanged<WorkOrder> onOrderChanged;
  final ValueChanged<String> onQuizSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final works =
        quizzes
            .where((item) => _matchesArtistWorkFilter(item.quiz, filter))
            .toList()
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
          key: const ValueKey('artist-work-toolbar'),
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
              ? const Center(child: Text('条件に合う作品がありません'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                  itemCount: works.length,
                  itemBuilder: (context, index) {
                    final quiz = works[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: QuizSongTile(
                        key: ValueKey('artist-song-${quiz.quiz.videoId}'),
                        quiz: quiz,
                        onOpen: () => onQuizSelected(quiz.quiz.videoId),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

bool _matchesArtistWorkFilter(Quiz quiz, QuizFilter filter) {
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

class _RelatedArtistsList extends StatelessWidget {
  const _RelatedArtistsList({required this.artists, required this.onOpen});

  final List<Artist> artists;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    if (artists.isEmpty) {
      return const Center(child: Text('関連アーティストはまだありません'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      itemCount: artists.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final artist = artists[index];
        return Material(
          color: const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            key: ValueKey('related-artist-${artist.artistId}'),
            leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
            title: Text(artist.name),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => onOpen(artist.name),
          ),
        );
      },
    );
  }
}
