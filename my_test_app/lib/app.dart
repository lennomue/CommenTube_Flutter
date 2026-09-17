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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF7E84),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF090909),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
