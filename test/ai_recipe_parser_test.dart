import 'package:flutter_test/flutter_test.dart';
import 'package:sik_app/services/ai_recipe_parser.dart';

void main() {
  group('AiRecipeParser Tests', () {
    test('Correctly parses natural markdown recipe from user screenshot', () {
      const sampleScreenshotText = '''
You have the perfect ingredients for a refreshing Matcha Oat Milk Iced Latte! Here’s a simple recipe for you:

### Matcha Oat Milk Iced Latte

Ingredients:
• 1–2 teaspoons matcha powder (adjust based on your preference)
• 1 cup milk (you can use oat milk or any milk of your choice)
• 1–2 teaspoons honey or sweetener (optional)
• Ice cubes
• Water (about 2–3 tablespoons for mixing the matcha)

Instructions:
1. Mix Matcha: In a small bowl, whisk the matcha powder with 2–3 tablespoons of hot water until smooth and frothy. You can use a bamboo whisk or a small frother.
2. Combine: In a glass, add ice cubes. Pour in the milk and then add the sweetener if desired.
3. Layer: Slowly pour the matcha mixture over the milk. You can stir it gently to combine or leave it layered for a nice visual effect.
4. Serve: Enjoy your refreshing iced latte!
''';

      final result = AiRecipeParser.parse(sampleScreenshotText);

      expect(result.recipe, isNotNull);
      expect(result.recipe!.title, contains('Matcha Oat Milk Iced Latte'));
      expect(result.recipe!.ingredients.length, 5);
      expect(result.recipe!.instructions.length, 4);
      expect(result.recipe!.category, 'Beverage');
      expect(result.cleanText, contains('You have the perfect ingredients'));
      expect(result.cleanText, isNot(contains('### Matcha Oat Milk Iced Latte')));
    });

    test('Correctly parses structured OPTIONS block', () {
      const sampleOptionsText = '''
Here are 3 curated recipe choices for you:
OPTIONS:
- Title: Matcha Oat Milk Iced Latte | Time: 5m | Difficulty: Easy | Category: Beverage | Desc: Refreshing cold matcha over oat milk
- Title: Fluffy Matcha Soufflé Pancakes | Time: 20m | Difficulty: Medium | Category: Dessert | Desc: Cloud-like Japanese pancakes
- Title: Chewy Matcha White Chocolate Cookies | Time: 25m | Difficulty: Easy | Category: Baking | Desc: Soft bakery cookies with white chocolate
''';

      final result = AiRecipeParser.parse(sampleOptionsText);

      expect(result.options.length, 3);
      expect(result.options[0].title, 'Matcha Oat Milk Iced Latte');
      expect(result.options[0].cookingTime, '5m');
      expect(result.options[0].difficulty, 'Easy');
      expect(result.options[1].title, 'Fluffy Matcha Soufflé Pancakes');
      expect(result.options[2].title, 'Chewy Matcha White Chocolate Cookies');
      expect(result.cleanText, 'Here are 3 curated recipe choices for you:');
    });

    test('Correctly parses explicit RECIPE block', () {
      const sampleRecipeBlock = '''
Here is your recipe from 식 studio:
RECIPE:
Title: Creamy Gochujang Rosé Pasta
Category: Main Dish
Time: 18 mins
Difficulty: Easy
Servings: 2
Ingredients:
- 200g Fettuccine or rigatoni
- 2 tbsp Gochujang paste
- 1 cup Heavy cream or oat cream
- 2 cloves Garlic, minced
- 1 tbsp Butter
Instructions:
1. Boil Pasta: Cook pasta in salted boiling water until al dente.
2. Make Sauce: Saute minced garlic in butter, stir in gochujang and pour in cream.
3. Toss & Serve: Toss cooked pasta in the velvety rosé sauce. Garnish with parmesan.
Tip: Save 1/4 cup of pasta water to emulsify the sauce into a silkier texture.
''';

      final result = AiRecipeParser.parse(sampleRecipeBlock);

      expect(result.recipe, isNotNull);
      expect(result.recipe!.title, 'Creamy Gochujang Rosé Pasta');
      expect(result.recipe!.cookingTime, '18 mins');
      expect(result.recipe!.difficulty, 'Easy');
      expect(result.recipe!.servings, 2);
      expect(result.recipe!.ingredients.length, 5);
      expect(result.recipe!.instructions.length, 3);
      expect(result.recipe!.chefNote, contains('Save 1/4 cup of pasta water'));
    });
  });
}
