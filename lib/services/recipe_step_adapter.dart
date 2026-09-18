import '../services/recipe_taste_evaluator.dart';

/// Represents a segment of a step's text for rich display
class StepTextSegment {
  final String text;
  final bool isStrikethrough;
  final bool isSubstitute;
  final bool isOmittedNote;

  const StepTextSegment({
    required this.text,
    this.isStrikethrough = false,
    this.isSubstitute = false,
    this.isOmittedNote = false,
  });
}

/// Represents an adapted recipe instruction step
class AdaptedStep {
  final int stepIndex; // 0-based
  final String originalText;
  final String adaptedText; // Clean string for cooking mode / audio
  final bool isAdapted;
  final bool isSkipped;
  final String? adaptationNote; // e.g. "Adapted · Gochugaru omitted"
  final List<StepTextSegment> segments;

  const AdaptedStep({
    required this.stepIndex,
    required this.originalText,
    required this.adaptedText,
    required this.isAdapted,
    required this.isSkipped,
    this.adaptationNote,
    required this.segments,
  });
}

class RecipeStepAdapter {
  /// Extract search keywords from ingredient name (e.g. "Gochugaru (Chili Flakes)" -> ["gochugaru", "chili flakes"])
  static List<String> extractKeywords(String ingredientName) {
    final clean = ingredientName.trim().toLowerCase();
    final Set<String> keywords = {clean};

    // Extract inside and outside parentheses
    final parenMatch = RegExp(r'^(.*?)\s*\((.*?)\)$').firstMatch(clean);
    if (parenMatch != null) {
      final before = parenMatch.group(1)?.trim();
      final inside = parenMatch.group(2)?.trim();
      if (before != null && before.isNotEmpty) keywords.add(before);
      if (inside != null && inside.isNotEmpty) keywords.add(inside);
    }

    // Common preparation adjectives to strip
    const adjectives = {
      'aged', 'firm', 'cooked', 'unsalted', 'salted', 'fresh', 'raw',
      'ground', 'minced', 'chopped', 'sliced', 'diced', 'large', 'medium', 'small',
      'warm', 'cold', 'jasmine', 'basmati', 'white', 'brown', 'clove', 'cloves',
      'tbsp', 'tsp', 'cup', 'cups', 'stalk', 'stalks', 'piece', 'pieces',
    };

    final words = clean.split(RegExp(r'[\s\(\),]+'));
    for (final word in words) {
      final w = word.trim();
      if (w.length >= 3 && !adjectives.contains(w)) {
        keywords.add(w);
      }
    }

    final list = keywords.toList();
    // Sort descending by length so longer phrases match first
    list.sort((a, b) => b.length.compareTo(a.length));
    return list;
  }

