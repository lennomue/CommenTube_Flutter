import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import '../state/quiz_experience_controller.dart';

class AppNavigationScaffold extends ConsumerWidget {
  const AppNavigationScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minimized = ref.watch(minimizedQuizExperienceProvider);
    return Scaffold(
      body: Stack(
        children: [
          navigationShell,
          if (minimized != null)
            Positioned(
              right: 16,
              bottom: 14,
              child: _MinimizedExperienceButton(
                experience: minimized,
                onPressed: () {
                  ref.read(minimizedQuizExperienceProvider.notifier).clear();
                  switch (minimized.kind) {
                    case QuizExperienceKind.game:
                      context.openGame(minimized.videoId);
                    case QuizExperienceKind.result:
                      context.openResult(minimized.videoId);
                  }
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(index, initialLocation: true);
        },
      ),
    );
  }
}

class _MinimizedExperienceButton extends StatelessWidget {
  const _MinimizedExperienceButton({
    required this.experience,
    required this.onPressed,
  });

  final MinimizedQuizExperience experience;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isGame = experience.kind == QuizExperienceKind.game;
    return Material(
      key: const ValueKey('minimized-experience-button'),
      color: Colors.white,
      elevation: 14,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox.square(
          dimension: 58,
          child: Icon(
            isGame ? Icons.question_mark_rounded : Icons.music_note_rounded,
            color: Colors.black,
            size: 29,
          ),
        ),
      ),
    );
  }
}

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xF2161616),
      child: SafeArea(
        top: false,
        child: SizedBox(
          key: const ValueKey('app-navigation-bar'),
          height: 40,
          child: Row(
            children: [
              Expanded(
                child: _NavigationIcon(
                  tooltip: 'ホーム',
                  selected: selectedIndex == 0,
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  onPressed: () => onDestinationSelected(0),
                ),
              ),
              Expanded(
                child: _NavigationIcon(
                  tooltip: 'ライブラリ',
                  selected: selectedIndex == 1,
                  icon: Icons.video_library_outlined,
                  selectedIcon: Icons.video_library_rounded,
                  onPressed: () => onDestinationSelected(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationIcon extends StatelessWidget {
  const _NavigationIcon({
    required this.tooltip,
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.onPressed,
  });

  final String tooltip;
  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: tooltip,
      child: IconButton(
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(
          selected ? selectedIcon : icon,
          color: selected ? Colors.white : const Color(0xFF8B8B8B),
          size: 25,
        ),
      ),
    );
  }
}
