import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_chat_message.dart';
import '../models/recipe.dart';
import '../models/fridge_item.dart';
import '../models/inventory_batch_action.dart';
import 'ingredient_intelligence.dart';
import 'ai_recipe_parser.dart';

class AiChatResponse {
  final String text;
  final List<String> quickReplies;
  final List<String> suggestedIngredients;
  final List<Recipe> recommendedRecipes;
  final List<AiChatAction> actions;
  final List<InventoryBatchActionItem> batchInventoryActions;
  final List<AiRecipeOption> recipeOptions;
  final AiStructuredRecipe? structuredRecipe;

  const AiChatResponse({
    required this.text,
    this.quickReplies = const [],
    this.suggestedIngredients = const [],
    this.recommendedRecipes = const [],
    this.actions = const [],
    this.batchInventoryActions = const [],
    this.recipeOptions = const [],
    this.structuredRecipe,
  });
}

class AiChatService {
  /// Generates an intelligent culinary response given the user's prompt,
  /// current fridge inventory, available recipes, and conversation history.
  static Future<AiChatResponse> generateResponse({
    required String prompt,
    required List<FridgeItem> fridgeItems,
    required List<Recipe> availableRecipes,
    required String apiKey,
    List<String>? preferredCuisines,
    List<AiChatMessage> conversationHistory = const [],
  }) async {
    final cleanPrompt = prompt.trim();
    final lower = cleanPrompt.toLowerCase();

    // 1. Try OpenAI if API Key is configured
    if (apiKey.isNotEmpty) {
      try {
        final onlineResponse = await _callOpenAi(
          apiKey: apiKey,
          prompt: cleanPrompt,
          fridgeItems: fridgeItems,
          availableRecipes: availableRecipes,
          history: conversationHistory,
          preferredCuisines: preferredCuisines,
        );
        if (onlineResponse != null) {
          return onlineResponse;
        }
      } catch (e) {
        // Log diagnostic details and fall back gracefully to built-in culinary intelligence engine
        // ignore: avoid_print
        print('[AiChatService] OpenAI request failed: $e');
      }
    }

    // 2. Offline / Built-in Culinary Intelligence Engine
    return _generateOfflineIntelligence(
      prompt: cleanPrompt,
      lower: lower,
      fridgeItems: fridgeItems,
      availableRecipes: availableRecipes,
    );
  }