  /// Adapt a list of cooking steps according to removed ingredients and substitutions
  static List<AdaptedStep> adaptSteps({
    required List<String> cookingSteps,
    required Set<String> removedIngredients,
    required Map<String, TasteAlternative> substitutions,
  }) {
    if (removedIngredients.isEmpty) {
      return cookingSteps.asMap().entries.map((entry) {
        return AdaptedStep(
          stepIndex: entry.key,
          originalText: entry.value,
          adaptedText: entry.value,
          isAdapted: false,
          isSkipped: false,
          segments: [StepTextSegment(text: entry.value)],
        );
      }).toList();
    }

    // Map each removed ingredient to its keyword list
    final Map<String, List<String>> ingredientKeywords = {};
    for (final ing in removedIngredients) {
      ingredientKeywords[ing] = extractKeywords(ing);
    }

    return cookingSteps.asMap().entries.map((entry) {
      final stepIndex = entry.key;
      final stepText = entry.value;

      // Find any removed ingredients referenced in this step
      String? matchedIng;
      String? matchedKeyword;
      int matchedStart = -1;
      int matchedEnd = -1;

      for (final ing in removedIngredients) {
        final keywords = ingredientKeywords[ing] ?? [];
        for (final kw in keywords) {
          final regex = RegExp('\\b${RegExp.escape(kw)}\\b', caseSensitive: false);
          final match = regex.firstMatch(stepText);
          if (match != null) {
            matchedIng = ing;
            matchedKeyword = match.group(0);
            matchedStart = match.start;
            matchedEnd = match.end;
            break;
          }
        }
        if (matchedIng != null) break;
      }

      // If no ingredient matched, return original step
      if (matchedIng == null || matchedKeyword == null) {
        return AdaptedStep(
          stepIndex: stepIndex,
          originalText: stepText,
          adaptedText: stepText,
          isAdapted: false,
          isSkipped: false,
          segments: [StepTextSegment(text: stepText)],
        );
      }

      final hasSub = substitutions.containsKey(matchedIng);
      final sub = substitutions[matchedIng];

      // Determine if the entire step was exclusively about preparing this ingredient
      // e.g. "Chop the kimchi into bite-sized pieces." or "Press tofu with paper towels..."
      final isExclusiveStep = _isStepExclusivelyForIngredient(stepText, matchedKeyword) && !hasSub;

      if (isExclusiveStep) {
        final cleanName = _cleanDisplayName(matchedIng);
        return AdaptedStep(
          stepIndex: stepIndex,
          originalText: stepText,
          adaptedText: '[Step skipped: $cleanName excluded]',
          isAdapted: true,
          isSkipped: true,
          adaptationNote: 'Step skipped · $cleanName excluded',
          segments: [
            StepTextSegment(
              text: stepText,
              isStrikethrough: true,
            ),
          ],
        );
      }

      // Otherwise, the step contains other cooking operations and this ingredient is adapted inline
      final before = stepText.substring(0, matchedStart);
      final after = stepText.substring(matchedEnd);

      final List<StepTextSegment> segments = [];
      if (before.isNotEmpty) {
        segments.add(StepTextSegment(text: before));
      }

      segments.add(StepTextSegment(
        text: matchedKeyword,
        isStrikethrough: true,
      ));

      String adaptedText;
      String adaptationNote;

      if (hasSub && sub != null) {
        segments.add(StepTextSegment(
          text: ' ${sub.name}',
          isSubstitute: true,
        ));
        adaptedText = '$before${sub.name} (sub for $matchedKeyword)$after';
        adaptationNote = 'Adapted · ${sub.name} (sub)';
      } else {
        segments.add(const StepTextSegment(
          text: ' (omitted)',
          isOmittedNote: true,
        ));
        adaptedText = '$before$matchedKeyword (omitted)$after';
        adaptationNote = 'Adapted · ${_cleanDisplayName(matchedIng)} omitted';
      }

      if (after.isNotEmpty) {
        segments.add(StepTextSegment(text: after));
      }

      return AdaptedStep(
        stepIndex: stepIndex,
        originalText: stepText,
        adaptedText: adaptedText,
        isAdapted: true,
        isSkipped: false,
        adaptationNote: adaptationNote,
        segments: segments,
      );
    }).toList();
  }

  static String _cleanDisplayName(String raw) {
    final parenMatch = RegExp(r'^(.*?)\s*\(.*?\)$').firstMatch(raw);
    if (parenMatch != null) {
      return parenMatch.group(1)?.trim() ?? raw;
    }
    return raw;
  }

  /// Check if a step only does preparation on this ingredient alone
  static bool _isStepExclusivelyForIngredient(String stepText, String keyword) {
    final lower = stepText.toLowerCase();
    // If the step mentions major composite words like "rice", "pan", "pot", "broth", "boil", "serve", "heat oil"
    // it likely has other actions.
    const sharedActions = [
      'pan', 'pot', 'oil', 'serve', 'bowl', 'rice', 'noodles', 'broth', 'soup', 'simmer',
    ];

    int sharedCount = 0;
    for (final action in sharedActions) {
      if (lower.contains(action) && !keyword.toLowerCase().contains(action)) {
        sharedCount++;
      }
    }

    // If step is relatively short and mentions prep verbs like chop/dice/slice/cube/press
    const prepVerbs = ['chop', 'dice', 'slice', 'cube', 'press', 'rinse', 'drain', 'peel'];
    final startsWithPrep = prepVerbs.any((v) => lower.contains(v));

    if (startsWithPrep && sharedCount <= 1 && lower.length < 75) {
      return true;
    }

    // Step dedicated to frying/cooking just this single component alone
    // e.g. "Fry an egg sunny-side up in a separate small pan and serve on top."
    if (keyword.toLowerCase() == 'egg' && lower.contains('fry an egg') && lower.contains('separate')) {
      return true;
    }

    return false;
  }
}
