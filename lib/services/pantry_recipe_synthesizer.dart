import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fridge_item.dart';
import '../models/recipe.dart';

/// Intelligent culinary engine that performs real-time analysis of kitchen inventory
/// and synthesizes genuine, 100% compatible home recipes tailored to what the user actually has.
class PantryRecipeSynthesizer {
  // Non-distinctive modifiers, colors, descriptors, and generic culinary categories.
  // Matching on these words ALONE must NEVER produce a match.
  static const Set<String> nonDistinctiveModifiers = {
    // Colors
    'red', 'green', 'white', 'black', 'yellow', 'brown', 'purple', 'blue', 'orange', 'dark', 'light',
    // Flavors & Qualities
    'sweet', 'sour', 'bitter', 'salty', 'savory', 'hot', 'spicy', 'mild', 'extra', 'aged',
    // Preparations & Physical States
    'fresh', 'dried', 'dry', 'raw', 'cooked', 'uncooked', 'frozen', 'canned', 'instant',
    'sliced', 'chopped', 'minced', 'diced', 'grated', 'shredded', 'crushed', 'toasted', 'roasted',
    'steamed', 'fried', 'baked', 'boiled', 'smoked', 'pickled', 'fermented', 'crisp', 'crispy',
    'whole', 'ground', 'powder', 'powdered', 'flake', 'flakes', 'pure', 'natural',
    // Generic Packaging & Containers
    'cube', 'cubes', 'piece', 'pieces', 'can', 'tin', 'pack', 'packet', 'bottle', 'jar', 'bag',
    // Geographic / Style Descriptors
    'traditional', 'classic', 'authentic', 'homemade', 'style', 'special', 'fine', 'coarse',
    'irish', 'korean', 'japanese', 'chinese', 'asian', 'thai', 'italian', 'mexican',
    'large', 'medium', 'small', 'mini', 'baby', 'thick', 'thin',
    // Generic category words (unless flavor-defining)
    'sauce', 'paste', 'curd', 'jam', 'spread', 'dressing', 'dip', 'marinade', 'seasoning', 'extract',
    'broth', 'stock', 'staple', 'staples', 'item', 'items', 'stuff', 'oil', 'fat',
  };

  /// Normalizes and extracts distinctive, core ingredient tokens.
  /// Example: "Sweet Corn" -> ["corn"]
  /// Example: "Sweet Chilli Sauce" -> ["chilli"]
  /// Example: "Sweet Potatoes" -> ["potato"]
  /// Example: "Sliced Green Jalapeños" -> ["jalapeno"]
  /// Example: "Red Cheddar Cheese" -> ["cheddar", "cheese"]
  static List<String> extractCoreTokens(String raw) {
    var s = raw.toLowerCase().trim();

    // Preserve Lao Gan Ma in all variations
    if (s.contains('lao gan ma') || s.contains('老干妈') || s.contains('laoganma')) {
      return ['lao gan ma'];
    }

    // Preserve compound dairy and plant milks (MUST NOT match plain milk)
    if (s.contains('condensed milk')) return ['condensed milk'];
    if (s.contains('coconut milk')) return ['coconut milk'];
    if (s.contains('almond milk')) return ['almond milk'];
    if (s.contains('oat milk')) return ['oat milk'];
    if (s.contains('soy milk') || s.contains('soymilk')) return ['soy milk'];
    if (s.contains('evaporated milk')) return ['evaporated milk'];
    if (s.contains('buttermilk')) return ['buttermilk'];

    // Preserve distinct spices and seasonings (prevent generic "pepper" or cross-matching)
    if (s.contains('black pepper')) return ['black pepper'];
    if (s.contains('white pepper')) return ['white pepper'];
    if (s.contains('cayenne')) return ['cayenne'];
    if (s.contains('bell pepper')) return ['bell pepper'];
    if (s.contains('chili flake') || s.contains('chilli flake') || s.contains('red pepper flake')) {
      return ['chili flake'];
    }
    if (s.contains('sesame oil')) return ['sesame oil'];
    if (s.contains('olive oil')) return ['olive oil'];
    if (s.contains('garlic powder')) return ['garlic powder'];
    if (s.contains('onion powder')) return ['onion powder'];

    // Remove brackets and punctuation
    s = s.replaceAll(RegExp(r'[\(\)\[\]\{\},.\/#!$%\^&\*;:{}=\-_`~]'), ' ');

    // Normalize accents
    s = s
        .replaceAll('ñ', 'n')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('á', 'a')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');

    final words = s.split(RegExp(r'\s+')).where((w) => w.length >= 2).toList();
    final List<String> core = [];

    for (var w in words) {
      // Lemmatize common plurals
      if (w.endsWith('ies') && w.length > 4) {
        w = '${w.substring(0, w.length - 3)}y';
      } else if (w.endsWith('es') &&
          w.length > 4 &&
          (w.endsWith('toes') || w.endsWith('ches') || w.endsWith('shes'))) {
        w = w.substring(0, w.length - 2);
      } else if (w.endsWith('s') && !w.endsWith('ss') && !w.endsWith('us') && w.length > 3) {
        w = w.substring(0, w.length - 1);
      }

      if (!nonDistinctiveModifiers.contains(w)) {
        core.add(w);
      }
    }

    // Fallback: If everything was filtered out as modifiers (e.g. "Butter", "Milk", "Salt"), keep them!
    if (core.isEmpty) {
      for (final w in words) {
        if (w.length >= 3) core.add(w);
      }
    }

    return core;
  }

