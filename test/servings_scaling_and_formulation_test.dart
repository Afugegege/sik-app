import 'package:flutter_test/flutter_test.dart';
import 'package:sik_app/models/recipe.dart';
import 'package:sik_app/services/servings_scaler.dart';

void main() {
  group('ServingsScaler Unit Tests', () {
    test('scales simple integer grams correctly with space preservation', () {
      final scaled2to4 = ServingsScaler.scaleAmount('200g', 2, 4);
      expect(scaled2to4, '400g');

      final scaled2to1 = ServingsScaler.scaleAmount('200g', 2, 1);
      expect(scaled2to1, '100g');

      final scaledWithSpace = ServingsScaler.scaleAmount('200 g', 2, 4);
      expect(scaledWithSpace, '400 g');
    });

    test('scales fractions accurately with culinary typography', () {
      // 1/2 cup scaled from 2 to 4 servings should be 1 cup
      final scaledHalfToFour = ServingsScaler.scaleAmount('1/2 cup', 2, 4);
      expect(scaledHalfToFour, '1 cup');

      // 1/2 cup scaled from 2 to 1 serving should be ¼ cup
      final scaledHalfToOne = ServingsScaler.scaleAmount('1/2 cup', 2, 1);
      expect(scaledHalfToOne, '¼ cup');

      // 3/4 tbsp scaled from 2 to 4 servings should be 1 ½ tbsp
      final scaledThreeQuarterToFour = ServingsScaler.scaleAmount('3/4 tbsp', 2, 4);
      expect(scaledThreeQuarterToFour, '1 ½ tbsp');
    });

    test('scales decimal numbers and strips clean zeros', () {
      final scaledDecimal = ServingsScaler.scaleAmount('1.5 tbsp', 2, 4);
      expect(scaledDecimal, '3 tbsp');

      final scaledFractional = ServingsScaler.scaleAmount('1 tbsp', 2, 1);
      expect(scaledFractional, '½ tbsp');
    });

    test('preserves qualitative amounts without corruption', () {
      expect(ServingsScaler.scaleAmount('To taste', 2, 4), 'To taste');
      expect(ServingsScaler.scaleAmount('A pinch', 2, 4), 'A pinch');
      expect(ServingsScaler.scaleAmount('Optional', 2, 4), 'Optional');
      expect(ServingsScaler.scaleAmount(null, 2, 4), null);
    });

    test('scaleRecipe returns updated recipe copy with scaled ingredients and new servings', () {
      const baseRecipe = Recipe(
        id: 'test_kimchi_fried_rice',
        title: 'Kimchi Bokkeumbap',
        koreanTitle: '김치볶음밥',
        imageUrl: '',
        cookingTimeMinutes: 15,
        cookingMethod: 'Stovetop',
        difficulty: 'Easy',
        kitchenMatchPercent: 95,
        servings: 2,
        ingredients: [
          RecipeIngredient(name: 'Rice', amount: '2 bowls', status: 'have'),
          RecipeIngredient(name: 'Kimchi', amount: '1 cup', status: 'have'),
          RecipeIngredient(name: 'Sesame oil', amount: '1 tbsp', status: 'have'),
          RecipeIngredient(name: 'Salt', amount: 'To taste', status: 'have'),
        ],
        cookingSteps: [
          'Chop kimchi finely.',
          'Stir-fry with cooked rice.',
        ],
      );

      final scaledRecipe = ServingsScaler.scaleRecipe(baseRecipe, 4);

      expect(scaledRecipe.servings, 4);
      expect(scaledRecipe.servingsLabel, 'servings');
      expect(scaledRecipe.ingredients[0].amount, '4 bowls');
      expect(scaledRecipe.ingredients[1].amount, '2 cup');
      expect(scaledRecipe.ingredients[2].amount, '2 tbsp');
      expect(scaledRecipe.ingredients[3].amount, 'To taste');

      // Test scaling down to 1 portion
      final scaledToSolo = ServingsScaler.scaleRecipe(baseRecipe, 1);
      expect(scaledToSolo.servings, 1);
      expect(scaledToSolo.servingsLabel, 'portion');
      expect(scaledToSolo.ingredients[0].amount, '1 bowls');
      expect(scaledToSolo.ingredients[1].amount, '½ cup');
      expect(scaledToSolo.ingredients[2].amount, '½ tbsp');
    });

    test('Recipe model servings property and copyWith works seamlessly', () {
      const recipe = Recipe(
        id: 'r1',
        title: 'Doenjang Jjigae',
        koreanTitle: '된장찌개',
        imageUrl: '',
        cookingTimeMinutes: 20,
        cookingMethod: 'Stovetop',
        difficulty: 'Medium',
        kitchenMatchPercent: 90,
        servings: 2,
        ingredients: [],
        cookingSteps: [],
      );

      expect(recipe.servings, 2);
      expect(recipe.servingsLabel, 'servings');

      final soloRecipe = recipe.copyWith(servings: 1);
      expect(soloRecipe.servings, 1);
      expect(soloRecipe.servingsLabel, 'portion');
    });
  });
}
