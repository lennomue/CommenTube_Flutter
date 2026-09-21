import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/game/presentation/game_screen.dart';
import '../../features/game/presentation/answer_webview_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/library/presentation/artist_screen.dart';
import '../../features/library/presentation/playlist_screen.dart';
import '../../features/result/presentation/result_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../models/playlist.dart';
import '../widgets/app_navigation_bar.dart';

GoRouter createAppRouter() {
  return GoRouter(
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppNavigationScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: AppRoute.home.name,
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'artist/:artist',
                    name: AppRoute.homeArtist.name,
                    builder: (context, state) =>
                        ArtistScreen(artist: state.pathParameters['artist']!),
                  ),
                  GoRoute(
                    path: 'playlist/:playlistId',
                    name: AppRoute.homePlaylist.name,
                    builder: (context, state) => PlaylistScreen(
                      playlistId: state.pathParameters['playlistId']!,
                      previewPlaylist: state.extra is UserPlaylist
                          ? state.extra! as UserPlaylist
                          : null,
                    ),
                  ),
                  GoRoute(
                    path: 'search',
                    name: AppRoute.search.name,
                    builder: (context, state) => const SearchScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                name: AppRoute.library.name,
                builder: (context, state) => const LibraryScreen(),
                routes: [
                  GoRoute(
                    path: 'artist/:artist',
                    name: AppRoute.libraryArtist.name,
                    builder: (context, state) =>
                        ArtistScreen(artist: state.pathParameters['artist']!),
                  ),
                  GoRoute(
                    path: 'playlist/:playlistId',
                    name: AppRoute.libraryPlaylist.name,
                    builder: (context, state) => PlaylistScreen(
                      playlistId: state.pathParameters['playlistId']!,
                      previewPlaylist: state.extra is UserPlaylist
                          ? state.extra! as UserPlaylist
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/game/:videoId',
        name: AppRoute.game.name,
        pageBuilder: (context, state) {
          final transition = state.extra is QuizPageTransition
              ? state.extra! as QuizPageTransition
              : QuizPageTransition.fromRight;
          return _quizPage(
            state: state,
            transition: transition,
            child: GameScreen(
              videoId: state.pathParameters['videoId']!,
              restoreFromMinimized:
                  transition == QuizPageTransition.restoreFromMinimized,
            ),
          );
        },
      ),
      GoRoute(
        path: '/result/:videoId',
        name: AppRoute.result.name,
        pageBuilder: (context, state) {
          final transition = state.extra is QuizPageTransition
              ? state.extra! as QuizPageTransition
              : QuizPageTransition.fromRight;
          return _quizPage(
            state: state,
            transition: transition,
            child: ResultScreen(
              videoId: state.pathParameters['videoId']!,
              restoreFromMinimized:
                  transition == QuizPageTransition.restoreFromMinimized,
            ),
          );
        },
      ),
      GoRoute(
        path: '/answer/:videoId',
        name: AppRoute.answer.name,
        builder: (context, state) => AnswerWebViewScreen(
          videoId: state.pathParameters['videoId']!,
          searchQuery: state.uri.queryParameters['q'] ?? '',
        ),
      ),
    ],
  );
}

enum QuizPageTransition { fromRight, fromBottom, restoreFromMinimized }

CustomTransitionPage<void> _quizPage({
  required GoRouterState state,
  required QuizPageTransition transition,
  required Widget child,
}) {
  final restores = transition == QuizPageTransition.restoreFromMinimized;
  return CustomTransitionPage<void>(
    key: state.pageKey,
    opaque: false,
    transitionDuration: restores
        ? Duration.zero
        : const Duration(milliseconds: 320),
    reverseTransitionDuration: Duration.zero,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (restores) {
        return child;
      }
      final begin = transition == QuizPageTransition.fromBottom
          ? const Offset(0, 1)
          : const Offset(1, 0);
      return SlideTransition(
        position: Tween<Offset>(begin: begin, end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      );
    },
    child: child,
  );
}

enum AppRoute {
  home,
  homeArtist,
  homePlaylist,
  search,
  game,
  result,
  answer,
  library,
  libraryArtist,
  libraryPlaylist,
}

extension AppRouteNavigation on BuildContext {
  void goHome() => goNamed(AppRoute.home.name);

  void goLibrary() => goNamed(AppRoute.library.name);

  void openSearch() => pushNamed(AppRoute.search.name);

  void openGame(
    String videoId, {
    QuizPageTransition transition = QuizPageTransition.fromRight,
  }) => pushNamed(
    AppRoute.game.name,
    pathParameters: {'videoId': videoId},
    extra: transition,
  );

  void goToGame(
    String videoId, {
    QuizPageTransition transition = QuizPageTransition.fromRight,
  }) => pushReplacementNamed(
    AppRoute.game.name,
    pathParameters: {'videoId': videoId},
    extra: transition,
  );

  void goToResult(String videoId) => pushReplacementNamed(
    AppRoute.result.name,
    pathParameters: {'videoId': videoId},
    extra: QuizPageTransition.fromRight,
  );

  void openResult(
    String videoId, {
    QuizPageTransition transition = QuizPageTransition.fromRight,
  }) => pushNamed(
    AppRoute.result.name,
    pathParameters: {'videoId': videoId},
    extra: transition,
  );

  Future<bool?> openAnswerWebView(String videoId, String searchQuery) =>
      pushNamed<bool>(
        AppRoute.answer.name,
        pathParameters: {'videoId': videoId},
        queryParameters: {'q': searchQuery},
      );

  void openArtist(String artist) {
    final path = GoRouterState.of(this).uri.path;
    pushNamed(
      path.startsWith('/library')
          ? AppRoute.libraryArtist.name
          : AppRoute.homeArtist.name,
      pathParameters: {'artist': artist},
    );
  }

  void openPlaylist(String playlistId) {
    final path = GoRouterState.of(this).uri.path;
    pushNamed(
      path.startsWith('/library')
          ? AppRoute.libraryPlaylist.name
          : AppRoute.homePlaylist.name,
      pathParameters: {'playlistId': playlistId},
    );
  }

  void openPublicPlaylist(PublicPlaylist playlist) {
    final path = GoRouterState.of(this).uri.path;
    pushNamed(
      path.startsWith('/library')
          ? AppRoute.libraryPlaylist.name
          : AppRoute.homePlaylist.name,
      pathParameters: {'playlistId': playlist.id},
      extra: playlist.asUnownedPlaylist(),
    );
  }
}

void openArtistFromCurrentBranch(GoRouter router, String artist) {
  final path = router.routerDelegate.currentConfiguration.uri.path;
  router.pushNamed(
    path.startsWith('/library')
        ? AppRoute.libraryArtist.name
        : AppRoute.homeArtist.name,
    pathParameters: {'artist': artist},
  );
}