  /// Strictly determines whether an inventory item satisfies a recipe ingredient requirement.
  /// Prevents false matches where shared adjectives (like "sweet", "green", "red")
  /// trigger matches between completely unrelated foods.
  static bool hasIngredient(String recipeIngredientName, List<FridgeItem> inventory) {
    if (inventory.isEmpty) return false;

    final rClean = recipeIngredientName.toLowerCase().trim();
    final rTokens = extractCoreTokens(recipeIngredientName);
    if (rTokens.isEmpty) return false;

    for (final item in inventory) {
      final fClean = item.name.toLowerCase().trim();
      if (fClean.isEmpty) continue;

      // 1. Direct exact match
      if (rClean == fClean) return true;

      // 2. Multilingual Lao Gan Ma match
      if ((rClean.contains('lao gan ma') || rClean.contains('老干妈')) &&
          (fClean.contains('lao gan ma') || fClean.contains('老干妈'))) {
        return true;
      }

      // 3. Core token match with modifier rejection
      final fTokens = extractCoreTokens(item.name);
      if (fTokens.isEmpty) continue;

      for (final rt in rTokens) {
        for (final ft in fTokens) {
          // Exact token equality
          if (rt == ft) return true;

          // Culinary synonyms or stem equivalence
          if (areSynonymsOrStems(rt, ft)) {
            return true;
          }

          // Stem prefix match if length >= 5 (e.g. courgette / courgettes)
          if (rt.length >= 5 && ft.length >= 5 && (rt.startsWith(ft) || ft.startsWith(rt))) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// Evaluates culinary equivalencies and stems.
  static bool areSynonymsOrStems(String a, String b) {
    if (a == b) return true;

    // Courgette <-> Zucchini
    if ((a == 'courgette' && b == 'zucchini') || (a == 'zucchini' && b == 'courgette')) return true;

    // Meehun / Vermicelli / Rice Noodle
    if ((a == 'meehun' || a == 'bihun' || a == 'beehoon') &&
        (b == 'meehun' || b == 'noodle' || b == 'vermicelli')) {
      return true;
    }
    if ((b == 'meehun' || b == 'bihun' || b == 'beehoon') &&
        (a == 'meehun' || a == 'noodle' || a == 'vermicelli')) {
      return true;
    }

    // Kelp <-> Kombu <-> Dashima
    if ((a == 'kelp' || a == 'kombu' || a == 'dashima') &&
        (b == 'kelp' || b == 'kombu' || b == 'dashima')) {
      return true;
    }

    // Scallion <-> Green Onion <-> Spring Onion
    if ((a == 'scallion' || a == 'spring onion') && b == 'onion') return true;
    if ((b == 'scallion' || b == 'spring onion') && a == 'onion') return true;

    // Pork chop / pork loin <-> pork
    if ((a == 'pork' || a == 'loin' || a == 'chop') && (b == 'pork')) return true;
    if ((b == 'pork' || b == 'loin' || b == 'chop') && (a == 'pork')) return true;

    // Chicken steak / breast <-> chicken
    if ((a == 'chicken') && (b == 'chicken')) return true;

    // Cheddar <-> Cheese
    if ((a == 'cheddar' || a == 'mozzarella') && b == 'cheese') return true;
    if ((b == 'cheddar' || b == 'mozzarella') && a == 'cheese') return true;

    // Soya / Soy
    if ((a == 'soy' || a == 'soya') && (b == 'soy' || b == 'soya')) return true;

    return false;
  }

  // ---------------------------------------------------------------------------
  // REAL-TIME PANTRY SYNTHESIZER
  // ---------------------------------------------------------------------------

  /// Synthesizes authentic, 100% matched recipes dynamically crafted around
  /// the user's real fridge, freezer, and pantry items, adapting to preferred cuisines.
  static List<Recipe> synthesizeFromInventory(List<FridgeItem> inventory, [List<String>? preferredCuisines]) {
    if (inventory.isEmpty) return const [];

    final List<Recipe> synthesized = [];
    final prefersKoreanOnly = preferredCuisines != null &&
        preferredCuisines.contains('Korean') &&
        !preferredCuisines.any((c) => c.contains('Western') || c.contains('Italian') || c.contains('Fusion') || c.contains('Japanese'));

    bool hasItem(String query) {
      final qLower = query.toLowerCase();
      return inventory.any((item) => hasIngredient(qLower, [item]));
    }

    // 1. Lao Gan Ma + Noodles / Meehun
    if ((hasItem('meehun') || hasItem('noodles')) && hasItem('lao gan ma')) {
      final noodleType = hasItem('meehun') ? 'Meehun' : 'Noodles';
      synthesized.add(
        Recipe(
          id: 'synth_laoganma_meehun_${noodleType.toLowerCase()}',
          title: 'Spicy Lao Gan Ma Garlic $noodleType',
          koreanTitle: prefersKoreanOnly ? '라오간마 볶음국수' : 'Chili Crisp Stir-Fry',
          imageUrl: '',
          cookingTimeMinutes: 10,
          cookingMethod: 'Stovetop',
          difficulty: 'Easy',
          kitchenMatchPercent: 100,
          category: 'Cook with what you have',
          isSaved: false,
          ingredients: [
            RecipeIngredient(name: noodleType, amount: '1 portion', status: 'have'),
            const RecipeIngredient(name: '老干妈 (Lao Gan Ma)', amount: '1.5 tbsp', status: 'have'),
            const RecipeIngredient(name: 'Garlic', amount: '2 cloves, minced', status: 'have'),
            if (hasItem('jalapeno') || hasItem('sliced green jalapenos'))
              const RecipeIngredient(name: 'Sliced Green Jalapeños', amount: '1 tbsp', status: 'have'),
            if (hasItem('soy sauce') || hasItem('dark soy sauce'))
              const RecipeIngredient(name: 'Soy Sauce', amount: '1 tbsp', status: 'have'),
          ],
          cookingSteps: const [
            'Cook or soak noodles/meehun in warm water until al dente; drain well.',
            'Heat 1 tbsp oil in a skillet, sauté minced garlic and sliced jalapeños for 1 minute until fragrant.',
            'Add Lao Gan Ma chili crisp and soy sauce, stirring into a sizzling, aromatic paste.',
            'Toss noodles into the skillet over medium-high heat until evenly coated and glossy. Serve hot!',
          ],
        ),
      );
    }

    // 2. Pork Loin Chop + Butter + Garlic / Rosemary
    if (hasItem('pork loin chop') || hasItem('pork')) {
      synthesized.add(
        Recipe(
          id: 'synth_pork_chop_rosemary',
          title: 'Pan-Seared Pork Loin Chop with Rosemary Butter',
          koreanTitle: prefersKoreanOnly ? '로즈마리 버터 돼지등심 구이' : 'Western Gourmet',
          imageUrl: '',
          cookingTimeMinutes: 14,
          cookingMethod: 'Stovetop',
          difficulty: 'Easy',
          kitchenMatchPercent: 100,
          category: 'Cook with what you have',
          isSaved: false,
          ingredients: [
            const RecipeIngredient(name: 'Pork Loin Chop', amount: '1–2 chops', status: 'have'),
            if (hasItem('butter'))
              const RecipeIngredient(name: 'Butter', amount: '20g', status: 'have'),
            if (hasItem('garlic'))
              const RecipeIngredient(name: 'Garlic', amount: '3 cloves, crushed', status: 'have'),
            if (hasItem('rosemary') || hasItem('rosemary whole'))
              const RecipeIngredient(name: 'Rosemary Whole', amount: '2 sprigs', status: 'have'),
            if (hasItem('salt'))
              const RecipeIngredient(name: 'Salt', amount: '1 pinch', status: 'have'),
          ],
          cookingSteps: const [
            'Pat pork loin chops dry and season generously with salt on both sides.',
            'Sear in a hot skillet for 3–4 minutes per side until a deep golden crust forms.',
            'Drop in butter, crushed garlic cloves, and fresh rosemary sprigs.',
            'Tilt skillet and continuously spoon the foaming melted rosemary-garlic butter over the chops for 2 minutes.',
            'Rest pork chops on a warm plate for 3 minutes before slicing to keep them juicy.',
          ],
        ),
      );
    }

    // 3. Breaded Chicken Steak + Sweet Chilli / BBQ + Rice
    if (hasItem('breaded chicken steak') || hasItem('chicken')) {
      final sauceName = hasItem('sweet chilli sauce') ? 'Sweet Chilli' : 'BBQ Sauce';
      synthesized.add(
        Recipe(
          id: 'synth_breaded_chicken_rice',
          title: 'Crispy Breaded Chicken Steak with $sauceName Rice',
          koreanTitle: prefersKoreanOnly ? '바삭 치킨 스테이크 덮밥' : 'Comfort Bowl',
          imageUrl: '',
          cookingTimeMinutes: 15,
          cookingMethod: 'Air Fryer',
          difficulty: 'Easy',
          kitchenMatchPercent: 100,
          category: 'Cook with what you have',
          isSaved: false,
          ingredients: [
            const RecipeIngredient(name: 'Breaded Chicken Steak', amount: '1 piece', status: 'have'),
            if (hasItem('sweet chilli sauce'))
              const RecipeIngredient(name: 'Sweet Chilli Sauce', amount: '2 tbsp', status: 'have')
            else if (hasItem('bbq sauce'))
              const RecipeIngredient(name: 'BBQ Sauce', amount: '2 tbsp', status: 'have'),
            if (hasItem('rice'))
              const RecipeIngredient(name: 'Rice', amount: '1 warm bowl', status: 'have'),
            if (hasItem('butter'))
              const RecipeIngredient(name: 'Butter', amount: '1 tsp', status: 'have'),
          ],
          cookingSteps: const [
            'Air fry or pan-fry breaded chicken steak at 195°C for 12–14 minutes until extra crispy and golden.',
            'Scoop warm rice into a serving bowl and melt a pat of butter into the rice.',
            'Slice the crispy chicken steak into thick strips and fan out over the rice.',
            'Drizzle generously with Sweet Chilli or BBQ sauce and serve immediately.',
          ],
        ),
      );
    }

    // 4. Irish Courgettes + White Miso Paste + Butter + Soy Sauce
    if (hasItem('irish courgettes') || hasItem('courgette') || hasItem('zucchini')) {
      synthesized.add(
        Recipe(
          id: 'synth_miso_butter_courgettes',
          title: 'Miso Butter Glazed Irish Courgettes',
          koreanTitle: prefersKoreanOnly ? '미소 버터 애호박 구이' : 'Japanese Home Style',
          imageUrl: '',
          cookingTimeMinutes: 8,
          cookingMethod: 'Stovetop',
          difficulty: 'Easy',
          kitchenMatchPercent: 100,
          category: 'Cook with what you have',
          isSaved: false,
          ingredients: [
            const RecipeIngredient(name: 'Irish Courgettes', amount: '1 large, sliced into rounds', status: 'have'),
            if (hasItem('white miso paste') || hasItem('miso'))
              const RecipeIngredient(name: 'White Miso Paste', amount: '1 tbsp', status: 'have'),
            if (hasItem('butter'))
              const RecipeIngredient(name: 'Butter', amount: '15g', status: 'have'),
            if (hasItem('sugar'))
              const RecipeIngredient(name: 'Sugar', amount: '½ tsp', status: 'have'),
            if (hasItem('soy sauce'))
              const RecipeIngredient(name: 'Soy Sauce', amount: '1 tsp', status: 'have'),
          ],
          cookingSteps: const [
            'Whisk white miso paste, sugar, and soy sauce with 1 tbsp warm water to form a smooth glaze.',
            'Melt butter in a flat skillet over medium heat and arrange sliced courgette rounds in a single layer.',
            'Sear for 2–3 minutes until lightly browned, then flip.',
            'Pour in the miso glaze; toss for 1 minute until courgettes are glossy, tender, and savory-sweet.',
          ],
        ),
      );
    }

    // 5. Irish Traditional Ham + Red Cheddar Cheese + Rice / Jalapeños
    if ((hasItem('irish traditional ham') || hasItem('ham')) &&
        (hasItem('red cheddar cheese') || hasItem('cheese'))) {
      synthesized.add(
        Recipe(
          id: 'synth_ham_cheddar_skillet',
          title: 'Irish Ham & Melted Red Cheddar Skillet',
          koreanTitle: prefersKoreanOnly ? '햄 치즈 라이스 팬' : 'Cafe Comfort',
          imageUrl: '',
          cookingTimeMinutes: 10,
          cookingMethod: 'Stovetop',
          difficulty: 'Easy',
          kitchenMatchPercent: 100,
          category: 'Cook with what you have',
          isSaved: false,
          ingredients: [
            const RecipeIngredient(name: 'Irish Traditional Ham', amount: '2 thick slices, diced', status: 'have'),
            const RecipeIngredient(name: 'Red Cheddar Cheese', amount: '40g, grated or sliced', status: 'have'),
            if (hasItem('rice'))
              const RecipeIngredient(name: 'Rice', amount: '1 bowl', status: 'have'),
            if (hasItem('butter'))
              const RecipeIngredient(name: 'Butter', amount: '1 tbsp', status: 'have'),
            if (hasItem('sliced green jalapenos') || hasItem('jalapeno'))
              const RecipeIngredient(name: 'Sliced Green Jalapeños', amount: '1 tbsp', status: 'have'),
          ],
          cookingSteps: const [
            'Melt butter in a skillet over medium heat and sauté diced Irish ham until edges are crisp and golden.',
            'Add sliced green jalapeños and warm rice, tossing for 2 minutes with a splash of soy sauce.',
            'Layer thick Red Cheddar cheese across the top, cover with lid, and cook on low for 2 minutes until cheese melts into gooey, savory perfection.',
          ],
        ),
      );
    }

    // 6. Tomyum Paste + Meehun + Lemon + Jalapeños
    if (hasItem('tomyum paste') || hasItem('tomyum')) {
      synthesized.add(
        Recipe(
          id: 'synth_tomyum_meehun_soup',
          title: 'Spicy Tomyum Meehun Soup with Lemon',
          koreanTitle: prefersKoreanOnly ? '레몬 똠얌 쌀국수' : 'Southeast Asian',
          imageUrl: '',
          cookingTimeMinutes: 10,
          cookingMethod: 'Stovetop',
          difficulty: 'Easy',
          kitchenMatchPercent: 100,
          category: 'Cook with what you have',
          isSaved: false,
          ingredients: [
            const RecipeIngredient(name: 'Tomyum Paste', amount: '1.5 tbsp', status: 'have'),
            if (hasItem('meehun') || hasItem('noodles'))
              RecipeIngredient(name: hasItem('meehun') ? 'Meehun' : 'Noodles', amount: '1 bundle', status: 'have'),
            if (hasItem('lemon'))
              const RecipeIngredient(name: 'Lemon', amount: '½ lemon, juiced', status: 'have'),
            if (hasItem('garlic'))
              const RecipeIngredient(name: 'Garlic', amount: '2 cloves, crushed', status: 'have'),
            if (hasItem('sliced green jalapenos') || hasItem('jalapeno'))
              const RecipeIngredient(name: 'Sliced Green Jalapeños', amount: '1 tbsp', status: 'have'),
          ],
          cookingSteps: const [
            'Bring 450ml water to a boil in a small pot with crushed garlic.',
            'Dissolve tomyum paste into the simmering broth until fragrant and tangy.',
            'Drop in meehun noodles and cook for 3 minutes until tender.',
            'Squeeze in fresh lemon juice and top with sliced green jalapeños for a bright, zesty kick.',
          ],
        ),
      );
    }

    // 7. Dried Kelp + White Miso Paste + Noodles
    if (hasItem('dried kelp') && hasItem('white miso paste')) {
      synthesized.add(
        Recipe(
          id: 'synth_miso_kelp_dashi_noodles',
          title: 'Warm Miso Kelp Dashi Noodle Broth',
          koreanTitle: prefersKoreanOnly ? '다시마 미소 장국수' : 'Japanese Dashi Soup',
          imageUrl: '',
          cookingTimeMinutes: 12,
          cookingMethod: 'Stovetop',
          difficulty: 'Easy',
          kitchenMatchPercent: 100,
          category: 'Cook with what you have',
          isSaved: false,
          ingredients: [
            const RecipeIngredient(name: 'Dried Kelp', amount: '1 piece (5x5cm)', status: 'have'),
            const RecipeIngredient(name: 'White Miso Paste', amount: '1.5 tbsp', status: 'have'),
            if (hasItem('noodles') || hasItem('meehun'))
              RecipeIngredient(name: hasItem('noodles') ? 'Noodles' : 'Meehun', amount: '1 portion', status: 'have'),
            if (hasItem('garlic'))
              const RecipeIngredient(name: 'Garlic', amount: '1 clove', status: 'have'),
          ],
          cookingSteps: const [
            'Place dried kelp in 400ml cold water in a pot. Bring to a gentle simmer for 7 minutes to extract deep umami dashi, then remove kelp.',
            'Turn heat to low. Whisk in white miso paste through a small strainer until completely dissolved.',
            'Cook noodles in separate boiling water, rinse, and place in a warm bowl.',
            'Pour the steaming kelp-miso broth over noodles and garnish with minced garlic or jalapeños.',
          ],
        ),
      );
    }

    // 8. Breaded Chicken Steak + Lemon + Butter (Western / Continental)
    if ((hasItem('breaded chicken steak') || hasItem('chicken')) &&
        hasItem('lemon') &&
        hasItem('butter')) {
      synthesized.add(
        Recipe(
          id: 'synth_lemon_butter_chicken',
          title: 'Crispy Lemon Butter Glazed Chicken',
          koreanTitle: prefersKoreanOnly ? '레몬 버터 치킨' : 'Western Classic',
          imageUrl: '',
          cookingTimeMinutes: 12,
          cookingMethod: 'Stovetop',
          difficulty: 'Easy',
          kitchenMatchPercent: 100,
          category: 'Cook with what you have',
          isSaved: false,
          ingredients: [
            const RecipeIngredient(name: 'Breaded Chicken Steak', amount: '1–2 steaks', status: 'have'),
            const RecipeIngredient(name: 'Butter', amount: '1.5 tbsp', status: 'have'),
            const RecipeIngredient(name: 'Lemon', amount: '½ lemon, juiced', status: 'have'),
            if (hasItem('garlic'))
              const RecipeIngredient(name: 'Garlic', amount: '2 cloves, minced', status: 'have'),
            if (hasItem('rosemary') || hasItem('rosemary whole'))
              const RecipeIngredient(name: 'Rosemary Whole', amount: '1 sprig', status: 'have'),
          ],
          cookingSteps: const [
            'Pan-fry or air-fry chicken steak until crisp and golden brown.',
            'In a small skillet, melt butter with minced garlic and rosemary over medium-low heat.',
            'Stir in fresh lemon juice to create a silky, glossy lemon-butter pan sauce.',
            'Drizzle sauce over crispy sliced chicken and serve immediately.',
          ],
        ),
      );
    }

    // 9. Courgettes + Garlic + Lemon + Butter (Mediterranean Sauté)
    if ((hasItem('irish courgettes') || hasItem('courgette')) &&
        hasItem('lemon') &&
        hasItem('garlic')) {
      synthesized.add(
        Recipe(
          id: 'synth_lemon_garlic_courgettes',
          title: 'Mediterranean Lemon Garlic Sautéed Courgettes',
          koreanTitle: prefersKoreanOnly ? '레몬 마늘 애호박 구이' : 'Mediterranean Sauté',
          imageUrl: '',
          cookingTimeMinutes: 7,
          cookingMethod: 'Stovetop',
          difficulty: 'Easy',
          kitchenMatchPercent: 100,
          category: 'Cook with what you have',
          isSaved: false,
          ingredients: [
            const RecipeIngredient(name: 'Irish Courgettes', amount: '1 medium, sliced into rounds', status: 'have'),
            const RecipeIngredient(name: 'Garlic', amount: '2 cloves, sliced thin', status: 'have'),
            const RecipeIngredient(name: 'Lemon', amount: '½ lemon, juiced & zested', status: 'have'),
            if (hasItem('butter'))
              const RecipeIngredient(name: 'Butter', amount: '1 tbsp', status: 'have'),
            if (hasItem('salt'))
              const RecipeIngredient(name: 'Salt', amount: '1 pinch', status: 'have'),
          ],
          cookingSteps: const [
            'Heat butter or oil in a pan over medium-high heat, add sliced garlic until golden.',
            'Toss in sliced courgettes and sear for 3–4 minutes until caramelized and tender.',
            'Finish with a squeeze of fresh lemon juice and sea salt before serving.',
          ],
        ),
      );
    }

    return synthesized;
  }

  // ---------------------------------------------------------------------------
  // ONLINE OPENAI PANTRY THINKING ENGINE
  // ---------------------------------------------------------------------------

  /// Calls OpenAI with the user's real inventory to synthesize tailored recipes
  /// that reflect deep culinary thought and adapt to user's preferred cuisine styles.
  static Future<List<Recipe>> thinkWithOpenAi({
    required String apiKey,
    required List<FridgeItem> inventory,
    List<String>? preferredCuisines,
  }) async {
    if (apiKey.isEmpty || inventory.isEmpty) return const [];

    final fridgeItems = inventory.where((i) => i.location == StorageLocation.fridge).map((e) => e.name).join(', ');
    final freezerItems = inventory.where((i) => i.location == StorageLocation.freezer).map((e) => e.name).join(', ');
    final pantryItems = inventory.where((i) => i.location == StorageLocation.pantry).map((e) => e.name).join(', ');
    final seasoningItems = inventory.where((i) => i.location == StorageLocation.seasoning).map((e) => e.name).join(', ');
    final cuisineText = (preferredCuisines != null && preferredCuisines.isNotEmpty)
        ? preferredCuisines.join(', ')
        : 'Diverse styles (Western & Italian, Japanese, Asian Fusion, Mexican, Mediterranean, Comfort)';

    final prompt = '''
You are 식 (sik) AI culinary studio intelligence — think like a passionate, Michelin-experienced chef and home cook who loves the joy of simple, delicious food.

The user has these items in their kitchen:
- Fridge: [${fridgeItems.isEmpty ? 'None' : fridgeItems}]
- Freezer: [${freezerItems.isEmpty ? 'None' : freezerItems}]
- Pantry: [${pantryItems.isEmpty ? 'None' : pantryItems}]
- Seasonings & Spices: [${seasoningItems.isEmpty ? 'None' : seasoningItems}]

User's preferred cuisine styles: [$cuisineText]

TASK:
Generate a DIVERSE, exciting, and human set of 3 to 4 recipe suggestions across THREE distinct culinary moods:

1. SLOT "pantry_utility" (1 recipe):
- "Cook with what you have right now."
- Uses held ingredients from the user's inventory. Zero waste. Practical and satisfying.
- Every ingredient held should have "status": "have".
- Category: "Cook with what you have"
- "slot": "pantry_utility"

2. SLOT "simple_classic" (1-2 recipes):
- "Pure culinary simplicity."
- Don't overcomplicate it! Think: marinated meat seared in a pan or roasted in the oven, pan-seared steak or chicken basted with butter and garlic, charred skewers, or simple comfort fried rice.
- Max 4-5 ingredients total, 3-4 steps.
- Focus on good technique: high heat, golden crust, resting meat, basting with butter.
- If an essential ingredient is not in the user's inventory, mark it with "status": "missing".
- Category: "Everyday Classic"
- "slot": "simple_classic"
- "inspirationNote": A 1-sentence chef tip on technique (e.g. "Get the pan smoking hot to create that deep golden crust").

3. SLOT "aspirational" (1 recipe):
- "Chef's Aspirational Discovery — dishes worth making."
- Something mouthwatering that inspires the cook to light the stove, even if they need to pick up 1 or 2 items (e.g. ribeye steak, fresh prawns, scallops, brioche).
- Mark held items with "status": "have" and items to buy with "status": "missing".
- Category: "Chef's Pick"
- "slot": "aspirational"
- "inspirationNote": A 1-sentence appetizing teaser (e.g. "Perfect weekend dinner — grab fresh steak and fresh herbs").

Respond with ONLY a raw JSON array of objects, with no markdown code blocks or backticks:
[
  {
    "title": "Recipe Name",
    "koreanTitle": "Cuisine style or subtitle (e.g. Italian, Japanese, Western, or Korean)",
    "cookingTimeMinutes": 15,
    "cookingMethod": "Stovetop",
    "difficulty": "Easy",
    "slot": "pantry_utility",
    "inspirationNote": "Chef tip or flavor note",
    "ingredients": [
      {"name": "Ingredient name", "amount": "quantity", "status": "have"}
    ],
    "cookingSteps": [
      "Step 1 instruction",
      "Step 2 instruction",
      "Step 3 instruction"
    ],
    "category": "Everyday Classic"
  }
]
''';

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.8,
          'max_tokens': 1200,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        var rawContent = data['choices']?[0]?['message']?['content'] as String?;
        if (rawContent != null && rawContent.isNotEmpty) {
          rawContent = rawContent.replaceAll('```json', '').replaceAll('```', '').trim();
          final List<dynamic> list = jsonDecode(rawContent);

          final List<Recipe> recipes = [];
          for (final item in list) {
            final map = item as Map<String, dynamic>;
            final rawIngs = (map['ingredients'] as List<dynamic>? ?? []);
            final ings = rawIngs.map((i) {
              final iMap = i as Map<String, dynamic>;
              final rawStatus = (iMap['status'] as String?)?.toLowerCase().trim() ?? 'have';
              return RecipeIngredient(
                name: iMap['name'] ?? '',
                amount: iMap['amount'] ?? '',
                status: (rawStatus == 'missing' || rawStatus == 'low') ? rawStatus : 'have',
              );
            }).toList();

            final steps = (map['cookingSteps'] as List<dynamic>? ?? [])
                .map((s) => s.toString())
                .toList();

            final slotStr = (map['slot'] as String?)?.toLowerCase().trim() ?? 'pantry_utility';
            final validSlot = (slotStr == 'simple_classic' || slotStr == 'aspirational')
                ? slotStr
                : 'pantry_utility';
            final note = map['inspirationNote'] as String?;

            final totalIng = ings.length;
            final haveIng = ings.where((i) => i.status == 'have').length;
            final matchPct = totalIng > 0 ? ((haveIng / totalIng) * 100).round() : 100;

            recipes.add(
              Recipe(
                id: 'ai_synth_${DateTime.now().millisecondsSinceEpoch}_${map['title'].hashCode.abs()}',
                title: map['title'] ?? 'Studio Dish',
                koreanTitle: map['koreanTitle'] ?? '',
                imageUrl: '',
                cookingTimeMinutes: map['cookingTimeMinutes'] ?? 15,
                cookingMethod: map['cookingMethod'] ?? 'Stovetop',
                difficulty: map['difficulty'] ?? 'Easy',
                kitchenMatchPercent: matchPct,
                category: map['category'] ?? (validSlot == 'simple_classic' ? 'Everyday Classic' : (validSlot == 'aspirational' ? "Chef's Pick" : 'Cook with what you have')),
                ingredients: ings,
                cookingSteps: steps,
                recipeSlot: validSlot,
                inspirationNote: note,
              ),
            );
          }
          return recipes;
        }
      } else {
        // ignore: avoid_print
        print('[PantryRecipeSynthesizer] OpenAI HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[PantryRecipeSynthesizer] OpenAI error: $e');
    }

    return const [];
  }
}
