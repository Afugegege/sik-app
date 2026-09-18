import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sik_app/providers/app_state.dart';
import 'package:sik_app/widgets/floating_ai_bar.dart';
import 'package:sik_app/widgets/kitchen_notepad_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    dotenv.testLoad(fileInput: 'OPENAI_API_KEY=mock_key');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('KitchenNotepadDialog renders minimal Korean ins memo and supports paste and send', (tester) async {
    String appliedText = '';
    String sentText = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  KitchenNotepadDialog.show(
                    context: context,
                    initialText: '500g salmon, 2 avocados',
                    onApply: (text) => appliedText = text,
                    onSend: (text) => sentText = text,
                  );
                },
                child: const Text('Open Notepad'),
              );
            },
          ),
        ),
      ),
    );

    // Open dialog
    await tester.tap(find.text('Open Notepad'));
    await tester.pumpAndSettle();

    // Verify minimal Korean ins header
    expect(find.text('MEMO'), findsOneWidget);
    expect(find.text('·  메모'), findsOneWidget);
    expect(find.text('500g salmon, 2 avocados'), findsOneWidget);

    // Verify minimal actions
    expect(find.text('Paste to bar'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);

    // Test Paste to bar button
    await tester.tap(find.text('Paste to bar'));
    await tester.pumpAndSettle();

    expect(find.text('MEMO'), findsNothing); // Dialog closed
    expect(appliedText, equals('500g salmon, 2 avocados'));
    expect(sentText, isEmpty);
  });

  testWidgets('FloatingAiBar contains notepad icon button and opens memo dialog', (tester) async {
    final appState = AppState();

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: FloatingAiBar(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find the notepad icon in the floating bar
    final notepadIconFinder = find.byIcon(Icons.edit_note_rounded);
    expect(notepadIconFinder, findsOneWidget);

    // Tap notepad icon
    await tester.tap(notepadIconFinder);
    await tester.pumpAndSettle();

    // Dialog should be open with minimal Korean ins header
    expect(find.text('MEMO'), findsOneWidget);
    expect(find.text('Paste to bar'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);

    // Close with close button
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('MEMO'), findsNothing);
  });
}
