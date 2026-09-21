import 'package:flutter_riverpod/flutter_riverpod.dart';

class FullscreenEditController extends Notifier<bool> {
  @override
  bool build() => false;

  void show() => state = true;

  void hide() => state = false;
}

final fullscreenEditProvider = NotifierProvider<FullscreenEditController, bool>(
  FullscreenEditController.new,
);
