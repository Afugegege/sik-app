import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sik_app/providers/app_state.dart';
import 'package:sik_app/services/ai_command_processor.dart';
import 'package:sik_app/widgets/floating_ai_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    dotenv.testLoad(fileInput: 'OPENAI_API_KEY=mock_key');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ActionPreview classification tests', () {
    test('Classifies save recipe correctly', () {
      final appState = AppState();
      final preview1 = AiCommandProcessor.classifyAction('save recipe', appState);
      expect(preview1.type, ActionPreviewType.saveRecipe);
      expect(preview1.title, 'Save recipe');

      final preview2 = AiCommandProcessor.classifyAction('save recipe Kimchi Jjigae', appState);
      expect(preview2.type, ActionPreviewType.saveRecipe);
      expect(preview2.title, 'Save recipe');
    });

    test('Classifies add inventory correctly', () {
      final appState = AppState();
      final preview = AiCommandProcessor.classifyAction('add 2 eggs and milk to fridge', appState);
      expect(preview.type, ActionPreviewType.addInventory);
      expect(preview.title, 'Add inventory');
      expect(preview.detail.contains('eggs'), isTrue);
    });

    test('Classifies shopping list addition correctly', () {
      final appState = AppState();
      final preview = AiCommandProcessor.classifyAction('buy soy sauce and garlic', appState);
      expect(preview.type, ActionPreviewType.addShopping);
      expect(preview.title, 'Add to shopping');
    });

    test('Classifies reminders and meal logs correctly', () {
      final appState = AppState();
      final rem = AiCommandProcessor.classifyAction('remind me to defrost beef in 2 hours', appState);
      expect(rem.type, ActionPreviewType.setReminder);
      expect(rem.title, 'Set reminder');

      final meal = AiCommandProcessor.classifyAction('log meal: Kimchi Fried Rice', appState);
      expect(meal.type, ActionPreviewType.logMeal);
      expect(meal.title, 'Log meal');
    });

    test('Classifies general question to openChat', () {
      final appState = AppState();
      final preview = AiCommandProcessor.classifyAction('how to bake sourdough cookies?', appState);
      expect(preview.type, ActionPreviewType.openChat);
      expect(preview.title, 'Open chat');
      expect(preview.detail, '"how to bake sourdough cookies?"');
    });
  });

  group('FloatingAiBar interactive notification bar tests', () {
    testWidgets('Typing shows action preview bar with approve and reject buttons', (tester) async {
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

      // Initially no notification bar
      expect(find.byKey(const ValueKey('action_preview_bar')), findsNothing);

      // Enter text into chat bar and submit
      await tester.enterText(find.byType(TextField), 'add 3 eggs and milk');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pumpAndSettle();

      // Action preview notification bar pops up!
      expect(find.byKey(const ValueKey('action_preview_bar')), findsOneWidget);
      expect(find.textContaining('Add inventory', findRichText: true), findsOneWidget);

      // Decline and Proceed buttons are present
      expect(find.text('Decline'), findsOneWidget);
      expect(find.text('Proceed'), findsOneWidget);

      // Tap Decline button
      await tester.tap(find.text('Decline'));
      await tester.pumpAndSettle();

      // Notification bar is dismissed and text is cleared
      expect(find.byKey(const ValueKey('action_preview_bar')), findsNothing);
      expect(find.text('add 3 eggs and milk'), findsNothing);
    });

    testWidgets('Approve button executes action and adds inventory', (tester) async {
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

      // Enter inventory command and submit
      await tester.enterText(find.byType(TextField), 'add 4 fresh avocados');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('action_preview_bar')), findsOneWidget);

      // Tap Proceed button
      await tester.tap(find.text('Proceed'));
      await tester.pumpAndSettle();

      // Notification bar dismissed, text cleared
      expect(find.byKey(const ValueKey('action_preview_bar')), findsNothing);

      // Item was added to inventory
      expect(appState.fridgeItems.any((item) => item.name.toLowerCase().contains('avocado')), isTrue);
    });
  });
}
