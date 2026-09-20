import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';

class CommenTubeApp extends StatefulWidget {
  const CommenTubeApp({super.key, this.router});

  final GoRouter? router;

  @override
  State<CommenTubeApp> createState() => _CommenTubeAppState();
}

class _CommenTubeAppState extends State<CommenTubeApp> {
  late final GoRouter _router;
  late final bool _ownsRouter;

  @override
  void initState() {
    super.initState();
    _ownsRouter = widget.router == null;
    _router = widget.router ?? createAppRouter();
  }

  @override
  void dispose() {
    if (_ownsRouter) {
      _router.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'CommenTube',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          onPrimary: Colors.black,
          secondary: Color(0xFFE7E7E7),
          onSecondary: Colors.black,
          surface: Color(0xFF171717),
        ),
        scaffoldBackgroundColor: const Color(0xFF090909),
        tabBarTheme: const TabBarThemeData(
          labelColor: Colors.white,
          unselectedLabelColor: Color(0xFF8C8C8C),
          indicatorColor: Colors.white,
        ),
        chipTheme: const ChipThemeData(
          backgroundColor: Color(0xFF3A3A3A),
          selectedColor: Colors.white,
          disabledColor: Color(0xFF262626),
          labelStyle: TextStyle(color: Colors.white),
          secondaryLabelStyle: TextStyle(color: Colors.black),
          checkmarkColor: Colors.black,
          side: BorderSide.none,
          shape: StadiumBorder(),
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
