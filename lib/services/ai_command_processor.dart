import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/fridge_item.dart';
import '../models/ai_follow_up_session.dart';
import '../models/cooking_record.dart';
import '../models/cooking_reminder.dart';
import '../models/recipe.dart';
import '../screens/shopping_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/random_recipe_picker_modal.dart';
import 'ingredient_intelligence.dart';
import 'openai_service.dart';

enum ActionPreviewType {
  saveRecipe,
  addInventory,
  addShopping,
  setReminder,
  logMeal,
  viewMode,
  quickCommand,
  openChat,
}

class ActionPreview {
  final ActionPreviewType type;
  final String title;
  final String detail;
  final IconData icon;

  const ActionPreview({
    required this.type,
    required this.title,
    required this.detail,
    required this.icon,
  });
}

class AiCommandResult {
  final bool executedAction;
  final String feedbackMessage;

  const AiCommandResult({
    required this.executedAction,
    required this.feedbackMessage,
  });
}

class AiCommandProcessor {
  /// Processes any natural language command from the user, orchestrating
  /// modifications across all functions within the app (Inventory, Shopping List,
  /// Cooking Journal, Reminders, Recipe Discovery, Card Picker, Theme & Settings).
  static Future<AiCommandResult> processUserPrompt(
    BuildContext context,
    String rawPrompt,
  ) async {
    final prompt = rawPrompt.trim();
    if (prompt.isEmpty) {
      return const AiCommandResult(
        executedAction: false,
        feedbackMessage: 'Please enter a command or recipe request.',
      );
    }

    final lower = prompt.toLowerCase();
    final appState = context.read<AppState>();

    // ------------------------------------------------------------------------
    // 1. FAST LOCAL NLP MATCHERS (Deterministic & Instant)
    // ------------------------------------------------------------------------

    // A. View Mode (Grid vs List)
    if (_isViewModeRequest(lower)) {
      final toGrid = lower.contains('grid');
      appState.setRecipeViewMode(toGrid);
      appState.setActiveTab(AppState.tabDishes);
      return AiCommandResult(
        executedAction: true,
        feedbackMessage: toGrid
            ? 'Switched recipe cards to Grid View'
            : 'Switched recipe cards to List View',
      );
    }

    // B. Random Recipe Card Picker
    if (_isRandomPickerRequest(lower)) {
      RandomRecipePickerModal.show(context);
      return const AiCommandResult(
        executedAction: true,
        feedbackMessage: 'Opened Random Recipe Picker',
      );
    }

    // C. Theme / Accent Color Selection
    final themeResult = _handleThemeCommand(appState, lower);
    if (themeResult != null) return themeResult;

    // D. Clear / Reset Inventory
    if (_isClearInventory(lower)) {
      appState.clearInventory();
      appState.setActiveTab(AppState.tabFridge);
      return const AiCommandResult(
        executedAction: true,
        feedbackMessage: 'Cleared all items from Kitchen Inventory',
      );
    }
    if (_isResetInventory(lower)) {
      appState.resetInventoryToDefault();
      appState.setActiveTab(AppState.tabFridge);
      return const AiCommandResult(
        executedAction: true,
        feedbackMessage: 'Restored default Kitchen Inventory items',
      );
    }

    // E. Clear Recipe Filters / Search
    if (_isClearFilterRequest(lower)) {
      appState.clearAiQuery();
      appState.setFilter('All');
      appState.setCookingMethod('All');
      return const AiCommandResult(
        executedAction: true,
        feedbackMessage: 'Cleared recipe filters and search query',
      );
    }

    // F. App Navigation
    final navResult = _handleNavigation(context, appState, lower);
    if (navResult != null) return navResult;

    // G. Dietary Restrictions
    final dietResult = _handleDietaryRestrictions(appState, lower);
    if (dietResult != null) return dietResult;

    // H. Shopping / Want List Additions & Actions
    if (_isShoppingListRequest(lower)) {
      return _handleShoppingList(appState, prompt, lower);
    }

    // I. Cooking Reminders (Defrost, Prep, Ingredient)
    if (_isReminderRequest(lower)) {
      return _handleReminder(appState, prompt, lower);
    }

    // J. Log Cooked Meal (Cooking Record)
    if (_isLogMealRequest(lower)) {
      return _handleLogMeal(appState, prompt, lower);
    }

    // K. Remove / Delete Inventory Items
    if (_isRemoveInventoryRequest(lower)) {
      final remResult = _handleRemoveInventory(appState, prompt, lower);
      if (remResult != null) return remResult;
    }

    // L. Add Items to Kitchen Inventory (Fridge / Freezer / Pantry)
    // Handles: "i wanted to add a list of stuff: ...", "add eggs, milk, tofu", "i bought groceries: ...", etc.
    if (_isAddInventoryRequest(lower)) {
      return _handleAddInventory(appState, prompt, lower);
    }

    // M. Save / Bookmark Recipe
    if (_isSaveRecipeRequest(lower)) {
      return _handleSaveRecipe(appState, prompt, lower);
    }

    // ------------------------------------------------------------------------
    // 2. OPENAI GPT ASSISTANT (If API Key Present & Prompt is Complex / Conversational)
    // ------------------------------------------------------------------------
    if (appState.apiKey.isNotEmpty) {
      try {
        final currentNames = appState.fridgeItems.map((e) => e.name).toList();
        final openAiResult = await OpenAiService.parseNaturalLanguageIntent(
          apiKey: appState.apiKey,
          userPrompt: prompt,
          currentFridgeItems: currentNames,
        );

        if (openAiResult != null && openAiResult['actions'] is List) {
          final actions = openAiResult['actions'] as List<dynamic>;
          if (actions.isNotEmpty) {
            String feedback = openAiResult['feedback'] as String? ?? '';
            final executedSummary = <String>[];

            for (final action in actions) {
              if (action is! Map<String, dynamic>) continue;
              final type = action['type'] as String?;

              switch (type) {
                case 'add_inventory':
                  final items = action['items'];
                  if (items is List) {
                    final names = <String>[];
                    for (final item in items) {
                      if (item is Map) {
                        final name = (item['name'] as String? ?? '').trim();
                        if (name.isEmpty) continue;
                        final locStr = (item['location'] as String? ?? '').toLowerCase();
                        StorageLocation loc = StorageLocation.fridge;
                        if (locStr.contains('freezer')) {
                          loc = StorageLocation.freezer;
                        } else if (locStr.contains('seasoning') || locStr.contains('spice')) {
                          loc = StorageLocation.seasoning;
                        } else if (locStr.contains('pantry')) {
                          loc = StorageLocation.pantry;
                        } else {
                          loc = IngredientIntelligence.autoDetectLocation(name);
                        }
                        final qty = (item['quantity'] as String? ?? 'Plenty');
                        appState.addFridgeItem(FridgeItem(
                          id: 'ai_${DateTime.now().millisecondsSinceEpoch}_${names.length}',
                          name: _capitalize(name),
                          location: loc,
                          quantityMode: qty == 'Plenty' ? QuantityMode.approximate : QuantityMode.exact,
                          quantityDisplay: qty,
                          status: 'Have',
                        ));
                        names.add('${_capitalize(name)} (${loc.name})');
                      }
                    }
                    if (names.isNotEmpty) {
                      appState.setActiveTab(AppState.tabFridge);
                      executedSummary.add('Added: ${names.join(", ")}');
                    }
                  }
                  break;

                case 'remove_inventory':
                  final items = action['items'];
                  if (items is List) {
                    for (final item in items) {
                      final name = item.toString().toLowerCase().trim();
                      final match = appState.fridgeItems.firstWhere(
                        (f) => f.name.toLowerCase().contains(name),
                        orElse: () => FridgeItem(
                          id: '',
                          name: '',
                          location: StorageLocation.fridge,
                          quantityMode: QuantityMode.approximate,
                        ),
                      );
                      if (match.id.isNotEmpty) {
                        appState.removeFridgeItem(match.id);
                        executedSummary.add('Removed ${match.name}');
                      }
                    }
                    appState.setActiveTab(AppState.tabFridge);
                  }
                  break;

                case 'add_shopping':
                  final items = action['items'];
                  if (items is List) {
                    final list = items.map((e) => _capitalize(e.toString().trim())).toList();
                    appState.addMultipleToWantList(list);
                    executedSummary.add('Added ${list.join(", ")} to shopping list');
                  }
                  break;

                case 'add_reminder':
                  final title = action['title'] as String? ?? 'Cooking Reminder';
                  final reminderType = action['reminderType'] as String? ?? 'prep';
                  final hours = (action['hoursFromNow'] as num? ?? 3).toInt();
                  appState.addCookingReminder(CookingReminder(
                    id: 'ai_rem_${DateTime.now().millisecondsSinceEpoch}',
                    title: '$title ⏰',
                    scheduledDate: DateTime.now().add(Duration(hours: hours)),
                    reminderType: reminderType,
                    isCompleted: false,
                  ));
                  executedSummary.add('Reminder set: $title');
                  break;

                case 'log_meal':
                  final title = action['recipeTitle'] as String? ?? 'Home Cooked Dish';
                  appState.addCookingRecord(CookingRecord(
                    id: 'ai_cr_${DateTime.now().millisecondsSinceEpoch}',
                    recipeTitle: _capitalize(title),
                    koreanTitle: '',
                    date: DateTime.now(),
                    photoUrl: '',
                    rating: 5,
                    notes: 'Logged via AI assistant',
                    tags: const ['AI Logged'],
                  ));
                  appState.setActiveTab(AppState.tabJournal);
                  executedSummary.add('Logged meal: $title');
                  break;

                case 'random_recipe':
                  if (context.mounted) {
                    RandomRecipePickerModal.show(context);
                  }
                  executedSummary.add('Opened Random Recipe Picker');
                  break;

                case 'switch_view':
                  final isGrid = action['isGrid'] as bool? ?? true;
                  appState.setRecipeViewMode(isGrid);
                  appState.setActiveTab(AppState.tabDishes);
                  executedSummary.add(isGrid ? 'Switched to Grid View' : 'Switched to List View');
                  break;

                case 'change_theme':
                  final colorName = action['colorName'] as String? ?? 'Terracotta';
                  final color = _getColorByName(colorName);
                  if (color != null) {
                    appState.setAccentColor(color);
                    executedSummary.add('Switched accent theme to $colorName');
                  }
                  break;

                case 'navigate':
                  final tab = (action['tab'] as num? ?? 0).toInt();
                  appState.setActiveTab(tab.clamp(0, 5));
                  break;

                case 'culinary_advice':
                  final advice = action['advice'] as String? ?? '';
                  if (advice.isNotEmpty) {
                    final session = AiFollowUpSession(
                      id: 'advice_${DateTime.now().millisecondsSinceEpoch}',
                      title: 'Culinary Advice',
                      question: advice,
                      type: AiFollowUpType.generalOptions,
                      quickReplies: const [
                        'What can I cook with this?',
                        'Show recipe ideas',
                        'Add to shopping list',
                      ],
                    );
                    appState.startAiFollowUpSession(session);
                    return AiCommandResult(
                      executedAction: true,
                      feedbackMessage: feedback.isNotEmpty ? feedback : 'Culinary advice provided',
                    );
                  }
                  break;

                case 'filter_recipes':
                  final q = action['query'] as String? ?? '';
                  if (q.isNotEmpty) {
                    appState.setAiQuery(q);
                    appState.setActiveTab(AppState.tabDishes);
                    executedSummary.add('Found recipes for "$q"');
                  }
                  break;
              }
            }

            if (executedSummary.isNotEmpty) {
              return AiCommandResult(
                executedAction: true,
                feedbackMessage: feedback.isNotEmpty ? feedback : executedSummary.join(' · '),
              );
            }
          }
        }
      } catch (_) {}
    }

    // ------------------------------------------------------------------------
    // 3. RECIPE RECOMMENDATIONS / DISCOVERY (Natural questions about what to cook)
    // ------------------------------------------------------------------------
    if (_isRecipeQuery(lower)) {
      return _handleRecipeQuery(appState, prompt, lower);
    }

    // ------------------------------------------------------------------------
    // 4. FALLBACK: Intelligent Recipe Search vs Conversational Assistance
    // ------------------------------------------------------------------------
    // Check if the prompt looks like an ingredient or dish name search:
    final words = lower.split(RegExp(r'\s+'));
    final isConversationalWord = lower.contains('cook') ||
        lower.contains('wanna') ||
        lower.contains('want') ||
        lower.contains('make') ||
        lower.contains('eat') ||
        lower.contains('bake') ||
        lower.contains('hungry') ||
        lower.contains('cookie') ||
        lower.contains('help');

    final isShortSearch = words.length <= 4 &&
        !isConversationalWord &&
        !lower.contains('?') &&
        !lower.startsWith('how') &&
        !lower.startsWith('why') &&
        !lower.startsWith('what');

    if (isShortSearch) {
      appState.setAiQuery(prompt);
      appState.setActiveTab(AppState.tabAi);
      return AiCommandResult(
        executedAction: true,
        feedbackMessage: 'Filtered recipes matching "$prompt"',
      );
    }

    // For longer conversational requests without an exact match:
    final session = AiFollowUpSession(
      id: 'general_${DateTime.now().millisecondsSinceEpoch}',
      title: 'How can I help?',
      question: 'I understood: "$prompt". What would you like to do with this?',
      type: AiFollowUpType.generalOptions,
      actionCards: const [
        AiActionCardItem(
          id: 'opt_add_fridge',
          title: 'Add to Inventory',
          subtitle: 'Store in Fridge, Freezer or Pantry',
          icon: Icons.kitchen_rounded,
        ),
        AiActionCardItem(
          id: 'opt_add_shop',
          title: 'Add to Shopping List',
          subtitle: 'Keep on your Want List to buy later',
          icon: Icons.shopping_basket_rounded,
        ),
        AiActionCardItem(
          id: 'opt_search_recipe',
          title: 'Search Recipes',
          subtitle: 'Find dishes using these ingredients',
          icon: Icons.restaurant_menu_rounded,
        ),
      ],
      quickReplies: [
        'Add to inventory',
        'Add to shopping list',
        'Search recipes for $prompt',
      ],
    );
    appState.startAiFollowUpSession(session);

    return AiCommandResult(
      executedAction: true,
      feedbackMessage: 'Processing "$prompt"',
    );
  }

