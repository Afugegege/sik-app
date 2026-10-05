import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sik_app/models/fridge_item.dart';
import 'package:sik_app/models/recipe.dart';
import 'package:sik_app/providers/app_state.dart';
import 'package:sik_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Optional Quantity & Background Data Preservation Tests', () {
    test('TrackQuantities toggle defaults to true and updates StorageService', () async {
      final appState = AppState();
      expect(appState.trackQuantities, isTrue);

      appState.setTrackQuantities(false);
      expect(appState.trackQuantities, isFalse);

      final saved = await StorageService.loadTrackQuantities();
      expect(saved, isFalse);

      appState.toggleTrackQuantities();
      expect(appState.trackQuantities, isTrue);
    });

    test('Turning off quantity tracking preserves background quantities and does not delete data', () {
      final appState = AppState();
      final item = FridgeItem(
        id: 'test_egg',
        name: 'Eggs',
        location: StorageLocation.fridge,
        quantityMode: QuantityMode.exact,
        quantityDisplay: '6 pieces',
        status: 'Have',
      );
      appState.addFridgeItem(item);

      // Verify item has quantity
      expect(appState.fridgeItems.first.quantityDisplay, '6 pieces');

      // User turns off quantity tracking function
      appState.setTrackQuantities(false);

      // Data MUST remain intact in background
      final retrievedItem = appState.fridgeItems.firstWhere((i) => i.id == 'test_egg');
      expect(retrievedItem.quantityDisplay, '6 pieces');
      expect(retrievedItem.quantityMode, QuantityMode.exact);

      // User edits item name or status while quantity tracking is off
      final edited = retrievedItem.copyWith(status: 'Running low');
      appState.updateFridgeItem(edited);

      // Quantity must still be safely preserved
      final afterEdit = appState.fridgeItems.firstWhere((i) => i.id == 'test_egg');
      expect(afterEdit.quantityDisplay, '6 pieces');
      expect(afterEdit.status, 'Running low');

      // User turns quantity tracking back on
      appState.setTrackQuantities(true);
      final restored = appState.fridgeItems.firstWhere((i) => i.id == 'test_egg');
      expect(restored.quantityDisplay, '6 pieces');
    });
  });

  group('Post-Cooking Inventory Check & Update Tests', () {
    test('applyPostCookingInventoryUpdate deducts items, records cooking, and updates Want list', () {
      final appState = AppState();
      final egg = FridgeItem(
        id: 'p_egg',
        name: 'Egg',
        location: StorageLocation.fridge,
        quantityMode: QuantityMode.exact,
        quantityDisplay: '4 pieces',
        status: 'Have',
      );
      final tofu = FridgeItem(
        id: 'p_tofu',
        name: 'Tofu',
        location: StorageLocation.fridge,
        quantityMode: QuantityMode.approximate,
        quantityDisplay: 'Some',
        status: 'Have',
      );
      appState.addFridgeItem(egg);
      appState.addFridgeItem(tofu);

      const testRecipe = Recipe(
        id: 'r_post_cook',
        title: 'Tofu Scramble',
        koreanTitle: '두부 스크램블',
        imageUrl: '',
        cookingTimeMinutes: 10,
        cookingMethod: 'Stovetop',
        difficulty: 'Easy',
        kitchenMatchPercent: 100,
        ingredients: [
          RecipeIngredient(name: 'Egg', amount: '2 pieces', status: 'have'),
          RecipeIngredient(name: 'Tofu', amount: '1 block', status: 'have'),
          RecipeIngredient(name: 'Chives', amount: '2 sprigs', status: 'missing'),
        ],
        cookingSteps: ['Scramble eggs and tofu together in a hot skillet.'],
      );

      // Simulate post-cooking update: Egg reduced to 2 pieces, Tofu finished, Chives added to want list
      appState.applyPostCookingInventoryUpdate(
        recipe: testRecipe,
        updatedItems: [
          egg.copyWith(quantityDisplay: '2 pieces'),
          tofu.copyWith(status: 'Missing', quantityDisplay: 'Almost empty'),
        ],
        depletedItemIdsToRemove: [],
        itemsToAddToWantList: ['Tofu', 'Chives'],
        cookingNotes: 'Great texture with medium heat.',
        rating: 5,
      );

      // Check updated fridge items
      final updatedEgg = appState.fridgeItems.firstWhere((f) => f.id == 'p_egg');
      expect(updatedEgg.quantityDisplay, '2 pieces');

      final updatedTofu = appState.fridgeItems.firstWhere((f) => f.id == 'p_tofu');
      expect(updatedTofu.status, 'Missing');

      // Check shopping list additions
      expect(appState.wantList.contains('Tofu'), isTrue);
      expect(appState.wantList.contains('Chives'), isTrue);

      // Check cooking history
      expect(appState.cookedHistory.any((r) => r.id == 'r_post_cook'), isTrue);
      expect(appState.cookingRecords.any((c) => c.recipeTitle == 'Tofu Scramble'), isTrue);
    });
  });

  group('Grocery Recommendation Menu Tests', () {
    test('Need Groceries filter surfaces recipes requiring grocery items', () {
      final appState = AppState();
      // Select Need Groceries filter
      appState.setFilter('Need Groceries');

      final groceryRecipes = appState.filteredRecipes;
      expect(groceryRecipes, isNotEmpty);

      // All recipes returned should have missing ingredients or be aspirational grocery discovery dishes
      for (final r in groceryRecipes) {
        final needsGroceries = r.missingIngredientsCount > 0 || r.isAspirational;
        expect(needsGroceries, isTrue, reason: 'Recipe ${r.title} must require groceries');
      }
    });
  });
}
