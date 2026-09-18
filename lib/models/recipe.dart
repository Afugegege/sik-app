import 'package:flutter/material.dart';

class RecipeIngredient {
  final String name;
  final String? amount;
  final String status; // 'have' | 'low' | 'missing'

  const RecipeIngredient({
    required this.name,
    this.amount,
    this.status = 'have',
  });

  RecipeIngredient copyWith({
    String? name,
    String? amount,
    String? status,
  }) {
    return RecipeIngredient(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      status: status ?? this.status,
    );
  }
}

class AiModificationDiff {
  final List<String> removed;
  final List<String> substituted; // e.g. "soy sauce → fish sauce"
  final String? timeChange; // e.g. "25 min → 18 min"
  final String? missingChange; // e.g. "3 missing → 0"

  const AiModificationDiff({
    this.removed = const [],
    this.substituted = const [],
    this.timeChange,
    this.missingChange,
  });
}

class Recipe {
  final String id;
  final String title;
  final String koreanTitle;
  final String imageUrl;
  final int cookingTimeMinutes;
  final String cookingMethod; // 'Stovetop' | 'Oven' | 'Air Fryer' | 'Microwave' | 'No-cook'
  final String difficulty; // 'Easy' | 'Medium' | 'Hard'
  final int kitchenMatchPercent; // e.g. 95
  final String category; // 'Cook with what you have' | 'Almost there' | 'Easy to find near you' | 'Quick & Simple' | 'Pastry & Dessert' | 'Baking' | 'Drinks'
  final List<RecipeIngredient> ingredients;
  final List<String> cookingSteps;
  final bool isAiModified;
  final bool isSaved;
  final bool isFavorite;
  final AiModificationDiff? diff;
  final String recipeSlot; // 'pantry_utility' | 'simple_classic' | 'aspirational'
  final String? inspirationNote; // Chef's tip or culinary mood note

  const Recipe({
    required this.id,
    required this.title,
    required this.koreanTitle,
    required this.imageUrl,
    required this.cookingTimeMinutes,
    required this.cookingMethod,
    required this.difficulty,
    required this.kitchenMatchPercent,
    this.category = 'Cook with what you have',
    required this.ingredients,
    required this.cookingSteps,
    this.isAiModified = false,
    this.isSaved = false,
    this.isFavorite = false,
    this.diff,
    this.recipeSlot = 'pantry_utility',
    this.inspirationNote,
  });

  bool get hasImage => imageUrl.isNotEmpty;

  String get categoryTag {
    final lower = (title + koreanTitle + category).toLowerCase();
    if (lower.contains('김치') || lower.contains('rice') || lower.contains('밥')) return 'RICE DISH';
    if (lower.contains('두부') || lower.contains('tofu')) return 'TOFU / PROTEIN';
    if (lower.contains('고구마') || lower.contains('sweet potato')) return 'KITCHEN SNACK';
    if (lower.contains('계란') || lower.contains('egg')) return 'EGG DISH';
    if (lower.contains('오이') || lower.contains('cucumber') || lower.contains('salad')) return 'FRESH SALAD';
    if (lower.contains('말차') || lower.contains('matcha') || lower.contains('drink')) return 'BEVERAGE';
    if (lower.contains('딸기') || lower.contains('strawberry') || lower.contains('dessert')) return 'DESSERT';
    if (lower.contains('baking') || lower.contains('bread')) return 'BAKERY';
    return 'KOREAN KITCHEN';
  }

  IconData get categoryIcon {
    final lower = '$title $koreanTitle $category'.toLowerCase();

    // 1. Drinks / Beverages
    if (lower.contains('drink') ||
        lower.contains('beverage') ||
        lower.contains('latte') ||
        lower.contains('coffee') ||
        lower.contains('matcha') ||
        lower.contains('juice') ||
        lower.contains('smoothie') ||
        lower.contains(' tea') ||
        lower.contains('tea ') ||
        lower.contains('oat milk') ||
        lower.contains('strawberry milk') ||
        category.toLowerCase().contains('drink')) {
      return Icons.local_cafe_rounded;
    }

    // 2. Desserts & Bakery
    if (lower.contains('dessert') ||
        lower.contains('baking') ||
        lower.contains('cookie') ||
        lower.contains('cake') ||
        lower.contains('shaved ice') ||
        lower.contains('sweet') ||
        lower.contains('bread') ||
        lower.contains('pastry') ||
        category.toLowerCase().contains('dessert') ||
        category.toLowerCase().contains('baking')) {
      return Icons.icecream_rounded;
    }

    // 3. Rice, Stews & Main Dishes
    if (lower.contains('rice') ||
        lower.contains('밥') ||
        lower.contains('stew') ||
        lower.contains('찌개') ||
        lower.contains('noodle') ||
        lower.contains('bibimbap') ||
        lower.contains('fried rice')) {
      return Icons.rice_bowl_rounded;
    }

    // 4. Egg Dishes
    if (lower.contains('egg') || lower.contains('계란')) {
      return Icons.egg_alt_rounded;
    }

    // 5. Appetizers, Snacks & Salads
    if (lower.contains('snack') ||
        lower.contains('salad') ||
        lower.contains('appetizer') ||
        lower.contains('banchan') ||
        lower.contains('side dish') ||
        lower.contains('cucumber') ||
        lower.contains('sweet potato')) {
      return Icons.tapas_rounded;
    }

    return Icons.dinner_dining_rounded;
  }

  int get missingIngredientsCount => ingredients.where((i) => i.status == 'missing').length;

  bool get isPantryUtility => recipeSlot == 'pantry_utility';
  bool get isSimpleClassic => recipeSlot == 'simple_classic';
  bool get isAspirational => recipeSlot == 'aspirational';

  Recipe copyWith({
    String? id,
    String? title,
    String? koreanTitle,
    String? imageUrl,
    int? cookingTimeMinutes,
    String? cookingMethod,
    String? difficulty,
    int? kitchenMatchPercent,
    String? category,
    List<RecipeIngredient>? ingredients,
    List<String>? cookingSteps,
    bool? isAiModified,
    bool? isSaved,
    bool? isFavorite,
    AiModificationDiff? diff,
    String? recipeSlot,
    String? inspirationNote,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      koreanTitle: koreanTitle ?? this.koreanTitle,
      imageUrl: imageUrl ?? this.imageUrl,
      cookingTimeMinutes: cookingTimeMinutes ?? this.cookingTimeMinutes,
      cookingMethod: cookingMethod ?? this.cookingMethod,
      difficulty: difficulty ?? this.difficulty,
      kitchenMatchPercent: kitchenMatchPercent ?? this.kitchenMatchPercent,
      category: category ?? this.category,
      ingredients: ingredients ?? this.ingredients,
      cookingSteps: cookingSteps ?? this.cookingSteps,
      isAiModified: isAiModified ?? this.isAiModified,
      isSaved: isSaved ?? this.isSaved,
      isFavorite: isFavorite ?? this.isFavorite,
      diff: diff ?? this.diff,
      recipeSlot: recipeSlot ?? this.recipeSlot,
      inspirationNote: inspirationNote ?? this.inspirationNote,
    );
  }
}
