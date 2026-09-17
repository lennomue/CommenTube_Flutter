import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/hint_progress.dart';
import '../../../core/models/quiz.dart';
import '../../../core/repositories/quiz_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/display_formatters.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key, required this.videoId});

  final String videoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quiz = ref.watch(quizProvider(videoId));
    return quiz.when(
      data: (item) => item == null
          ? const _MissingQuizScreen()
          : _GameContent(key: ValueKey(item.quiz.videoId), quiz: item),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => const _MissingQuizScreen(),
    );
  }
}

class _GameContent extends StatefulWidget {
  const _GameContent({super.key, required this.quiz});

  final QuizWithLiveStats quiz;

  @override
  State<_GameContent> createState() => _GameContentState();
}

class _GameContentState extends State<_GameContent> {
  late final Set<String> _unlockedHintKeys;

  @override
  void initState() {
    super.initState();
    final representativeComment = widget.quiz.quiz.representativeComment;
    _unlockedHintKeys = {
      if (representativeComment != null)
        HintKey.comment(representativeComment.commentId),
    };
  }

  @override
  Widget build(BuildContext context) {
    return _GameScaffold(
      quiz: widget.quiz,
      progress: HintProgress(unlockedHintKeys: _unlockedHintKeys),
      onUnlock: (hintKey) {
        setState(() => _unlockedHintKeys.add(hintKey));
      },
    );
  }
}

class _GameScaffold extends StatelessWidget {
  const _GameScaffold({
    required this.quiz,
    required this.progress,
    required this.onUnlock,
  });

  final QuizWithLiveStats quiz;
  final HintProgress progress;
  final ValueChanged<String> onUnlock;

  @override
  Widget build(BuildContext context) {
    final data = quiz.quiz;
    return Scaffold(
      body: SafeArea(
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              _GameHeader(quiz: quiz),
              const ColoredBox(
                color: Color(0xFF111111),
                child: TabBar(
                  tabs: [
                    Tab(
                      icon: Icon(Icons.chat_bubble_outline_rounded),
                      text: 'コメント',
                    ),
                    Tab(icon: Icon(Icons.music_note_rounded), text: '歌詞'),
                    Tab(icon: Icon(Icons.info_outline_rounded), text: '楽曲情報'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _HintTabBody(
                      children: [
                        for (final indexed in quiz.comments.indexed)
                          _UnlockableHint(
                            hintKey: HintKey.comment(
                              indexed.$2.comment.commentId,
                            ),
                            label: 'コメント ${indexed.$1 + 1}',
                            progress: progress,
                            onUnlock: onUnlock,
                            child: _CommentHint(comment: indexed.$2),
                          ),
                      ],
                    ),
                    _HintTabBody(
                      children: [
                        for (final indexed in data.videoLyrics.indexed)
                          _UnlockableHint(
                            hintKey: HintKey.lyric(indexed.$1),
                            label: '歌詞 ${indexed.$1 + 1}',
                            progress: progress,
                            onUnlock: onUnlock,
                            child: _HintCard(text: indexed.$2),
                          ),
                      ],
                    ),
                    _HintTabBody(
                      children: [
                        _UnlockableHint(
                          hintKey: HintKey.videoGenre,
                          label: '動画種別',
                          progress: progress,
                          onUnlock: onUnlock,
                          child: _HintCard(
                            text: '動画種別: ${videoGenreLabel(data.videoGenre)}',
                          ),
                        ),
                        _UnlockableHint(
                          hintKey: HintKey.musicGenres,
                          label: '楽曲ジャンル',
                          progress: progress,
                          onUnlock: onUnlock,
                          child: _HintCard(
                            text:
                                'ジャンル: ${data.musicGenres.map(genreLabel).join(' / ')}',
                          ),
                        ),
                        _UnlockableHint(
                          hintKey: HintKey.musicLanguages,
                          label: '言語',
                          progress: progress,
                          onUnlock: onUnlock,
                          child: _HintCard(
                            text:
                                '言語: ${data.musicLanguages.map(languageLabel).join(' / ')}',
                          ),
                        ),
                        _UnlockableHint(
                          hintKey: HintKey.musicArtists,
                          label: 'アーティスト',
                          progress: progress,
                          onUnlock: onUnlock,
                          child: _HintCard(
                            text: 'アーティスト: ${data.musicArtists.join(' / ')}',
                          ),
                        ),
                        _UnlockableHint(
                          hintKey: HintKey.musicReleasedAt,
                          label: '楽曲リリース日',
                          progress: progress,
                          onUnlock: onUnlock,
                          child: _HintCard(
                            text: '楽曲リリース: ${formatDate(data.musicReleasedAt)}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _GameActions(videoId: data.videoId),
            ],
          ),
        ),
      ),
    );
  }
}

class _HintTabBody extends StatelessWidget {
  const _HintTabBody({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: children,
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
          const Icon(Icons.lock_outline_rounded, color: Color(0xFFFF97D7)),
          const SizedBox(width: 10),
          Expanded(child: Text('$labelは未開放です')),
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
  const _GameHeader({required this.quiz});

  final QuizWithLiveStats quiz;

  @override
  Widget build(BuildContext context) {
    final data = quiz.quiz;
    return Container(
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
                tooltip: 'ホームに戻る',
                onPressed: context.goHome,
                icon: const Icon(Icons.home_rounded),
              ),
              Text(
                data.musicGenres.isEmpty
                    ? 'ジャンル不明'
                    : genreLabel(data.musicGenres.first),
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
                  value: formatDate(data.videoPublishedAt),
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
        Icon(icon, color: const Color(0xFFFF97D7)),
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

class _GameActions extends StatelessWidget {
  const _GameActions({required this.videoId});

  final String videoId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(top: BorderSide(color: Color(0xFF333333))),
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              key: const ValueKey('answer-button'),
              onPressed: () => _answer(context),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('回答する'),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            key: const ValueKey('skip-button'),
            onPressed: () => context.goToResult(videoId),
            child: const Text('スキップ'),
          ),
        ],
      ),
    );
  }

  Future<void> _answer(BuildContext context) async {
    final isCorrect = await context.openAnswerWebView(videoId);
    if (!context.mounted || isCorrect == null) {
      return;
    }
    if (isCorrect) {
      context.goToResult(videoId);
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('不正解です。ヒントを確認してもう一度挑戦しましょう。')),
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
