import 'package:flutter_riverpod/flutter_riverpod.dart';

enum QuizExperienceKind { game, result }

class MinimizedQuizExperience {
  const MinimizedQuizExperience({required this.kind, required this.videoId});

  final QuizExperienceKind kind;
  final String videoId;
}

class MinimizedQuizExperienceController
    extends Notifier<MinimizedQuizExperience?> {
  @override
  MinimizedQuizExperience? build() => null;

  void minimize(QuizExperienceKind kind, String videoId) {
    state = MinimizedQuizExperience(kind: kind, videoId: videoId);
  }

  void clear() => state = null;
}

final minimizedQuizExperienceProvider =
    NotifierProvider<
      MinimizedQuizExperienceController,
      MinimizedQuizExperience?
    >(MinimizedQuizExperienceController.new);

class ArtistQuizSession {
  const ArtistQuizSession({
    required this.artist,
    required this.videoIds,
    required this.currentIndex,
  });

  final String artist;
  final List<String> videoIds;
  final int currentIndex;

  String get currentVideoId => videoIds[currentIndex];
  bool get isLast => currentIndex >= videoIds.length - 1;
  String? get nextVideoId => isLast ? null : videoIds[currentIndex + 1];

  ArtistQuizSession advance() {
    if (isLast) {
      return this;
    }
    return ArtistQuizSession(
      artist: artist,
      videoIds: videoIds,
      currentIndex: currentIndex + 1,
    );
  }
}

class ArtistQuizSessionController extends Notifier<ArtistQuizSession?> {
  @override
  ArtistQuizSession? build() => null;

  void start(String artist, List<String> videoIds) {
    if (videoIds.isEmpty) {
      state = null;
      return;
    }
    state = ArtistQuizSession(
      artist: artist,
      videoIds: List.unmodifiable(videoIds),
      currentIndex: 0,
    );
  }

  void advance() {
    state = state?.advance();
  }

  void clear() => state = null;
}

final artistQuizSessionProvider =
    NotifierProvider<ArtistQuizSessionController, ArtistQuizSession?>(
      ArtistQuizSessionController.new,
    );

class PlaylistQuizSession {
  const PlaylistQuizSession({
    required this.playlistId,
    required this.videoIds,
    required this.currentIndex,
  });

  final String playlistId;
  final List<String> videoIds;
  final int currentIndex;

  String get currentVideoId => videoIds[currentIndex];
  bool get isLast => currentIndex >= videoIds.length - 1;
  String? get nextVideoId => isLast ? null : videoIds[currentIndex + 1];

  PlaylistQuizSession advance() {
    if (isLast) {
      return this;
    }
    return PlaylistQuizSession(
      playlistId: playlistId,
      videoIds: videoIds,
      currentIndex: currentIndex + 1,
    );
  }
}

class PlaylistQuizSessionController extends Notifier<PlaylistQuizSession?> {
  @override
  PlaylistQuizSession? build() => null;

  void start(String playlistId, List<String> videoIds) {
    if (videoIds.isEmpty) {
      state = null;
      return;
    }
    state = PlaylistQuizSession(
      playlistId: playlistId,
      videoIds: List.unmodifiable(videoIds),
      currentIndex: 0,
    );
  }

  void advance() => state = state?.advance();

  void clear() => state = null;
}

final playlistQuizSessionProvider =
    NotifierProvider<PlaylistQuizSessionController, PlaylistQuizSession?>(
      PlaylistQuizSessionController.new,
    );
