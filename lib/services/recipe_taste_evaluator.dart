import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../theme/app_theme.dart';

class TasteAlternative {
  final String name;
  final String portion;
  final double recoveredScore; // e.g. 9.3 out of 10
  final String culinaryNote;

  const TasteAlternative({
    required this.name,
    required this.portion,
    required this.recoveredScore,
    required this.culinaryNote,
  });

  double get tasteRestoration => (recoveredScore - 8.5).clamp(0.4, 1.2);
}

class TasteImpactResult {
  final String ingredientName;
  final double originalScore; // 10.0
  final double impactedScore; // e.g. 8.5
  final String impactSeverity; // 'Mild shift' | 'Noticeable impact' | 'Crucial component'
  final String explanation;
  final List<TasteAlternative> alternatives;

  const TasteImpactResult({
    required this.ingredientName,
    this.originalScore = 10.0,
    required this.impactedScore,
    required this.impactSeverity,
    required this.explanation,
    required this.alternatives,
  });

  double get scoreDrop => (originalScore - impactedScore);
  double get tasteRating => impactedScore;

  Color get scoreColor {
    if (impactedScore >= 9.0) return AppTheme.accentGreen;
    if (impactedScore >= 8.0) return AppTheme.accentAmber;
    return const Color(0xFFE76F51);
  }
}

