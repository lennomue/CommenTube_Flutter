import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/game/presentation/game_screen.dart';
import '../../features/game/presentation/answer_webview_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/result/presentation/result_screen.dart';

GoRouter createAppRouter() {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: AppRoute.home.name,
        builder: (context, state) => const HomeScreen(),
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
      GoRoute(
        path: '/library',
        name: AppRoute.library.name,
        builder: (context, state) => const LibraryScreen(),
      ),
    ],
  );
}

enum AppRoute { home, game, result, answer, library }

extension AppRouteNavigation on BuildContext {
  void goTo(AppRoute route) => goNamed(route.name);

  void goHome() => goNamed(AppRoute.home.name);

  void goToGame(String videoId) =>
      goNamed(AppRoute.game.name, pathParameters: {'videoId': videoId});

  void goToResult(String videoId) =>
      goNamed(AppRoute.result.name, pathParameters: {'videoId': videoId});

  Future<bool?> openAnswerWebView(String videoId) => pushNamed<bool>(
    AppRoute.answer.name,
    pathParameters: {'videoId': videoId},
  );
}
