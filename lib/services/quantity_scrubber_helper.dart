class QuantityStepResult {
  final String quantityDisplay;
  final String status;

  const QuantityStepResult({
    required this.quantityDisplay,
    required this.status,
  });
}

class QuantityScrubberHelper {
  static const List<String> fuzzyLevels = [
    'Empty',
    'Almost empty',
    'Running low',
    'A little',
    'Some',
    'Half',
    'Plenty',
    'Full',
  ];

  static final RegExp _numericPattern = RegExp(r'^([0-9]+(?:\.[0-9]+)?)\s*(.*)$');

  /// Determines whether a given text is predominantly numeric or qualitative.
  static bool isNumeric(String? text) {
    if (text == null || text.trim().isEmpty) return false;
    return _numericPattern.hasMatch(text.trim());
  }

  /// Calculates the stepped quantity when sliding left (decrement) or right (increment).
  static QuantityStepResult stepQuantity({
    required String? currentQuantity,
    required String currentStatus,
    required bool increment,
  }) {
    final raw = (currentQuantity ?? '').trim();

    if (raw.isEmpty) {
      if (increment) {
        return const QuantityStepResult(
          quantityDisplay: '1 piece',
          status: 'Have',
        );
      } else {
        return const QuantityStepResult(
          quantityDisplay: 'Empty',
          status: 'Missing',
        );
      }
    }

    final numMatch = _numericPattern.firstMatch(raw);

    if (numMatch != null) {
      final numStr = numMatch.group(1)!;
      final unitStr = numMatch.group(2)?.trim() ?? '';
      final currentVal = double.tryParse(numStr) ?? 1.0;

      final (stepSize, isDecimal) = _getStepSize(currentVal, unitStr);

      double nextVal = increment ? currentVal + stepSize : currentVal - stepSize;
      if (nextVal < 0) nextVal = 0;

      // Handle clean rounding to avoid floating point anomalies
      if (!isDecimal) {
        nextVal = nextVal.roundToDouble();
      } else {
        nextVal = (nextVal * 100).round() / 100.0;
      }

      final formattedNum = _formatNumber(nextVal);
      final adjustedUnit = _adjustUnitPluralization(nextVal, unitStr);
      final newDisplay = adjustedUnit.isNotEmpty ? '$formattedNum $adjustedUnit' : formattedNum;

      final newStatus = _deriveStatusForValue(nextVal, currentStatus);

      return QuantityStepResult(
        quantityDisplay: newDisplay,
        status: newStatus,
      );
    }

    // Fuzzy qualitative stepping
    final newDisplay = _stepFuzzy(raw, increment);
    final newStatus = _deriveStatusForFuzzy(newDisplay, currentStatus);

    return QuantityStepResult(
      quantityDisplay: newDisplay,
      status: newStatus,
    );
  }

  static (double, bool) _getStepSize(double val, String unit) {
    final u = unit.toLowerCase();

    if (u == 'g' || u == 'grams' || u == 'gram' || u == 'ml' || u == 'milliliters') {
      if (val >= 100) return (50.0, false);
      if (val >= 20) return (10.0, false);
      return (5.0, false);
    }

    if (u == 'kg' || u == 'kilos' || u == 'kilograms' || u == 'l' || u == 'liters' || u == 'litres') {
      if (val >= 2.0) return (0.5, true);
      return (0.25, true);
    }

    // Discrete items (e.g. pieces, packs, cans, eggs, bottles)
    return (1.0, false);
  }

  static String _formatNumber(double val) {
    if (val == val.truncateToDouble()) {
      return val.toInt().toString();
    }
    // Up to 2 decimal places, removing unnecessary trailing zero
    final s = val.toStringAsFixed(2);
    if (s.endsWith('0')) {
      return val.toStringAsFixed(1);
    }
    return s;
  }

  static String _adjustUnitPluralization(double val, String unit) {
    if (unit.isEmpty) return '';

    final lower = unit.toLowerCase();
    final isPlural = val != 1.0;

    // Handle common unit singular/plural variations
    if (lower == 'piece' || lower == 'pieces') {
      return isPlural ? 'pieces' : 'piece';
    }
    if (lower == 'pack' || lower == 'packs') {
      return isPlural ? 'packs' : 'pack';
    }
    if (lower == 'can' || lower == 'cans') {
      return isPlural ? 'cans' : 'can';
    }
    if (lower == 'bottle' || lower == 'bottles') {
      return isPlural ? 'bottles' : 'bottle';
    }
    if (lower == 'box' || lower == 'boxes') {
      return isPlural ? 'boxes' : 'box';
    }
    if (lower == 'egg' || lower == 'eggs') {
      return isPlural ? 'eggs' : 'egg';
    }
    if (lower == 'slice' || lower == 'slices') {
      return isPlural ? 'slices' : 'slice';
    }
    if (lower == 'bag' || lower == 'bags') {
      return isPlural ? 'bags' : 'bag';
    }

    return unit;
  }

  static String _stepFuzzy(String current, bool increment) {
    int index = _findFuzzyIndex(current);

    if (index == -1) {
      // Default baseline if unrecognized
      return increment ? 'Plenty' : 'Low';
    }

    int nextIndex = increment ? index + 1 : index - 1;
    if (nextIndex < 0) nextIndex = 0;
    if (nextIndex >= fuzzyLevels.length) nextIndex = fuzzyLevels.length - 1;

    return fuzzyLevels[nextIndex];
  }

  static int _findFuzzyIndex(String current) {
    final lower = current.trim().toLowerCase();

    for (int i = 0; i < fuzzyLevels.length; i++) {
      if (fuzzyLevels[i].toLowerCase() == lower) {
        return i;
      }
    }

    // Keyword heuristics
    if (lower.contains('empty')) return 0;
    if (lower.contains('almost empty')) return 1;
    if (lower.contains('low') || lower.contains('running low')) return 2;
    if (lower.contains('little')) return 3;
    if (lower.contains('some')) return 4;
    if (lower.contains('half')) return 5;
    if (lower.contains('plenty')) return 6;
    if (lower.contains('full')) return 7;

    return -1;
  }

  static String _deriveStatusForValue(double val, String currentStatus) {
    if (val <= 0) {
      return 'Missing';
    } else if (val == 1.0) {
      // 1 item can be Have or Running low depending on prior status
      return currentStatus == 'Running low' ? 'Running low' : 'Have';
    } else {
      return 'Have';
    }
  }

  static String _deriveStatusForFuzzy(String fuzzyLevel, String currentStatus) {
    final lower = fuzzyLevel.toLowerCase();

    if (lower == 'empty') {
      return 'Missing';
    } else if (lower == 'almost empty' || lower == 'running low' || lower == 'a little') {
      return 'Running low';
    } else {
      return 'Have';
    }
  }
}
