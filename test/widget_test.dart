import 'package:flutter_test/flutter_test.dart';
import 'package:sik_app/main.dart';

void main() {
  testWidgets('SikApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SikApp());

    // Verify that 식 logo renders.
    expect(find.text('식'), findsWidgets);
  });
}
