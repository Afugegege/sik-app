import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sik_app/models/fridge_item.dart';
import 'package:sik_app/models/recipe.dart';
import 'package:sik_app/services/pantry_recipe_synthesizer.dart';
import 'package:sik_app/services/ingredient_intelligence.dart';
import 'package:sik_app/providers/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dotenv.testLoad(fileInput: 'OPENAI_API_KEY=mock_key');
  });

  group('PantryRecipeSynthesizer Strict Ingredient Matching', () {
    final userFridgeItems = [
      // 🧊 Fridge — 16
      FridgeItem(id: '1', name: 'Sliced Green Jalapeños', location: StorageLocation.fridge, quantityDisplay: '1 jar', status: 'Have'),
      FridgeItem(id: '2', name: 'Irish Courgettes', location: StorageLocation.fridge, quantityDisplay: '2 pcs', status: 'Have'),
      FridgeItem(id: '3', name: 'Lemon', location: StorageLocation.fridge, quantityDisplay: '1 pc', status: 'Have'),
      FridgeItem(id: '4', name: 'Butter', location: StorageLocation.fridge, quantityDisplay: '1 block', status: 'Have'),
      FridgeItem(id: '5', name: 'Irish Traditional Ham', location: StorageLocation.fridge, quantityDisplay: '1 pack', status: 'Have'),
      FridgeItem(id: '6', name: 'Red Cheddar Cheese', location: StorageLocation.fridge, quantityDisplay: '200g', status: 'Have'),
      FridgeItem(id: '7', name: 'Milk', location: StorageLocation.fridge, quantityDisplay: '1L', status: 'Have'),
      FridgeItem(id: '8', name: 'Strawberry Jam', location: StorageLocation.fridge, quantityDisplay: '1 jar', status: 'Have'),
      FridgeItem(id: '9', name: 'Passion Fruit Curd', location: StorageLocation.fridge, quantityDisplay: '1 jar', status: 'Have'),
      FridgeItem(id: '10', name: 'Rosemary Whole', location: StorageLocation.fridge, quantityDisplay: '1 bunch', status: 'Have'),
      FridgeItem(id: '11', name: '老干妈 (Lao Gan Ma)', location: StorageLocation.fridge, quantityDisplay: '1 jar', status: 'Have'),
      FridgeItem(id: '12', name: 'Garlic', location: StorageLocation.fridge, quantityDisplay: '1 head', status: 'Have'),
      FridgeItem(id: '13', name: 'Tomyum Paste', location: StorageLocation.fridge, quantityDisplay: '1 jar', status: 'Have'),
      FridgeItem(id: '14', name: 'White Miso Paste', location: StorageLocation.fridge, quantityDisplay: '1 tub', status: 'Have'),
      FridgeItem(id: '15', name: 'Dried Kelp', location: StorageLocation.fridge, quantityDisplay: '1 pack', status: 'Have'),
      FridgeItem(id: '16', name: 'Meehun', location: StorageLocation.fridge, quantityDisplay: '1 pack', status: 'Have'),
      // ❄️ Freezer — 2
      FridgeItem(id: '17', name: 'Breaded Chicken Steak', location: StorageLocation.freezer, quantityDisplay: '2 pcs', status: 'Have'),
      FridgeItem(id: '18', name: 'Pork Loin Chop', location: StorageLocation.freezer, quantityDisplay: '2 pcs', status: 'Have'),
      // 🥫 Pantry — 8
      FridgeItem(id: '19', name: 'Rice', location: StorageLocation.pantry, quantityDisplay: '1 bag', status: 'Have'),
      FridgeItem(id: '20', name: 'Sugar', location: StorageLocation.pantry, quantityDisplay: '1 bag', status: 'Have'),
      FridgeItem(id: '21', name: 'Salt', location: StorageLocation.pantry, quantityDisplay: '1 tub', status: 'Have'),
      FridgeItem(id: '22', name: 'BBQ Sauce', location: StorageLocation.pantry, quantityDisplay: '1 bottle', status: 'Have'),
      FridgeItem(id: '23', name: 'Sweet Chilli Sauce', location: StorageLocation.pantry, quantityDisplay: '1 bottle', status: 'Have'),
      FridgeItem(id: '24', name: 'Dark Soy Sauce', location: StorageLocation.pantry, quantityDisplay: '1 bottle', status: 'Have'),
      FridgeItem(id: '25', name: 'Soy Sauce', location: StorageLocation.pantry, quantityDisplay: '1 bottle', status: 'Have'),
      FridgeItem(id: '26', name: 'Noodles', location: StorageLocation.pantry, quantityDisplay: '2 packs', status: 'Have'),
    ];

    test('Sweet Chilli Sauce must NEVER cause Sweet Corn or Sweet Potatoes to match', () {
      final chilliSauceOnly = [
        FridgeItem(id: 'x1', name: 'Sweet Chilli Sauce', location: StorageLocation.pantry, quantityDisplay: '1 bottle', status: 'Have'),
      ];

      expect(
        PantryRecipeSynthesizer.hasIngredient('Sweet Corn', chilliSauceOnly),
        isFalse,
        reason: 'Sweet Corn should NOT match Sweet Chilli Sauce just because both contain the modifier "sweet"!',
      );

      expect(
        PantryRecipeSynthesizer.hasIngredient('Sweet Potatoes', chilliSauceOnly),
        isFalse,
        reason: 'Sweet Potatoes should NOT match Sweet Chilli Sauce!',
      );

      expect(
        PantryRecipeSynthesizer.hasIngredient('Green Onion', [
          FridgeItem(id: 'x2', name: 'Sliced Green Jalapeños', location: StorageLocation.fridge, quantityDisplay: '1 jar', status: 'Have'),
        ]),
        isFalse,
        reason: 'Green Onion should NOT match Sliced Green Jalapeños just because both contain "green"!',
      );
    });

    test('User inventory correctly does NOT have Sweet Corn or Sweet Potatoes', () {
      expect(PantryRecipeSynthesizer.hasIngredient('Sweet Corn', userFridgeItems), isFalse);
      expect(PantryRecipeSynthesizer.hasIngredient('Sweet Potatoes', userFridgeItems), isFalse);
      expect(PantryRecipeSynthesizer.hasIngredient('Corn', userFridgeItems), isFalse);
    });

    test('User inventory correctly matches true held ingredients', () {
      expect(PantryRecipeSynthesizer.hasIngredient('Pork Loin Chop', userFridgeItems), isTrue);
      expect(PantryRecipeSynthesizer.hasIngredient('Irish Courgettes', userFridgeItems), isTrue);
      expect(PantryRecipeSynthesizer.hasIngredient('Courgette', userFridgeItems), isTrue);
      expect(PantryRecipeSynthesizer.hasIngredient('Breaded Chicken Steak', userFridgeItems), isTrue);
      expect(PantryRecipeSynthesizer.hasIngredient('Lao Gan Ma', userFridgeItems), isTrue);
      expect(PantryRecipeSynthesizer.hasIngredient('老干妈', userFridgeItems), isTrue);
      expect(PantryRecipeSynthesizer.hasIngredient('White Miso Paste', userFridgeItems), isTrue);
      expect(PantryRecipeSynthesizer.hasIngredient('Dried Kelp', userFridgeItems), isTrue);
      expect(PantryRecipeSynthesizer.hasIngredient('Kelp', userFridgeItems), isTrue);
      expect(PantryRecipeSynthesizer.hasIngredient('Meehun', userFridgeItems), isTrue);
      expect(PantryRecipeSynthesizer.hasIngredient('Noodles', userFridgeItems), isTrue);
    });

    test('PantryRecipeSynthesizer synthesizes 100% genuine dishes from user inventory', () {
      final dishes = PantryRecipeSynthesizer.synthesizeFromInventory(userFridgeItems);
      expect(dishes, isNotEmpty);

      // Check key synthesized recipes are generated
      final titles = dishes.map((d) => d.title).toList();
      expect(titles.any((t) => t.contains('Lao Gan Ma')), isTrue);
      expect(titles.any((t) => t.contains('Pork Loin Chop')), isTrue);
      expect(titles.any((t) => t.contains('Breaded Chicken Steak')), isTrue);
      expect(titles.any((t) => t.contains('Irish Courgettes')), isTrue);
      expect(titles.any((t) => t.contains('Ham & Melted Red Cheddar')), isTrue);
      expect(titles.any((t) => t.contains('Tomyum')), isTrue);

      // Verify each synthesized recipe has 100% kitchenMatchPercent and all ingredients have status 'have'
      for (final dish in dishes) {
        expect(dish.kitchenMatchPercent, 100);
        for (final ing in dish.ingredients) {
          expect(
            PantryRecipeSynthesizer.hasIngredient(ing.name, userFridgeItems),
            isTrue,
            reason: '${dish.title} requires ${ing.name} which must exist in user inventory',
          );
        }
      }
    });

    test('AppState resolves recipes accurately and marks Sweet Corn as missing', () {
      final appState = AppState();
      appState.clearInventory();
      for (final item in userFridgeItems) {
        appState.addFridgeItem(item);
      }

      const cornCheese = Recipe(
        id: 'test_corn_cheese',
        title: 'Korean Corn Cheese Skillet',
        koreanTitle: '콘치즈',
        imageUrl: '',
        cookingTimeMinutes: 8,
        cookingMethod: 'Stovetop',
        difficulty: 'Easy',
        kitchenMatchPercent: 0,
        category: 'Snack',
        cookingSteps: ['Melt butter and cheese in skillet with sweet corn.'],
        ingredients: [
          RecipeIngredient(name: 'Sweet Corn', amount: '1 can', status: 'missing'),
          RecipeIngredient(name: 'Butter', amount: '1 tbsp', status: 'missing'),
          RecipeIngredient(name: 'Mayonnaise', amount: '1 tbsp', status: 'missing'),
          RecipeIngredient(name: 'Red Cheddar Cheese', amount: '40g', status: 'missing'),
        ],
      );

      // Check ingredient matching on the corn cheese recipe directly via appState
      final cornIng = cornCheese.ingredients.firstWhere((i) => i.name == 'Sweet Corn');
      expect(
        PantryRecipeSynthesizer.hasIngredient(cornIng.name, appState.fridgeItems),
        isFalse,
        reason: 'Sweet Corn must NEVER be marked as have when user only has Sweet Chilli Sauce',
      );
    });

    test('AppState refreshPantryMatchesWithThinking produces real thinking state and results', () async {
      final appState = AppState();
      appState.clearInventory();
      for (final item in userFridgeItems) {
        appState.addFridgeItem(item);
      }

      expect(appState.isThinkingPantry, isFalse);
      final future = appState.refreshPantryMatchesWithThinking();
      expect(appState.isThinkingPantry, isTrue);

      final result = await future;
      expect(appState.isThinkingPantry, isFalse);
      expect(result.readyCount, greaterThan(0));
      expect(result.message, contains('ready to cook'));
    });

    test('Milk must NEVER match Condensed Milk, Coconut Milk, or Oat Milk', () {
      final milkOnly = [
        FridgeItem(id: 'm1', name: 'Milk', location: StorageLocation.fridge, quantityDisplay: '1L', status: 'Have'),
      ];

      expect(
        PantryRecipeSynthesizer.hasIngredient('Condensed Milk', milkOnly),
        isFalse,
        reason: 'Regular Milk must NEVER match Condensed Milk!',
      );
      expect(
        PantryRecipeSynthesizer.hasIngredient('Sweetened Condensed Milk', milkOnly),
        isFalse,
        reason: 'Regular Milk must NEVER match Sweetened Condensed Milk!',
      );
      expect(
        PantryRecipeSynthesizer.hasIngredient('Coconut Milk', milkOnly),
        isFalse,
        reason: 'Regular Milk must NOT match Coconut Milk!',
      );
      expect(
        PantryRecipeSynthesizer.hasIngredient('Oat Milk', milkOnly),
        isFalse,
        reason: 'Regular Milk must NOT match Oat Milk!',
      );
      expect(
        PantryRecipeSynthesizer.hasIngredient('Evaporated Milk', milkOnly),
        isFalse,
        reason: 'Regular Milk must NOT match Evaporated Milk!',
      );
    });

    test('Condensed Milk matches when user actually has Condensed Milk', () {
      final condensedMilkOnly = [
        FridgeItem(id: 'cm1', name: 'Condensed Milk', location: StorageLocation.seasoning, quantityDisplay: '1 can', status: 'Have'),
      ];

      expect(
        PantryRecipeSynthesizer.hasIngredient('Condensed Milk', condensedMilkOnly),
        isTrue,
      );
      expect(
        PantryRecipeSynthesizer.hasIngredient('Sweetened Condensed Milk', condensedMilkOnly),
        isTrue,
      );
      expect(
        PantryRecipeSynthesizer.hasIngredient('Milk', condensedMilkOnly),
        isFalse,
        reason: 'Having Condensed Milk does not provide plain fresh Milk for cooking/drinking',
      );
    });

    test('Unlisted spices and seasonings are strictly NOT held', () {
      expect(PantryRecipeSynthesizer.hasIngredient('Black Pepper', userFridgeItems), isFalse);
      expect(PantryRecipeSynthesizer.hasIngredient('Cumin', userFridgeItems), isFalse);
      expect(PantryRecipeSynthesizer.hasIngredient('Cinnamon', userFridgeItems), isFalse);
      expect(PantryRecipeSynthesizer.hasIngredient('Sesame Oil', userFridgeItems), isFalse);
      expect(PantryRecipeSynthesizer.hasIngredient('Gochugaru', userFridgeItems), isFalse);
      expect(PantryRecipeSynthesizer.hasIngredient('Condensed Milk', userFridgeItems), isFalse);
    });

    test('IngredientIntelligence accurately routes spices and seasonings to StorageLocation.seasoning', () {
      expect(IngredientIntelligence.autoDetectLocation('Salt'), StorageLocation.seasoning);
      expect(IngredientIntelligence.autoDetectLocation('Black Pepper'), StorageLocation.seasoning);
      expect(IngredientIntelligence.autoDetectLocation('Condensed Milk'), StorageLocation.seasoning);
      expect(IngredientIntelligence.autoDetectLocation('Sesame Oil'), StorageLocation.seasoning);
      expect(IngredientIntelligence.autoDetectLocation('Soy Sauce'), StorageLocation.seasoning);
      expect(IngredientIntelligence.autoDetectLocation('Gochugaru'), StorageLocation.seasoning);
      expect(IngredientIntelligence.autoDetectLocation('Cumin'), StorageLocation.seasoning);
      expect(IngredientIntelligence.autoDetectLocation('Cinnamon'), StorageLocation.seasoning);
      expect(IngredientIntelligence.autoDetectLocation('White Miso Paste'), StorageLocation.seasoning);
      expect(IngredientIntelligence.autoDetectLocation('老干妈 (Lao Gan Ma)'), StorageLocation.seasoning);

      // Bell Pepper must remain produce / fridge
      expect(IngredientIntelligence.autoDetectLocation('Bell Pepper'), StorageLocation.fridge);
      // Chicken Steak must remain freezer
      expect(IngredientIntelligence.autoDetectLocation('Breaded Chicken Steak'), StorageLocation.freezer);
      // Rice must remain pantry
      expect(IngredientIntelligence.autoDetectLocation('Rice'), StorageLocation.pantry);
    });
  });
}
