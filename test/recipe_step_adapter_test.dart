import 'package:flutter_test/flutter_test.dart';
import 'package:sik_app/services/recipe_step_adapter.dart';
import 'package:sik_app/services/recipe_taste_evaluator.dart';

void main() {
  group('RecipeStepAdapter Tests', () {
    const steps = [
      'Chop the kimchi into bite-sized pieces.',
      'Heat 1 tbsp oil in a pan over medium heat and sauté kimchi for 3 minutes.',
      'Add cooked rice and gochugaru, mixing thoroughly.',
      'Drizzle sesame oil around the pan edges for aroma.',
      'Fry an egg sunny-side up in a separate small pan and serve on top.',
    ];

    test('Returns untouched steps when no ingredients are removed', () {
      final adapted = RecipeStepAdapter.adaptSteps(
        cookingSteps: steps,
        removedIngredients: {},
        substitutions: {},
      );

      expect(adapted.length, equals(5));
      for (int i = 0; i < 5; i++) {
        expect(adapted[i].isAdapted, isFalse);
        expect(adapted[i].isSkipped, isFalse);
        expect(adapted[i].adaptedText, equals(steps[i]));
      }
    });

    test('Adapts step 3 when Gochugaru (Chili Flakes) is removed without sub', () {
      final adapted = RecipeStepAdapter.adaptSteps(
        cookingSteps: steps,
        removedIngredients: {'Gochugaru (Chili Flakes)'},
        substitutions: {},
      );

      expect(adapted.length, equals(5));
      expect(adapted[0].isAdapted, isFalse);
      expect(adapted[1].isAdapted, isFalse);

      // Step 3 should be adapted
      final step3 = adapted[2];
      expect(step3.isAdapted, isTrue);
      expect(step3.isSkipped, isFalse);
      expect(step3.adaptationNote, contains('Gochugaru omitted'));

      // Check segments
      final strikethroughSegment = step3.segments.firstWhere((s) => s.isStrikethrough);
      expect(strikethroughSegment.text.toLowerCase(), equals('gochugaru'));

      final omittedSegment = step3.segments.firstWhere((s) => s.isOmittedNote);
      expect(omittedSegment.text, contains('(omitted)'));
    });

    test('Adapts step 3 with substitute when Paprika is selected', () {
      const sub = TasteAlternative(
        name: 'Paprika',
        portion: '1 tsp',
        recoveredScore: 9.3,
        culinaryNote: 'Provides mild pepper warmth and vibrant red color without spiciness.',
      );

      final adapted = RecipeStepAdapter.adaptSteps(
        cookingSteps: steps,
        removedIngredients: {'Gochugaru (Chili Flakes)'},
        substitutions: {'Gochugaru (Chili Flakes)': sub},
      );

      final step3 = adapted[2];
      expect(step3.isAdapted, isTrue);
      expect(step3.isSkipped, isFalse);
      expect(step3.adaptationNote, contains('Paprika (sub)'));

      final subSegment = step3.segments.firstWhere((s) => s.isSubstitute);
      expect(subSegment.text, contains('Paprika'));
    });

    test('Marks prep step as skipped when Kimchi is removed', () {
      final adapted = RecipeStepAdapter.adaptSteps(
        cookingSteps: steps,
        removedIngredients: {'Aged Kimchi'},
        substitutions: {},
      );

      // Step 1: Chop the kimchi into bite-sized pieces -> skipped
      final step1 = adapted[0];
      expect(step1.isAdapted, isTrue);
      expect(step1.isSkipped, isTrue);
      expect(step1.adaptationNote, contains('Step skipped'));
      expect(step1.segments.first.isStrikethrough, isTrue);
    });

    test('Marks egg frying step as skipped when Egg is removed', () {
      final adapted = RecipeStepAdapter.adaptSteps(
        cookingSteps: steps,
        removedIngredients: {'Egg'},
        substitutions: {},
      );

      final step5 = adapted[4];
      expect(step5.isAdapted, isTrue);
      expect(step5.isSkipped, isTrue);
      expect(step5.adaptationNote, contains('Step skipped · Egg excluded'));
    });
  });
}
