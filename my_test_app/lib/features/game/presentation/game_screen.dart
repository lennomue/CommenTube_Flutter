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
import '../../../core/widgets/neon_accent.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({
    super.key,
    required this.videoId,
    this.restoreFromMinimized = false,
  });

  final String videoId;
  final bool restoreFromMinimized;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  bool _recordedHistory = false;
  bool? _isNew;

  @override
  Widget build(BuildContext context) {
    final quiz = ref.watch(quizProvider(widget.videoId));
    final history = ref.watch(quizHistoryProvider);
    return quiz.when(
      data: (item) {
        if (item == null) {
          return const _MissingQuizScreen();
        }
        if (_isNew == null) {
          final records = history.value;
          if (records == null && history.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          _isNew = !(records ?? const []).any(
            (record) => record.videoId == widget.videoId,
          );
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

        return _GameContent(
          key: ValueKey(item.quiz.videoId),
          quiz: item,
          onMinimize: minimize,
          restoreFromMinimized: widget.restoreFromMinimized,
          isNew: _isNew ?? false,
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
  const _GameContent({
    super.key,
    required this.quiz,
    required this.onMinimize,
    required this.restoreFromMinimized,
    required this.isNew,
  });

  final QuizWithLiveStats quiz;
  final VoidCallback onMinimize;
  final bool restoreFromMinimized;
  final bool isNew;

  @override
  State<_GameContent> createState() => _GameContentState();
}

class _GameContentState extends State<_GameContent> {
  late final Set<String> _unlockedHintKeys;
  late final MinimizablePageController _minimizeController;
  late final TextEditingController _answerSearchController;
  late final FocusNode _answerSearchFocusNode;
  bool _isCompact = false;
  bool _isAnswerInputOpen = false;
  double _answerPullDistance = 0;
  double _answerCloseDistance = 0;
  _AnswerFeedback? _feedback;

  @override
  void initState() {
    super.initState();
    _minimizeController = MinimizablePageController();
    _answerSearchController = TextEditingController();
    _answerSearchFocusNode = FocusNode();
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
  void dispose() {
    _answerSearchController.dispose();
    _answerSearchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quiz = widget.quiz;
    final data = quiz.quiz;
    final progress = HintProgress(unlockedHintKeys: _unlockedHintKeys);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            DefaultTabController(
              length: 3,
              initialIndex: data.thumbnailHintType == ThumbnailHintType.lyric
                  ? 1
                  : 0,
              child: MinimizablePageSurface(
                controller: _minimizeController,
                topHeight: 200,
                onMinimize: widget.onMinimize,
                animateFromMinimized: widget.restoreFromMinimized,
                foreground: Stack(
                  children: [
                    if (_isAnswerInputOpen)
                      Positioned.fill(
                        child: GestureDetector(
                          key: const ValueKey('answer-input-dismiss-area'),
                          behavior: HitTestBehavior.opaque,
                          onTap: _closeAnswerInput,
                        ),
                      ),
                    _FloatingGameActions(
                      compact: _isCompact,
                      isInputOpen: _isAnswerInputOpen,
                      pullDistance: _answerPullDistance,
                      closeDistance: _answerCloseDistance,
                      searchController: _answerSearchController,
                      searchFocusNode: _answerSearchFocusNode,
                      onPullUpdate: _handleAnswerPullUpdate,
                      onPullEnd: _handleAnswerPullEnd,
                      onClosePullUpdate: _handleAnswerClosePullUpdate,
                      onClosePullEnd: _handleAnswerClosePullEnd,
                      onSearch: () =>
                          _answer(_answerSearchController.text.trim()),
                      onSkip: () => context.goToResult(data.videoId),
                    ),
                  ],
                ),
                top: ColoredBox(
                  color: const Color(0xFF111111),
                  child: Column(
                    children: [
                      _GameHeader(
                        quiz: quiz,
                        onMinimize: _minimizeController.minimize,
                      ),
                      ColoredBox(
                        key: ValueKey('game-hint-tabs'),
                        color: Color(0xFF111111),
                        child: TabBar(
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: widget.isNew
                              ? const NeonTabIndicator()
                              : const UnderlineTabIndicator(
                                  borderSide: BorderSide(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
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
                              text: '作品情報',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                body: ColoredBox(
                  color: const Color(0xFF090909),
                  child: Stack(
                    children: [
                      TabBarView(
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
                                  text:
                                      'アーティスト: ${data.artistNames.join(' / ')}',
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
                    ],
                  ),
                ),
              ),
            ),
            if (_feedback != null) _AnswerFeedbackOverlay(_feedback!),
          ],
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

  void _handleAnswerPullUpdate(DragUpdateDetails details) {
    if (_isAnswerInputOpen) {
      return;
    }
    setState(() {
      _answerPullDistance = (_answerPullDistance - details.delta.dy).clamp(
        0.0,
        96.0,
      );
    });
  }

  void _handleAnswerPullEnd(DragEndDetails details) {
    final opens =
        _answerPullDistance >= 42 || (details.primaryVelocity ?? 0) < -500;
    if (opens) {
      _openAnswerInput();
      return;
    }
    setState(() => _answerPullDistance = 0);
  }

  void _openAnswerInput() {
    setState(() {
      _isAnswerInputOpen = true;
      _answerPullDistance = 96;
      _answerCloseDistance = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _answerSearchFocusNode.requestFocus();
      }
    });
  }

  void _handleAnswerClosePullUpdate(DragUpdateDetails details) {
    if (!_isAnswerInputOpen) {
      return;
    }
    setState(() {
      _answerCloseDistance = (_answerCloseDistance + details.delta.dy).clamp(
        0.0,
        96.0,
      );
    });
  }

  void _handleAnswerClosePullEnd(DragEndDetails details) {
    final closes =
        _answerCloseDistance >= 34 || (details.primaryVelocity ?? 0) > 500;
    if (closes) {
      _closeAnswerInput();
      return;
    }
    setState(() => _answerCloseDistance = 0);
  }

  void _closeAnswerInput() {
    _answerSearchFocusNode.unfocus();
    _answerSearchController.clear();
    setState(() {
      _isAnswerInputOpen = false;
      _answerPullDistance = 0;
      _answerCloseDistance = 0;
    });
  }

  Future<void> _answer(String searchQuery) async {
    if (searchQuery.isEmpty) {
      return;
    }
    _answerSearchFocusNode.unfocus();
    final isCorrect = await context.openAnswerWebView(
      widget.quiz.quiz.videoId,
      searchQuery,
    );
    if (!mounted || isCorrect == null) {
      return;
    }
    _closeAnswerInput();
    setState(() {
      _feedback = isCorrect
          ? _AnswerFeedback.correct
          : _AnswerFeedback.incorrect;
    });
    await Future<void>.delayed(Duration(milliseconds: isCorrect ? 1050 : 1500));
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
    required this.isInputOpen,
    required this.pullDistance,
    required this.closeDistance,
    required this.searchController,
    required this.searchFocusNode,
    required this.onPullUpdate,
    required this.onPullEnd,
    required this.onClosePullUpdate,
    required this.onClosePullEnd,
    required this.onSearch,
    required this.onSkip,
  });

  final bool compact;
  final bool isInputOpen;
  final double pullDistance;
  final double closeDistance;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<DragUpdateDetails> onPullUpdate;
  final ValueChanged<DragEndDetails> onPullEnd;
  final ValueChanged<DragUpdateDetails> onClosePullUpdate;
  final ValueChanged<DragEndDetails> onClosePullEnd;
  final VoidCallback onSearch;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final openProgress = isInputOpen
        ? 1.0
        : (pullDistance / 96).clamp(0.0, 1.0);
    final closeProgress = (closeDistance / 96).clamp(0.0, 1.0);
    final baseSize = compact ? 62.0 : 112.0;
    final answerSize =
        baseSize + (276 - baseSize) * openProgress - (45 * closeProgress);
    final collapsedBottom = compact ? 12.0 : 24.0;
    final answerBottom =
        collapsedBottom +
        ((22 - collapsedBottom) * openProgress) -
        (28 * closeProgress);
    return Positioned.fill(
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: pullDistance > 0 && !isInputOpen
                ? Duration.zero
                : const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            bottom: answerBottom,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Semantics(
                button: true,
                label: isInputOpen ? '回答を検索' : '上にスワイプして回答',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: isInputOpen
                      ? onClosePullUpdate
                      : onPullUpdate,
                  onVerticalDragEnd: isInputOpen ? onClosePullEnd : onPullEnd,
                  child: Material(
                    key: const ValueKey('answer-button'),
                    color: Colors.white,
                    elevation: 12,
                    shadowColor: Colors.black,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: AnimatedContainer(
                      duration: pullDistance > 0 && !isInputOpen
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      width: answerSize,
                      height: answerSize,
                      alignment: Alignment.center,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: (1 - openProgress * 1.6).clamp(0, 1),
                            child: Transform.translate(
                              offset: const Offset(0, -24),
                              child: compact
                                  ? const Icon(
                                      Icons.keyboard_arrow_up_rounded,
                                      color: Colors.black,
                                      size: 34,
                                    )
                                  : const Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.keyboard_arrow_up_rounded,
                                          color: Colors.black,
                                          size: 34,
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
                          IgnorePointer(
                            ignoring: !isInputOpen,
                            child: Opacity(
                              opacity: openProgress,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isInputOpen)
                                      TextField(
                                        key: const ValueKey(
                                          'answer-search-field',
                                        ),
                                        controller: searchController,
                                        focusNode: searchFocusNode,
                                        textInputAction: TextInputAction.search,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: '検索ワード',
                                          hintStyle: TextStyle(
                                            color: Color(0xFF777777),
                                          ),
                                          filled: true,
                                          fillColor: Color(0xFFD8D8D8),
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(22),
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                        onSubmitted: (_) {
                                          if (searchController.text
                                              .trim()
                                              .isNotEmpty) {
                                            onSearch();
                                          }
                                        },
                                      )
                                    else
                                      Container(
                                        height: 39,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD8D8D8),
                                          borderRadius: BorderRadius.circular(
                                            22,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    ValueListenableBuilder<TextEditingValue>(
                                      valueListenable: searchController,
                                      builder: (context, value, child) {
                                        final enabled = value.text
                                            .trim()
                                            .isNotEmpty;
                                        return IconButton(
                                          key: const ValueKey(
                                            'open-youtube-search',
                                          ),
                                          tooltip: 'YouTubeで検索',
                                          onPressed: enabled ? onSearch : null,
                                          iconSize: 42,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 48,
                                            minHeight: 42,
                                          ),
                                          icon: Icon(
                                            Icons.smart_display_rounded,
                                            color: enabled
                                                ? const Color(0xFFFF0033)
                                                : const Color(0xFF343434),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
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
          Positioned(
            right: 16,
            bottom: 20,
            child: IgnorePointer(
              ignoring: openProgress > 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: 1 - openProgress,
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
            ),
          ),
        ],
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
          child: Transform.translate(
            offset: const Offset(0, -24),
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