  // ==========================================================================
  // INTENT DETECTORS & EXTRACTION HELPERS
  // ==========================================================================

  static bool _isViewModeRequest(String lower) {
    return lower == 'grid' ||
        lower == 'grid view' ||
        lower == 'switch to grid' ||
        lower == 'switch to grid view' ||
        lower == 'show grid' ||
        lower == 'show as grid' ||
        lower == 'grid layout' ||
        lower == 'list' ||
        lower == 'list view' ||
        lower == 'switch to list' ||
        lower == 'switch to list view' ||
        lower == 'show list' ||
        lower == 'show as list' ||
        lower == 'list layout';
  }

  static bool _isRandomPickerRequest(String lower) {
    return lower == 'pick a recipe' ||
        lower == 'pick recipe' ||
        lower == 'pick for me' ||
        lower == 'random recipe' ||
        lower == 'random' ||
        lower == 'draw a card' ||
        lower == 'draw card' ||
        lower == 'spin recipe' ||
        lower == 'surprise me' ||
        lower == 'what to cook today' ||
        lower.contains('random recipe') ||
        lower.contains('pick a recipe') ||
        lower.contains('draw a card');
  }

  static bool _isClearInventory(String lower) {
    return lower == 'clear inventory' ||
        lower == 'clear fridge' ||
        lower == 'empty fridge' ||
        lower == 'empty inventory' ||
        lower == 'delete all items' ||
        lower == 'clear all items' ||
        lower == 'remove all items' ||
        lower == 'clear all' ||
        lower == 'delete all';
  }

