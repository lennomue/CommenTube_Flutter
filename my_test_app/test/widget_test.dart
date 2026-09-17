import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_test_app/app.dart';

void main() {
  testWidgets('Home画面に5問分のプレビューを表示する', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CommenTubeApp()));
    await tester.pumpAndSettle();

    expect(find.text('CommenTube'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('quiz-card-mock_video_01')),
      findsOneWidget,
    );
    expect(find.text('ポップ'), findsOneWidget);
    expect(find.text('6711万回視聴'), findsOneWidget);
    expect(find.text('ホーム'), findsOneWidget);

    final lastCard = find.byKey(const ValueKey('quiz-card-mock_video_05'));
    await tester.scrollUntilVisible(lastCard, 500);
    expect(lastCard, findsOneWidget);
  });

  testWidgets('ボトムナビゲーションでhomeとlibraryを行き来できる', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CommenTubeApp()));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.video_library_outlined));
    await tester.pumpAndSettle();
    expect(find.text('ライブラリ画面'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('CommenTube'), findsOneWidget);
  });
}
