import 'package:url_launcher/url_launcher.dart';

Uri youtubeWatchUri(String videoId) {
  return Uri.https('www.youtube.com', '/watch', {'v': videoId});
}

Future<bool> openYouTubeVideo(String videoId) {
  return launchUrl(
    youtubeWatchUri(videoId),
    mode: LaunchMode.externalApplication,
  );
}
