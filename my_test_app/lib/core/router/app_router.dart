import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/game/presentation/game_screen.dart';
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
        path: '/game',
        name: AppRoute.game.name,
        builder: (context, state) => const GameScreen(),
      ),
      GoRoute(
        path: '/result',
        name: AppRoute.result.name,
        builder: (context, state) => const ResultScreen(),
      ),
      GoRoute(
        path: '/library',
        name: AppRoute.library.name,
        builder: (context, state) => const LibraryScreen(),
      ),
    ],
  );
}

enum AppRoute { home, game, result, library }

extension AppRouteNavigation on BuildContext {
  void goTo(AppRoute route) => goNamed(route.name);
}
