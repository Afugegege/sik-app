import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sik_app/main.dart';
import 'package:sik_app/models/ai_chat_message.dart';
import 'package:sik_app/models/fridge_item.dart';
import 'package:sik_app/providers/app_state.dart';
import 'package:sik_app/screens/ai_chat_screen.dart';
import 'package:sik_app/widgets/ai_studio_recipe_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AI Chat Driven Main Screen Tests', () {
    test('AppState defaults to tabAi (tab 0)', () async {
      final appState = AppState();
      expect(AppState.tabAi, 0);
      expect(appState.activeTabIndex, AppState.tabAi);
    });

    testWidgets('SikApp launches directly into AiChatScreen on Tab 0',
        (WidgetTester tester) async {
      await tester.pumpWidget(const SikApp());
      await tester.pump();

      // Verify AiChatScreen is present as main tab
      expect(find.byType(AiChatScreen), findsOneWidget);

      // Verify the Korean stamp emblem '식' is rendered in top bar and hero
      expect(find.text('식'), findsWidgets);

      // Verify Culinary AI title and composer hint are rendered
      expect(find.text('식 (sik) Culinary AI'), findsOneWidget);
      expect(find.text('Tell AI what you have or want to make...'), findsOneWidget);
    });

    testWidgets(
        'AI prompt synthesis parses pantry ingredients into structured recipe card',
        (WidgetTester tester) async {
      final appState = AppState();
      // Add items to pantry
      appState.addFridgeItem(const FridgeItem(
        id: 'test_kimchi',
        name: 'Kimchi',
        location: StorageLocation.fridge,
      ));
      appState.addFridgeItem(const FridgeItem(
        id: 'test_tofu',
        name: 'Tofu',
        location: StorageLocation.fridge,
      ));

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(
              body: AiChatScreen(isMainTab: true),
            ),
          ),
        ),
      );
      await tester.pump();

      // Trigger chat message: "I have kimchi and tofu, let us make kimchi stew"
      await appState.sendUserChatMessage(
        'I have kimchi and tofu, let us make kimchi stew',
      );
      await tester.pumpAndSettle();

      // Verify AI reply was generated
      expect(appState.chatMessages.length, greaterThanOrEqualTo(2));
      final lastMsg = appState.chatMessages.last;
      expect(lastMsg.isUser, isFalse);
      expect(lastMsg.structuredRecipe, isNotNull);

      // Verify AiStudioRecipeCard renders for the structured recipe
      expect(find.byType(AiStudioRecipeCard), findsOneWidget);
      expect(find.text('Cook Now'), findsOneWidget);
    });

    testWidgets('AiStudioRecipeCard displays pantry matching and servings controls',
        (WidgetTester tester) async {
      final appState = AppState();
      appState.addFridgeItem(const FridgeItem(
        id: 'i1',
        name: 'Eggs',
        location: StorageLocation.fridge,
      ));
      appState.addFridgeItem(const FridgeItem(
        id: 'i2',
        name: 'Rice',
        location: StorageLocation.pantry,
      ));

      const recipe = AiStructuredRecipe(
        title: 'Egg Fried Rice',
        koreanTitle: '계란 볶음밥',
        cookingTime: '15 mins',
        difficulty: 'Easy',
        servings: 2,
        ingredients: ['2 cups cooked rice', '2 large eggs', '1 tbsp soy sauce'],
        instructions: [
          'Heat skillet with cooking oil.',
          'Scramble eggs until soft.',
          'Add cold rice and stir fry vigorously.',
          'Drizzle soy sauce and toss.',
        ],
        chefNote: 'Use day-old chilled rice for crisp grain texture.',
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AiStudioRecipeCard(recipe: recipe),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check title rendering
      expect(find.text('Egg Fried Rice'), findsOneWidget);
      expect(find.text('계란 볶음밥'), findsOneWidget);

      // Check pantry match badge
      expect(find.textContaining('in kitchen'), findsOneWidget);

      // Check Servings scaler rendered
      expect(find.text('2'), findsWidgets); // 2 servings
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);

      // Tap + button to scale to 3 servings
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(find.text('3'), findsWidgets);

      // Check Cook Now button
      expect(find.text('Cook Now'), findsOneWidget);
    });
  });
}
