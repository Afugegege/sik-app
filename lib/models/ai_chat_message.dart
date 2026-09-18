import 'recipe.dart';
import 'inventory_batch_action.dart';

enum AiChatActionType {
  none,
  addToShoppingList,
  addIngredientsToInventory,
  viewRecipe,
  clearFilters,
  changeTheme,
}

class AiChatAction {
  final AiChatActionType type;
  final String label;
  final dynamic payload; // e.g. List<String> of items, or Recipe

  const AiChatAction({
    required this.type,
    required this.label,
    this.payload,
  });
}

class AiRecipeOption {
  final String title;
  final String cookingTime; // e.g. "5m" or "15 mins"
  final String difficulty; // e.g. "Easy"
  final String description; // brief tagline / vibe
  final String category; // e.g. "Beverage", "Baking", "Dinner"

  const AiRecipeOption({
    required this.title,
    this.cookingTime = '',
    this.difficulty = 'Easy',
    this.description = '',
    this.category = '',
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'cookingTime': cookingTime,
    'difficulty': difficulty,
    'description': description,
    'category': category,
  };

  factory AiRecipeOption.fromJson(Map<String, dynamic> json) => AiRecipeOption(
    title: json['title'] ?? '',
    cookingTime: json['cookingTime'] ?? '',
    difficulty: json['difficulty'] ?? 'Easy',
    description: json['description'] ?? '',
    category: json['category'] ?? '',
  );
}

class AiStructuredRecipe {
  final String title;
  final String koreanTitle;
  final String category;
  final String cookingTime;
  final String difficulty;
  final int servings;
  final List<String> ingredients;
  final List<String> instructions;
  final String chefNote;

  const AiStructuredRecipe({
    required this.title,
    this.koreanTitle = '',
    this.category = 'Studio Recipe',
    this.cookingTime = '15 mins',
    this.difficulty = 'Easy',
    this.servings = 1,
    this.ingredients = const [],
    this.instructions = const [],
    this.chefNote = '',
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'koreanTitle': koreanTitle,
    'category': category,
    'cookingTime': cookingTime,
    'difficulty': difficulty,
    'servings': servings,
    'ingredients': ingredients,
    'instructions': instructions,
    'chefNote': chefNote,
  };

  factory AiStructuredRecipe.fromJson(Map<String, dynamic> json) => AiStructuredRecipe(
    title: json['title'] ?? '',
    koreanTitle: json['koreanTitle'] ?? '',
    category: json['category'] ?? 'Studio Recipe',
    cookingTime: json['cookingTime'] ?? '15 mins',
    difficulty: json['difficulty'] ?? 'Easy',
    servings: json['servings'] ?? 1,
    ingredients: List<String>.from(json['ingredients'] ?? []),
    instructions: List<String>.from(json['instructions'] ?? []),
    chefNote: json['chefNote'] ?? '',
  );
}

class AiChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String> quickReplies;
  final List<String> suggestedIngredients;
  final List<Recipe> recommendedRecipes;
  final List<AiChatAction> actions;
  final List<InventoryBatchActionItem> batchInventoryActions;
  final List<AiRecipeOption> recipeOptions;
  final AiStructuredRecipe? structuredRecipe;

  final bool isVoiceMessage;
  final int? voiceDurationSeconds;

  const AiChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.quickReplies = const [],
    this.suggestedIngredients = const [],
    this.recommendedRecipes = const [],
    this.actions = const [],
    this.batchInventoryActions = const [],
    this.recipeOptions = const [],
    this.structuredRecipe,
    this.isVoiceMessage = false,
    this.voiceDurationSeconds,
  });

  AiChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    List<String>? quickReplies,
    List<String>? suggestedIngredients,
    List<Recipe>? recommendedRecipes,
    List<AiChatAction>? actions,
    List<InventoryBatchActionItem>? batchInventoryActions,
    List<AiRecipeOption>? recipeOptions,
    AiStructuredRecipe? structuredRecipe,
    bool? isVoiceMessage,
    int? voiceDurationSeconds,
  }) {
    return AiChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      quickReplies: quickReplies ?? this.quickReplies,
      suggestedIngredients: suggestedIngredients ?? this.suggestedIngredients,
      recommendedRecipes: recommendedRecipes ?? this.recommendedRecipes,
      actions: actions ?? this.actions,
      batchInventoryActions: batchInventoryActions ?? this.batchInventoryActions,
      recipeOptions: recipeOptions ?? this.recipeOptions,
      structuredRecipe: structuredRecipe ?? this.structuredRecipe,
      isVoiceMessage: isVoiceMessage ?? this.isVoiceMessage,
      voiceDurationSeconds: voiceDurationSeconds ?? this.voiceDurationSeconds,
    );
  }
}
