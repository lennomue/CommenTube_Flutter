import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/game/presentation/game_screen.dart';
import '../../features/game/presentation/answer_webview_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/library/presentation/library_screen.dart';
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
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                name: AppRoute.library.name,
                builder: (context, state) => const LibraryScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/game/:videoId',
        name: AppRoute.game.name,
        builder: (context, state) =>
            GameScreen(videoId: state.pathParameters['videoId']!),
      ),
      GoRoute(
        path: '/result/:videoId',
        name: AppRoute.result.name,
        builder: (context, state) =>
            ResultScreen(videoId: state.pathParameters['videoId']!),
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

enum AppRoute { home, game, result, answer, library }

extension AppRouteNavigation on BuildContext {
  void goHome() => goNamed(AppRoute.home.name);

  void returnHome() {
    if (canPop()) {
      pop();
      return;
    }
    goHome();
  }

  void openGame(String videoId) =>
      pushNamed(AppRoute.game.name, pathParameters: {'videoId': videoId});

  void goToGame(String videoId) =>
      goNamed(AppRoute.game.name, pathParameters: {'videoId': videoId});

  void goToResult(String videoId) =>
      goNamed(AppRoute.result.name, pathParameters: {'videoId': videoId});

  Future<bool?> openAnswerWebView(String videoId) => pushNamed<bool>(
    AppRoute.answer.name,
    pathParameters: {'videoId': videoId},
  );
}
