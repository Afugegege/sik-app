import '../models/recipe.dart';

class ServingsScaler {
  static final RegExp _fractionPattern = RegExp(r'^(\d+)\s*/\s*(\d+)');
  static final RegExp _decimalPattern = RegExp(r'^(\d+(?:\.\d+)?)\s*(.*)$');

  /// Scales a textual ingredient amount (e.g., "2 cups", "500 g", "1/2 tsp", "1 large")
  /// from [baseServings] to [targetServings].
  static String? scaleAmount(String? rawAmount, int baseServings, int targetServings) {
    if (rawAmount == null) return null;
    if (rawAmount.trim().isEmpty) return '';
    if (baseServings <= 0 || targetServings <= 0 || baseServings == targetServings) {
      return rawAmount.trim();
    }

    final trimmed = rawAmount.trim();
    final multiplier = targetServings / baseServings;

    // 1. Check for simple fraction like "1/2 cup" or "3/4 tsp"
    final fracMatch = _fractionPattern.firstMatch(trimmed);
    if (fracMatch != null) {
      final num = double.tryParse(fracMatch.group(1) ?? '1') ?? 1.0;
      final den = double.tryParse(fracMatch.group(2) ?? '1') ?? 1.0;
      final value = (num / den) * multiplier;
      final rest = trimmed.substring(fracMatch.end).trim();
      return _formatScaledValue(value, rest, hadSpace: true);
    }

    // 2. Check for number at start like "2 cups", "500g", "1.5 tbsp"
    final decMatch = _decimalPattern.firstMatch(trimmed);
    if (decMatch != null) {
      final numVal = double.tryParse(decMatch.group(1) ?? '');
      if (numVal != null) {
        final scaled = numVal * multiplier;
        final rawNum = decMatch.group(1) ?? '';
        final afterNum = trimmed.substring(rawNum.length);
        final hadSpace = afterNum.startsWith(' ');
        final unitAndDesc = decMatch.group(2)?.trim() ?? '';
        return _formatScaledValue(scaled, unitAndDesc, hadSpace: hadSpace);
      }
    }

    // If qualitative like "Some", "A little", "To taste", return unchanged
    return trimmed;
  }

  static String _formatScaledValue(double value, String unitAndDesc, {bool hadSpace = true}) {
    // Round to sensible culinary fractions / decimals
    String formattedNum;
    if ((value - value.round()).abs() < 0.04) {
      formattedNum = value.round().toString();
    } else if ((value - 0.25).abs() < 0.05) {
      formattedNum = '¼';
    } else if ((value - 0.333).abs() < 0.05) {
      formattedNum = '⅓';
    } else if ((value - 0.5).abs() < 0.05) {
      formattedNum = '½';
    } else if ((value - 0.666).abs() < 0.05) {
      formattedNum = '⅔';
    } else if ((value - 0.75).abs() < 0.05) {
      formattedNum = '¾';
    } else if (value >= 1.0 && (value - value.floor() - 0.5).abs() < 0.05) {
      formattedNum = '${value.floor()} ½';
    } else if (value >= 1.0 && (value - value.floor() - 0.25).abs() < 0.05) {
      formattedNum = '${value.floor()} ¼';
    } else if (value >= 1.0 && (value - value.floor() - 0.75).abs() < 0.05) {
      formattedNum = '${value.floor()} ¾';
    } else {
      // 1 decimal place if needed
      formattedNum = value < 10
          ? value.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')
          : value.round().toString();
    }

    if (unitAndDesc.isEmpty) {
      return formattedNum;
    }

    if (!hadSpace && RegExp(r'^[a-zA-Z가-힣]').hasMatch(unitAndDesc) && !formattedNum.contains(' ')) {
      return '$formattedNum$unitAndDesc';
    }

    return '$formattedNum $unitAndDesc';
  }

  /// Scales all ingredients in a [Recipe] from [recipe.servings] to [targetServings].
  static Recipe scaleRecipe(Recipe recipe, int targetServings) {
    final baseServings = recipe.servings <= 0 ? 2 : recipe.servings;
    if (baseServings == targetServings) return recipe;

    final scaledIngredients = recipe.ingredients.map((ing) {
      final newAmount = scaleAmount(ing.amount, baseServings, targetServings);
      return ing.copyWith(amount: newAmount);
    }).toList();

    return recipe.copyWith(
      servings: targetServings,
      ingredients: scaledIngredients,
    );
  }
}