  static bool _isResetInventory(String lower) {
    return lower == 'reset inventory' ||
        lower == 'restore inventory' ||
        lower == 'restore fridge' ||
        lower == 'reset fridge' ||
        lower == 'default inventory';
  }

  static bool _isClearFilterRequest(String lower) {
    return lower == 'clear' ||
        lower == 'clear search' ||
        lower == 'reset search' ||
        lower == 'clear query' ||
        lower == 'clear filter' ||
        lower == 'clear filters' ||
        lower == 'show all recipes';
  }

  static bool _isShoppingListRequest(String lower) {
    if (lower.contains('shopping list') || lower.contains('want list') || lower.contains('buy list')) {
      return true;
    }
    return lower.startsWith('buy ') ||
        lower.startsWith('need to buy ') ||
        lower.startsWith('add to shopping ') ||
        lower.startsWith('need ') && !lower.contains('cook');
  }

  static bool _isReminderRequest(String lower) {
    return lower.contains('remind') ||
        lower.contains('reminder') ||
        lower.contains('defrost') ||
        lower.contains('unfreeze') ||
        lower.contains('thaw');
  }

  static bool _isLogMealRequest(String lower) {
    return lower.startsWith('i cooked ') ||
        lower.startsWith('i made ') ||
        lower.startsWith('just cooked ') ||
        lower.startsWith('just made ') ||
        lower.startsWith('log meal') ||
        (lower.startsWith('log ') && lower.contains('meal'));
  }

  static bool _isRemoveInventoryRequest(String lower) {
    return lower.startsWith('remove ') ||
        lower.startsWith('delete ') ||
        lower.startsWith('out of ') ||
        lower.startsWith('used up ') ||
        lower.startsWith('finished ') ||
        lower.startsWith('threw away ') ||
        lower.startsWith('we finished ');
  }

