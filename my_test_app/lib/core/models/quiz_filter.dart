class QuizFilter {
  const QuizFilter({
    this.contentGenres = const [],
    this.languages = const [],
    this.videoGenres = const [],
    this.artists = const [],
    this.publishedFromYear,
    this.publishedToYear,
  });

  static const empty = QuizFilter();

  final List<String> contentGenres;
  final List<String> languages;
  final List<String> videoGenres;
  final List<String> artists;
  final int? publishedFromYear;
  final int? publishedToYear;

  bool get isEmpty =>
      contentGenres.isEmpty &&
      languages.isEmpty &&
      videoGenres.isEmpty &&
      artists.isEmpty &&
      publishedFromYear == null &&
      publishedToYear == null;

  int get activeConditionCount =>
      contentGenres.length +
      languages.length +
      videoGenres.length +
      artists.length +
      (publishedFromYear == null && publishedToYear == null ? 0 : 1);

  QuizFilter toggleContentGenre(String genre) {
    return copyWith(contentGenres: _toggled(contentGenres, genre));
  }

  QuizFilter toggleLanguage(String language) {
    return copyWith(languages: _toggled(languages, language));
  }

  QuizFilter toggleVideoGenre(String genre) {
    return copyWith(videoGenres: _toggled(videoGenres, genre));
  }

  QuizFilter withPublishedYears({required int? from, required int? to}) {
    return QuizFilter(
      contentGenres: contentGenres,
      languages: languages,
      videoGenres: videoGenres,
      artists: artists,
      publishedFromYear: from,
      publishedToYear: to,
    );
  }

  QuizFilter copyWith({
    List<String>? contentGenres,
    List<String>? languages,
    List<String>? videoGenres,
    List<String>? artists,
  }) {
    return QuizFilter(
      contentGenres: contentGenres ?? this.contentGenres,
      languages: languages ?? this.languages,
      videoGenres: videoGenres ?? this.videoGenres,
      artists: artists ?? this.artists,
      publishedFromYear: publishedFromYear,
      publishedToYear: publishedToYear,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is QuizFilter &&
        _listEquals(contentGenres, other.contentGenres) &&
        _listEquals(languages, other.languages) &&
        _listEquals(videoGenres, other.videoGenres) &&
        _listEquals(artists, other.artists) &&
        publishedFromYear == other.publishedFromYear &&
        publishedToYear == other.publishedToYear;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(contentGenres),
    Object.hashAll(languages),
    Object.hashAll(videoGenres),
    Object.hashAll(artists),
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
