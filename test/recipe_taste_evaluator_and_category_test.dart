import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sik_app/models/recipe.dart';
import 'package:sik_app/providers/app_state.dart';
import 'package:sik_app/screens/recipe_detail_screen.dart';
import 'package:sik_app/services/recipe_taste_evaluator.dart';
import 'package:sik_app/widgets/explore_filters.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    dotenv.testLoad(fileInput: 'OPENAI_API_KEY=mock_key');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Category Food Icons', () {
    test('Returns distinct icons for food categories', () {
      const drinkRecipe = Recipe(
        id: 'r_drink',
        title: 'Matcha Oat Latte',
        koreanTitle: '말차 라떼',
        imageUrl: '',
        cookingTimeMinutes: 5,
        cookingMethod: 'No-cook',
        difficulty: 'Easy',
        kitchenMatchPercent: 100,
        category: 'Drinks',
        ingredients: [],
        cookingSteps: [],
      );
      expect(drinkRecipe.categoryIcon, Icons.local_cafe_rounded);

      const dessertRecipe = Recipe(
        id: 'r_dessert',
        title: 'Strawberry Bingsu',
        koreanTitle: '딸기 빙수',
        imageUrl: '',
        cookingTimeMinutes: 10,
        cookingMethod: 'No-cook',
        difficulty: 'Easy',
        kitchenMatchPercent: 90,
        category: 'Pastry & Dessert',
        ingredients: [],
        cookingSteps: [],
      );
      expect(dessertRecipe.categoryIcon, Icons.icecream_rounded);

      const eggRecipe = Recipe(
        id: 'r_egg',
        title: 'Microwave Fluffy Steamed Egg',
        koreanTitle: '계란찜',
        imageUrl: '',
        cookingTimeMinutes: 5,
        cookingMethod: 'Microwave',
        difficulty: 'Easy',
        kitchenMatchPercent: 95,
        category: 'Cook with what you have',
        ingredients: [],
        cookingSteps: [],
      );
      expect(eggRecipe.categoryIcon, Icons.egg_alt_rounded);

      const mainRecipe = Recipe(
        id: 'r_main',
        title: 'Kimchi Fried Rice with Soft Egg',
        koreanTitle: '김치볶음밥',
        imageUrl: '',
        cookingTimeMinutes: 15,
        cookingMethod: 'Stovetop',
        difficulty: 'Easy',
        kitchenMatchPercent: 95,
        category: 'Cook with what you have',
        ingredients: [],
        cookingSteps: [],
      );
      expect(mainRecipe.categoryIcon, Icons.rice_bowl_rounded);

      // ExploreFilters category icons
      expect(ExploreFilters.getCategoryIcon('Drinks'), Icons.local_cafe_rounded);
      expect(ExploreFilters.getCategoryIcon('Pastry & Dessert'), Icons.icecream_rounded);
      expect(ExploreFilters.getCategoryIcon('Quick & Simple'), Icons.bolt_rounded);
      expect(ExploreFilters.getCategoryIcon('Cook with what you have'), Icons.kitchen_rounded);
    });
  });

  group('Recipe Taste Evaluator Engine', () {
    const testRecipe = Recipe(
      id: 'r_test',
      title: 'Kimchi Fried Rice',
      koreanTitle: '김치볶음밥',
      imageUrl: '',
      cookingTimeMinutes: 15,
      cookingMethod: 'Stovetop',
      difficulty: 'Easy',
      kitchenMatchPercent: 95,
      category: 'Cook with what you have',
      ingredients: [
        RecipeIngredient(name: 'Aged Kimchi', amount: '1 cup', status: 'have'),
        RecipeIngredient(name: 'Sesame Oil', amount: '1 tbsp', status: 'have'),
        RecipeIngredient(name: 'Garlic', amount: '2 cloves', status: 'have'),
      ],
      cookingSteps: ['Cook everything'],
    );

    test('Evaluates single ingredient removal and provides alternatives', () {
      final garlicResult = RecipeTasteEvaluator.evaluateRemoval(
        recipeTitle: testRecipe.title,
        ingredientName: 'Garlic',
      );

      expect(garlicResult.originalScore, 10.0);
      expect(garlicResult.impactedScore, inInclusiveRange(8.0, 8.8));
      expect(garlicResult.explanation, contains('aroma'));
      expect(garlicResult.alternatives.isNotEmpty, isTrue);

      final firstAlt = garlicResult.alternatives.first;
      expect(firstAlt.name, contains('Garlic Powder'));
      expect(firstAlt.recoveredScore, greaterThan(8.8));
      expect(firstAlt.culinaryNote.isNotEmpty, isTrue);
    });

    test('Evaluates combined removal and substitution restoration', () {
      final combined = RecipeTasteEvaluator.evaluateCombined(
        recipe: testRecipe,
        removedIngredients: {'Aged Kimchi'},
      );
      expect(combined.tasteRating, lessThan(8.0)); // Kimchi is key

      // With substitution
      const kimchiAlt = TasteAlternative(
        name: 'Sauerkraut + Chili Flakes',
        portion: '1 cup',
        recoveredScore: 9.1,
        culinaryNote: 'Fermented tartness with mild heat',
      );

      final withSub = RecipeTasteEvaluator.evaluateCombined(
        recipe: testRecipe,
        removedIngredients: {'Aged Kimchi'},
        substitutions: {'Aged Kimchi': kimchiAlt},
      );
      expect(withSub.tasteRating, greaterThan(combined.tasteRating));
      expect(withSub.explanation, contains('Substituted Aged Kimchi'));
    });
  });

  group('RecipeDetailScreen Widget Tests', () {
    testWidgets('Renders compact header without 280px empty image when hasImage is false', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final appState = AppState();

      final nonImageRecipe = appState.recipes.firstWhere((r) => !r.hasImage);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AppState>.value(
            value: appState,
            child: RecipeDetailScreen(recipe: nonImageRecipe),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check title and ingredients rendered
      expect(find.text(nonImageRecipe.title), findsOneWidget);
      expect(find.text('Ingredients'), findsOneWidget);
      expect(find.text('Start Cooking'), findsOneWidget);

      // Verify no empty image network error container or 280px flexible space
      expect(find.byType(SliverAppBar), findsOneWidget);
    });

    testWidgets('Interactive ingredient removal triggers AI Taste Impact Card', (tester) async {
      final appState = AppState();

      final recipe = appState.recipes.first;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AppState>.value(
            value: appState,
            child: RecipeDetailScreen(recipe: recipe),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially no Taste Balance card
      expect(find.text('Taste Balance'), findsNothing);

      // Tap exclude button on first ingredient
      final excludeBtnFinder = find.byTooltip('Exclude ingredient');
      expect(excludeBtnFinder, findsWidgets);

      await tester.tap(excludeBtnFinder.first);
      await tester.pumpAndSettle();

      // Taste Balance Card should now appear!
      expect(find.text('Taste Balance'), findsOneWidget);
      expect(find.text('Find Substitutes'), findsOneWidget);

      // Restore ingredient
      final restoreBtn = find.text('Restore');
      expect(restoreBtn, findsWidgets);
      await tester.tap(restoreBtn.first);
      await tester.pumpAndSettle();

      // Impact card should disappear after restoring
      expect(find.text('Taste Balance'), findsNothing);
    });
  });
}
