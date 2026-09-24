import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/quiz.dart';
import '../../../core/models/quiz_filter.dart';
import '../../../core/repositories/quiz_providers.dart';
import '../../../core/repositories/quiz_history_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/state/home_scroll_controller.dart';
import '../../../core/state/quiz_experience_controller.dart';
import '../../../core/utils/display_formatters.dart';
import '../../../core/widgets/neon_accent.dart';
import 'home_filter_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  QuizFilter _filter = QuizFilter.empty;
  int _refreshSeed = 0;

  @override
  Widget build(BuildContext context) {
    final quizzes = ref.watch(filteredQuizzesProvider(_filter));
    final history = ref.watch(quizHistoryProvider).value ?? const [];
    final scrollController = ref.watch(homeScrollControllerProvider);
    final seenIds = history.map((item) => item.videoId).toSet();
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _HomeHeader(onSearch: context.openSearch),
          HomeFilterBar(
            filter: _filter,
            onChanged: _setFilter,
            onOpenDetails: _openDetailedFilters,
          ),
          Expanded(
            child: quizzes.when(
              data: (items) => items.isEmpty
                  ? _EmptyQuizFeed(onClear: () => _setFilter(QuizFilter.empty))
                  : RefreshIndicator(
                      onRefresh: () async {
                        setState(() => _refreshSeed++);
                      },
                      child: _QuizFeed(
                        controller: scrollController,
                        quizzes: _selectFeed(items, seenIds),
                        seenIds: seenIds,
                        onOpenQuiz: _openQuiz,
                      ),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _LoadError(
                onRetry: () => ref.invalidate(filteredQuizzesProvider(_filter)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<QuizWithLiveStats> _selectFeed(
    List<QuizWithLiveStats> items,
    Set<String> seenIds,
  ) {
    final random = Random(Object.hash(_filter, _refreshSeed));
    final unseen =
        items.where((item) => !seenIds.contains(item.quiz.videoId)).toList()
          ..shuffle(random);
    final seen =
        items.where((item) => seenIds.contains(item.quiz.videoId)).toList()
          ..shuffle(random);
    return [...unseen, ...seen].take(10).toList(growable: false);
  }

  void _setFilter(QuizFilter filter) {
    setState(() => _filter = filter);
  }

  void _openQuiz(String videoId) {
    ref.read(artistQuizSessionProvider.notifier).clear();
    ref.read(playlistQuizSessionProvider.notifier).clear();
    ref.read(minimizedQuizExperienceProvider.notifier).clear();
    context.openGame(videoId);
  }

  Future<void> _openDetailedFilters() async {
    final selected = await showDetailedQuizFilters(
      context,
      _filter,
      onChanged: (filter) {
        if (mounted) {
          _setFilter(filter);
        }
      },
    );
    if (selected != null && mounted) {
      _setFilter(selected);
    }
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF050505),
        border: Border(bottom: BorderSide(color: Color(0xFF383838))),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.play_circle_fill_rounded,
            color: Colors.white,
            size: 42,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'CommenTube',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('home-search-button'),
            tooltip: '検索',
            onPressed: onSearch,
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
    );
  }
}

class _QuizFeed extends StatelessWidget {
  const _QuizFeed({
    required this.controller,
    required this.quizzes,
    required this.seenIds,
    required this.onOpenQuiz,
  });

  final ScrollController controller;
  final List<QuizWithLiveStats> quizzes;
  final Set<String> seenIds;
  final ValueChanged<String> onOpenQuiz;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: const ValueKey('home-quiz-feed'),
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      itemCount: quizzes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final quiz = quizzes[index];
        return HomeQuizPreviewCard(
          key: ValueKey('quiz-card-${quiz.quiz.videoId}'),
          quiz: quiz,
          onTap: () => onOpenQuiz(quiz.quiz.videoId),
          isNew: !seenIds.contains(quiz.quiz.videoId),
        );
      },
    );
  }
}

class HomeQuizPreviewCard extends StatelessWidget {
  const HomeQuizPreviewCard({
    super.key,
    required this.quiz,
    required this.onTap,
    this.isNew = false,
  });

  final QuizWithLiveStats quiz;
  final VoidCallback onTap;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final atmosphere = quiz.quiz.atmosphereColor;
    final accent = HSLColor.fromAHSL(
      1,
      atmosphere.hue,
      atmosphere.saturation.clamp(0, 1).toDouble(),
      atmosphere.lightness.clamp(0, 1).toDouble(),
    ).toColor();
    final hint = quiz.quiz.thumbnailHint;

    return NeonOutline(
      enabled: isNew,
      child: Material(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: DecoratedBox(
                  key: ValueKey('quiz-thumbnail-upper-${quiz.quiz.videoId}'),
                  decoration: const BoxDecoration(color: Colors.black),
                  child: Center(
                    child: Container(
                      key: ValueKey('quiz-thumbnail-hint-${quiz.quiz.videoId}'),
                      margin: const EdgeInsets.symmetric(horizontal: 28),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hint?.type == ThumbnailHintType.lyric
                                ? Icons.music_note_rounded
                                : Icons.chat_bubble_outline_rounded,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              hint?.content ?? 'ヒントはありません',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                key: ValueKey('quiz-thumbnail-lower-${quiz.quiz.videoId}'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.78),
                      const Color(0xFF242424),
                    ],
                  ),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_circle_outline_rounded, size: 28),
                        const SizedBox(width: 10),
                        Text(
                          '${formatCompactCount(quiz.videoStats.viewCount)}回視聴',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Text(
                      formatRelativeDate(quiz.quiz.postedAt),
                      style: const TextStyle(
                        color: Color(0xFFD0D0D0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('問題データを読み込めませんでした'),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('再読み込み')),
        ],
      ),
    );
  }
}

class _EmptyQuizFeed extends StatelessWidget {
  const _EmptyQuizFeed({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 44),
            const SizedBox(height: 12),
            const Text('条件に合う問題がありません'),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onClear, child: const Text('条件をクリア')),
          ],
        ),
      ),
    );
  }
}