  static bool _isAddInventoryRequest(String lower) {
    return lower == 'add' ||
        lower == 'add inventory' ||
        lower.startsWith('add ') ||
        lower.startsWith('add:') ||
        lower.startsWith('add -') ||
        lower.startsWith('add inventory') ||
        lower.contains('wanted to add') ||
        lower.contains('want to add') ||
        lower.contains('add a list') ||
        lower.contains('to inventory') ||
        lower.contains('in inventory') ||
        lower.contains('to fridge') ||
        lower.contains('in fridge') ||
        lower.contains('to freezer') ||
        lower.contains('in freezer') ||
        lower.contains('to pantry') ||
        lower.contains('in pantry') ||
        lower.contains('stock up') ||
        lower.contains('i bought') ||
        lower.contains('got groceries') ||
        lower.contains('bought groceries') ||
        lower.startsWith('bought ') ||
        lower.startsWith('got ') ||
        lower.startsWith('put ');
  }

  static bool _isSaveRecipeRequest(String lower) {
    return lower.startsWith('save recipe') ||
        lower.startsWith('save ') ||
        lower.contains('save this recipe') ||
        lower.contains('save the recipe') ||
        lower.contains('bookmark recipe') ||
        lower.contains('bookmark ') ||
        lower.contains('favorite recipe') ||
        lower.contains('star recipe') ||
        lower == 'save';
  }

  static bool _isRecipeQuery(String lower) {
    return lower.contains('what can i cook') ||
        lower.contains('what should i cook') ||
        lower.contains('what can i make') ||
        lower.contains('wanna cook') ||
        lower.contains('want to cook') ||
        lower.contains('wanna make') ||
        lower.contains('want to make') ||
        lower.contains('wanna bake') ||
        lower.contains('want to bake') ||
        lower.contains('recipe ideas') ||
        lower.contains('dinner ideas') ||
        lower.contains('meal ideas') ||
        lower.contains('suggest') ||
        lower.contains('recipes with') ||
        lower.contains('what to cook') ||
        lower.contains('what to eat') ||
        lower.contains('hungry') ||
        lower == 'cook';
  }

  // ==========================================================================
  // ACTION HANDLERS
  // ==========================================================================

  static AiCommandResult? _handleThemeCommand(AppState appState, String lower) {
    final isColorRequest = lower.contains('theme') ||
        lower.contains('color') ||
        lower.contains('accent') ||
        lower.contains('style') ||
        lower.contains('palette') ||
        lower == 'black and white' ||
        lower == 'black & white' ||
        lower == 'b&w' ||
        lower == 'monochrome' ||
        lower == 'matcha' ||
        lower == 'amber' ||
        lower == 'persimmon' ||
        lower == 'plum' ||
        lower == 'indigo' ||
        lower == 'terracotta';

    if (!isColorRequest) return null;

    Color? newColor;
    String colorName = '';

    if (lower.contains('black') ||
        lower.contains('white') ||
        lower.contains('b&w') ||
        lower.contains('mono') ||
        lower.contains('stone')) {
      newColor = const Color(0xFF1C1917);
      colorName = 'Black & White';
    } else if (lower.contains('matcha') || lower.contains('sage') || lower.contains('green')) {
      newColor = const Color(0xFF2D6A4F);
      colorName = 'Matcha Sage';
    } else if (lower.contains('amber') || lower.contains('yellow') || lower.contains('gold')) {
      newColor = const Color(0xFFD97706);
      colorName = 'Warm Amber';
    } else if (lower.contains('persimmon') || lower.contains('orange')) {
      newColor = const Color(0xFFC05621);
      colorName = 'Persimmon';
    } else if (lower.contains('plum') || lower.contains('berry') || lower.contains('purple')) {
      newColor = const Color(0xFF7C3AED);
      colorName = 'Berry Plum';
    } else if (lower.contains('indigo') || lower.contains('blue')) {
      newColor = const Color(0xFF1E3A8A);
      colorName = 'Korean Indigo';
    } else if (lower.contains('terracotta') || lower.contains('warm')) {
      newColor = AppTheme.defaultAccent;
      colorName = 'Terracotta';
    }

    if (newColor != null) {
      appState.setAccentColor(newColor);
      final session = AiFollowUpSession(
        id: 'theme_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Accent Theme: $colorName',
        question: 'Switched app accent to $colorName! Tap any card to test another mood:',
        type: AiFollowUpType.accentColor,
        quickReplies: const [
          'Matcha Sage',
          'Warm Amber',
          'Persimmon',
          'Berry Plum',
          'Korean Indigo',
          'Terracotta',
          'Black & White',
        ],
      );
      appState.startAiFollowUpSession(session);
      return AiCommandResult(
        executedAction: true,
        feedbackMessage: 'Switched app theme to $colorName',
      );
    } else {
      final session = AiFollowUpSession(
        id: 'theme_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Choose Accent Theme',
        question: 'Which accent color fits your kitchen mood today? Tap a preview card to apply:',
        type: AiFollowUpType.accentColor,
        quickReplies: const [
          'Matcha Sage',
          'Warm Amber',
          'Persimmon',
          'Berry Plum',
          'Korean Indigo',
          'Terracotta',
          'Black & White',
        ],
      );
      appState.startAiFollowUpSession(session);
      return const AiCommandResult(
        executedAction: true,
        feedbackMessage: 'Opened Accent Theme selector',
      );
    }
  }

