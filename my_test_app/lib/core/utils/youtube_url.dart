String? extractYouTubeVideoId(String? rawUrl) {
  if (rawUrl == null) {
    return null;
  }
  final uri = Uri.tryParse(rawUrl);
  if (uri == null || !_isYouTubeHost(uri.host) || uri.path != '/watch') {
    return null;
  }
  final videoId = uri.queryParameters['v'];
  return videoId == null || videoId.isEmpty ? null : videoId;
}

bool isYouTubeWatchUrl(String? rawUrl) {
  return extractYouTubeVideoId(rawUrl) != null;
}

bool isCorrectYouTubeAnswer(String? rawUrl, String expectedVideoId) {
  return extractYouTubeVideoId(rawUrl) == expectedVideoId;
}

bool _isYouTubeHost(String host) {
  final normalizedHost = host.toLowerCase();
  return normalizedHost == 'youtube.com' ||
      normalizedHost.endsWith('.youtube.com');
}
