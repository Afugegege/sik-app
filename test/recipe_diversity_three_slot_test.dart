import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sik_app/models/mock_data.dart';
import 'package:sik_app/models/recipe.dart';
import 'package:sik_app/providers/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    dotenv.testLoad(fileInput: 'OPENAI_API_KEY=mock_key');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Recipe Diversity & Three-Slot Architecture Tests', () {
    test('MockData contains chef-crafted simple classic recipes with inspiration notes', () {
      final classics = MockData.simpleClassicRecipes;
      expect(classics, isNotEmpty);
      expect(classics.length, greaterThanOrEqualTo(6));

      for (final recipe in classics) {
        expect(recipe.isSimpleClassic, isTrue);
        expect(recipe.recipeSlot, 'simple_classic');
        expect(recipe.inspirationNote, isNotNull);
        expect(recipe.inspirationNote!.isNotEmpty, isTrue);
        // Simple classics should be minimalist (<= 5 ingredients, <= 4 steps)
        expect(recipe.ingredients.length, lessThanOrEqualTo(5));
        expect(recipe.cookingSteps.length, lessThanOrEqualTo(4));
      }

      // Verify iconic simple classics exist
      final titles = classics.map((r) => r.title.toLowerCase()).toList();
      expect(titles.any((t) => t.contains('chicken')), isTrue);
      expect(titles.any((t) => t.contains('steak')), isTrue);
      expect(titles.any((t) => t.contains('skewers')), isTrue);
      expect(titles.any((t) => t.contains('salmon')), isTrue);
    });

    test('AppState._composeDiverseFeed surfaces a balanced mix of slots on initial load', () {
      final appState = AppState();
      final feed = appState.recipes;

      expect(feed, isNotEmpty);

      // Check slot distribution
      final pantryDishes = feed.where((r) => r.isPantryUtility).toList();
      final classicDishes = feed.where((r) => r.isSimpleClassic).toList();
      final aspirationalDishes = feed.where((r) => r.isAspirational).toList();

      expect(pantryDishes, isNotEmpty, reason: 'Must have pantry utility dishes to cook now');
      expect(classicDishes, isNotEmpty, reason: 'Must have simple everyday classics');
      expect(aspirationalDishes, isNotEmpty, reason: 'Must have aspirational dishes to inspire');

      // Verify aspirational recipes appear even if match is under 100%
      for (final asp in aspirationalDishes) {
        expect(asp.isAspirational, isTrue);
        expect(asp.category, equals("Chef's Pick"));
      }
    });

    test('Filtered recipes default sort preserves chef slot ordering (Pantry -> Classic -> Aspirational)', () {
      final appState = AppState();
      final filtered = appState.filteredRecipes;

      expect(filtered, isNotEmpty);

      // Verify that all pantry utility dishes appear before aspirational dishes
      int firstAspirationalIndex = filtered.indexWhere((r) => r.isAspirational);
      int lastPantryIndex = filtered.lastIndexWhere((r) => r.isPantryUtility);

      if (firstAspirationalIndex != -1 && lastPantryIndex != -1) {
        expect(
          lastPantryIndex,
          lessThan(firstAspirationalIndex),
          reason: 'Pantry utility recipes should appear before aspirational recipes in default feed',
        );
      }
    });

    test('Recipe model copyWith correctly updates and preserves recipeSlot and inspirationNote', () {
      const original = Recipe(
        id: 'test_slot',
        title: 'Cast-Iron Ribeye',
        koreanTitle: '스테이크',
        imageUrl: '',
        cookingTimeMinutes: 12,
        cookingMethod: 'Stovetop',
        difficulty: 'Medium',
        kitchenMatchPercent: 50,
        ingredients: [],
        cookingSteps: [],
        recipeSlot: 'simple_classic',
        inspirationNote: 'Baste with garlic butter',
      );

      expect(original.isSimpleClassic, isTrue);
      expect(original.isPantryUtility, isFalse);
      expect(original.isAspirational, isFalse);

      final updated = original.copyWith(
        recipeSlot: 'aspirational',
        inspirationNote: 'Worth visiting the butcher',
      );

      expect(updated.isAspirational, isTrue);
      expect(updated.isSimpleClassic, isFalse);
      expect(updated.inspirationNote, 'Worth visiting the butcher');
    });
  });
}
