import '../models/ai_chat_message.dart';

class AiRecipeParserResult {
  final String cleanText;
  final List<AiRecipeOption> options;
  final AiStructuredRecipe? recipe;

  const AiRecipeParserResult({
    required this.cleanText,
    this.options = const [],
    this.recipe,
  });
}

/// Intelligent parser that detects, extracts, and separates structured culinary data
/// (recipe title option selectors and full aesthetic recipes) from conversational AI text.
class AiRecipeParser {
  static AiRecipeParserResult parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return const AiRecipeParserResult(cleanText: '');
    }

    // 1. Explicit OPTIONS: block
    if (rawText.contains('OPTIONS:')) {
      final parts = rawText.split('OPTIONS:');
      final intro = parts[0].trim();
      final optionsContent = parts[1].trim();

      final List<AiRecipeOption> options = [];
      final lines = optionsContent.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        if (trimmed.startsWith('-') ||
            trimmed.startsWith('•') ||
            trimmed.startsWith('*') ||
            RegExp(r'^\d+\.').hasMatch(trimmed)) {
          final opt = _parseOptionLine(trimmed);
          if (opt != null) options.add(opt);
        }
      }

      if (options.isNotEmpty) {
        return AiRecipeParserResult(
          cleanText: intro.isNotEmpty
              ? intro
              : 'Here are curated recipe choices from 식 studio:',
          options: options,
        );
      }
    }

    // 2. Explicit RECIPE: block
    if (rawText.contains('RECIPE:')) {
      final parts = rawText.split('RECIPE:');
      final intro = parts[0].trim();
      final recipeContent = parts[1].trim();

      final recipe = _parseStructuredRecipeBlock(recipeContent);
      if (recipe != null) {
        return AiRecipeParserResult(
          cleanText: intro.isNotEmpty
              ? intro
              : 'Here is your curated recipe from 식 studio:',
          recipe: recipe,
        );
      }
    }

    // 3. Natural Markdown Recipe Detection
    final naturalRecipe = _detectAndExtractNaturalRecipe(rawText);
    if (naturalRecipe != null) {
      return naturalRecipe;
    }

    // 4. Natural Options Detection
    final naturalOptions = _detectAndExtractNaturalOptions(rawText);
    if (naturalOptions != null) {
      return naturalOptions;
    }

    return AiRecipeParserResult(cleanText: rawText.trim());
  }

  // ---------------------------------------------------------------------------
  // EXPLICIT BLOCK PARSERS
  // ---------------------------------------------------------------------------

  static AiRecipeOption? _parseOptionLine(String line) {
    // Strip leading list symbols: - , • , 1. , *
    var cleaned = line.replaceFirst(RegExp(r'^[-•*\d.]+\s*'), '').trim();

    String title = '';
    String time = '15m';
    String diff = 'Easy';
    String category = 'Studio Dish';
    String desc = '';

    if (cleaned.contains('|')) {
      final segments = cleaned.split('|').map((s) => s.trim()).toList();
      for (final seg in segments) {
        final lower = seg.toLowerCase();
        if (lower.startsWith('title:')) {
          title = seg.substring(6).trim();
        } else if (lower.startsWith('time:')) {
          time = seg.substring(5).trim();
        } else if (lower.startsWith('difficulty:')) {
          diff = seg.substring(11).trim();
        } else if (lower.startsWith('category:')) {
          category = seg.substring(9).trim();
        } else if (lower.startsWith('desc:')) {
          desc = seg.substring(5).trim();
        } else if (title.isEmpty) {
          title = seg;
        }
      }
    } else {
      // e.g. **Title** (time) - description
      final titleMatch = RegExp(r'\*\*(.*?)\*\*').firstMatch(cleaned);
      if (titleMatch != null) {
        title = titleMatch.group(1)!.trim();
        final rest = cleaned.replaceFirst(titleMatch.group(0)!, '').trim();
        final timeMatch = RegExp(r'\((\d+.*?)\)').firstMatch(rest);
        if (timeMatch != null) {
          time = timeMatch.group(1)!.trim();
        }
        desc = rest.replaceAll(RegExp(r'[\(\)-]'), '').trim();
      } else {
        title = cleaned;
      }
    }

    title = title.replaceAll(RegExp(r'[*_#]'), '').trim();
    if (title.isEmpty) return null;

    return AiRecipeOption(
      title: title,
      cookingTime: time,
      difficulty: diff,
      category: category,
      description: desc,
    );
  }

  static AiStructuredRecipe? _parseStructuredRecipeBlock(String content) {
    final lines = content.split('\n');
    String title = 'Curated Recipe';
    String category = 'Studio Recipe';
    String time = '15 mins';
    String diff = 'Easy';
    int servings = 1;
    String tip = '';
    final List<String> ingredients = [];
    final List<String> instructions = [];

    String currentSection = 'meta';

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final lower = line.toLowerCase();

      if (lower.startsWith('title:')) {
        title = line.substring(6).replaceAll(RegExp(r'[*_#]'), '').trim();
        continue;
      }
      if (lower.startsWith('category:')) {
        category = line.substring(9).trim();
        continue;
      }
      if (lower.startsWith('time:')) {
        time = line.substring(5).trim();
        continue;
      }
      if (lower.startsWith('difficulty:')) {
        diff = line.substring(11).trim();
        continue;
      }
      if (lower.startsWith('servings:')) {
        final s = int.tryParse(line.substring(9).replaceAll(RegExp(r'[^0-9]'), ''));
        if (s != null) servings = s;
        continue;
      }
      if (lower.startsWith('ingredients:')) {
        currentSection = 'ingredients';
        continue;
      }
      if (lower.startsWith('instructions:') || lower.startsWith('steps:')) {
        currentSection = 'instructions';
        continue;
      }
      if (lower.startsWith('tip:') || lower.startsWith('note:') || lower.startsWith('chef tip:')) {
        currentSection = 'tip';
        tip = line.replaceFirst(RegExp(r'^(tip|note|chef tip):\s*', caseSensitive: false), '').trim();
        continue;
      }

      if (currentSection == 'ingredients') {
        final clean = line.replaceFirst(RegExp(r'^[-•*\d.]+\s*'), '').trim();
        if (clean.isNotEmpty) ingredients.add(clean);
      } else if (currentSection == 'instructions') {
        final clean = line.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
        if (clean.isNotEmpty) instructions.add(clean);
      } else if (currentSection == 'tip') {
        tip = '$tip $line'.trim();
      }
    }

    if (ingredients.isNotEmpty && instructions.isNotEmpty) {
      return AiStructuredRecipe(
        title: title,
        category: category,
        cookingTime: time,
        difficulty: diff,
        servings: servings,
        ingredients: ingredients,
        instructions: instructions,
        chefNote: tip,
      );
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // NATURAL MARKDOWN RECIPE EXTRACTOR
  // ---------------------------------------------------------------------------

  static AiRecipeParserResult? _detectAndExtractNaturalRecipe(String text) {
    final lower = text.toLowerCase();
    final hasIngredients = lower.contains('ingredients:');
    final hasInstructions = lower.contains('instructions:') ||
        lower.contains('directions:') ||
        lower.contains('steps:');

    if (!hasIngredients || !hasInstructions) {
      return null;
    }

    final lines = text.split('\n');
    int ingredientsIdx = -1;
    int instructionsIdx = -1;
    int titleIdx = -1;

    for (int i = 0; i < lines.length; i++) {
      final l = lines[i].trim().toLowerCase();
      if (l == 'ingredients:' || l == '**ingredients:**' || l.startsWith('ingredients:')) {
        if (ingredientsIdx == -1) ingredientsIdx = i;
      } else if (l == 'instructions:' ||
          l == '**instructions:**' ||
          l.startsWith('instructions:') ||
          l == 'directions:' ||
          l == 'steps:' ||
          l == '**steps:**') {
        if (instructionsIdx == -1) instructionsIdx = i;
      } else if (ingredientsIdx == -1 &&
          (lines[i].trim().startsWith('###') ||
              lines[i].trim().startsWith('##') ||
              lines[i].trim().startsWith('#') ||
              lines[i].trim().startsWith('**Recipe:'))) {
        titleIdx = i;
      }
    }

    if (ingredientsIdx == -1 || instructionsIdx == -1 || instructionsIdx <= ingredientsIdx) {
      return null;
    }

    // Extract Title
    String title = 'Curated Studio Recipe';
    String introText = '';

    if (titleIdx != -1) {
      title = lines[titleIdx].replaceAll(RegExp(r'[#*_]'), '').replaceFirst('Recipe:', '').trim();
      introText = lines.sublist(0, titleIdx).join('\n').trim();
    } else {
      // Check line immediately preceding ingredients
      if (ingredientsIdx > 0) {
        final prev = lines[ingredientsIdx - 1].replaceAll(RegExp(r'[#*_]'), '').trim();
        if (prev.isNotEmpty && prev.length < 50 && !prev.endsWith(':')) {
          title = prev;
          introText = lines.sublist(0, ingredientsIdx - 1).join('\n').trim();
        } else {
          introText = lines.sublist(0, ingredientsIdx).join('\n').trim();
        }
      }
    }

    // Extract Ingredients
    final List<String> ingredients = [];
    for (int i = ingredientsIdx + 1; i < instructionsIdx; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final clean = line.replaceFirst(RegExp(r'^[-•*\d.]+\s*'), '').trim();
      if (clean.isNotEmpty) ingredients.add(clean);
    }

    // Extract Instructions & Tips
    final List<String> instructions = [];
    String tip = '';
    for (int i = instructionsIdx + 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final lLower = line.toLowerCase();
      if (lLower.startsWith('tip:') ||
          lLower.startsWith('*pro tip:') ||
          lLower.startsWith('*chef tip:') ||
          lLower.startsWith('note:')) {
        tip = line.replaceFirst(RegExp(r'^\*?(tip|pro tip|chef tip|note):\*?\s*', caseSensitive: false), '').trim();
        continue;
      }
      final clean = line.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
      if (clean.isNotEmpty) {
        instructions.add(clean);
      }
    }

    if (ingredients.length < 2 || instructions.isEmpty) {
      return null;
    }

    // Auto-detect category & cooking time
    String category = 'Studio Recipe';
    String time = '15 mins';
    final tLower = title.toLowerCase();
    if (tLower.contains('latte') || tLower.contains('tea') || tLower.contains('coffee') || tLower.contains('drink')) {
      category = 'Beverage';
      time = '5 mins';
    } else if (tLower.contains('cookie') || tLower.contains('cake') || tLower.contains('pancake') || tLower.contains('bake')) {
      category = 'Baking & Dessert';
      time = '25 mins';
    } else if (tLower.contains('pasta') || tLower.contains('noodle') || tLower.contains('rice')) {
      category = 'Main Dish';
      time = '18 mins';
    } else if (tLower.contains('soup') || tLower.contains('stew')) {
      category = 'Soup & Stew';
      time = '20 mins';
    }

    return AiRecipeParserResult(
      cleanText: introText.isNotEmpty
          ? introText
          : 'You have great ingredients for this! Here is your curated recipe:',
      recipe: AiStructuredRecipe(
        title: title,
        category: category,
        cookingTime: time,
        difficulty: 'Easy',
        servings: 1,
        ingredients: ingredients,
        instructions: instructions,
        chefNote: tip,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // NATURAL OPTIONS DETECTOR
  // ---------------------------------------------------------------------------

  static AiRecipeParserResult? _detectAndExtractNaturalOptions(String text) {
    // If text contains a short list of 2-4 bold recipe items and NO instructions/ingredients:
    if (text.toLowerCase().contains('ingredients:') || text.toLowerCase().contains('instructions:')) {
      return null;
    }

    final lines = text.split('\n');
    final List<AiRecipeOption> options = [];
    final List<String> introLines = [];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final isListLine = line.startsWith('- ') ||
          line.startsWith('• ') ||
          line.startsWith('* ') ||
          RegExp(r'^\d+\.\s+').hasMatch(line);

      if (isListLine && line.contains('**')) {
        final opt = _parseOptionLine(line);
        if (opt != null) {
          options.add(opt);
          continue;
        }
      }

      if (options.isEmpty) {
        introLines.add(line);
      }
    }

    if (options.length >= 2 && options.length <= 5) {
      return AiRecipeParserResult(
        cleanText: introLines.join('\n').trim(),
        options: options,
      );
    }
    return null;
  }
}
