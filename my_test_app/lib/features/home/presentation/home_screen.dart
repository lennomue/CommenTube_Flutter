import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/app_navigation_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<List<QuizPreview>> _quizPreviews;

  @override
  void initState() {
    super.initState();
    _quizPreviews = _loadQuizPreviews();
  }

  Future<List<QuizPreview>> _loadQuizPreviews() async {
    final source = await rootBundle.loadString('assets/data/quizzes.json');
    final data = jsonDecode(source) as List<dynamic>;
    return data
        .map((item) => QuizPreview.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _HomeHeader(),
            Expanded(
              child: FutureBuilder<List<QuizPreview>>(
                future: _quizPreviews,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('問題データを読み込めませんでした'));
                  }

                  final quizzes = snapshot.data;
                  if (quizzes == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                    itemCount: quizzes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      return _QuizPreviewCard(
                        key: ValueKey('quiz-card-${quizzes[index].videoId}'),
                        quiz: quizzes[index],
                        colorIndex: index,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppNavigationBar(selectedIndex: 0),
    );
  }
}

class QuizPreview {
  const QuizPreview({
    required this.videoId,
    required this.musicGenre,
    required this.videoViewCount,
    required this.videoPublishedAt,
  });

  factory QuizPreview.fromJson(Map<String, dynamic> json) {
    return QuizPreview(
      videoId: json['video_id'] as String,
      musicGenre: (json['music_genre'] as List<dynamic>).cast<String>(),
      videoViewCount: json['video_view_count'] as int,
      videoPublishedAt: DateTime.parse(json['video_published_at'] as String),
    );
  }

  final String videoId;
  final List<String> musicGenre;
  final int videoViewCount;
  final DateTime videoPublishedAt;
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
          Text(
            'CommenTube',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _QuizPreviewCard extends StatelessWidget {
  const _QuizPreviewCard({
    super.key,
    required this.quiz,
    required this.colorIndex,
  });

  static const _accentColors = [
    Color(0xFF9D7375),
    Color(0xFF718978),
    Color(0xFF81749C),
    Color(0xFF7F8469),
    Color(0xFF697F8E),
  ];

  final QuizPreview quiz;
  final int colorIndex;

  @override
  Widget build(BuildContext context) {
    final accent = _accentColors[colorIndex % _accentColors.length];
    final genre = quiz.musicGenre.isEmpty
        ? 'ジャンル不明'
        : _genreLabel(quiz.musicGenre.first);

    return Material(
      color: const Color(0xFF141414),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
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
                child: FractionallySizedBox(
                  widthFactor: 0.62,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F0F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.headphones_rounded,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            genre,
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
            child: Row(
              children: [
                const Icon(Icons.play_circle_outline_rounded, size: 28),
                const SizedBox(width: 12),
                Text(
                  _formatViewCount(quiz.videoViewCount),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 18),
                Text(
                  _formatPublishedAge(quiz.videoPublishedAt),
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
    );
  }

  String _genreLabel(String genre) {
    return switch (genre) {
      'pop' => 'ポップ',
      'rock' => 'ロック',
      'r_and_b_soul' => 'R&B・ソウル',
      'anime_soundtrack' => 'アニメ・サントラ',
      'hiphop' => 'ヒップホップ',
      _ => genre,
    };
  }

  String _formatViewCount(int count) {
    if (count >= 100000000) {
      final value = count / 100000000;
      final text = value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(1);
      return '$text億回視聴';
    }
    if (count >= 10000) {
      return '${(count / 10000).round()}万回視聴';
    }
    return '$count回視聴';
  }

  String _formatPublishedAge(DateTime publishedAt) {
    final years = DateTime.now().difference(publishedAt).inDays ~/ 365;
    return years < 1 ? '1年以内' : '$years年前';
  }
}
