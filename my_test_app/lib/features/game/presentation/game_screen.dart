import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/hint_progress.dart';
import '../../../core/models/quiz.dart';
import '../../../core/repositories/quiz_providers.dart';
import '../../../core/repositories/quiz_history_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/state/quiz_experience_controller.dart';
import '../../../core/utils/display_formatters.dart';
import '../../../core/widgets/minimizable_page_surface.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.videoId});

  final String videoId;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  bool _recordedHistory = false;

  @override
  Widget build(BuildContext context) {
    final quiz = ref.watch(quizProvider(widget.videoId));
    return quiz.when(
      data: (item) {
        if (item == null) {
          return const _MissingQuizScreen();
        }
        _recordHistoryOnce(item.quiz.videoId);
        void minimize() {
          ref
              .read(minimizedQuizExperienceProvider.notifier)
              .minimize(QuizExperienceKind.game, item.quiz.videoId);
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.goHome();
          }
        }

        return MinimizablePageSurface(
          dragRegionHeight: 165,
          onMinimize: minimize,
          child: _GameContent(
            key: ValueKey(item.quiz.videoId),
            quiz: item,
            onMinimize: minimize,
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => const _MissingQuizScreen(),
    );
  }

  void _recordHistoryOnce(String videoId) {
    if (_recordedHistory) {
      return;
    }
    _recordedHistory = true;
    ref.read(quizHistoryRepositoryProvider).recordPlay(videoId);
  }
}

class _GameContent extends StatefulWidget {
  const _GameContent({super.key, required this.quiz, required this.onMinimize});

  final QuizWithLiveStats quiz;
  final VoidCallback onMinimize;

  @override
  State<_GameContent> createState() => _GameContentState();
}

class _GameContentState extends State<_GameContent> {
  late final Set<String> _unlockedHintKeys;
  bool _isCompact = false;
  _AnswerFeedback? _feedback;

  @override
  void initState() {
    super.initState();
    final data = widget.quiz.quiz;
    _unlockedHintKeys = {
      if (data.thumbnailHintType == ThumbnailHintType.comment &&
          data.comments.isNotEmpty)
        HintKey.comment(data.comments.first.commentId),
      if (data.thumbnailHintType == ThumbnailHintType.lyric &&
          data.musicLyrics.isNotEmpty)
        HintKey.lyric(0),
    };
  }

  @override
  Widget build(BuildContext context) {
    final quiz = widget.quiz;
    final data = quiz.quiz;
    final progress = HintProgress(unlockedHintKeys: _unlockedHintKeys);
    return Scaffold(
      body: SafeArea(
        child: DefaultTabController(
          length: 3,
          child: Stack(
            children: [
              Column(
                children: [
                  _GameHeader(quiz: quiz, onMinimize: widget.onMinimize),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    alignment: Alignment.topCenter,
                    child: _isCompact
                        ? const SizedBox(width: double.infinity)
                        : const ColoredBox(
                            key: ValueKey('game-hint-tabs'),
                            color: Color(0xFF111111),
                            child: TabBar(
                              tabs: [
                                Tab(
                                  icon: Icon(Icons.chat_bubble_outline_rounded),
                                  text: 'コメント',
                                ),
                                Tab(
                                  icon: Icon(Icons.music_note_rounded),
                                  text: '歌詞',
                                ),
                                Tab(
                                  icon: Icon(Icons.info_outline_rounded),
                                  text: '楽曲情報',
                                ),
                              ],
                            ),
                          ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _HintTabBody(
                          onScrollDirection: _handleScrollDirection,
                          children: [
                            for (final indexed in quiz.comments.indexed)
                              _UnlockableHint(
                                hintKey: HintKey.comment(
                                  indexed.$2.comment.commentId,
                                ),
                                label: 'コメント ${indexed.$1 + 1}',
                                progress: progress,
                                onUnlock: _unlock,
                                child: _CommentHint(comment: indexed.$2),
                              ),
                          ],
                        ),
                        _HintTabBody(
                          onScrollDirection: _handleScrollDirection,
                          children: [
                            for (final indexed in data.musicLyrics.indexed)
                              _UnlockableHint(
                                hintKey: HintKey.lyric(indexed.$1),
                                label: '歌詞 ${indexed.$1 + 1}',
                                progress: progress,
                                onUnlock: _unlock,
                                child: _HintCard(text: indexed.$2),
                              ),
                          ],
                        ),
                        _HintTabBody(
                          onScrollDirection: _handleScrollDirection,
                          children: [
                            _UnlockableHint(
                              hintKey: HintKey.videoGenre,
                              label: '動画種別',
                              progress: progress,
                              onUnlock: _unlock,
                              child: _HintCard(
                                text:
                                    '動画種別: ${videoGenreLabel(data.videoGenre)}',
                              ),
                            ),
                            _UnlockableHint(
                              hintKey: HintKey.contentGenres,
                              label: '内容ジャンル',
                              progress: progress,
                              onUnlock: _unlock,
                              child: _HintCard(
                                text:
                                    'ジャンル: ${data.contentGenres.map(genreLabel).join(' / ')}',
                              ),
                            ),
                            _UnlockableHint(
                              hintKey: HintKey.languages,
                              label: '言語',
                              progress: progress,
                              onUnlock: _unlock,
                              child: _HintCard(
                                text:
                                    '言語: ${data.languages.map(languageLabel).join(' / ')}',
                              ),
                            ),
                            _UnlockableHint(
                              hintKey: HintKey.artists,
                              label: 'アーティスト',
                              progress: progress,
                              onUnlock: _unlock,
                              child: _HintCard(
                                text: 'アーティスト: ${data.artistNames.join(' / ')}',
                              ),
                            ),
                            _UnlockableHint(
                              hintKey: HintKey.musicReleasedAt,
                              label: '楽曲リリース日',
                              progress: progress,
                              onUnlock: _unlock,
                              child: _HintCard(
                                text:
                                    '楽曲リリース: ${formatPartialDate(data.musicReleasedAt)}',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _FloatingGameActions(
                compact: _isCompact,
                onAnswer: _answer,
                onSkip: () => context.goToResult(data.videoId),
              ),
              if (_feedback != null) _AnswerFeedbackOverlay(_feedback!),
            ],
          ),
        ),
      ),
    );
  }

  void _unlock(String hintKey) {
    setState(() => _unlockedHintKeys.add(hintKey));
  }

  void _handleScrollDirection(ScrollDirection direction) {
    final compact = direction == ScrollDirection.reverse;
    if (direction == ScrollDirection.idle || compact == _isCompact) {
      return;
    }
    setState(() => _isCompact = compact);
  }

  Future<void> _answer() async {
    final isCorrect = await context.openAnswerWebView(widget.quiz.quiz.videoId);
    if (!mounted || isCorrect == null) {
      return;
    }
    setState(() {
      _feedback = isCorrect
          ? _AnswerFeedback.correct
          : _AnswerFeedback.incorrect;
    });
    await Future<void>.delayed(Duration(milliseconds: isCorrect ? 700 : 1000));
    if (!mounted) {
      return;
    }
    if (isCorrect) {
      context.goToResult(widget.quiz.quiz.videoId);
      return;
    }
    setState(() => _feedback = null);
  }
}

class _HintTabBody extends StatelessWidget {
  const _HintTabBody({required this.children, required this.onScrollDirection});

  final List<Widget> children;
  final ValueChanged<ScrollDirection> onScrollDirection;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        onScrollDirection(notification.direction);
        return false;
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 156),
        children: children,
      ),
    );
  }
}

class _UnlockableHint extends StatelessWidget {
  const _UnlockableHint({
    required this.hintKey,
    required this.label,
    required this.progress,
    required this.onUnlock,
    required this.child,
  });

  final String hintKey;
  final String label;
  final HintProgress progress;
  final ValueChanged<String> onUnlock;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (progress.isUnlocked(hintKey)) {
      return child;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          const SizedBox(width: 10),
          FilledButton(
            key: ValueKey('unlock-$hintKey'),
            onPressed: () => onUnlock(hintKey),
            child: const Text('開放'),
          ),
        ],
      ),
    );
  }
}

class _GameHeader extends StatelessWidget {
  const _GameHeader({required this.quiz, required this.onMinimize});

  final QuizWithLiveStats quiz;
  final VoidCallback onMinimize;

  @override
  Widget build(BuildContext context) {
    final data = quiz.quiz;
    return Container(
      key: const ValueKey('game-minimize-area'),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF505050), Color(0xFF151515)],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                key: const ValueKey('minimize-game-button'),
                tooltip: 'ゲームを小さくする',
                onPressed: onMinimize,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
              Text(
                data.contentGenres.isEmpty
                    ? 'ジャンル不明'
                    : genreLabel(data.contentGenres.first),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.play_circle_outline_rounded,
                  value: formatCompactCount(quiz.videoStats.viewCount),
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.thumb_up_alt_outlined,
                  value: formatCompactCount(quiz.videoStats.likeCount),
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.calendar_month_outlined,
                  value: formatDate(data.postedAt),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _CommentHint extends StatelessWidget {
  const _CommentHint({required this.comment});

  final QuizCommentWithStats comment;

  @override
  Widget build(BuildContext context) {
    return _HintCard(
      text: comment.comment.content,
      footer:
          '♡ ${formatCompactCount(comment.likeCount)}  ${formatRelativeDate(comment.comment.commentedAt)}',
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.text, this.footer});

  final String text;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text),
          if (footer != null) ...[
            const SizedBox(height: 8),
            Text(
              footer!,
              style: const TextStyle(color: Color(0xFFB8B8B8), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _FloatingGameActions extends StatelessWidget {
  const _FloatingGameActions({
    required this.compact,
    required this.onAnswer,
    required this.onSkip,
  });

  final bool compact;
  final VoidCallback onAnswer;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final answerSize = compact ? 62.0 : 112.0;
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              left: 0,
              right: 0,
              bottom: compact ? 12 : 24,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Semantics(
                  button: true,
                  label: '回答する',
                  child: Material(
                    key: const ValueKey('answer-button'),
                    color: Colors.white,
                    elevation: 12,
                    shadowColor: Colors.black,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onAnswer,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        width: answerSize,
                        height: answerSize,
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: compact
                              ? const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.black,
                                  size: 34,
                                )
                              : const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.black,
                                      size: 38,
                                    ),
                                    Text(
                                      'ANSWER',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 20,
              child: Semantics(
                button: true,
                label: 'スキップ',
                child: Material(
                  key: const ValueKey('skip-button'),
                  color: const Color(0xFF303030),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onSkip,
                    child: const SizedBox.square(
                      dimension: 50,
                      child: Icon(
                        Icons.skip_next_rounded,
                        color: Color(0xFFBEBEBE),
                      ),
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
}

enum _AnswerFeedback { correct, incorrect }

class _AnswerFeedbackOverlay extends StatelessWidget {
  const _AnswerFeedbackOverlay(this.feedback);

  final _AnswerFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final correct = feedback == _AnswerFeedback.correct;
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xE8000000),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                correct ? Icons.circle_outlined : Icons.close_rounded,
                size: 104,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              Text(
                correct ? '正解！' : '不正解',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (!correct) ...[
                const SizedBox(height: 10),
                const Text(
                  'ヒントを確認して、もう一度挑戦しましょう',
                  style: TextStyle(color: Color(0xFFCCCCCC)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MissingQuizScreen extends StatelessWidget {
  const _MissingQuizScreen();

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
