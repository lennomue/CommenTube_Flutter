import 'package:flutter/material.dart';

import '../../../core/widgets/app_navigation_bar.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(child: Center(child: Text('ライブラリ画面'))),
      bottomNavigationBar: AppNavigationBar(selectedIndex: 1),
    );
  }
}