  static AiCommandResult? _handleNavigation(
    BuildContext context,
    AppState appState,
    String lower,
  ) {
    if (lower == 'fridge' ||
        lower.contains('open fridge') ||
        lower.contains('show fridge') ||
        lower.contains('go to fridge') ||
        lower == 'inventory') {
      appState.setActiveTab(AppState.tabFridge);
      return const AiCommandResult(
        executedAction: true,
        feedbackMessage: 'Switched to Kitchen Inventory (Fridge)',
      );
    } else if (lower == 'calendar' ||
        lower == 'journal' ||
        lower.contains('show calendar') ||
        lower.contains('show journal') ||
        lower.contains('cooking journal')) {
      appState.setActiveTab(AppState.tabJournal);
      return const AiCommandResult(
        executedAction: true,
        feedbackMessage: 'Switched to Cooking Calendar & Journal',
      );
    } else if (lower == 'saved' ||
        lower.contains('favorites') ||
        lower.contains('show saved') ||
        lower.contains('library') ||
        lower.contains('bookmarks') ||
        lower.contains('wishlist')) {
      appState.setActiveTab(AppState.tabSaved);
      return const AiCommandResult(
        executedAction: true,
        feedbackMessage: 'Switched to Saved Library tab',
      );
    } else if (lower == 'profile' ||
        lower.contains('settings') ||
        lower.contains('go to profile')) {
      appState.setActiveTab(AppState.tabProfile);
      return const AiCommandResult(
        executedAction: true,
        feedbackMessage: 'Switched to Profile & Settings tab',
      );
    } else if (lower == 'explore' ||
        lower.contains('discovery') ||
        lower.contains('dating') ||
        lower.contains('swipe')) {
      appState.setActiveTab(AppState.tabExplore);
      return const AiCommandResult(
        executedAction: true,
        feedbackMessage: 'Switched to Explore Discovery flow',
      );
    } else if (lower == 'dishes' ||
        lower == 'home' ||
        lower.contains('show dishes') ||
        lower.contains('all recipes') ||
        lower.contains('studio')) {
      appState.setActiveTab(AppState.tabDishes);
      return const AiCommandResult(
        executedAction: true,
        feedbackMessage: 'Switched to Dishes Studio feed',
      );
    } else if (lower.contains('open shopping list') ||
        lower.contains('show shopping list') ||
        lower == 'shopping list' ||
        lower == 'want list') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ShoppingScreen()),
      );
      return const AiCommandResult(
        executedAction: true,
        feedbackMessage: 'Opened Shopping List',
      );
    }
    return null;
  }

  static AiCommandResult? _handleDietaryRestrictions(
    AppState appState,
    String lower,
  ) {
    if (lower.contains('vegetarian')) {
      appState.toggleDietaryRestriction('Vegetarian');
      return const AiCommandResult(
        executedAction: true,
        feedbackMessage: 'Toggled Vegetarian preference',
      );
    } else if (lower.contains('vegan')) {
      appState.toggleDietaryRestriction('Vegan');
      return const AiCommandResult(
        executedAction: true,
        feedbackMessage: 'Toggled Vegan preference',
      );
    } else if (lower.contains('gluten')) {
      appState.toggleDietaryRestriction('Gluten-free');
      return const AiCommandResult(
        executedAction: true,
        feedbackMessage: 'Toggled Gluten-free preference',
      );
    }
    return null;
  }

  static AiCommandResult _handleShoppingList(
    AppState appState,
    String prompt,
    String lower,
  ) {
    // Check for remove from shopping list
    if (lower.startsWith('remove') || lower.startsWith('delete')) {
      String clean = prompt.replaceAll(
        RegExp(r'\b(remove|delete|from shopping list|from want list|from my list|the)\b', caseSensitive: false),
        '',
      ).trim();
      if (clean.isNotEmpty) {
        appState.removeFromWantList(_capitalize(clean));
        return AiCommandResult(
          executedAction: true,
          feedbackMessage: 'Removed "$clean" from your Shopping List',
        );
      }
    }

    // Extract item(s) to add
    String cleanStr = prompt.replaceAll(
      RegExp(
        r'\b(add to shopping list|add to want list|add to buy list|need to buy|i need to buy|need|buy|put on shopping list|put on want list|on my shopping list|to shopping list|to my want list|some|a|an)\b',
        caseSensitive: false,
      ),
      '',
    ).replaceAll(RegExp(r'[:;]'), '').trim();

    final rawItems = cleanStr.split(RegExp(r',|\band\b|&|\n', caseSensitive: false));
    final addedList = <String>[];

    for (final raw in rawItems) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      final itemName = _capitalizeWords(trimmed);
      appState.addToWantList(itemName);
      addedList.add(itemName);
    }

    if (addedList.isNotEmpty) {
      return AiCommandResult(
        executedAction: true,
        feedbackMessage: 'Added to Shopping List: ${addedList.join(", ")}',
      );
    }

    return const AiCommandResult(
      executedAction: false,
      feedbackMessage: 'Could not identify items to add to shopping list.',
    );
  }

  static AiCommandResult _handleReminder(
    AppState appState,
    String prompt,
    String lower,
  ) {
    String reminderTitle = prompt.trim();
    String reminderType = 'prep';

    if (lower.contains('unfreeze') || lower.contains('defrost') || lower.contains('thaw')) {
      reminderType = 'defrost';
      reminderTitle = reminderTitle
          .replaceAll(RegExp(r'\b(remind me to|remind me|please|set reminder to|set reminder)\b', caseSensitive: false), '')
          .trim();
      if (!reminderTitle.toLowerCase().startsWith('unfreeze') &&
          !reminderTitle.toLowerCase().startsWith('defrost') &&
          !reminderTitle.toLowerCase().startsWith('thaw')) {
        reminderTitle = 'Defrost $reminderTitle';
      }
      reminderTitle = _capitalize(reminderTitle);
    } else if (lower.contains('buy') || lower.contains('get') || lower.contains('ingredient')) {
      reminderType = 'ingredient';
      reminderTitle = reminderTitle
          .replaceAll(RegExp(r'\b(remind me to|remind me|please|set reminder to|set reminder)\b', caseSensitive: false), '')
          .trim();
      reminderTitle = _capitalize(reminderTitle);
    } else {
      reminderTitle = reminderTitle
          .replaceAll(RegExp(r'\b(remind me to|remind me|please|set reminder to|set reminder)\b', caseSensitive: false), '')
          .trim();
      reminderTitle = _capitalize(reminderTitle);
    }

    DateTime scheduledDate = DateTime.now().add(const Duration(hours: 3));
    if (lower.contains('tomorrow')) {
      scheduledDate = DateTime.now().add(const Duration(days: 1));
    } else if (lower.contains('tonight') || lower.contains('this evening')) {
      scheduledDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 18);
    } else if (lower.contains('next week')) {
      scheduledDate = DateTime.now().add(const Duration(days: 7));
    }

    final reminder = CookingReminder(
      id: 'ai_rem_${DateTime.now().millisecondsSinceEpoch}',
      title: reminderTitle,
      scheduledDate: scheduledDate,
      reminderType: reminderType,
      isCompleted: false,
    );
    appState.addCookingReminder(reminder);

    return AiCommandResult(
      executedAction: true,
      feedbackMessage: 'Created reminder: $reminderTitle',
    );
  }

  static AiCommandResult _handleLogMeal(
    AppState appState,
    String prompt,
    String lower,
  ) {
    String dishName = prompt
        .replaceAll(RegExp(r'\b(i cooked|i made|just cooked|just made|log meal|log)\b', caseSensitive: false), '')
        .trim();
    if (dishName.isNotEmpty) {
      dishName = _capitalize(dishName);
      final record = CookingRecord(
        id: 'ai_cr_${DateTime.now().millisecondsSinceEpoch}',
        recipeTitle: dishName,
        koreanTitle: '',
        date: DateTime.now(),
        photoUrl: '',
        rating: 5,
        notes: 'Logged via AI assistant',
        tags: const ['AI Logged'],
      );
      appState.addCookingRecord(record);
      appState.setActiveTab(2);

      return AiCommandResult(
        executedAction: true,
        feedbackMessage: 'Logged "$dishName" to your Cooking Journal',
      );
    }
    return const AiCommandResult(
      executedAction: false,
      feedbackMessage: 'Please specify the dish you cooked.',
    );
  }

  static AiCommandResult? _handleRemoveInventory(
    AppState appState,
    String prompt,
    String lower,
  ) {
    String itemName = prompt.replaceAll(
      RegExp(r'\b(remove|delete|out of|used up|finished|threw away|we finished|the|my|some)\b', caseSensitive: false),
      '',
    ).trim();

    if (itemName.isNotEmpty) {
      final match = appState.fridgeItems.firstWhere(
        (f) => f.name.toLowerCase().contains(itemName.toLowerCase()),
        orElse: () => FridgeItem(
          id: '',
          name: '',
          location: StorageLocation.fridge,
          quantityMode: QuantityMode.approximate,
        ),
      );

      if (match.id.isNotEmpty) {
        appState.removeFridgeItem(match.id);
        appState.setActiveTab(AppState.tabFridge);
        return AiCommandResult(
          executedAction: true,
          feedbackMessage: 'Removed "${match.name}" from inventory',
        );
      }
    }
    return null;
  }

  /// Handles natural language inventory additions (lists, single items, quantities, and auto-categorization)
  static AiCommandResult _handleAddInventory(
    AppState appState,
    String prompt,
    String lower,
  ) {
    final explicitFreezer = lower.contains('to freezer') || lower.contains('in freezer');
    final explicitPantry = lower.contains('to pantry') || lower.contains('in pantry');
    final explicitFridge = lower.contains('to fridge') || lower.contains('in fridge');
    final hasMultipleLocations = [explicitFreezer, explicitPantry, explicitFridge].where((b) => b).length > 1;

    // Clean conversational preamble (e.g. "i wanted to add a list of stuff: tofu, eggs, milk")
    String cleanStr = prompt.replaceAll(
      RegExp(
        r'^(please\s+)?(i\s+)?((wanted|want|would like|need|could you|can you)\s+to\s+add|add|bought|got|put|stock up on)?\s*(a\s+list\s+of\s+stuff|a\s+list\s+of|the\s+following\s+items|the\s+following|some\s+groceries|groceries|some)?\s*(to\s+my\s+inventory|to\s+inventory|in\s+inventory)?\s*[:;,-]?\s*',
        caseSensitive: false,
      ),
      '',
    );

    // If single location specified at the end of the sentence, clean it from cleanStr
    if (!hasMultipleLocations) {
      cleanStr = cleanStr.replaceAll(
        RegExp(r'\b(to fridge|to freezer|to pantry|in fridge|in freezer|in pantry|into fridge|into freezer|into pantry|into my fridge|into my freezer|into my pantry|in my fridge|in my freezer|in my pantry)\b', caseSensitive: false),
        '',
      ).replaceAll(RegExp(r'[:;]'), '').trim();
    }

    if (cleanStr.isEmpty || cleanStr.toLowerCase() == 'add' || cleanStr.toLowerCase() == 'inventory') {
      appState.setActiveTab(AppState.tabFridge);
      return const AiCommandResult(
        executedAction: true,
        feedbackMessage: 'Switched to Kitchen Inventory. Type items or tap + Add to log groceries.',
      );
    }

    // Split by commas, newlines, bullets, and conjunctions ("and", "&")
    final rawItems = cleanStr.split(RegExp(r',|\band\b|&|\n|\r|•|\*', caseSensitive: false));
    final addedDetails = <String>[];

    for (final raw in rawItems) {
      String itemText = raw.trim();
      if (itemText.isEmpty) continue;

      // Check for inline location cues per item (e.g. "ice cream to freezer", "eggs to fridge")
      StorageLocation location;
      final lowerItem = itemText.toLowerCase();
      if (lowerItem.contains('freezer')) {
        location = StorageLocation.freezer;
        itemText = itemText.replaceAll(RegExp(r'\b(to freezer|in freezer|into freezer|freezer)\b', caseSensitive: false), '').trim();
      } else if (lowerItem.contains('seasoning') || lowerItem.contains('spice')) {
        location = StorageLocation.seasoning;
        itemText = itemText.replaceAll(RegExp(r'\b(to seasonings?|in seasonings?|into seasonings?|seasonings?|to spices?|in spices?|into spices?|spices?)\b', caseSensitive: false), '').trim();
      } else if (lowerItem.contains('pantry')) {
        location = StorageLocation.pantry;
        itemText = itemText.replaceAll(RegExp(r'\b(to pantry|in pantry|into pantry|pantry)\b', caseSensitive: false), '').trim();
      } else if (lowerItem.contains('fridge')) {
        location = StorageLocation.fridge;
        itemText = itemText.replaceAll(RegExp(r'\b(to fridge|in fridge|into fridge|fridge)\b', caseSensitive: false), '').trim();
      } else if (!hasMultipleLocations && explicitFreezer) {
        location = StorageLocation.freezer;
      } else if (!hasMultipleLocations && explicitPantry) {
        location = StorageLocation.pantry;
      } else if (!hasMultipleLocations && explicitFridge) {
        location = StorageLocation.fridge;
      } else {
        location = IngredientIntelligence.autoDetectLocation(itemText);
      }

      // Parse quantity details if present (e.g. "2 packs of tofu", "1 dozen eggs", "500g beef")
      String quantityDisplay = 'Plenty';
      QuantityMode quantityMode = QuantityMode.approximate;

      final qtyMatch = RegExp(
        r'^(\d+(\.\d+)?\s*(kg|g|lbs|lb|oz|ml|l|packs?|packets?|bottles?|cartons?|blocks?|cans?|dozens?|bunches?|pieces?|pcs)?|\b(a|an|one|two|three|four|five|six|some|plenty|half|few|a\s+bottle\s+of|a\s+pack\s+of|a\s+carton\s+of|a\s+block\s+of|a\s+can\s+of|a\s+bunch\s+of)\b)\s*',
        caseSensitive: false,
      ).firstMatch(itemText);

      if (qtyMatch != null && qtyMatch.group(0) != null) {
        final rawQty = qtyMatch.group(0)!.trim();
        itemText = itemText.substring(qtyMatch.group(0)!.length).replaceAll(RegExp(r'^of\s+', caseSensitive: false), '').trim();
        if (rawQty.isNotEmpty) {
          quantityDisplay = _capitalize(rawQty);
          quantityMode = QuantityMode.exact;
        }
      }

      if (itemText.isEmpty) continue;
      final itemName = _capitalizeWords(itemText);

      final newItem = FridgeItem(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}_${addedDetails.length}',
        name: itemName,
        location: location,
        quantityMode: quantityMode,
        quantityDisplay: quantityDisplay,
        status: 'Have',
      );

      appState.addFridgeItem(newItem);

      final locName = location == StorageLocation.freezer
          ? 'Freezer'
          : (location == StorageLocation.pantry
              ? 'Pantry'
              : (location == StorageLocation.seasoning ? 'Seasoning' : 'Fridge'));
      addedDetails.add('$itemName ($locName)');
    }

    if (addedDetails.isNotEmpty) {
      appState.setActiveTab(AppState.tabFridge); // Switch to Fridge / Inventory tab
      return AiCommandResult(
        executedAction: true,
        feedbackMessage: 'Added ${addedDetails.length} items to inventory: ${addedDetails.join(", ")}',
      );
    }

    return const AiCommandResult(
      executedAction: false,
      feedbackMessage: 'Could not parse ingredients to add. Please try again.',
    );
  }

  static AiCommandResult _handleRecipeQuery(
    AppState appState,
    String prompt,
    String lower,
  ) {
    final allRecipes = appState.recipes;
    List matching = allRecipes;

    if (lower.contains('quick') || lower.contains('fast') || lower.contains('15')) {
      matching = allRecipes.where((r) => r.cookingTimeMinutes <= 20).toList();
    } else if (lower.contains('vegetarian') || lower.contains('vegan')) {
      matching = allRecipes
          .where((r) =>
              r.title.toLowerCase().contains('tofu') ||
              r.title.toLowerCase().contains('pancake') ||
              (!r.title.toLowerCase().contains('pork') && !r.title.toLowerCase().contains('beef')))
          .toList();
    } else if (lower.contains('air fryer') || lower.contains('airfryer')) {
      matching = allRecipes.where((r) => r.cookingMethod == 'Air Fryer').toList();
    }

    if (matching.isEmpty) matching = allRecipes;

    final actionCards = matching.take(4).map((r) {
      return AiActionCardItem(
        id: r.id,
        title: r.title,
        subtitle: '${r.cookingTimeMinutes} min · ${r.kitchenMatchPercent}% match',
        recipe: r,
      );
    }).toList();

    final session = AiFollowUpSession(
      id: 'recipes_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Recipe Recommendations',
      question: 'Found ${actionCards.length} recipes tailored to your pantry! Which sounds appetizing?',
      type: AiFollowUpType.recipeRecommendation,
      actionCards: actionCards,
      quickReplies: const [
        'Quick (<20 min)',
        'Vegetarian',
        'Air Fryer',
        'Show All Recipes',
      ],
    );
    appState.startAiFollowUpSession(session);

    return AiCommandResult(
      executedAction: true,
      feedbackMessage: 'Recommended ${actionCards.length} recipes',
    );
  }

  static Color? _getColorByName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('matcha') || lower.contains('green')) return const Color(0xFF2D6A4F);
    if (lower.contains('amber') || lower.contains('yellow')) return const Color(0xFFD97706);
    if (lower.contains('persimmon') || lower.contains('orange')) return const Color(0xFFC05621);
    if (lower.contains('plum') || lower.contains('berry') || lower.contains('purple')) return const Color(0xFF7C3AED);
    if (lower.contains('indigo') || lower.contains('blue')) return const Color(0xFF1E3A8A);
    if (lower.contains('terracotta')) return AppTheme.defaultAccent;
    if (lower.contains('black') || lower.contains('white') || lower.contains('b&w')) return const Color(0xFF1C1917);
    return null;
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  static String _capitalizeWords(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) => _capitalize(w)).join(' ');
  }

  static AiCommandResult _handleSaveRecipe(
    AppState appState,
    String prompt,
    String lower,
  ) {
    String target = prompt.replaceAll(
      RegExp(
        r'^(please\s+)?(save\s+recipe|save\s+this\s+recipe|save\s+the\s+recipe|save|bookmark\s+recipe|bookmark|favorite\s+recipe|favorite|star)\s*',
        caseSensitive: false,
      ),
      '',
    ).trim();

    Recipe? matchedRecipe;
    if (target.isNotEmpty) {
      final lowerTarget = target.toLowerCase();
      for (final r in appState.recipes) {
        if (r.title.toLowerCase().contains(lowerTarget) ||
            r.koreanTitle.toLowerCase().contains(lowerTarget)) {
          matchedRecipe = r;
          break;
        }
      }
    }

    if (matchedRecipe == null && appState.recipes.isNotEmpty) {
      try {
        matchedRecipe = appState.recipes.firstWhere((r) => !r.isSaved);
      } catch (_) {
        matchedRecipe = appState.recipes.first;
      }
    }

    if (matchedRecipe != null) {
      if (!matchedRecipe.isSaved) {
        appState.toggleSaveRecipe(matchedRecipe.id);
      }
      appState.setActiveTab(AppState.tabSaved);
      return AiCommandResult(
        executedAction: true,
        feedbackMessage: "Saved '${matchedRecipe.title}' to your recipes",
      );
    }

    return const AiCommandResult(
      executedAction: false,
      feedbackMessage: 'No recipe found to save.',
    );
  }

  /// Classifies a typed prompt into an actionable preview for the notification bar
  static ActionPreview classifyAction(String query, AppState appState) {
    final clean = query.trim();
    if (clean.isEmpty) {
      return const ActionPreview(
        type: ActionPreviewType.openChat,
        title: 'Open chat',
        detail: '',
        icon: Icons.chat_bubble_outline_rounded,
      );
    }

    final lower = clean.toLowerCase();

    // 1. Save Recipe
    if (_isSaveRecipeRequest(lower)) {
      String recipeName = clean.replaceAll(
        RegExp(
          r'^(please\s+)?(save\s+recipe|save\s+this\s+recipe|save\s+the\s+recipe|save|bookmark\s+recipe|bookmark|favorite\s+recipe|favorite|star)\s*',
          caseSensitive: false,
        ),
        '',
      ).trim();

      if (recipeName.isEmpty) {
        Recipe? top;
        try {
          top = appState.recipes.firstWhere((r) => !r.isSaved);
        } catch (_) {
          if (appState.recipes.isNotEmpty) top = appState.recipes.first;
        }
        recipeName = top?.title ?? 'Recipe';
      } else {
        Recipe? match;
        for (final r in appState.recipes) {
          if (r.title.toLowerCase().contains(recipeName.toLowerCase()) ||
              r.koreanTitle.toLowerCase().contains(recipeName.toLowerCase())) {
            match = r;
            break;
          }
        }
        if (match != null) recipeName = match.title;
      }

      return ActionPreview(
        type: ActionPreviewType.saveRecipe,
        title: 'Save recipe',
        detail: recipeName,
        icon: Icons.bookmark_add_rounded,
      );
    }

    // 2. Add Inventory
    if (_isAddInventoryRequest(lower)) {
      String itemsStr = clean.replaceAll(
        RegExp(
          r'^(please\s+)?(i\s+)?((wanted|want|would like|need|could you|can you)\s+to\s+add|add|bought|got|put|stock up on)?\s*(a\s+list\s+of\s+stuff|a\s+list\s+of|the\s+following\s+items|the\s+following|some\s+groceries|groceries|some)?\s*(to\s+my\s+inventory|to\s+inventory|in\s+inventory)?\s*[:;,-]?\s*',
          caseSensitive: false,
        ),
        '',
      ).replaceAll(
        RegExp(
          r'\b(to fridge|to freezer|to pantry|in fridge|in freezer|in pantry|into fridge|into freezer|into pantry)\b',
          caseSensitive: false,
        ),
        '',
      ).trim();

      if (itemsStr.isEmpty || itemsStr.trim().toLowerCase() == 'add' || itemsStr.trim().toLowerCase() == 'inventory') {
        itemsStr = 'Open inventory logger';
      }

      return ActionPreview(
        type: ActionPreviewType.addInventory,
        title: 'Add inventory',
        detail: itemsStr,
        icon: Icons.kitchen_rounded,
      );
    }

    // 3. Shopping / Want list
    if (_isShoppingListRequest(lower)) {
      String items = clean.replaceAll(
        RegExp(
          r'^(please\s+)?(add\s+to\s+shopping\s+list|add\s+to\s+shopping|add\s+to\s+want\s+list|buy|need\s+to\s+buy)\s*[:;,-]?\s*',
          caseSensitive: false,
        ),
        '',
      ).replaceAll(
        RegExp(r'\b(to shopping list|to want list|to grocery list)\b', caseSensitive: false),
        '',
      ).trim();
      return ActionPreview(
        type: ActionPreviewType.addShopping,
        title: 'Add to shopping',
        detail: items.isNotEmpty ? items : clean,
        icon: Icons.shopping_bag_outlined,
      );
    }

    // 4. Reminders
    if (_isReminderRequest(lower)) {
      return ActionPreview(
        type: ActionPreviewType.setReminder,
        title: 'Set reminder',
        detail: clean,
        icon: Icons.alarm_rounded,
      );
    }

    // 5. Log Meal
    if (_isLogMealRequest(lower)) {
      return ActionPreview(
        type: ActionPreviewType.logMeal,
        title: 'Log meal',
        detail: clean,
        icon: Icons.restaurant_menu_rounded,
      );
    }

    // 6. View mode / quick commands
    if (_isViewModeRequest(lower)) {
      final toGrid = lower.contains('grid');
      return ActionPreview(
        type: ActionPreviewType.viewMode,
        title: toGrid ? 'Grid view' : 'List view',
        detail: toGrid ? 'Switch to Grid cards' : 'Switch to List view',
        icon: toGrid ? Icons.grid_view_rounded : Icons.view_agenda_rounded,
      );
    }

    if (_isClearInventory(lower)) {
      return const ActionPreview(
        type: ActionPreviewType.quickCommand,
        title: 'Clear inventory',
        detail: 'Remove all items',
        icon: Icons.delete_sweep_rounded,
      );
    }

    if (_isResetInventory(lower)) {
      return const ActionPreview(
        type: ActionPreviewType.quickCommand,
        title: 'Reset inventory',
        detail: 'Restore default ingredients',
        icon: Icons.restart_alt_rounded,
      );
    }

    if (_isRandomPickerRequest(lower)) {
      return const ActionPreview(
        type: ActionPreviewType.quickCommand,
        title: 'Random recipe',
        detail: 'Draw mystery recipe',
        icon: Icons.shuffle_rounded,
      );
    }

    // 7. Default: Open AI Chat
    return ActionPreview(
      type: ActionPreviewType.openChat,
      title: 'Open chat',
      detail: '"$clean"',
      icon: Icons.chat_bubble_outline_rounded,
    );
  }
}
