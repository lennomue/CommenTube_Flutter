import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/quiz.dart';
import '../../../core/repositories/quiz_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/display_formatters.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzes = ref.watch(quizzesProvider);
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const _HomeHeader(),
          Expanded(
            child: quizzes.when(
              data: (items) => _QuizFeed(quizzes: items),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  _LoadError(onRetry: () => ref.invalidate(quizzesProvider)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

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
      child: const Row(
        children: [
          Icon(
            Icons.play_circle_fill_rounded,
            color: Color(0xFFFF858B),
            size: 42,
          ),
          SizedBox(width: 10),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'CommenTube',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizFeed extends StatelessWidget {
  const _QuizFeed({required this.quizzes});

  final List<QuizWithLiveStats> quizzes;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      itemCount: quizzes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final quiz = quizzes[index];
        return _QuizPreviewCard(
          key: ValueKey('quiz-card-${quiz.quiz.videoId}'),
          quiz: quiz,
          colorIndex: index,
          onTap: () => context.openGame(quiz.quiz.videoId),
        );
      },
    );
  }
}

class _QuizPreviewCard extends StatelessWidget {
  const _QuizPreviewCard({
    super.key,
    required this.quiz,
    required this.colorIndex,
    required this.onTap,
  });

  static const _accentColors = [
    Color(0xFF9D7375),
    Color(0xFF718978),
    Color(0xFF81749C),
    Color(0xFF7F8469),
    Color(0xFF697F8E),
  ];

  final QuizWithLiveStats quiz;
  final int colorIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _accentColors[colorIndex % _accentColors.length];
    final comment = quiz.representativeComment?.comment.content ?? 'ヒントはありません';

    return Material(
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
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.95,
                    colors: [accent.withValues(alpha: 0.42), Colors.black],
                  ),
                ),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 28),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F0F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            comment,
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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.62),
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
                    formatRelativeDate(quiz.quiz.videoPublishedAt),
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
