import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/quiz.dart';
import '../../../core/repositories/quiz_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/state/quiz_experience_controller.dart';
import 'quiz_detail_panel.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, required this.videoId});

  final String videoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quiz = ref.watch(quizProvider(videoId));
    return quiz.when(
      data: (item) => item == null
          ? const _MissingResultScreen()
          : _ResultContent(quiz: item),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => const _MissingResultScreen(),
    );
  }
}

class _ResultContent extends ConsumerWidget {
  const _ResultContent({required this.quiz});

  final QuizWithLiveStats quiz;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allQuizzes = ref.watch(quizzesProvider).value;
    final session = ref.watch(artistQuizSessionProvider);
    final usesArtistSession =
        session != null && session.currentVideoId == quiz.quiz.videoId;
    final finishesArtistSession = usesArtistSession && session.isLast;
    final nextVideoId = usesArtistSession
        ? session.nextVideoId
        : _nextVideoId(allQuizzes, quiz.quiz.videoId);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            QuizDetailPanel(
              quiz: quiz,
              bottomPadding: 130,
              onMinimize: () => _minimize(context, ref),
              onArtistOpen: (artist) => _openArtist(context, ref, artist),
              leading: IconButton(
                key: const ValueKey('minimize-result-button'),
                tooltip: 'リザルトを小さくする',
                onPressed: () => _minimize(context, ref),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: _NextQuizButton(
                label: finishesArtistSession ? 'FINISH' : 'NEXT QUIZ',
                enabled: finishesArtistSession || nextVideoId != null,
                onPressed: finishesArtistSession
                    ? () => _finishArtistSession(context, ref)
                    : nextVideoId == null
                    ? null
                    : () {
                        if (usesArtistSession) {
                          ref
                              .read(artistQuizSessionProvider.notifier)
                              .advance();
                        }
                        context.goToGame(nextVideoId);
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _nextVideoId(List<QuizWithLiveStats>? quizzes, String currentId) {
    if (quizzes == null || quizzes.length < 2) {
      return null;
    }
    final index = quizzes.indexWhere((item) => item.quiz.videoId == currentId);
    return quizzes[(index + 1) % quizzes.length].quiz.videoId;
  }

  void _minimize(BuildContext context, WidgetRef ref) {
    ref
        .read(minimizedQuizExperienceProvider.notifier)
        .minimize(QuizExperienceKind.result, quiz.quiz.videoId);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.goHome();
    }
  }

  void _openArtist(BuildContext context, WidgetRef ref, String artist) {
    final router = GoRouter.of(context);
    _minimize(context, ref);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      openArtistFromCurrentBranch(router, artist);
    });
  }

  void _finishArtistSession(BuildContext context, WidgetRef ref) {
    ref.read(artistQuizSessionProvider.notifier).clear();
    ref.read(minimizedQuizExperienceProvider.notifier).clear();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    context.goHome();
  }
}

class _NextQuizButton extends StatelessWidget {
  const _NextQuizButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('next-quiz-button'),
      color: enabled ? Colors.white : const Color(0xFF555555),
      elevation: 14,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: enabled ? Colors.black : const Color(0xFFAAAAAA),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_rounded,
                color: enabled ? Colors.black : const Color(0xFFAAAAAA),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissingResultScreen extends StatelessWidget {
  const _MissingResultScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: context.goHome,
          child: const Text('ホームに戻る'),
        ),
      ),
    );
  }
}
