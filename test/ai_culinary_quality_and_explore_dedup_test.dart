import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sik_app/models/ai_chat_message.dart';
import 'package:sik_app/models/fridge_item.dart';
import 'package:sik_app/models/recipe.dart';
import 'package:sik_app/providers/app_state.dart';
import 'package:sik_app/services/ai_chat_service.dart';
import 'package:sik_app/widgets/ai_recipe_options_card.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('AiRecipeOptionsCard Overflow & Markdown Stripping Tests', () {
    testWidgets('Renders options cleanly on narrow mobile screen without overflow or raw asterisks',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const options = [
        AiRecipeOption(
          title: 'Warm Miso Kelp Dashi Noodle Broth',
          cookingTime: '**20m**',
          difficulty: '**Medium**',
          category: 'Comfort Soup',
          description: 'A comforting bowl of noodles in a savory seasoned dashi broth.',
        ),
        AiRecipeOption(
          title: 'Spicy Tomyum Meehun Soup with Lemon',
          cookingTime: '**25m**',
          difficulty: '**Medium**',
          category: 'Southeast Asian',
          description: 'A flavorful and spicy Thai-inspired soup with fragrant herbs.',
        ),
      ];

      String? selectedOption;

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>(
          create: (_) => AppState(),
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AiRecipeOptionsCard(
                  options: options,
                  onSelectOption: (opt) {
                    selectedOption = opt;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no asterisks are displayed in UI
      expect(find.text('20m'), findsOneWidget);
      expect(find.text('Medium'), findsWidgets);
      expect(find.text('**20m**'), findsNothing);
      expect(find.text('**Medium**'), findsNothing);

      // Verify tap works
      await tester.tap(find.text('Warm Miso Kelp Dashi Noodle Broth'));
      await tester.pumpAndSettle();
      expect(selectedOption, 'Warm Miso Kelp Dashi Noodle Broth');

      // Verify no RenderFlex overflow exception occurred
      expect(tester.takeException(), isNull);
    });
  });

  group('Explore Tab Non-Duplication Tests', () {
    test('curateDiscoveryDeck strictly excludes any dish present on the dashboard', () async {
      final appState = AppState();

      // Dashboard currently has recipes
      final dashboardTitles = appState.recipes.map((r) => r.title.toLowerCase().trim()).toSet();
      final dashboardIds = appState.recipes.map((r) => r.id).toSet();

      expect(dashboardTitles.isNotEmpty, isTrue);

      // Curate discovery deck for each mood
      for (final mood in ['savory', 'craving', 'bake', 'dessert']) {
        final discoveryDeck = appState.curateDiscoveryDeck(
          mood: mood,
          vibe: 'any',
          timeframe: 'any',
          constraint: 'open',
        );

        expect(discoveryDeck.isNotEmpty, isTrue, reason: 'Explore deck must provide recipes for mood $mood');

        for (final recipe in discoveryDeck) {
          expect(
            dashboardIds.contains(recipe.id),
            isFalse,
            reason: 'Explore recipe ${recipe.title} (id: ${recipe.id}) must not duplicate a dashboard ID',
          );
          expect(
            dashboardTitles.contains(recipe.title.toLowerCase().trim()),
            isFalse,
            reason: 'Explore recipe "${recipe.title}" must not duplicate a dashboard recipe title',
          );
        }
      }
    });
  });

  group('AI Chat Recipe Quality & Non-Duplication Tests', () {
    test('AI recipe suggestions do NOT recommend dishes already on dashboard', () async {
      final List<Recipe> dashboardRecipes = [
        const Recipe(
          id: 'd1',
          title: 'Warm Miso Kelp Dashi Noodle Broth',
          koreanTitle: '따뜻한 된장 국수',
          imageUrl: '',
          cookingTimeMinutes: 20,
          cookingMethod: 'Stovetop',
          difficulty: 'Easy',
          kitchenMatchPercent: 100,
          category: 'Soup',
          ingredients: [],
          cookingSteps: [],
        ),
        const Recipe(
          id: 'd2',
          title: 'Spicy Tomyum Meehun Soup with Lemon',
          koreanTitle: '똠얌 미훈',
          imageUrl: '',
          cookingTimeMinutes: 25,
          cookingMethod: 'Stovetop',
          difficulty: 'Medium',
          kitchenMatchPercent: 100,
          category: 'Soup',
          ingredients: [],
          cookingSteps: [],
        ),
        const Recipe(
          id: 'd3',
          title: 'Spicy Lao Gan Ma Garlic Meehun',
          koreanTitle: '라오간마 비빔면',
          imageUrl: '',
          cookingTimeMinutes: 15,
          cookingMethod: 'Stovetop',
          difficulty: 'Easy',
          kitchenMatchPercent: 100,
          category: 'Noodles',
          ingredients: [],
          cookingSteps: [],
        ),
      ];

      final fridgeItems = [
        const FridgeItem(
          id: 'f1',
          name: 'Noodles',
          location: StorageLocation.pantry,
          quantityMode: QuantityMode.approximate,
          quantityDisplay: 'Plenty',
          status: 'Have',
        ),
        const FridgeItem(
          id: 'f2',
          name: 'Chicken Breast',
          location: StorageLocation.fridge,
          quantityMode: QuantityMode.approximate,
          quantityDisplay: 'Have',
          status: 'Have',
        ),
      ];

      final response = await AiChatService.generateResponse(
        prompt: 'what can i cook for dinner?',
        fridgeItems: fridgeItems,
        availableRecipes: dashboardRecipes,
        apiKey: '',
      );

      expect(response.recipeOptions.isNotEmpty, isTrue);

      final dashboardTitles = dashboardRecipes.map((r) => r.title.toLowerCase().trim()).toSet();
      for (final opt in response.recipeOptions) {
        expect(
          dashboardTitles.contains(opt.title.toLowerCase().trim()),
          isFalse,
          reason: 'Option "${opt.title}" must not be one of the existing dashboard recipes',
        );
      }
    });

    test('AI generates properly seasoned soup noodles with garlic, soy, salt, and broth', () async {
      final response = await AiChatService.generateResponse(
        prompt: 'how do i make soup noodles?',
        fridgeItems: const [],
        availableRecipes: const [],
        apiKey: '',
      );

      expect(response.structuredRecipe, isNotNull);
      final recipe = response.structuredRecipe!;

      // Verify that soup noodles are deeply seasoned (never plain water!)
      final ingredientsText = recipe.ingredients.join(' ').toLowerCase();
      expect(ingredientsText.contains('broth') || ingredientsText.contains('stock'), isTrue,
          reason: 'Must include seasoned broth or stock');
      expect(ingredientsText.contains('salt'), isTrue, reason: 'Must include salt');
      expect(ingredientsText.contains('soy sauce'), isTrue, reason: 'Must include soy sauce');
      expect(ingredientsText.contains('garlic'), isTrue, reason: 'Must include garlic');

      // Verify chef note emphasizes seasoning broth
      expect(recipe.chefNote.toLowerCase().contains('unseasoned water'), isTrue);
    });

    test('AI generates properly seasoned chicken steak recipe when selected', () async {
      final response = await AiChatService.generateResponse(
        prompt: 'Crispy Lemon Butter Pan-Seared Chicken Steak',
        fridgeItems: const [],
        availableRecipes: const [],
        apiKey: '',
      );

      expect(response.structuredRecipe, isNotNull);
      final recipe = response.structuredRecipe!;
      expect(recipe.title, 'Crispy Lemon Butter Pan-Seared Chicken Steak');

      final ingredientsText = recipe.ingredients.join(' ').toLowerCase();
      expect(ingredientsText.contains('butter'), isTrue);
      expect(ingredientsText.contains('lemon'), isTrue);
      expect(ingredientsText.contains('salt'), isTrue);
      expect(ingredientsText.contains('pepper'), isTrue);
      expect(ingredientsText.contains('garlic'), isTrue);
    });
  });
}
