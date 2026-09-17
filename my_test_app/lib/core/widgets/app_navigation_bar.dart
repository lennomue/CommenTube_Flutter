import 'package:flutter/material.dart';

import '../router/app_router.dart';

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({super.key, required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      height: 72,
      backgroundColor: const Color(0xF2161616),
      indicatorColor: const Color(0xFF3B3B3B),
      onDestinationSelected: (index) {
        context.goTo(index == 0 ? AppRoute.home : AppRoute.library);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'ホーム',
        ),
        NavigationDestination(
          icon: Icon(Icons.video_library_outlined),
          selectedIcon: Icon(Icons.video_library),
          label: 'ライブラリ',
        ),
      ],
    );
  }
}