class RecipeTasteEvaluator {
  /// Evaluates the sensory and taste rating impact when a specific ingredient is removed
  static TasteImpactResult evaluateRemoval({
    required String recipeTitle,
    required String ingredientName,
    List<String> remainingIngredients = const [],
  }) {
    final lower = ingredientName.toLowerCase().trim();
    final recipeLower = recipeTitle.toLowerCase();

    // 1. Condensed Milk / Sweeteners / Dairy
    if (lower.contains('condensed milk')) {
      return const TasteImpactResult(
        ingredientName: 'Condensed Milk',
        impactedScore: 8.5,
        impactSeverity: 'Noticeable impact',
        explanation:
            'Without Condensed Milk, the shaved ice loses its creamy sweetness and velvety mouthfeel.',
        alternatives: [
          TasteAlternative(
            name: 'Honey or Agave Nectar',
            portion: '1.5 tbsp',
            recoveredScore: 9.3,
            culinaryNote: 'Provides clean floral sweetness and smooth consistency.',
          ),
          TasteAlternative(
            name: 'Whole Milk + 1 tbsp Sugar',
            portion: '2 tbsp',
            recoveredScore: 9.0,
            culinaryNote: 'Simmered briefly, mimics condensed milk thickness well.',
          ),
          TasteAlternative(
            name: 'Coconut Milk / Condensed Coconut',
            portion: '1.5 tbsp',
            recoveredScore: 9.2,
            culinaryNote: 'Adds a delightful fragrant tropical creaminess.',
          ),
        ],
      );
    }

    // 2. Strawberries / Fruit
    if (lower.contains('strawberry') || lower.contains('strawberries')) {
      return const TasteImpactResult(
        ingredientName: 'Fresh Strawberries',
        impactedScore: 8.0,
        impactSeverity: 'Crucial component',
        explanation:
            'Strawberries provide the signature fruit-tart brightness and fresh aroma of this treat.',
        alternatives: [
          TasteAlternative(
            name: 'Fresh Blueberries or Raspberries',
            portion: '100 g',
            recoveredScore: 9.2,
            culinaryNote: 'Offers vibrant berry tartness and refreshing fruit texture.',
          ),
          TasteAlternative(
            name: 'Strawberry Jam or Puree',
            portion: '2 tbsp',
            recoveredScore: 9.4,
            culinaryNote: 'Intense strawberry flavor, reduce extra added sugar slightly.',
          ),
          TasteAlternative(
            name: 'Ripe Mango or Kiwi Slices',
            portion: '100 g',
            recoveredScore: 9.0,
            culinaryNote: 'Creates a delicious, sweet tropical variation.',
          ),
        ],
      );
    }

    // 3. Whole Milk / Dairy Base
    if (lower.contains('milk') && !lower.contains('condensed')) {
      return const TasteImpactResult(
        ingredientName: 'Whole Milk',
        impactedScore: 8.2,
        impactSeverity: 'Core base ingredient',
        explanation:
            'Whole milk provides the silky richness and snow-like shaved texture.',
        alternatives: [
          TasteAlternative(
            name: 'Oat Milk (Barista Blend)',
            portion: '250 ml',
            recoveredScore: 9.4,
            culinaryNote: 'Creamy texture with a warm, slightly nutty finish.',
          ),
          TasteAlternative(
            name: 'Almond or Soy Milk',
            portion: '250 ml',
            recoveredScore: 9.1,
            culinaryNote: 'Light and refreshing dessert base.',
          ),
        ],
      );
    }

    // 4. Kimchi
    if (lower.contains('kimchi')) {
      return const TasteImpactResult(
        ingredientName: 'Kimchi',
        impactedScore: 7.8,
        impactSeverity: 'Dominant flavor foundation',
        explanation:
            'Without Kimchi, the dish loses its iconic lactic acidity, umami depth, and spicy fermented crunch.',
        alternatives: [
          TasteAlternative(
            name: 'Sauerkraut + Chili Flakes (Gochugaru)',
            portion: '1/2 cup + 1 tsp chili',
            recoveredScore: 8.9,
            culinaryNote: 'Captures fermented tang with customizable warmth.',
          ),
          TasteAlternative(
            name: 'Pickled Cabbage + 1 tsp Sriracha',
            portion: '1/2 cup',
            recoveredScore: 8.7,
            culinaryNote: 'Provides acidity and crisp texture.',
          ),
        ],
      );
    }

    // 5. Eggs
    if (lower.contains('egg')) {
      return const TasteImpactResult(
        ingredientName: 'Egg',
        impactedScore: 8.6,
        impactSeverity: 'Protein & texture shift',
        explanation:
            'Eggs add richness, savory fat, and a binding custard or runny yolk coating.',
        alternatives: [
          TasteAlternative(
            name: 'Silken Tofu Cubes',
            portion: '80 g',
            recoveredScore: 9.2,
            culinaryNote: 'Soft, creamy protein that absorbs pan flavors beautifully.',
          ),
          TasteAlternative(
            name: 'Avocado Slices',
            portion: '1/2 avocado',
            recoveredScore: 9.0,
            culinaryNote: 'Adds rich, buttery fat and smooth mouthfeel.',
          ),
        ],
      );
    }

    // 6. Gochujang / Chili Paste
    if (lower.contains('gochujang') || lower.contains('chili paste')) {
      return const TasteImpactResult(
        ingredientName: 'Gochujang',
        impactedScore: 8.2,
        impactSeverity: 'Key seasoning note',
        explanation:
            'Without Gochujang, the sauce lacks spicy-sweet fermented savoriness.',
        alternatives: [
          TasteAlternative(
            name: 'Sriracha + 1/2 tsp Miso + Pinch of Sugar',
            portion: '1 tbsp',
            recoveredScore: 9.3,
            culinaryNote: 'Closest balance of tang, spice, and umami depth.',
          ),
          TasteAlternative(
            name: 'Chili Garlic Sauce + Honey',
            portion: '1 tbsp',
            recoveredScore: 8.9,
            culinaryNote: 'Great punchy heat with savory sweetness.',
          ),
        ],
      );
    }

    // 7. Garlic / Aromatics
    if (lower.contains('garlic') || lower.contains('onion') || lower.contains('scallion')) {
      return TasteImpactResult(
        ingredientName: ingredientName,
        impactedScore: 8.8,
        impactSeverity: 'Aromatic foundation shift',
        explanation:
            'Without $ingredientName, the aroma base is more muted with less savory lift.',
        alternatives: const [
          TasteAlternative(
            name: 'Garlic Powder / Onion Powder',
            portion: '1/2 tsp',
            recoveredScore: 9.4,
            culinaryNote: 'Concentrated savory aroma without fresh prep.',
          ),
          TasteAlternative(
            name: 'Shallots or Chives',
            portion: '1 tbsp minced',
            recoveredScore: 9.2,
            culinaryNote: 'Delicate sweet allium flavor.',
          ),
        ],
      );
    }

    // 8. Tofu / Protein
    if (lower.contains('tofu')) {
      return const TasteImpactResult(
        ingredientName: 'Tofu',
        impactedScore: 8.3,
        impactSeverity: 'Main protein omission',
        explanation:
            'Removing Tofu leaves the dish lighter without its comforting, crisp-tender substance.',
        alternatives: [
          TasteAlternative(
            name: 'King Oyster Mushrooms or Shiitake',
            portion: '100 g',
            recoveredScore: 9.2,
            culinaryNote: 'Incredible chewy texture and deep savory umami.',
          ),
          TasteAlternative(
            name: 'Edamame or Chickpeas',
            portion: '1/2 cup',
            recoveredScore: 8.9,
            culinaryNote: 'Nutty, high-protein alternative.',
          ),
        ],
      );
    }

    // 9. Soy Sauce / Salt / Seasoning
    if (lower.contains('soy sauce') || lower.contains('tamari') || lower.contains('salt')) {
      return TasteImpactResult(
        ingredientName: ingredientName,
        impactedScore: 8.4,
        impactSeverity: 'Salinity & savoriness drop',
        explanation:
            'Without $ingredientName, the dish tastes under-seasoned and lacks savory contrast.',
        alternatives: const [
          TasteAlternative(
            name: 'Fish Sauce or Miso Paste',
            portion: '1 tsp',
            recoveredScore: 9.3,
            culinaryNote: 'Deep fermented saltiness that enhances dish depth.',
          ),
          TasteAlternative(
            name: 'Sea Salt + Splash of Lemon',
            portion: 'Pinch + 1/2 tsp',
            recoveredScore: 8.8,
            culinaryNote: 'Bright, clean mineral lift.',
          ),
        ],
      );
    }

    // 10. General Default
    final isDessert = recipeLower.contains('dessert') ||
        recipeLower.contains('baking') ||
        recipeLower.contains('cookie') ||
        recipeLower.contains('sweet');

    return TasteImpactResult(
      ingredientName: ingredientName,
      impactedScore: 8.7,
      impactSeverity: 'Moderate flavor balance shift',
      explanation:
          'Without $ingredientName, the recipe retains its core structure but loses a complementary layer of flavor and aroma balance.',
      alternatives: isDessert
          ? const [
              TasteAlternative(
                name: 'Honey or Pure Maple Syrup',
                portion: '1 tbsp',
                recoveredScore: 9.2,
                culinaryNote: 'Natural sweetness and pleasant aromatic moisture.',
              ),
              TasteAlternative(
                name: 'Vanilla Extract + Pinch of Salt',
                portion: '1/4 tsp',
                recoveredScore: 9.0,
                culinaryNote: 'Rounds out dessert flavors.',
              ),
            ]
          : const [
              TasteAlternative(
                name: 'Toasted Sesame Oil + Soy Sauce',
                portion: '1/2 tsp each',
                recoveredScore: 9.3,
                culinaryNote: 'Brings classic Korean aroma and rich nutty warmth.',
              ),
              TasteAlternative(
                name: 'Vegetable or Mushroom Broth',
                portion: '2 tbsp',
                recoveredScore: 9.0,
                culinaryNote: 'Restores moisture and rounded savory balance.',
              ),
            ],
    );
  }

