import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/game/presentation/game_screen.dart';
import '../../features/game/presentation/answer_webview_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/library/presentation/artist_screen.dart';
import '../../features/result/presentation/result_screen.dart';
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
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/game/:videoId',
        name: AppRoute.game.name,
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          fullscreenDialog: true,
          child: GameScreen(videoId: state.pathParameters['videoId']!),
        ),
      ),
      GoRoute(
        path: '/result/:videoId',
        name: AppRoute.result.name,
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          fullscreenDialog: true,
          child: ResultScreen(videoId: state.pathParameters['videoId']!),
        ),
      ),
      GoRoute(
        path: '/answer/:videoId',
        name: AppRoute.answer.name,
        builder: (context, state) =>
            AnswerWebViewScreen(videoId: state.pathParameters['videoId']!),
      ),
    ],
  );
}

enum AppRoute { home, homeArtist, game, result, answer, library, libraryArtist }

extension AppRouteNavigation on BuildContext {
  void goHome() => goNamed(AppRoute.home.name);

  void openGame(String videoId) =>
      pushNamed(AppRoute.game.name, pathParameters: {'videoId': videoId});

  void goToGame(String videoId) => pushReplacementNamed(
    AppRoute.game.name,
    pathParameters: {'videoId': videoId},
  );

  void goToResult(String videoId) => pushReplacementNamed(
    AppRoute.result.name,
    pathParameters: {'videoId': videoId},
  );

  void openResult(String videoId) =>
      pushNamed(AppRoute.result.name, pathParameters: {'videoId': videoId});

  Future<bool?> openAnswerWebView(String videoId) => pushNamed<bool>(
    AppRoute.answer.name,
    pathParameters: {'videoId': videoId},
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
