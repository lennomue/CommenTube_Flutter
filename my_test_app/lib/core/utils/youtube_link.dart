import 'package:url_launcher/url_launcher.dart';

enum MusicService { youtubeMusic, spotify, amazonMusic, appleMusic }

Uri youtubeWatchUri(String videoId) {
  return Uri.https('www.youtube.com', '/watch', {'v': videoId});
}

Future<bool> openYouTubeVideo(String videoId) {
  return openExternalUri(youtubeWatchUri(videoId));
}

Uri musicServiceSearchUri(MusicService service, String query) {
  return switch (service) {
    MusicService.youtubeMusic => Uri.https('music.youtube.com', '/search', {
      'q': query,
    }),
    MusicService.spotify => Uri.https('open.spotify.com', '/search/$query'),
    MusicService.amazonMusic => Uri.https('music.amazon.com', '/search/$query'),
    MusicService.appleMusic => Uri.https('music.apple.com', '/us/search', {
      'term': query,
    }),
  };
}

Future<bool> openMusicService(MusicService service, String query) {
  return openExternalUri(musicServiceSearchUri(service, query));
}

Future<bool> openExternalUri(Uri uri) {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
