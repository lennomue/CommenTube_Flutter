import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../../core/utils/youtube_url.dart';

class AnswerWebViewScreen extends StatefulWidget {
  const AnswerWebViewScreen({
    super.key,
    required this.videoId,
    required this.searchQuery,
  });

  final String videoId;
  final String searchQuery;

  @override
  State<AnswerWebViewScreen> createState() => _AnswerWebViewScreenState();
}

class _AnswerWebViewScreenState extends State<AnswerWebViewScreen> {
  late final WebViewController _controller;
  String? _currentUrl;
  int _progress = 0;
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _isClosing = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const {
          PlaybackMediaTypes.audio,
          PlaybackMediaTypes.video,
        },
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params);
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF090909))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() => _progress = progress);
            }
          },
          onPageStarted: _handleUrlChanged,
          onPageFinished: (url) {
            unawaited(_prepareLoadedPage(url));
          },
          onUrlChange: (change) {
            final url = change.url;
            if (url != null) {
              _handleUrlChanged(url);
              if (isYouTubeWatchUrl(url)) {
                unawaited(_configureInlinePlayback());
              }
            }
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            final allowed =
                uri != null &&
                (uri.scheme == 'http' ||
                    uri.scheme == 'https' ||
                    uri.scheme == 'about');
            if (!allowed) {
              _showMessage('外部アプリへの遷移をブロックしました');
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              _showMessage('ページを読み込めませんでした: ${error.description}');
            }
          },
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      unawaited(
        (controller.platform as AndroidWebViewController)
            .setMediaPlaybackRequiresUserGesture(true),
      );
    }

    _controller = controller;
    final query = widget.searchQuery.trim();
    final initialUrl = query.isEmpty
        ? Uri.https('m.youtube.com', '/')
        : Uri.https('m.youtube.com', '/results', {'search_query': query});
    unawaited(_controller.loadRequest(initialUrl));
  }

  bool get _isWatchPage => isYouTubeWatchUrl(_currentUrl);

  void _handleUrlChanged(String url) {
    if (!mounted) {
      return;
    }
    setState(() => _currentUrl = url);
  }

  Future<void> _prepareLoadedPage(String url) async {
    _handleUrlChanged(url);
    if (isYouTubeWatchUrl(url)) {
      await _configureInlinePlayback();
    }
    await _refreshNavigationState();
  }

  Future<void> _configureInlinePlayback() async {
    try {
      await _controller.runJavaScript(_inlinePlaybackScript);
    } on Object {
      // Navigation can replace the JavaScript context while this runs.
    }
  }

  Future<void> _refreshNavigationState() async {
    final results = await Future.wait([
      _controller.canGoBack(),
      _controller.canGoForward(),
    ]);
    if (!mounted) {
      return;
    }
    setState(() {
      _canGoBack = results[0];
      _canGoForward = results[1];
    });
  }

  Future<void> _goBack() async {
    await _controller.goBack();
    await _refreshNavigationState();
  }

  Future<void> _goForward() async {
    await _controller.goForward();
    await _refreshNavigationState();
  }

  Future<void> _submitAnswer() async {
    if (_isSubmitting || _isClosing) {
      return;
    }
    setState(() => _isSubmitting = true);

    final currentUrl = await _controller.currentUrl();
    if (!isYouTubeWatchUrl(currentUrl)) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showMessage('動画ページのURLを検出できませんでした');
      }
      return;
    }

    final isCorrect = isCorrectYouTubeAnswer(currentUrl, widget.videoId);
    await _close(answerResult: isCorrect);
  }

  Future<void> _close({bool? answerResult}) async {
    if (_isClosing) {
      return;
    }
    setState(() => _isClosing = true);
    try {
      await _pauseAllVideos();
      await _controller.loadRequest(Uri.parse('about:blank'));
    } finally {
      if (mounted) {
        context.pop(answerResult);
      }
    }
  }

  Future<void> _pauseAllVideos() async {
    try {
      await _controller.runJavaScript(
        "document.querySelectorAll('video').forEach((video) => video.pause());",
      );
    } on Object {
      // The page may already have navigated away.
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final displayUrl = _currentUrl ?? 'YouTubeを読み込んでいます…';
    return PopScope(
      canPop: _isClosing,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          unawaited(_close());
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _AnswerHeader(onClose: () => _close(), currentUrl: displayUrl),
              if (_progress < 100)
                LinearProgressIndicator(value: _progress / 100),
              Expanded(child: WebViewWidget(controller: _controller)),
              _AnswerControls(
                canGoBack: _canGoBack,
                canGoForward: _canGoForward,
                isWatchPage: _isWatchPage,
                isSubmitting: _isSubmitting,
                onBack: _goBack,
                onForward: _goForward,
                onReload: _controller.reload,
                onAnswer: _submitAnswer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const String _inlinePlaybackScript = r'''
(() => {
  if (window.__commentubeInlineObserver) {
    window.__commentubeInlineObserver.disconnect();
  }

  let pausedInitialVideo = false;
  const configureVideo = (video) => {
    video.setAttribute('playsinline', 'true');
    video.setAttribute('webkit-playsinline', 'true');
    video.removeAttribute('autoplay');
    video.autoplay = false;

    if (!pausedInitialVideo) {
      video.pause();
      pausedInitialVideo = true;
    }
  };

  const configureAllVideos = () => {
    document.querySelectorAll('video').forEach(configureVideo);
  };

  configureAllVideos();
  window.__commentubeInlineObserver = new MutationObserver(configureAllVideos);
  window.__commentubeInlineObserver.observe(document.documentElement, {
    childList: true,
    subtree: true,
  });
})();
''';

class _AnswerHeader extends StatelessWidget {
  const _AnswerHeader({required this.onClose, required this.currentUrl});

  final VoidCallback onClose;
  final String currentUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 8),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(bottom: BorderSide(color: Color(0xFF333333))),
      ),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('close-answer-webview'),
            tooltip: '閉じる',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YouTubeで回答',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  currentUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFB8B8B8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerControls extends StatelessWidget {
  const _AnswerControls({
    required this.canGoBack,
    required this.canGoForward,
    required this.isWatchPage,
    required this.isSubmitting,
    required this.onBack,
    required this.onForward,
    required this.onReload,
    required this.onAnswer,
  });

  final bool canGoBack;
  final bool canGoForward;
  final bool isWatchPage;
  final bool isSubmitting;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onReload;
  final VoidCallback onAnswer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(top: BorderSide(color: Color(0xFF333333))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                tooltip: '戻る',
                onPressed: canGoBack ? onBack : null,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              IconButton(
                tooltip: '進む',
                onPressed: canGoForward ? onForward : null,
                icon: const Icon(Icons.arrow_forward_ios_rounded),
              ),
              IconButton(
                tooltip: '再読み込み',
                onPressed: onReload,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const ValueKey('answer-webview-action'),
              onPressed: isWatchPage && !isSubmitting ? onAnswer : null,
              child: isSubmitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isWatchPage ? 'ANSWER' : 'PLAY THE VIDEO'),
            ),
          ),
        ],
      ),
    );
  }
}
