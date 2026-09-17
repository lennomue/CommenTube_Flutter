import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/quiz.dart';
import '../../../core/repositories/quiz_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/display_formatters.dart';

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
    final data = quiz.quiz;
    final allQuizzes = ref.watch(quizzesProvider).value;
    final nextVideoId = _nextVideoId(allQuizzes, data.videoId);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                key: const ValueKey('result-home-button'),
                tooltip: 'ホームに戻る',
                onPressed: context.goHome,
                icon: const Icon(Icons.home_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              data.musicTitle,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              data.musicArtists.join(' / '),
              style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 17),
            ),
            const SizedBox(height: 18),
            _ResultStats(quiz: quiz),
            const SizedBox(height: 18),
            _InfoRow(
              label: 'ジャンル',
              value: data.musicGenres.map(genreLabel).join(' / '),
            ),
            _InfoRow(label: '動画種別', value: videoGenreLabel(data.videoGenre)),
            _InfoRow(
              label: '言語',
              value: data.musicLanguages.map(languageLabel).join(' / '),
            ),
            _InfoRow(label: 'リリース', value: formatDate(data.musicReleasedAt)),
            const SizedBox(height: 18),
            const _SectionTitle(icon: Icons.chat_bubble_outline, title: 'コメント'),
            for (final comment in quiz.comments)
              _ResultCard(
                text: comment.comment.content,
                footer:
                    '♡ ${formatCompactCount(comment.likeCount)}  ${formatRelativeDate(comment.comment.commentedAt)}',
              ),
            const SizedBox(height: 10),
            const _SectionTitle(icon: Icons.music_note_rounded, title: '歌詞'),
            for (final lyric in data.videoLyrics) _ResultCard(text: lyric),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const ValueKey('next-quiz-button'),
              onPressed: nextVideoId == null
                  ? null
                  : () => context.goToGame(nextVideoId),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('次の問題へ'),
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
}

class _ResultStats extends StatelessWidget {
  const _ResultStats({required this.quiz});

  final QuizWithLiveStats quiz;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '▷ ${formatCompactCount(quiz.videoStats.viewCount)}',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              '♡ ${formatCompactCount(quiz.videoStats.likeCount)}',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              formatDate(quiz.quiz.videoPublishedAt),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFFAAAAAA)),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.text, this.footer});

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