  static List<TasteAlternative> getAlternativesForIngredient(String ingredientName) {
    return evaluateRemoval(recipeTitle: '', ingredientName: ingredientName).alternatives;
  }

  static TasteImpactResult evaluateCombined({
    required Recipe recipe,
    required Set<String> removedIngredients,
    Map<String, TasteAlternative> substitutions = const {},
  }) {
    if (removedIngredients.isEmpty) {
      return const TasteImpactResult(
        ingredientName: '',
        originalScore: 10.0,
        impactedScore: 10.0,
        impactSeverity: 'Full Flavor',
        explanation: 'Original full recipe flavor profile.',
        alternatives: [],
      );
    }

    double totalDrop = 0.0;
    final explanations = <String>[];
    final allAlternatives = <TasteAlternative>[];

    for (final ing in removedIngredients) {
      final single = evaluateRemoval(recipeTitle: recipe.title, ingredientName: ing);
      if (substitutions.containsKey(ing)) {
        final sub = substitutions[ing]!;
        final subDrop = (10.0 - sub.recoveredScore).clamp(0.1, 0.7);
        totalDrop += subDrop;
        explanations.add('Substituted $ing with ${sub.name} (recovers profile to ~${sub.recoveredScore.toStringAsFixed(1)}/10).');
      } else {
        totalDrop += single.scoreDrop;
        explanations.add(single.explanation);
        allAlternatives.addAll(single.alternatives);
      }
    }

    final finalScore = (10.0 - totalDrop).clamp(5.0, 9.8);
    final severity = finalScore >= 9.0
        ? 'Restored with substitute'
        : finalScore >= 8.0
            ? 'Noticeable flavor loss'
            : 'Severe quality drop';

    return TasteImpactResult(
      ingredientName: removedIngredients.join(', '),
      originalScore: 10.0,
      impactedScore: finalScore,
      impactSeverity: severity,
      explanation: explanations.join(' '),
      alternatives: allAlternatives,
    );
  }
}
