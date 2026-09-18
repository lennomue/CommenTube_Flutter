class QuizFilter {
  const QuizFilter({
    this.musicGenres = const [],
    this.musicLanguages = const [],
    this.videoGenres = const [],
    this.publishedFromYear,
    this.publishedToYear,
  });

  static const empty = QuizFilter();

  final List<String> musicGenres;
  final List<String> musicLanguages;
  final List<String> videoGenres;
  final int? publishedFromYear;
  final int? publishedToYear;

  bool get isEmpty =>
      musicGenres.isEmpty &&
      musicLanguages.isEmpty &&
      videoGenres.isEmpty &&
      publishedFromYear == null &&
      publishedToYear == null;

  int get activeConditionCount =>
      musicGenres.length +
      musicLanguages.length +
      videoGenres.length +
      (publishedFromYear == null && publishedToYear == null ? 0 : 1);

  QuizFilter toggleMusicGenre(String genre) {
    return copyWith(musicGenres: _toggled(musicGenres, genre));
  }

  QuizFilter toggleMusicLanguage(String language) {
    return copyWith(musicLanguages: _toggled(musicLanguages, language));
  }

  QuizFilter toggleVideoGenre(String genre) {
    return copyWith(videoGenres: _toggled(videoGenres, genre));
  }

  QuizFilter withPublishedYears({required int? from, required int? to}) {
    return QuizFilter(
      musicGenres: musicGenres,
      musicLanguages: musicLanguages,
      videoGenres: videoGenres,
      publishedFromYear: from,
      publishedToYear: to,
    );
  }

  QuizFilter copyWith({
    List<String>? musicGenres,
    List<String>? musicLanguages,
    List<String>? videoGenres,
  }) {
    return QuizFilter(
      musicGenres: musicGenres ?? this.musicGenres,
      musicLanguages: musicLanguages ?? this.musicLanguages,
      videoGenres: videoGenres ?? this.videoGenres,
      publishedFromYear: publishedFromYear,
      publishedToYear: publishedToYear,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is QuizFilter &&
        _listEquals(musicGenres, other.musicGenres) &&
        _listEquals(musicLanguages, other.musicLanguages) &&
        _listEquals(videoGenres, other.videoGenres) &&
        publishedFromYear == other.publishedFromYear &&
        publishedToYear == other.publishedToYear;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(musicGenres),
    Object.hashAll(musicLanguages),
    Object.hashAll(videoGenres),
    publishedFromYear,
    publishedToYear,
  );
}

List<String> _toggled(List<String> values, String value) {
  final result = values.toSet();
  result.contains(value) ? result.remove(value) : result.add(value);
  return result.toList(growable: false)..sort();
}

bool _listEquals(List<String> first, List<String> second) {
  if (identical(first, second)) {
    return true;
  }
  if (first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) {
      return false;
    }
  }
  return true;
}
