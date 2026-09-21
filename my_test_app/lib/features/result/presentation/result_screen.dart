import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/quiz.dart';
import '../../../core/repositories/quiz_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/state/quiz_experience_controller.dart';
import '../../../core/widgets/minimizable_page_surface.dart';
import 'quiz_detail_panel.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({
    super.key,
    required this.videoId,
    this.restoreFromMinimized = false,
  });

  final String videoId;
  final bool restoreFromMinimized;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quiz = ref.watch(quizProvider(videoId));
    return quiz.when(
      data: (item) => item == null
          ? const _MissingResultScreen()
          : _ResultContent(
              quiz: item,
              restoreFromMinimized: restoreFromMinimized,
            ),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => const _MissingResultScreen(),
    );
  }
}

class _ResultContent extends ConsumerStatefulWidget {
  const _ResultContent({
    required this.quiz,
    required this.restoreFromMinimized,
  });

  final QuizWithLiveStats quiz;
  final bool restoreFromMinimized;

  @override
  ConsumerState<_ResultContent> createState() => _ResultContentState();
}

class _ResultContentState extends ConsumerState<_ResultContent> {
  bool _isFinishing = false;

  @override
  Widget build(BuildContext context) {
    final quiz = widget.quiz;
    final allQuizzes = ref.watch(quizzesProvider).value;
    final session = ref.watch(artistQuizSessionProvider);
    final playlistSession = ref.watch(playlistQuizSessionProvider);
    final usesArtistSession =
        session != null && session.currentVideoId == quiz.quiz.videoId;
    final usesPlaylistSession =
        playlistSession != null &&
        playlistSession.currentVideoId == quiz.quiz.videoId;
    final finishesSequence =
        (usesArtistSession && session.isLast) ||
        (usesPlaylistSession && playlistSession.isLast);
    final nextVideoId = usesPlaylistSession
        ? playlistSession.nextVideoId
        : usesArtistSession
        ? session.nextVideoId
        : _nextVideoId(allQuizzes, quiz.quiz.videoId);
    final minimizeController = MinimizablePageController();
    return AnimatedSlide(
      key: const ValueKey('result-finish-slide'),
      offset: _isFinishing ? const Offset(0, -1.08) : Offset.zero,
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeInCubic,
      child: IgnorePointer(
        ignoring: _isFinishing,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: QuizDetailPanel(
              quiz: quiz,
              bottomPadding: 150,
              minimizeController: minimizeController,
              animateFromMinimized: widget.restoreFromMinimized,
              onMinimize: () => _minimize(context, ref),
              onArtistOpen: (artist) => _openArtist(context, ref, artist),
              onQuizOpen: (videoId) => _openRelated(context, ref, videoId),
              leading: IconButton(
                key: const ValueKey('minimize-result-button'),
                tooltip: 'リザルトを小さくする',
                onPressed: minimizeController.minimize,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
              bodyOverlay: Positioned(
                left: 18,
                right: 18,
                bottom: 30,
                child: _NextQuizButton(
                  label: finishesSequence ? 'FINISH' : 'NEXT QUIZ',
                  enabled: finishesSequence || nextVideoId != null,
                  onPressed: finishesSequence
                      ? _finishSequence
                      : nextVideoId == null
                      ? null
                      : () {
                          if (usesArtistSession) {
                            ref
                                .read(artistQuizSessionProvider.notifier)
                                .advance();
                          }
                          if (usesPlaylistSession) {
                            ref
                                .read(playlistQuizSessionProvider.notifier)
                                .advance();
                          }
                          context.goToGame(
                            nextVideoId,
                            transition: QuizPageTransition.fromBottom,
                          );
                        },
                ),
              ),
            ),
          ),
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
        .minimize(QuizExperienceKind.result, widget.quiz.quiz.videoId);
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

  void _openRelated(BuildContext context, WidgetRef ref, String videoId) {
    ref.read(artistQuizSessionProvider.notifier).clear();
    ref.read(playlistQuizSessionProvider.notifier).clear();
    ref.read(minimizedQuizExperienceProvider.notifier).clear();
    context.goToGame(videoId);
  }

  Future<void> _finishSequence() async {
    if (_isFinishing) {
      return;
    }
    setState(() => _isFinishing = true);
    await Future<void>.delayed(const Duration(milliseconds: 340));
    if (!mounted) {
      return;
    }
    ref.read(artistQuizSessionProvider.notifier).clear();
    ref.read(playlistQuizSessionProvider.notifier).clear();
    ref.read(minimizedQuizExperienceProvider.notifier).clear();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    context.goHome();
  }
}

class _NextQuizButton extends StatefulWidget {
  const _NextQuizButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  State<_NextQuizButton> createState() => _NextQuizButtonState();
}

class _NextQuizButtonState extends State<_NextQuizButton> {
  double _pullDistance = 0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final progress = (_pullDistance / 72).clamp(0.0, 1.0);
    final foreground = widget.enabled ? Colors.black : const Color(0xFFAAAAAA);
    return GestureDetector(
      key: const ValueKey('next-quiz-button'),
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: widget.enabled
          ? (_) => setState(() => _isDragging = true)
          : null,
      onVerticalDragUpdate: widget.enabled
          ? (details) => setState(
              () => _pullDistance = (_pullDistance - details.delta.dy).clamp(
                0.0,
                104.0,
              ),
            )
          : null,
      onVerticalDragCancel: widget.enabled ? _reset : null,
      onVerticalDragEnd: widget.enabled
          ? (details) {
              final commits =
                  progress >= 0.45 || (details.primaryVelocity ?? 0) < -500;
              if (commits) {
                widget.onPressed?.call();
              }
              _reset();
            }
          : null,
      child: AnimatedContainer(
        key: const ValueKey('next-quiz-stretch'),
        duration: _isDragging
            ? Duration.zero
            : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 72 + _pullDistance,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 62 + _pullDistance,
              child: Material(
                color: widget.enabled ? Colors.white : const Color(0xFF555555),
                elevation: 14,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                child: Center(
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  key: const ValueKey('next-quiz-handle'),
                  color: widget.enabled
                      ? Colors.white
                      : const Color(0xFF555555),
                  elevation: 0,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: SizedBox(
                    width: 54,
                    height: 24,
                    child: Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: foreground,
                      size: 25,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reset() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isDragging = false;
      _pullDistance = 0;
    });
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