  // ---------------------------------------------------------------------------
  // BUILT-IN CULINARY & NATURAL LANGUAGE ENGINE
  // ---------------------------------------------------------------------------
  static AiChatResponse _generateOfflineIntelligence({
    required String prompt,
    required String lower,
    required List<FridgeItem> fridgeItems,
    required List<Recipe> availableRecipes,
  }) {
    final fridgeItemNames = fridgeItems.map((e) => e.name).toList();

    // 0. BATCH INVENTORY UPDATE OR GROCERY / PANTRY HAUL
    if (_isBatchInventoryIntent(lower)) {
      final batchActions = _parseBatchInventoryActions(prompt, lower, fridgeItems);
      if (batchActions.isNotEmpty) {
        return AiChatResponse(
          text: 'I\'ve organized your inventory updates below (**${batchActions.length} items**).\n\n'
              'You can edit quantities, switch storage locations (Fridge, Freezer, Pantry), or change actions. Tap **Apply Updates** to save them to your kitchen!',
          batchInventoryActions: batchActions,
          quickReplies: const [
            'What can I cook with my fridge?',
            'Show recipe ideas',
            'View shopping list',
          ],
        );
      }
    }

    // 0.5. MATCHA RECIPES (OPTIONS OR STRUCTURED RECIPE)
    if (lower.contains('matcha')) {
      final isSpecificLatte = lower.contains('latte') ||
          lower.contains('iced') ||
          lower.contains('milk') ||
          lower.contains('drink') ||
          lower.contains('matcha oat milk');

      final isSpecificPancake = lower.contains('pancake') || lower.contains('souffle');
      final isSpecificCookie = lower.contains('cookie') || lower.contains('cookies');

      if (isSpecificLatte) {
        return AiChatResponse(
          text: 'You have great ingredients for a refreshing Matcha Oat Milk Iced Latte! Here is your curated recipe from 식 studio:',
          structuredRecipe: const AiStructuredRecipe(
            title: 'Matcha Oat Milk Iced Latte',
            category: 'Beverage',
            cookingTime: '5 mins',
            difficulty: 'Easy',
            servings: 1,
            ingredients: [
              '1–2 tsp Japanese ceremonial matcha powder',
              '1 cup oat milk (or milk of your choice)',
              '1–2 tsp honey, agave, or simple syrup',
              'Ice cubes',
              '2–3 tbsp warm water (approx 80°C)',
            ],
            instructions: [
              'Whisk Matcha: In a small bowl, whisk matcha powder with 2–3 tbsp warm water until smooth, vibrant, and frothy.',
              'Prepare Glass: Fill a tall glass with ice cubes, then pour in cold oat milk and sweeten to taste.',
              'Layer & Serve: Slowly pour the whisked matcha over the cold milk to create an aesthetic two-toned layered effect. Stir gently & enjoy!',
            ],
            chefNote: 'Use warm water (not boiling) to preserve matcha\'s delicate sweetness and avoid bitterness.',
          ),
          quickReplies: const [
            'Add matcha to shopping list',
            'How to make Matcha Soufflé Pancakes?',
            'What can I cook with my fridge?',
          ],
        );
      }

      if (isSpecificPancake) {
        return AiChatResponse(
          text: 'Here is your recipe for cloud-like Matcha Soufflé Pancakes from 식 studio:',
          structuredRecipe: const AiStructuredRecipe(
            title: 'Fluffy Matcha Soufflé Pancakes',
            category: 'Dessert & Pastry',
            cookingTime: '20 mins',
            difficulty: 'Medium',
            servings: 2,
            ingredients: [
              '2 large eggs (separated into whites and yolks)',
              '2 tbsp granulated sugar',
              '2 tbsp all-purpose flour',
              '1 tbsp ceremonial matcha powder',
              '1 tbsp milk',
              '½ tsp vanilla extract',
              'Powdered sugar for dusting',
            ],
            instructions: [
              'Whisk Yolks: Whisk egg yolks, milk, and vanilla until pale. Sift in flour and matcha powder; gently fold until smooth.',
              'Whip Meringue: In a clean bowl, whip egg whites while gradually adding sugar until stiff, glossy peaks form.',
              'Fold Batter: Gently fold ⅓ of the meringue into the yolk mixture, then fold in the remaining meringue without deflating.',
              'Cook Low & Slow: Dollop batter onto a lightly oiled skillet on low heat. Add 1 tsp water, cover, and steam for 4–5 minutes each side.',
            ],
            chefNote: 'Keep the pan strictly on low heat with a tight lid to steam the pancakes through without burning.',
          ),
          quickReplies: const [
            'Add matcha to shopping list',
            'Matcha Oat Milk Iced Latte',
            'What can I cook with my fridge?',
          ],
        );
      }

      if (isSpecificCookie) {
        return AiChatResponse(
          text: 'Here is your recipe for chewy bakery-style Matcha Cookies from 식 studio:',
          structuredRecipe: const AiStructuredRecipe(
            title: 'Chewy Matcha White Chocolate Cookies',
            category: 'Baking',
            cookingTime: '25 mins',
            difficulty: 'Easy',
            servings: 8,
            ingredients: [
              '1 cup all-purpose flour',
              '1 tbsp culinary matcha powder',
              '½ cup unsalted butter (melted and cooled)',
              '⅓ cup granulated white sugar',
              '¼ cup brown sugar',
              '1 large egg yolk',
              '½ cup white chocolate chips',
              '¼ tsp baking soda & pinch of salt',
            ],
            instructions: [
              'Mix Dry: Whisk flour, matcha powder, baking soda, and salt in a bowl.',
              'Cream Wet: In another bowl, whisk melted butter with white sugar and brown sugar until glossy. Add egg yolk.',
              'Combine: Fold dry ingredients into wet until just combined. Gently fold in white chocolate chips.',
              'Bake: Scoop onto a parchment-lined baking sheet. Bake at 175°C (350°F) for 9–11 minutes until edges are set.',
            ],
            chefNote: 'Do not overbake! The cookies should be soft in the center when removed; they firm up into a chewy crumb as they cool.',
          ),
          quickReplies: const [
            'Add matcha to shopping list',
            'Matcha Oat Milk Iced Latte',
            'What can I cook with my fridge?',
          ],
        );
      }

      // Default Matcha options selection:
      return const AiChatResponse(
        text: 'Here are 3 curated matcha recipes from 식 studio. Tap a dish to view its studio recipe & cooking steps:',
        recipeOptions: [
          AiRecipeOption(
            title: 'Matcha Oat Milk Iced Latte',
            cookingTime: '5m',
            difficulty: 'Easy',
            category: 'Beverage',
            description: 'Layered velvety whisked ceremonial matcha over cold creamy oat milk.',
          ),
          AiRecipeOption(
            title: 'Fluffy Matcha Soufflé Pancakes',
            cookingTime: '20m',
            difficulty: 'Medium',
            category: 'Dessert',
            description: 'Cloud-like, airy Japanese soufflé pancakes dusted with ceremonial matcha.',
          ),
          AiRecipeOption(
            title: 'Chewy Matcha White Chocolate Cookies',
            cookingTime: '25m',
            difficulty: 'Easy',
            category: 'Baking',
            description: 'Bakery-style soft, chewy cookies with earthy matcha and sweet white chocolate.',
          ),
        ],
        quickReplies: [
          'Matcha Oat Milk Iced Latte',
          'Fluffy Matcha Soufflé Pancakes',
          'Chewy Matcha White Chocolate Cookies',
        ],
      );
    }

    // 1. COOKIE & BAKING INGREDIENT QUERIES
    if (lower.contains('cookie') ||
        lower.contains('cookies') ||
        (lower.contains('bake') && !lower.contains('potato')) ||
        lower.contains('baking') ||
        lower.contains('sweet treat')) {
      const cookieIngredients = [
        'All-Purpose Flour',
        'Unsalted Butter',
        'Brown Sugar',
        'Granulated White Sugar',
        'Eggs',
        'Pure Vanilla Extract',
        'Baking Soda',
        'Salt',
        'Semi-Sweet Chocolate Chips',
      ];

      final text = StringBuffer();
      text.writeln('Here is everything you need to make classic, bakery-style cookies:');
      text.writeln('');
      text.writeln('• **All-Purpose Flour** (2 cups / 250g) – Provides the core structure.');
      text.writeln('• **Unsalted Butter** (¾ cup / 170g, softened) – For rich flavor & tender crumb.');
      text.writeln('• **Brown Sugar** (¾ cup packed) – Crucial for a soft, chewy center.');
      text.writeln('• **Granulated White Sugar** (½ cup) – Helps create crisp golden edges.');
      text.writeln('• **Eggs** (1 whole + 1 yolk) – Adds moisture and binding.');
      text.writeln('• **Vanilla Extract** (1-2 tsp) – Enhances the aroma.');
      text.writeln('• **Baking Soda** (½ tsp) & **Fine Salt** (½ tsp) – For gentle lift & balancing sweetness.');
      text.writeln('• **Chocolate Chips or Chunks** (1 to 1½ cups) – Dark or semisweet.');
      text.writeln('');
      text.writeln('*Pro Baker Tip:* Chill your scooped dough in the fridge for at least 30 minutes before baking at 175°C (350°F). It stops spreading and creates an irresistible chewy texture!');

      return AiChatResponse(
        text: text.toString(),
        suggestedIngredients: cookieIngredients,
        quickReplies: const [
          'Add cookie ingredients to shopping list',
          'What can I substitute for eggs?',
          'What can I cook with my fridge?',
          'How long do I bake cookies?',
        ],
        actions: [
          AiChatAction(
            type: AiChatActionType.addToShoppingList,
            label: 'Add all Cookie Ingredients to Shopping List',
            payload: cookieIngredients,
          ),
          AiChatAction(
            type: AiChatActionType.addIngredientsToInventory,
            label: 'Add to Pantry / Fridge',
            payload: cookieIngredients,
          ),
        ],
      );
    }

    // 1.5. SPECIFIC STUDIO RECIPE SELECTIONS (FULL SEASONED CHEF RECIPES)
    // Soup noodles / Meehun soup query:
    if ((lower.contains('soup') && (lower.contains('noodle') || lower.contains('meehun'))) ||
        lower.contains('soup noodle') ||
        lower.contains('noodle soup') ||
        lower.contains('savory umami garlic broth')) {
      return AiChatResponse(
        text: 'Here is your recipe for deeply seasoned, aromatic noodle soup from 식 studio:',
        structuredRecipe: const AiStructuredRecipe(
          title: 'Savory Umami Garlic Broth Meehun Soup',
          category: 'Asian Noodle Soup',
          cookingTime: '12 mins',
          difficulty: 'Easy',
          servings: 1,
          ingredients: [
            '1 bundle Meehun or noodles',
            '450 ml seasoned broth (dashi, chicken stock, or water with bullion)',
            '2 cloves garlic (finely minced)',
            '1 slice fresh ginger (finely grated)',
            '1 tbsp light soy sauce',
            '½ tsp kosher salt & pinch of white pepper',
            '1 tsp toasted sesame oil',
            '1 tsp cooking oil (or butter)',
            '1 large egg (soft-boiled or gently poached in broth)',
            '1 scallion (thinly sliced, greens reserved for garnish)',
          ],
          instructions: [
            'Sizzle Aromatics: Heat 1 tsp oil in a small pot over medium heat. Sauté minced garlic, ginger, and scallion whites for 45 seconds until fragrant (do not burn).',
            'Infuse Broth: Pour in 450ml broth (or stock). Add 1 tbsp soy sauce, ½ tsp salt, and a pinch of white pepper. Bring to a rolling simmer for 3 minutes so flavors fuse deeply.',
            'Cook Noodles: Drop meehun directly into the simmering savory broth. Cook for 2–3 minutes until tender and springy.',
            'Finish & Emulsify: Turn off heat. Stir in 1 tsp toasted sesame oil. Ladle into a deep bowl, crack fresh pepper, and top with soft egg and scallion greens.',
          ],
          chefNote: 'Never boil soup noodles in plain unseasoned water! Blooming garlic and ginger in oil first, then building broth with soy sauce, salt, and sesame oil creates instant restaurant-depth flavor.',
        ),
        quickReplies: const [
          'Add garlic & noodles to shopping list',
          'Sichuan Chili Crisp Scallion Oil Tossed Noodles',
          'What can I cook with my fridge?',
        ],
      );
    }

    // Crispy Lemon Butter Chicken Steak query:
    if ((lower.contains('chicken') && (lower.contains('steak') || lower.contains('lemon') || lower.contains('sear') || lower.contains('baste'))) ||
        lower.contains('crispy lemon butter')) {
      return AiChatResponse(
        text: 'Here is your recipe for juicy bistro-style Pan-Seared Lemon Butter Chicken:',
        structuredRecipe: const AiStructuredRecipe(
          title: 'Crispy Lemon Butter Pan-Seared Chicken Steak',
          category: 'Bistro Main',
          cookingTime: '18 mins',
          difficulty: 'Medium',
          servings: 1,
          ingredients: [
            '1-2 chicken breasts or thighs (patted dry)',
            '2 tbsp unsalted butter',
            '3 cloves garlic (crushed)',
            '½ fresh lemon (juiced)',
            '½ tsp kosher salt & ½ tsp cracked black pepper',
            '1 sprig fresh rosemary or thyme (optional)',
            '1 tbsp olive oil or cooking oil',
          ],
          instructions: [
            'Season & Sear: Generously season chicken on all sides with salt and black pepper. Heat oil in a heavy skillet over medium-high heat; sear chicken 5–6 minutes until deeply golden.',
            'Butter Baste: Flip chicken. Add butter, crushed garlic, and herbs to the skillet. As butter foams, tilt pan and repeatedly spoon the hot garlic butter over the chicken for 3–4 minutes.',
            'Lemon Pan Jus: Squeeze fresh lemon juice directly into pan juices, swirling vigorously into a glossy emulsion.',
            'Rest & Slice: Let chicken rest on a warm board for 3 minutes, slice into medallions, and spoon the fragrant pan sauce over the top.',
          ],
          chefNote: 'Continuous butter basting locks in moisture and develops a rich, savory crust without drying out the chicken.',
        ),
        quickReplies: const [
          'Add chicken to shopping list',
          'Side dishes for lemon butter chicken',
          'What can I cook with my fridge?',
        ],
      );
    }

    // Sichuan Chili Crisp Scallion Noodles query:
    if ((lower.contains('chili crisp') && lower.contains('noodle')) ||
        lower.contains('scallion oil') ||
        lower.contains('sichuan chili crisp scallion oil tossed noodles') ||
        lower.contains('tossed noodle')) {
      return AiChatResponse(
        text: 'Here is your recipe for fiery, fragrant Sichuan Scallion Oil Tossed Noodles:',
        structuredRecipe: const AiStructuredRecipe(
          title: 'Sichuan Chili Crisp Scallion Oil Tossed Noodles',
          category: 'Asian Bistro',
          cookingTime: '12 mins',
          difficulty: 'Easy',
          servings: 1,
          ingredients: [
            '1 portion noodles or meehun',
            '1.5 tbsp Lao Gan Ma chili crisp',
            '2 cloves garlic (finely minced)',
            '1 scallion (sliced into ribbons)',
            '1 tbsp light soy sauce & 1 tsp dark soy sauce',
            '1 tsp rice vinegar & 1 tsp toasted sesame oil',
            '¼ tsp salt & pinch of sugar',
            '1.5 tbsp neutral cooking oil',
          ],
          instructions: [
            'Cook Noodles: Boil noodles in salted water until chewy and al dente. Drain thoroughly and place in a heatproof bowl.',
            'Assemble Aromatics: Heap minced garlic, scallion whites, and pinch of salt on top of the cooked noodles.',
            'Sizzling Oil Splash: Heat cooking oil in a small pan until shimmering hot; pour directly over the garlic and scallions to release intense toasted aromas.',
            'Toss with Sauce: Add Lao Gan Ma, soy sauce, dark soy sauce, vinegar, and sesame oil. Toss vigorously until every strand is glossy and spicy.',
          ],
          chefNote: 'Splashing hot oil directly onto raw garlic and scallion blooming unlocks rich sweetness and eliminates raw pungency.',
        ),
        quickReplies: const [
          'Add Lao Gan Ma to shopping list',
          'Savory Umami Garlic Broth Meehun Soup',
          'What can I cook with my fridge?',
        ],
      );
    }

    // Caramelized Garlic Soy Glazed Pork Chops query:
    if ((lower.contains('pork') && (lower.contains('chop') || lower.contains('glaze') || lower.contains('soy'))) ||
        lower.contains('caramelized garlic soy')) {
      return AiChatResponse(
        text: 'Here is your recipe for sizzling Garlic Soy Glazed Pork Chops:',
        structuredRecipe: const AiStructuredRecipe(
          title: 'Caramelized Garlic Soy Glazed Pork Chops',
          category: 'Comfort Main',
          cookingTime: '20 mins',
          difficulty: 'Medium',
          servings: 2,
          ingredients: [
            '2 thick pork chops (bone-in or boneless)',
            '2 tbsp soy sauce',
            '1 tbsp honey or brown sugar',
            '3 cloves garlic (minced)',
            '1 tbsp butter',
            '½ tsp kosher salt & coarse black pepper',
            '1 tbsp cooking oil',
          ],
          instructions: [
            'Sear Crisp: Pat pork chops dry; season with salt and black pepper. Sear in smoking hot oil for 4 minutes per side until deeply browned.',
            'Build Reduction: Reduce heat to medium. Add butter, minced garlic, soy sauce, and honey.',
            'Glaze & Lacquer: Turn pork chops repeatedly in the bubbling reduction for 2 minutes until evenly coated in a sticky savory glaze.',
            'Rest: Rest for 4 minutes on a cutting board before slicing to preserve every drop of juice.',
          ],
          chefNote: 'Letting the honey and soy caramelize around the pork chops creates a smoky umami glaze that pairs wonderfully with rice or noodles.',
        ),
        quickReplies: const [
          'Add pork chops to shopping list',
          'Garlic Butter Scallion Fried Rice',
          'What can I cook with my fridge?',
        ],
      );
    }

    // Smoky Cheddar & Ham Skillet Brioche Melt query:
    if ((lower.contains('brioche') && lower.contains('melt')) ||
        lower.contains('cheddar & ham skillet brioche melt') ||
        (lower.contains('ham') && lower.contains('cheddar') && lower.contains('melt'))) {
      return AiChatResponse(
        text: 'Here is your recipe for the ultimate molten Skillet Brioche Melt:',
        structuredRecipe: const AiStructuredRecipe(
          title: 'Smoky Cheddar & Ham Skillet Brioche Melt',
          category: 'Cafe Comfort',
          cookingTime: '10 mins',
          difficulty: 'Easy',
          servings: 1,
          ingredients: [
            '2 thick slices brioche or sourdough bread',
            '3 slices Irish traditional ham',
            '50 g Irish red cheddar (thickly sliced or shredded)',
            '1 tbsp pickled jalapeños or grain mustard',
            '1.5 tbsp salted butter',
            'Pinch of freshly cracked black pepper',
          ],
          instructions: [
            'Butter Bread: Generously butter the outer sides of both bread slices.',
            'Layer Filling: Inside, layer half the red cheddar, sliced ham, pickled jalapeños, black pepper, and remaining cheddar.',
            'Skillet Steam: Place sandwich in skillet on medium-low heat. Cover with a lid for 3 minutes to melt cheddar fully.',
            'Crisp Crust: Uncover, flip, press lightly with spatula, and toast 3 minutes until exterior is deep golden and shatteringly crisp.',
          ],
          chefNote: 'Covering the skillet for the first 3 minutes creates steam that melts the cheese right to the center without burning the buttered crust.',
        ),
        quickReplies: const [
          'Add cheddar to shopping list',
          'Crispy Lemon Butter Pan-Seared Chicken Steak',
          'What can I cook with my fridge?',
        ],
      );
    }

    // 2. "I WANNA COOK" / MEAL & RECIPE INTENT (GENERATE NEW NON-DASHBOARD CHOICES)
    if (lower.contains('wanna cook') ||
        lower.contains('want to cook') ||
        lower.contains('what can i cook') ||
        lower.contains('what can i make') ||
        lower.contains('recipe') ||
        lower.contains('recipes') ||
        lower.contains('dinner') ||
        lower.contains('lunch') ||
        lower.contains('hungry') ||
        lower.contains('meal ideas') ||
        lower == 'cook' ||
        lower.contains('suggest recipe')) {
      final dashboardTitles = availableRecipes.map((r) => r.title.toLowerCase().trim()).toSet();

      final allCandidates = <({AiRecipeOption option, int matchScore})>[
        (
          option: const AiRecipeOption(
            title: 'Crispy Lemon Butter Pan-Seared Chicken Steak',
            cookingTime: '18m',
            difficulty: 'Medium',
            category: 'Bistro Main',
            description: 'Golden chicken pan-basted in bubbling garlic butter, fresh lemon pan sauce, and cracked pepper.',
          ),
          matchScore: fridgeItemNames.any((i) => i.toLowerCase().contains('chicken')) ? 100 : 40,
        ),
        (
          option: const AiRecipeOption(
            title: 'Sichuan Chili Crisp Scallion Oil Tossed Noodles',
            cookingTime: '12m',
            difficulty: 'Easy',
            category: 'Asian Bistro',
            description: 'Springy noodles tossed in sizzling garlic scallion oil, savory soy sauce, and Lao Gan Ma chili crisp.',
          ),
          matchScore: (fridgeItemNames.any((i) => i.toLowerCase().contains('noodle') || i.toLowerCase().contains('meehun')) ? 50 : 0) +
              (fridgeItemNames.any((i) => i.toLowerCase().contains('lao gan ma') || i.toLowerCase().contains('chili')) ? 50 : 30),
        ),
        (
          option: const AiRecipeOption(
            title: 'Savory Umami Garlic Broth Meehun Soup',
            cookingTime: '12m',
            difficulty: 'Easy',
            category: 'Asian Noodle Soup',
            description: 'Aromatic garlic-infused savory seasoned broth with tender meehun noodles, sesame oil, and soft egg.',
          ),
          matchScore: fridgeItemNames.any((i) => i.toLowerCase().contains('meehun') || i.toLowerCase().contains('noodle')) ? 90 : 35,
        ),
        (
          option: const AiRecipeOption(
            title: 'Caramelized Garlic Soy Glazed Pork Chops',
            cookingTime: '20m',
            difficulty: 'Medium',
            category: 'Comfort Main',
            description: 'Tender thick pork chops seared crisp and lacquered in a rich bubbling garlic, soy, and honey reduction.',
          ),
          matchScore: fridgeItemNames.any((i) => i.toLowerCase().contains('pork')) ? 100 : 30,
        ),
        (
          option: const AiRecipeOption(
            title: 'Smoky Cheddar & Ham Skillet Brioche Melt',
            cookingTime: '10m',
            difficulty: 'Easy',
            category: 'Cafe Comfort',
            description: 'Crusty golden bread toasted in butter with molten Irish red cheddar, sliced ham, and cracked black pepper.',
          ),
          matchScore: (fridgeItemNames.any((i) => i.toLowerCase().contains('cheddar') || i.toLowerCase().contains('cheese')) ? 50 : 20) +
              (fridgeItemNames.any((i) => i.toLowerCase().contains('ham')) ? 50 : 20),
        ),
        (
          option: const AiRecipeOption(
            title: 'Silky Egg Drop Miso Garlic Noodle Pot',
            cookingTime: '12m',
            difficulty: 'Easy',
            category: 'Japanese Comfort',
            description: 'Piping hot umami dashi broth with ribboned eggs, dissolved white miso, sautéed garlic, and tender noodles.',
          ),
          matchScore: (fridgeItemNames.any((i) => i.toLowerCase().contains('miso')) ? 50 : 20) +
              (fridgeItemNames.any((i) => i.toLowerCase().contains('egg')) ? 50 : 20),
        ),
        (
          option: const AiRecipeOption(
            title: 'Garlic Butter Scallion Fried Rice with Fried Egg',
            cookingTime: '10m',
            difficulty: 'Easy',
            category: 'Quick Comfort',
            description: 'Fluffy jasmine rice tossed in sizzling browned garlic butter and soy sauce, topped with a runny fried egg.',
          ),
          matchScore: fridgeItemNames.any((i) => i.toLowerCase().contains('rice')) ? 90 : 40,
        ),
      ];

      // CRITICAL: Strictly filter out any dish that is already on the dashboard!
      final filtered = allCandidates
          .where((c) => !dashboardTitles.contains(c.option.title.toLowerCase().trim()))
          .toList()
        ..sort((a, b) => b.matchScore.compareTo(a.matchScore));

      final topOptions = (filtered.isNotEmpty ? filtered : allCandidates)
          .take(3)
          .map((c) => c.option)
          .toList();

      return AiChatResponse(
        text: fridgeItemNames.isNotEmpty
            ? 'Based on your kitchen inventory (**${fridgeItemNames.take(4).join(', ')}**), here are 3 fresh, chef-seasoned choices (distinct from your dashboard):'
            : 'Here are 3 delicious, well-seasoned recipe choices from 식 studio:',
        recipeOptions: topOptions,
        quickReplies: topOptions.map((r) => r.title).toList(),
      );
    }

    // 3. COMMON INGREDIENT SUBSTITUTION QUERIES
    if (lower.contains('substitute') ||
        lower.contains('substitution') ||
        lower.contains('replace') ||
        lower.contains('no mirin') ||
        lower.contains('no gochujang') ||
        lower.contains('no soy sauce') ||
        lower.contains('don\'t have')) {
      final text = StringBuffer();
      text.writeln('Here are handy culinary substitutions you can use immediately:');
      text.writeln('');
      if (lower.contains('gochujang')) {
        text.writeln('• **Gochujang:** Mix 1 tbsp Sriracha or red pepper powder (Gochugaru) + 1 tsp Miso paste or Doenjang + 1 tsp Honey/Sugar.');
      } else if (lower.contains('mirin')) {
        text.writeln('• **Mirin:** Use 1 tbsp Dry White Wine or Sake + ½ tsp Sugar or honey (or 1 tbsp apple cider vinegar + pinch of sugar).');
      } else if (lower.contains('doenjang') || lower.contains('miso')) {
        text.writeln('• **Doenjang:** White or Yellow Japanese Miso works wonderfully. Use 1:1 ratio.');
      } else if (lower.contains('sesame oil')) {
        text.writeln('• **Toasted Sesame Oil:** Perilla oil (Deulgireum) or lightly toasted sesame seeds in neutral cooking oil.');
      } else if (lower.contains('egg') || lower.contains('eggs')) {
        text.writeln('• **Eggs in Baking:** ¼ cup unsweetened applesauce, OR ½ mashed ripe banana, OR 1 tbsp ground flaxseed mixed with 3 tbsp water.');
      } else {
        text.writeln('• **Gochujang:** Sriracha + Miso paste + hint of honey.');
        text.writeln('• **Mirin:** White cooking wine/sake + ½ tsp sugar.');
        text.writeln('• **Soy Sauce:** Tamari, Coconut Aminos, or a splash of Fish Sauce diluted with water.');
        text.writeln('• **Cornstarch:** All-purpose flour (use 2x amount) or Potato Starch.');
      }
      text.writeln('');
      text.writeln('Would you like a specific replacement for any ingredient in your pantry?');

      return AiChatResponse(
        text: text.toString(),
        quickReplies: const [
          'Gochujang substitute',
          'Mirin substitute',
          'Egg substitute for baking',
          'What can I cook with my fridge?',
        ],
      );
    }

    // 4. SPECIFIC INGREDIENT DISH SEARCH (e.g. "tofu", "kimchi", "rice", "pork")
    final cleanPrompt = prompt.trim();
    final matchedRecipes = availableRecipes.where((r) {
      final inTitle = r.title.toLowerCase().contains(lower) || r.koreanTitle.contains(cleanPrompt);
      final inIngredients = r.ingredients.any((i) => i.name.toLowerCase().contains(lower));
      return inTitle || inIngredients;
    }).take(3).toList();

    if (matchedRecipes.isNotEmpty && cleanPrompt.length < 30) {
      return AiChatResponse(
        text: 'Found ${matchedRecipes.length} dishes highlighting **$cleanPrompt** in your recipe collection:\n\n'
            'Tap a card below to start cooking or check missing ingredients.',
        recommendedRecipes: matchedRecipes,
        quickReplies: [
          'How do I prep $cleanPrompt?',
          'What else pairs with $cleanPrompt?',
          'Add $cleanPrompt to shopping list',
          'Show all recipes',
        ],
      );
    }

    // 5. SHOPPING LIST ADDITION INTENT VIA CHAT
    if (lower.startsWith('add') && (lower.contains('shopping') || lower.contains('want') || lower.contains('buy'))) {
      final rawItems = cleanPrompt
          .replaceAll(RegExp(r'\b(add|to|my|shopping|list|want|buy|please|items|item)\b', caseSensitive: false), '')
          .split(RegExp(r'[,&]|\band\b', caseSensitive: false))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      if (rawItems.isNotEmpty) {
        return AiChatResponse(
          text: 'I can add these items to your Shopping Want List:\n${rawItems.map((e) => '• $e').join('\n')}',
          quickReplies: const [
            'View my shopping list',
            'What can I cook with my fridge?',
          ],
          actions: [
            AiChatAction(
              type: AiChatActionType.addToShoppingList,
              label: 'Add to Shopping List',
              payload: rawItems,
            ),
          ],
        );
      }
    }

    // 6. DEFAULT INTELLECTUAL CULINARY ASSISTANT RESPONSE
    return AiChatResponse(
      text: 'I\'m your **식 (sik)** culinary assistant!\n\n'
          'You can ask me anything about:\n'
          '• **Baking & Ingredients:** e.g. *"what ingredient i should get if i wanna make cookies"*\n'
          '• **Fridge Cooking Ideas:** e.g. *"what can I cook with tofu and eggs?"*\n'
          '• **Korean Substitutions:** e.g. *"what can I use instead of Gochujang or Mirin?"*\n'
          '• **App Automation:** e.g. *"add milk and flour to shopping list"* or *"clear fridge filters"*.\n\n'
          'What are you looking to create today?',
      quickReplies: const [
        'What ingredients do I need for cookies?',
        'What can I cook with what I have?',
        'Korean sauce substitutions',
        'Quick 15-minute dinner ideas',
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ONLINE OPENAI INTEGRATION
  // ---------------------------------------------------------------------------
  static Future<AiChatResponse?> _callOpenAi({
    required String apiKey,
    required String prompt,
    required List<FridgeItem> fridgeItems,
    required List<Recipe> availableRecipes,
    required List<AiChatMessage> history,
    List<String>? preferredCuisines,
  }) async {
    final fridgeItemsList = fridgeItems.where((i) => i.location == StorageLocation.fridge).map((e) => e.name).join(', ');
    final freezerItemsList = fridgeItems.where((i) => i.location == StorageLocation.freezer).map((e) => e.name).join(', ');
    final pantryItemsList = fridgeItems.where((i) => i.location == StorageLocation.pantry).map((e) => e.name).join(', ');
    final seasoningItemsList = fridgeItems.where((i) => i.location == StorageLocation.seasoning).map((e) => e.name).join(', ');
    final recipeTitles = availableRecipes.map((r) => r.title).take(15).join(', ');
    final cuisinesList = preferredCuisines != null && preferredCuisines.isNotEmpty
        ? preferredCuisines.join(', ')
        : 'Versatile Global, Western, Italian, Japanese, Chinese, Fusion, Korean';

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': '''You are 식 (sik) AI, a master chef and culinary intelligence assistant.
The user is asking questions about cooking, ingredients, baking, recipes, or fridge planning.

USER'S PREFERRED CUISINES & STYLES: [$cuisinesList]

CURRENT USER KITCHEN INVENTORY:
- Fridge: [${fridgeItemsList.isEmpty ? 'None' : fridgeItemsList}]
- Freezer: [${freezerItemsList.isEmpty ? 'None' : freezerItemsList}]
- Pantry: [${pantryItemsList.isEmpty ? 'None' : pantryItemsList}]
- Seasonings & Condiments: [${seasoningItemsList.isEmpty ? 'None' : seasoningItemsList}]

EXISTING DASHBOARD RECIPES (DO NOT DUPLICATE OR SUGGEST THESE):
[$recipeTitles]
CRITICAL RULE: The user already has the recipes above prominently on their dashboard. You MUST NEVER suggest or repeat any of these recipes! Provide exciting, fresh, brand-new culinary ideas.

CULINARY SEASONING & FLAVOR EXCELLENCE (CRITICAL):
1. NEVER generate bland, watery, or unseasoned food! Under no circumstances should soup noodle broth be made of plain water without savory seasoning and salt.
2. Every savory recipe MUST have deep, balanced, authentic seasoning:
   - Savory base: salt, soy sauce, dashi broth, chicken/vegetable stock, miso, boullion, or fish sauce.
   - Aromatics: minced garlic, scallion, ginger, shallots, or onions.
   - Umami & rich mouthfeel: butter, toasted sesame oil, olive oil, or chili crisp.
   - Balance & acidity: fresh lemon juice, rice vinegar, or black pepper.
3. INGREDIENT USAGE RULES:
   - Heavily prioritize and feature the user's actual ingredients from Fridge, Freezer, and Pantry.
   - Universal culinary staples (salt, black pepper, cooking oil, water/broth base, garlic) can ALWAYS be included to ensure dishes taste delicious and gourmet.
   - If a key flavor enhancer is recommended (e.g. 1 tbsp soy sauce, 1 tsp sesame oil, 1 pinch salt), include it clearly in the ingredients list.
4. CUISINE VARIETY:
   - Match the user's ingredients and preferred cuisines ($cuisinesList).
   - If they have Western items (butter, ham, cheddar, chicken, courgette, lemon), suggest French Bistro, Italian Pasta, or Cafe Comfort.
   - If they have Asian condiments (Lao Gan Ma, miso, meehun, rice), suggest Sichuan Chili Scallion bowls, Japanese Dashi Noodle pots, or Thai Tom Yum.
   - Do NOT default everything to Korean unless Korean ingredients or style are requested.

STRICT FORMATTING & RECIPE RULES:
1. When the user asks for recipes in general, dinner/lunch ideas, or what to cook (e.g. "what can i cook", "wanna cook", "give me dinner ideas", "pasta recipes", "soup noodles"):
Give a brief 1-sentence appetizing chef intro and provide 2 to 4 curated recipe options using this exact structure:
OPTIONS:
- Title: [Exciting Recipe Name] | Time: [e.g. 15m] | Difficulty: [Easy/Medium/Hard] | Category: [Bistro/Asian Fusion/Comfort/Pasta] | Desc: [1 sentence mouthwatering description detailing flavor and seasoning]
- Title: [Exciting Recipe Name] | Time: [e.g. 20m] | Difficulty: [Easy/Medium] | Category: [Category] | Desc: [1 sentence mouthwatering description detailing flavor and seasoning]
- Title: [Exciting Recipe Name] | Time: [e.g. 25m] | Difficulty: [Easy/Medium] | Category: [Category] | Desc: [1 sentence mouthwatering description detailing flavor and seasoning]

2. When the user selects or explicitly asks for a specific recipe (e.g. "how to cook X", "show me recipe for X", or clicks an option):
Provide the complete recipe using this clean structured format:
RECIPE:
Title: [Recipe Name]
Category: [Category]
Time: [e.g. 18 mins]
Difficulty: [Easy / Medium / Chef]
Servings: 1-2
Ingredients:
- [Specific quantity and ingredient, including essential seasonings like salt, pepper, aromatics, sauces]
Instructions:
1. [Prep & Aromatics]: [Clear step instruction]
2. [Sear / Sauté / Simmer]: [Clear step instruction with heat control and basting/seasoning]
3. [Finish & Serve]: [Garnish and presentation]
Tip: [1 practical chef tip for texture and flavor elevation]

3. For culinary inquiries or substitutions, provide structured, concise, expert guidance.
4. At the end of every response, suggest 2-4 short follow-up prompts on a line starting with:
SUGGESTIONS: suggestion 1 | suggestion 2 | suggestion 3'''
      },
    ];

    // Add recent conversation history for multi-turn context
    for (final m in history.take(6)) {
      messages.add({
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.text,
      });
    }

    messages.add({
      'role': 'user',
      'content': prompt,
    });

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 700,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final rawContent = data['choices']?[0]?['message']?['content'] as String?;
      if (rawContent != null && rawContent.isNotEmpty) {
        String mainText = rawContent;
        List<String> quickReplies = [];

        if (rawContent.contains('SUGGESTIONS:')) {
          final parts = rawContent.split('SUGGESTIONS:');
          mainText = parts[0].trim();
          if (parts.length > 1) {
            quickReplies = parts[1]
                .split('|')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
          }
        }

        // Parse structured recipe or options from the response text
        final parsed = AiRecipeParser.parse(mainText);
        final displayText = parsed.cleanText;

        if (quickReplies.isEmpty) {
          if (parsed.options.isNotEmpty) {
            quickReplies = parsed.options.map((o) => o.title).toList();
          } else {
            quickReplies = [
              'What can I cook with what I have?',
              'Show ingredient substitutions',
              'Add to shopping list',
            ];
          }
        }

        // Check if recipe titles are mentioned in the response to attach preview cards
        final matchedRecipes = availableRecipes
            .where((r) => mainText.toLowerCase().contains(r.title.toLowerCase()))
            .take(2)
            .toList();

        return AiChatResponse(
          text: displayText,
          quickReplies: quickReplies,
          recommendedRecipes: matchedRecipes,
          recipeOptions: parsed.options,
          structuredRecipe: parsed.recipe,
        );
      }
    } else {
      // ignore: avoid_print
      print('[AiChatService] OpenAI HTTP ${response.statusCode}: ${response.body}');
    }
    return null;
  }

  static bool _isBatchInventoryIntent(String lower) {
    if (lower.contains('update inventory') ||
        lower.contains('update my inventory') ||
        lower.contains('update a lot of stuff') ||
        lower.contains('grocery haul') ||
        lower.contains('pantry haul') ||
        lower.contains('i bought groceries') ||
        lower.contains('bought groceries') ||
        lower.contains('got groceries') ||
        lower.contains('restock') ||
        lower.contains('stock up')) {
      return true;
    }
    if ((lower.startsWith('add ') || lower.startsWith('bought ') || lower.startsWith('i bought ')) &&
        (lower.contains(',') || lower.contains('&') || lower.contains(' and '))) {
      return true;
    }
    return false;
  }

  static List<InventoryBatchActionItem> _parseBatchInventoryActions(
    String prompt,
    String lower,
    List<FridgeItem> currentFridgeItems,
  ) {
    String cleaned = prompt;
    final prefixPatterns = [
      RegExp(r'^(update\s+(a\s+lot\s+of\s+stuff\s+in\s+)?(my\s+)?inventory\s*[:\-\n]?)', caseSensitive: false),
      RegExp(r'^(i\s+bought\s+groceries\s*[:\-\n]?)', caseSensitive: false),
      RegExp(r'^(grocery\s+haul\s*[:\-\n]?)', caseSensitive: false),
      RegExp(r'^(pantry\s+haul\s*[:\-\n]?)', caseSensitive: false),
      RegExp(r'^(add\s+(a\s+list\s+of\s+stuff\s+)?to\s+inventory\s*[:\-\n]?)', caseSensitive: false),
      RegExp(r'^(i\s+bought\s*)', caseSensitive: false),
      RegExp(r'^(bought\s*)', caseSensitive: false),
    ];

    for (final p in prefixPatterns) {
      cleaned = cleaned.replaceFirst(p, '').trim();
    }

    final tokens = cleaned
        .split(RegExp(r'[\n,;]|\band\b', caseSensitive: false))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final List<InventoryBatchActionItem> items = [];
    int counter = 0;

    for (final rawToken in tokens) {
      if (rawToken.length < 2) continue;
      final tokenLower = rawToken.toLowerCase();

      // Detect action type
      BatchActionType actionType = BatchActionType.add;
      if (tokenLower.contains('remove') ||
          tokenLower.contains('delete') ||
          tokenLower.contains('finished') ||
          tokenLower.contains('finish') ||
          tokenLower.contains('used up') ||
          tokenLower.contains('out of') ||
          tokenLower.contains('ate') ||
          tokenLower.contains('expired') ||
          tokenLower.contains('throw away') ||
          tokenLower.contains('threw away')) {
        actionType = BatchActionType.remove;
      } else if (tokenLower.contains('set') ||
          tokenLower.contains('update') ||
          tokenLower.contains('low') ||
          tokenLower.contains('running low')) {
        actionType = BatchActionType.update;
      }

      // Detect storage location
      StorageLocation location;
      if (tokenLower.contains('freezer')) {
        location = StorageLocation.freezer;
      } else if (tokenLower.contains('seasoning') || tokenLower.contains('spice')) {
        location = StorageLocation.seasoning;
      } else if (tokenLower.contains('pantry')) {
        location = StorageLocation.pantry;
      } else if (tokenLower.contains('fridge')) {
        location = StorageLocation.fridge;
      } else {
        location = IngredientIntelligence.autoDetectLocation(tokenLower);
      }

      // Detect quantity
      String quantity = 'Plenty';
      String status = 'Have';

      if (tokenLower.contains('low') || tokenLower.contains('running low')) {
        quantity = 'Low';
        status = 'Running low';
      } else {
        final qtyRegex = RegExp(
          r'(\b\d+(\.\d+)?\s*(kg|g|lbs?|oz|ml|l|packs?|cartons?|blocks?|cans?|dozens?|bunches?|pieces?|pcs)?\b|\b(a|an|one|two|three|four|five|six|some|plenty|half)\b)',
          caseSensitive: false,
        );
        final m = qtyRegex.firstMatch(tokenLower);
        if (m != null && m.group(0) != null) {
          final matched = m.group(0)!.trim();
          if (matched != 'a' && matched != 'an') {
            quantity = matched;
          }
        }
      }

      // Clean item name
      String name = rawToken;
      name = name.replaceAll(RegExp(
        r'\b(remove|delete|finished|finish|used up|out of|expired|ate|threw away|throw away|add|bought|got|put|set|to|in|into|the|my|of|a|an|is|are|freezer|pantry|fridge|running low|low|plenty|some)\b',
        caseSensitive: false,
      ), ' ');
      name = name.replaceAll(RegExp(r'^\d+(\.\d+)?\s*(kg|g|packs?|cans?|pieces?|pcs)?\s*', caseSensitive: false), '');
      name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

      if (name.isEmpty) {
        name = rawToken.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').trim();
      }

      final capitalized = name.split(' ').map((w) {
        if (w.isEmpty) return w;
        return w[0].toUpperCase() + w.substring(1).toLowerCase();
      }).join(' ');

      if (capitalized.trim().isNotEmpty) {
        items.add(
          InventoryBatchActionItem(
            id: 'batch_${DateTime.now().millisecondsSinceEpoch}_${counter++}',
            name: capitalized.trim(),
            location: location,
            quantityDisplay: quantity,
            status: status,
            actionType: actionType,
            isSelected: true,
          ),
        );
      }
    }

    return items;
  }
}
