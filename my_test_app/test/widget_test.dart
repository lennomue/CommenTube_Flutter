import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_test_app/main.dart';

void main() {
  testWidgets('Home画面に5問分のプレビューを表示する', (tester) async {
    await tester.pumpWidget(const CommenTubeApp());
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
}
