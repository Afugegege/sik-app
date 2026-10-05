import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/recipe.dart';
import '../models/fridge_item.dart';
import '../models/mock_data.dart';
import '../models/ai_follow_up_session.dart';
import '../models/ai_chat_message.dart';
import '../models/inventory_batch_action.dart';
import '../models/cooking_record.dart';
import '../models/cooking_reminder.dart';
import '../services/storage_service.dart';
import '../services/pantry_recipe_synthesizer.dart';
import '../theme/app_theme.dart';

class AppState extends ChangeNotifier {
  static const int tabDishes = 0;
  static const int tabExplore = 1;
  static const int tabFridge = 2;
  static const int tabJournal = 3;
  static const int tabSaved = 4;
  static const int tabProfile = 5;

  int _activeTabIndex = 0;
  String _currentAiQuery = '';
  bool _isAiPromptExpanded = false;
  String _selectedFilter = 'All';
  String _selectedCookingMethod = 'All';

  // Recipe View Mode (Grid vs List)
  bool _isRecipeGridView = false;

  // Explore Screen Filter Collapse State (collapsed by default)
  bool _isFilterExpanded = false;

  // Recipe Sort Option ('match' | 'time' | 'fewest_ingredients' | 'alphabetical')
  String _selectedSortOption = 'match';

  // Floating Random Recipe Picker visibility (can be closed and reopened)
  bool _isRandomPickerVisible = true;

  // Inventory Quantity Tracking Toggle (User preference: ON or OFF)
  // When OFF, quantities are hidden from UI to reduce friction, but retained safely in background.
  bool _trackQuantities = true;
  bool get trackQuantities => _trackQuantities;

  void setTrackQuantities(bool value) {
    if (_trackQuantities == value) return;
    _trackQuantities = value;
    StorageService.saveTrackQuantities(value);
    notifyListeners();
  }

  void toggleTrackQuantities() {
    setTrackQuantities(!_trackQuantities);
  }

  // AI Interactive Follow-up Session State
  AiFollowUpSession? _aiFollowUpSession;

  // Culinary Engine Thinking State (deliberate real analysis)
  bool _isThinkingPantry = false;
  bool get isThinkingPantry => _isThinkingPantry;

  // Dynamic Accent Color State
  Color _accentColor = AppTheme.defaultAccent;

  // Profile Settings State
  String _userRegion = MockData.defaultRegion;
  List<String> _preferredCuisines = List.from(MockData.defaultCuisines);
  List<String> _dietaryRestrictions = List.from(MockData.defaultDietaryRestrictions);
  List<String> _kitchenAppliances = List.from(MockData.defaultAppliances);

  final List<String> _wantList = [
    'Green Onion',
    'Gochujang Paste',
  ];

  final List<Recipe> _cookedHistory = [];

  // Cooking Calendar & Meal Journal State
  final List<CookingRecord> _cookingRecords = [
    CookingRecord(
      id: 'cr_seed_1',
      recipeTitle: 'Kimchi Fried Rice with Soft Egg',
      koreanTitle: '김치볶음밥',
      date: DateTime.now(),
      photoUrl: '',
      rating: 5,
      notes: 'Cooked with aged kimchi from fridge. Delicious crispy crust at the bottom!',
      tags: const ['Quick', 'Lunch', 'Korean'],
    ),
  ];

  // Future Cooking Reminders (Defrost, Ingredients, Prep)
  final List<CookingReminder> _cookingReminders = [
    CookingReminder(
      id: 'rem_seed_1',
      title: 'Unfreeze beef brisket in fridge',
      scheduledDate: DateTime.now().add(const Duration(hours: 3)),
      reminderType: 'defrost',
      isCompleted: false,
    ),
    CookingReminder(
      id: 'rem_seed_2',
      title: 'Buy fresh tofu & eggs for dinner',
      scheduledDate: DateTime.now().add(const Duration(days: 1)),
      reminderType: 'ingredient',
      isCompleted: false,
    ),
    CookingReminder(
      id: 'rem_seed_3',
      title: 'Marinate pork belly 2 hrs before cooking',
      scheduledDate: DateTime.now().add(const Duration(days: 2)),
      reminderType: 'prep',
      isCompleted: false,
    ),
  ];

  // Dynamic User & Inventory Recipes
  final List<Recipe> _recipes = [];
  final List<FridgeItem> _fridgeItems = List.from(MockData.seedFridgeItems);

  // AI Chat Conversation History
  final List<AiChatMessage> _chatMessages = [
    AiChatMessage(
      id: 'welcome_1',
      text: '안녕하세요! What are we cooking or prepping today?\n\nAsk for recipe ideas with your fridge items, cookie & baking ratios, Korean sauce substitutions, or batch-log your grocery haul.',
      isUser: false,
      timestamp: DateTime.now(),
      quickReplies: const [
        'What can I cook with my fridge?',
        'Cookie & baking guide',
        'Batch add groceries to fridge',
        'Korean sauce guide',
      ],
    ),
  ];

  String _apiKey = AppConfig.resolveApiKey(null);

  AppState() {
    if (_fridgeItems.isNotEmpty) {
      _syncSynthesizedRecipes();
      _autoCheckAndSurfaceUnlockedRecipes();
    }
    _loadStateFromStorage();
  }

  Future<void> _loadStateFromStorage() async {
    final savedColorValue = await StorageService.loadAccentColor();
    if (savedColorValue != null) _accentColor = Color(savedColorValue);

    final savedRegion = await StorageService.loadUserRegion();
    if (savedRegion != null) _userRegion = savedRegion;

    final savedCuisines = await StorageService.loadUserCuisines();
    if (savedCuisines != null) _preferredCuisines = savedCuisines;

    final savedDietary = await StorageService.loadDietaryRestrictions();
    if (savedDietary != null) _dietaryRestrictions = savedDietary;

    final savedAppliances = await StorageService.loadAppliances();
    if (savedAppliances != null) _kitchenAppliances = savedAppliances;

    final savedApiKey = await StorageService.loadApiKey();
    _apiKey = AppConfig.resolveApiKey(savedApiKey);

    final savedWant = await StorageService.loadWantList();
    if (savedWant != null) {
      _wantList.clear();
      _wantList.addAll(savedWant);
    }

    // Load saved cooking records
    final savedRecordsJson = await StorageService.loadCookingRecords();
    if (savedRecordsJson != null && savedRecordsJson.isNotEmpty) {
      try {
        final list = jsonDecode(savedRecordsJson) as List<dynamic>;
        _cookingRecords.clear();
        _cookingRecords.addAll(list.map((e) => CookingRecord.fromJson(e as Map<String, dynamic>)));
      } catch (_) {}
    }

    // Load saved cooking reminders
    final savedRemindersJson = await StorageService.loadCookingReminders();
    if (savedRemindersJson != null && savedRemindersJson.isNotEmpty) {
      try {
        final list = jsonDecode(savedRemindersJson) as List<dynamic>;
        _cookingReminders.clear();
        _cookingReminders.addAll(list.map((e) => CookingReminder.fromJson(e as Map<String, dynamic>)));
      } catch (_) {}
    }

    // Load saved recipe view mode (grid vs list)
    final savedViewMode = await StorageService.loadRecipeViewMode();
    if (savedViewMode != null) {
      _isRecipeGridView = savedViewMode;
    }

    final savedTrackQuantities = await StorageService.loadTrackQuantities();
    if (savedTrackQuantities != null) {
      _trackQuantities = savedTrackQuantities;
    }

    // Load saved kitchen inventory memory
    final savedFridge = await StorageService.loadFridgeItems();
    if (savedFridge != null) {
      _fridgeItems.clear();
      _fridgeItems.addAll(savedFridge);
    }
    _recipes.clear();
    // Synthesize dishes tailored to loaded inventory
    if (_fridgeItems.isNotEmpty) {
      _syncSynthesizedRecipes();
      _autoCheckAndSurfaceUnlockedRecipes();
    }

    notifyListeners();
  }

  void _saveFridgeItemsToStorage() {
    StorageService.saveFridgeItems(_fridgeItems);
  }

  String get apiKey => _apiKey;

  void setApiKey(String key) {
    _apiKey = key;
    StorageService.saveApiKey(key);
    notifyListeners();
  }

  int get activeTabIndex => _activeTabIndex;
  String get currentAiQuery => _currentAiQuery;
  bool get isAiPromptExpanded => _isAiPromptExpanded;
  String get selectedFilter => _selectedFilter;
  String get selectedCookingMethod => _selectedCookingMethod;
  bool get isRecipeGridView => _isRecipeGridView;
  bool get isFilterExpanded => _isFilterExpanded;
  bool get isRandomPickerVisible => _isRandomPickerVisible;

  void toggleFilterExpanded() {
    _isFilterExpanded = !_isFilterExpanded;
    notifyListeners();
  }

  void setFilterExpanded(bool expanded) {
    if (_isFilterExpanded == expanded) return;
    _isFilterExpanded = expanded;
    notifyListeners();
  }

  void toggleRandomPickerVisible() {
    _isRandomPickerVisible = !_isRandomPickerVisible;
    notifyListeners();
  }

  void setRandomPickerVisible(bool visible) {
    if (_isRandomPickerVisible == visible) return;
    _isRandomPickerVisible = visible;
    notifyListeners();
  }

  void toggleRecipeViewMode() {
    _isRecipeGridView = !_isRecipeGridView;
    StorageService.saveRecipeViewMode(_isRecipeGridView);
    notifyListeners();
  }

  void setRecipeViewMode(bool isGrid) {
    if (_isRecipeGridView == isGrid) return;
    _isRecipeGridView = isGrid;
    StorageService.saveRecipeViewMode(isGrid);
    notifyListeners();
  }

  int get matchingRecipeCount {
    if (_fridgeItems.isEmpty) return 0;
    return recipes.where((r) => r.kitchenMatchPercent >= 75).length;
  }

  int get almostMatchingRecipeCount {
    if (_fridgeItems.isEmpty) return 0;
    return recipes.where((r) => r.kitchenMatchPercent >= 50 && r.kitchenMatchPercent < 75).length;
  }

  Color get accentColor => _accentColor;
  String get userRegion => _userRegion;
  List<String> get preferredCuisines => List.unmodifiable(_preferredCuisines);
  List<String> get dietaryRestrictions => List.unmodifiable(_dietaryRestrictions);
  List<String> get kitchenAppliances => List.unmodifiable(_kitchenAppliances);

  // Dynamic Theme Colors derived from selected accent color
  Color get bgPrimary => AppTheme.getPrimaryBg(_accentColor);
  Color get bgCard => AppTheme.getCardBg(_accentColor);
  Color get bgSubtle => AppTheme.getSubtleBg(_accentColor);
  Color get glassBg => AppTheme.getGlassBg(_accentColor);

  List<String> get wantList => List.unmodifiable(_wantList);
  List<Recipe> get cookedHistory => List.unmodifiable(_cookedHistory);
  List<Recipe> get recipes {
    if (_fridgeItems.isEmpty) {
      return const [];
    }
    return _recipes
        .map((r) => _resolveRecipeWithInventory(r))
        .where((r) => r.isSaved || r.isAspirational || r.isSimpleClassic || r.kitchenMatchPercent > 0 || r.missingIngredientsCount > 0)
        .toList();
  }

  Recipe _resolveRecipeWithInventory(Recipe recipe) {
    if (_fridgeItems.isEmpty) {
      final updatedIngredients = recipe.ingredients.map((ing) {
        return ing.copyWith(status: 'missing');
      }).toList();
      return recipe.copyWith(
        kitchenMatchPercent: 0,
        ingredients: updatedIngredients,
      );
    }

    int matchCount = 0;
    final updatedIngredients = recipe.ingredients.map((ing) {
      final hasIt = _hasIngredient(ing.name, _fridgeItems);
      if (hasIt) {
        matchCount++;
        final isLow = _fridgeItems.any((f) => 
          _hasIngredient(ing.name, [f]) && f.status.toLowerCase() == 'running low'
        );
        return ing.copyWith(status: isLow ? 'low' : 'have');
      } else {
        return ing.copyWith(status: 'missing');
      }
    }).toList();

    final pct = recipe.ingredients.isEmpty
        ? 0
        : ((matchCount / recipe.ingredients.length) * 100).round();

    return recipe.copyWith(
      kitchenMatchPercent: pct,
      ingredients: updatedIngredients,
    );
  }

  bool _hasIngredient(String recipeIngredientName, List<FridgeItem> inventory) {
    return PantryRecipeSynthesizer.hasIngredient(recipeIngredientName, inventory);
  }
  List<FridgeItem> get fridgeItems => _fridgeItems;
  List<CookingRecord> get cookingRecords => List.unmodifiable(_cookingRecords);
  List<CookingReminder> get cookingReminders => List.unmodifiable(_cookingReminders);
  List<AiChatMessage> get chatMessages => List.unmodifiable(_chatMessages);

  void addChatMessage(AiChatMessage message) {
    _chatMessages.add(message);
    notifyListeners();
  }

  void clearChatMessages() {
    _chatMessages.clear();
    _chatMessages.add(
      AiChatMessage(
        id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
        text: '안녕하세요! What are we cooking or prepping today?\n\nAsk for recipe ideas with your fridge items, cookie & baking ratios, Korean sauce substitutions, or batch-log your grocery haul.',
        isUser: false,
        timestamp: DateTime.now(),
        quickReplies: const [
          'What can I cook with my fridge?',
          'Cookie & baking guide',
          'Batch add groceries to fridge',
          'Korean sauce guide',
        ],
      ),
    );
    notifyListeners();
  }

  int _composeDiverseFeed() {
    if (_fridgeItems.isEmpty) {
      _recipes.removeWhere((r) => !r.isSaved);
      return 0;
    }

    final Set<String> existingTitles = _recipes.where((r) => r.isSaved).map((r) => r.title.toLowerCase().trim()).toSet();
    final Set<String> existingIds = _recipes.where((r) => r.isSaved).map((r) => r.id).toSet();
    final List<Recipe> newlyCurated = [];

    // 1. SLOT A: Pantry Utility (1-2 recipes tailored strictly to exact inventory)
    final synthesized = PantryRecipeSynthesizer.synthesizeFromInventory(_fridgeItems, _preferredCuisines);
    for (final synth in synthesized.take(2)) {
      final t = synth.title.toLowerCase().trim();
      if (!existingTitles.contains(t) && !existingIds.contains(synth.id)) {
        existingTitles.add(t);
        existingIds.add(synth.id);
        newlyCurated.add(synth.copyWith(recipeSlot: 'pantry_utility'));
      }
    }

    // Include best-matching pantry recipes if slot A has room
    if (newlyCurated.where((r) => r.isPantryUtility).length < 2) {
      final candidates = [...MockData.extendedMinimalistRecipes, ...MockData.seedRecipes];
      final resolvedCandidates = candidates
          .where((c) => !existingTitles.contains(c.title.toLowerCase().trim()) && !existingIds.contains(c.id))
          .map((c) => _resolveRecipeWithInventory(c))
          .where((c) => c.kitchenMatchPercent >= 40)
          .toList();
      resolvedCandidates.sort((a, b) => b.kitchenMatchPercent.compareTo(a.kitchenMatchPercent));

      for (final candidate in resolvedCandidates) {
        final t = candidate.title.toLowerCase().trim();
        if (!existingTitles.contains(t) && !existingIds.contains(candidate.id)) {
          existingTitles.add(t);
          existingIds.add(candidate.id);
          newlyCurated.add(candidate.copyWith(recipeSlot: 'pantry_utility'));
          if (newlyCurated.where((r) => r.isPantryUtility).length >= 2) break;
        }
      }
    }

    // 2. SLOT B: Simple Everyday Classics (2-3 universal, technique-driven dishes)
    final resolvedClassics = MockData.simpleClassicRecipes.map((c) => _resolveRecipeWithInventory(c)).toList();
    resolvedClassics.sort((a, b) => b.kitchenMatchPercent.compareTo(a.kitchenMatchPercent));

    for (final classic in resolvedClassics.take(3)) {
      final t = classic.title.toLowerCase().trim();
      if (!existingTitles.contains(t) && !existingIds.contains(classic.id)) {
        existingTitles.add(t);
        existingIds.add(classic.id);
        newlyCurated.add(classic.copyWith(recipeSlot: 'simple_classic'));
      }
    }

    // 3. SLOT C: Aspirational & Grocery Inspiration Discovery (inspiring dishes worth getting groceries for)
    final aspirationalCandidates = MockData.discoveryCatalog.where((d) {
      final t = d.title.toLowerCase().trim();
      return !existingTitles.contains(t) && !existingIds.contains(d.id);
    }).map((d) => _resolveRecipeWithInventory(d)).toList();

    for (final asp in aspirationalCandidates.take(6)) {
      final t = asp.title.toLowerCase().trim();
      existingTitles.add(t);
      existingIds.add(asp.id);
      newlyCurated.add(asp.copyWith(
        recipeSlot: 'aspirational',
        category: "Chef's Pick",
      ));
    }

    // Retain any existing AI-synthesized recipes and user-saved recipes
    final aiRecipes = _recipes.where((r) => r.id.startsWith('ai_synth_')).toList();
    final savedRecipes = _recipes.where((r) => r.isSaved).toList();

    _recipes.clear();
    _recipes.addAll(savedRecipes);
    for (final aiR in aiRecipes) {
      final t = aiR.title.toLowerCase().trim();
      if (!_recipes.any((r) => r.title.toLowerCase().trim() == t)) {
        _recipes.add(aiR);
      }
    }
    for (final item in newlyCurated) {
      final t = item.title.toLowerCase().trim();
      if (!_recipes.any((r) => r.title.toLowerCase().trim() == t)) {
        _recipes.add(item);
      }
    }

    return newlyCurated.length;
  }

  int _syncSynthesizedRecipes() {
    return _composeDiverseFeed();
  }

  int _autoCheckAndSurfaceUnlockedRecipes() {
    return 0;
  }

  /// Refreshes the dashboard pantry matches and checks for newly unlocked compatible dishes
  ({int readyCount, int highMatchCount, int addedCount, String message}) refreshPantryMatches() {
    final totalAdded = _composeDiverseFeed();
    notifyListeners();

    final ready = recipes.where((r) => r.kitchenMatchPercent >= 75).length;
    final high = recipes.where((r) => r.kitchenMatchPercent >= 50).length;

    final String message;
    if (_fridgeItems.isEmpty) {
      message = 'Dashboard refreshed · Kitchen inventory is empty';
    } else if (totalAdded > 0) {
      message = 'Culinary Studio · Curated $totalAdded diverse dishes across your kitchen ($ready ready to cook)';
    } else {
      message = 'Refreshed · $ready ready to cook, $high high matches';
    }

    return (readyCount: ready, highMatchCount: high, addedCount: totalAdded, message: message);
  }

  /// Deliberately analyzes pantry inventory with real reasoning time and surfaces authentic dishes
  Future<({int readyCount, int highMatchCount, int addedCount, String message})> refreshPantryMatchesWithThinking([BuildContext? context]) async {
    _isThinkingPantry = true;
    notifyListeners();

    // Deliberate thinking cadence so user experiences real analysis of their pantry items
    await Future.delayed(const Duration(milliseconds: 650));

    // Online synthesis if key present
    if (_apiKey.isNotEmpty && _fridgeItems.isNotEmpty) {
      try {
        final onlineRecipes = await PantryRecipeSynthesizer.thinkWithOpenAi(
          apiKey: _apiKey,
          inventory: _fridgeItems,
          preferredCuisines: _preferredCuisines,
        );
        for (final r in onlineRecipes) {
          final idx = _recipes.indexWhere((x) => x.title.toLowerCase() == r.title.toLowerCase());
          if (idx != -1) {
            _recipes[idx] = r;
          } else {
            _recipes.insert(0, r);
          }
        }
      } catch (_) {}
    }

    final totalAdded = _composeDiverseFeed();

    _isThinkingPantry = false;
    notifyListeners();

    final ready = recipes.where((r) => r.kitchenMatchPercent >= 75).length;
    final high = recipes.where((r) => r.kitchenMatchPercent >= 50).length;

    final String message;
    if (_fridgeItems.isEmpty) {
      message = 'Pantry analyzed · Kitchen inventory is empty';
    } else if (totalAdded > 0) {
      message = 'Culinary Studio · Curated $totalAdded diverse dishes across your kitchen ($ready ready to cook)';
    } else {
      message = 'Pantry analyzed · $ready ready to cook, $high high matches';
    }

    return (readyCount: ready, highMatchCount: high, addedCount: totalAdded, message: message);
  }

  /// Explores more simple recipes that have solid compatibility (>= 50-60%) and few ingredients
  ({int addedCount, int totalCount, String message}) exploreMoreRecipes() {
    int newlyAdded = 0;

    if (_fridgeItems.isNotEmpty) {
      // Find candidate minimalist recipes not yet in feed with solid match rate (>= 50%)
      final candidates = MockData.extendedMinimalistRecipes.where((candidate) {
        final alreadyInFeed = _recipes.any((r) => r.id == candidate.id || r.title.toLowerCase() == candidate.title.toLowerCase());
        if (alreadyInFeed) return false;
        final resolved = _resolveRecipeWithInventory(candidate);
        return resolved.kitchenMatchPercent >= 50 && resolved.ingredients.length <= 4;
      }).toList();

      candidates.sort((a, b) {
        final matchA = _resolveRecipeWithInventory(a).kitchenMatchPercent;
        final matchB = _resolveRecipeWithInventory(b).kitchenMatchPercent;
        return matchB.compareTo(matchA);
      });

      for (final candidate in candidates.take(3)) {
        _recipes.add(candidate);
        newlyAdded++;
      }

      // If no 50%+ match candidates, add top minimalist 3-ingredient dishes to help the user cook easily
      if (newlyAdded == 0) {
        final remaining = MockData.extendedMinimalistRecipes.where((c) =>
          !_recipes.any((r) => r.id == c.id || r.title.toLowerCase() == c.title.toLowerCase()) &&
          c.ingredients.length <= 3
        ).toList();
        for (final c in remaining.take(2)) {
          _recipes.add(c);
          newlyAdded++;
        }
      }
    } else {
      // Inventory empty: surface 2 ultra-simple 3-ingredient pantry staple dishes
      final remaining = MockData.extendedMinimalistRecipes.where((c) =>
        !_recipes.any((r) => r.id == c.id || r.title.toLowerCase() == c.title.toLowerCase()) &&
        c.ingredients.length <= 4
      ).toList();
      for (final c in remaining.take(2)) {
        _recipes.add(c);
        newlyAdded++;
      }
    }

    notifyListeners();

    final String message;
    if (newlyAdded > 0) {
      message = 'Explored and added $newlyAdded simple recipes with solid compatibility.';
    } else {
      message = 'All matching minimalist recipes are already in your feed.';
    }

    return (addedCount: newlyAdded, totalCount: _recipes.length, message: message);
  }

  void addMultipleFridgeItems(List<String> names, [StorageLocation location = StorageLocation.pantry]) {
    for (final name in names) {
      final exists = _fridgeItems.any((f) => f.name.toLowerCase() == name.toLowerCase());
      if (!exists) {
        _fridgeItems.insert(
          0,
          FridgeItem(
            id: 'f_${DateTime.now().millisecondsSinceEpoch}_${name.hashCode.abs()}',
            name: name,
            location: location,
            quantityMode: QuantityMode.approximate,
            quantityDisplay: 'Plenty',
            status: 'Have',
          ),
        );
      }
    }
    _saveFridgeItemsToStorage();
    _syncSynthesizedRecipes();
    _autoCheckAndSurfaceUnlockedRecipes();
    notifyListeners();
  }

  int applyBatchInventoryChanges(List<InventoryBatchActionItem> changes) {
    int count = 0;
    for (final change in changes) {
      if (!change.isSelected) continue;

      switch (change.actionType) {
        case BatchActionType.add:
          final existingIdx = _fridgeItems.indexWhere(
            (f) => f.name.toLowerCase().trim() == change.name.toLowerCase().trim(),
          );
          if (existingIdx != -1) {
            _fridgeItems[existingIdx] = _fridgeItems[existingIdx].copyWith(
              location: change.location,
              quantityDisplay: change.quantityDisplay,
              status: change.status,
            );
          } else {
            _fridgeItems.insert(
              0,
              FridgeItem(
                id: 'f_${DateTime.now().millisecondsSinceEpoch}_${count}_${change.name.hashCode.abs()}',
                name: change.name,
                location: change.location,
                quantityMode: QuantityMode.exact,
                quantityDisplay: change.quantityDisplay,
                status: change.status,
              ),
            );
          }
          count++;
          break;

        case BatchActionType.update:
          final existingIdx = _fridgeItems.indexWhere(
            (f) => f.name.toLowerCase().trim() == change.name.toLowerCase().trim(),
          );
          if (existingIdx != -1) {
            _fridgeItems[existingIdx] = _fridgeItems[existingIdx].copyWith(
              location: change.location,
              quantityDisplay: change.quantityDisplay,
              status: change.status,
            );
            count++;
          } else {
            _fridgeItems.insert(
              0,
              FridgeItem(
                id: 'f_${DateTime.now().millisecondsSinceEpoch}_${count}_${change.name.hashCode.abs()}',
                name: change.name,
                location: change.location,
                quantityMode: QuantityMode.exact,
                quantityDisplay: change.quantityDisplay,
                status: change.status,
              ),
            );
            count++;
          }
          break;

        case BatchActionType.remove:
          final beforeLen = _fridgeItems.length;
          _fridgeItems.removeWhere(
            (f) => f.name.toLowerCase().trim() == change.name.toLowerCase().trim(),
          );
          if (_fridgeItems.length < beforeLen) {
            count++;
          }
          break;
      }
    }

    if (count > 0) {
      _saveFridgeItemsToStorage();
      _syncSynthesizedRecipes();
      _autoCheckAndSurfaceUnlockedRecipes();
      notifyListeners();
    }
    return count;
  }

  void addCookingRecord(CookingRecord record) {
    _cookingRecords.insert(0, record);
    _persistCookingRecords();
    notifyListeners();
  }

  void deleteCookingRecord(String id) {
    _cookingRecords.removeWhere((r) => r.id == id);
    _persistCookingRecords();
    notifyListeners();
  }

  void _persistCookingRecords() {
    final list = _cookingRecords.map((r) => r.toJson()).toList();
    StorageService.saveCookingRecords(jsonEncode(list));
  }


  void addCookingReminder(CookingReminder reminder) {
    _cookingReminders.insert(0, reminder);
    _persistCookingReminders();
    notifyListeners();
  }

  void toggleReminderCompleted(String reminderId) {
    final index = _cookingReminders.indexWhere((r) => r.id == reminderId);
    if (index != -1) {
      final current = _cookingReminders[index];
      _cookingReminders[index] = current.copyWith(isCompleted: !current.isCompleted);
      _persistCookingReminders();
      notifyListeners();
    }
  }

  void toggleCookingReminder(String id) => toggleReminderCompleted(id);

  void deleteCookingReminder(String reminderId) {
    _cookingReminders.removeWhere((r) => r.id == reminderId);
    _persistCookingReminders();
    notifyListeners();
  }

  void _persistCookingReminders() {
    final list = _cookingReminders.map((r) => r.toJson()).toList();
    StorageService.saveCookingReminders(jsonEncode(list));
  }

  List<Recipe> get filteredRecipes {
    final list = recipes.where((recipe) {
      if (_selectedFilter == 'Cook with what you have') {
        return recipe.kitchenMatchPercent >= 75;
      }
      if (_selectedFilter == 'Almost there') {
        return recipe.kitchenMatchPercent >= 50 && recipe.kitchenMatchPercent < 75;
      }
      if (_selectedFilter == 'Need Groceries') {
        return recipe.missingIngredientsCount > 0 || recipe.recipeSlot == 'aspirational';
      }
      if (_selectedFilter != 'All' && recipe.category != _selectedFilter) {
        return false;
      }
      if (_selectedCookingMethod != 'All' && recipe.cookingMethod != _selectedCookingMethod) {
        return false;
      }
      if (_currentAiQuery.isNotEmpty) {
        final query = _currentAiQuery.toLowerCase();
        final titleMatch = recipe.title.toLowerCase().contains(query);
        final koreanMatch = recipe.koreanTitle.toLowerCase().contains(query);
        final methodMatch = recipe.cookingMethod.toLowerCase().contains(query);
        final categoryMatch = recipe.category.toLowerCase().contains(query);
        final ingredientMatch = recipe.ingredients.any((i) => i.name.toLowerCase().contains(query));

        if (!titleMatch && !koreanMatch && !methodMatch && !categoryMatch && !ingredientMatch) {
          return false;
        }
      }
      return true;
    }).toList();

    // Apply user selected sorting
    switch (_selectedSortOption) {
      case 'time':
        list.sort((a, b) => a.cookingTimeMinutes.compareTo(b.cookingTimeMinutes));
        break;
      case 'fewest_ingredients':
        list.sort((a, b) => a.ingredients.length.compareTo(b.ingredients.length));
        break;
      case 'alphabetical':
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'match':
      default:
        if (_selectedFilter == 'Need Groceries') {
          // In Need Groceries view, prioritize recipes that need fewest items or have great match potential
          list.sort((a, b) {
            final cmp = a.missingIngredientsCount.compareTo(b.missingIngredientsCount);
            if (cmp != 0) return cmp;
            return b.kitchenMatchPercent.compareTo(a.kitchenMatchPercent);
          });
        } else if (_fridgeItems.isNotEmpty) {
          list.sort((a, b) {
            final slotWeightA = a.isPantryUtility ? 0 : (a.isSimpleClassic ? 1 : 2);
            final slotWeightB = b.isPantryUtility ? 0 : (b.isSimpleClassic ? 1 : 2);
            if (slotWeightA != slotWeightB) {
              return slotWeightA.compareTo(slotWeightB);
            }
            return b.kitchenMatchPercent.compareTo(a.kitchenMatchPercent);
          });
        }
        break;
    }

    return list;
  }

  String get selectedSortOption => _selectedSortOption;

  void setSortOption(String sortOption) {
    if (_selectedSortOption == sortOption) return;
    _selectedSortOption = sortOption;
    notifyListeners();
  }

  void setActiveTab(int index) {
    _activeTabIndex = index;
    notifyListeners();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setCookingMethod(String method) {
    _selectedCookingMethod = method;
    notifyListeners();
  }

  void setAiQuery(String query) {
    _currentAiQuery = query;
    notifyListeners();
  }

  void clearAiQuery() {
    _currentAiQuery = '';
    notifyListeners();
  }

  AiFollowUpSession? get aiFollowUpSession => _aiFollowUpSession;

  void startAiFollowUpSession(AiFollowUpSession session) {
    _aiFollowUpSession = session;
    notifyListeners();
  }

  void dismissAiFollowUpSession() {
    _aiFollowUpSession = null;
    notifyListeners();
  }

  void toggleAiFollowUpCollapse() {
    if (_aiFollowUpSession != null) {
      _aiFollowUpSession = _aiFollowUpSession!.copyWith(
        isCollapsed: !_aiFollowUpSession!.isCollapsed,
      );
      notifyListeners();
    }
  }

  void setAiFollowUpCollapsed(bool collapsed) {
    if (_aiFollowUpSession != null) {
      _aiFollowUpSession = _aiFollowUpSession!.copyWith(
        isCollapsed: collapsed,
      );
      notifyListeners();
    }
  }

  void toggleAiPromptExpanded() {
    _isAiPromptExpanded = !_isAiPromptExpanded;
    notifyListeners();
  }

  // Accent Color Selection
  void setAccentColor(Color color) {
    _accentColor = color;
    StorageService.saveAccentColor(color.toARGB32());
    notifyListeners();
  }

  // Profile Modification Methods
  void setUserRegion(String region) {
    _userRegion = region;
    StorageService.saveUserRegion(region);
    notifyListeners();
  }

  void togglePreferredCuisine(String cuisine) {
    if (_preferredCuisines.contains(cuisine)) {
      _preferredCuisines.remove(cuisine);
    } else {
      _preferredCuisines.add(cuisine);
    }
    StorageService.saveUserCuisines(_preferredCuisines);
    _syncSynthesizedRecipes();
    _autoCheckAndSurfaceUnlockedRecipes();
    notifyListeners();
  }

  void toggleDietaryRestriction(String restriction) {
    if (_dietaryRestrictions.contains(restriction)) {
      _dietaryRestrictions.remove(restriction);
    } else {
      _dietaryRestrictions.add(restriction);
    }
    StorageService.saveDietaryRestrictions(_dietaryRestrictions);
    notifyListeners();
  }

  void toggleKitchenAppliance(String appliance) {
    if (_kitchenAppliances.contains(appliance)) {
      _kitchenAppliances.remove(appliance);
    } else {
      _kitchenAppliances.add(appliance);
    }
    StorageService.saveAppliances(_kitchenAppliances);
    notifyListeners();
  }

  void toggleSaveRecipe(String recipeId) {
    final index = _recipes.indexWhere((r) => r.id == recipeId);
    if (index != -1) {
      final current = _recipes[index];
      _recipes[index] = current.copyWith(isSaved: !current.isSaved);
      notifyListeners();
    }
  }

  final List<Recipe> _wishlistRecipes = [];
  List<Recipe> get wishlistRecipes => List.unmodifiable(_wishlistRecipes);

  void addToWishlist(Recipe recipe) {
    if (!_wishlistRecipes.any((r) => r.id == recipe.id)) {
      _wishlistRecipes.insert(0, recipe);
      notifyListeners();
    }
  }

  void saveRecipeFromDiscovery(Recipe recipe) {
    final index = _recipes.indexWhere((r) => r.id == recipe.id);
    if (index != -1) {
      _recipes[index] = _recipes[index].copyWith(isSaved: true);
    } else {
      _recipes.insert(0, recipe.copyWith(isSaved: true));
    }
    notifyListeners();
  }

  /// Curates exactly 4 minimalist recipe cards matching questionnaire constraints & inventory
  List<Recipe> curateDiscoveryDeck({
    required String mood, // 'bake' | 'craving' | 'dessert' | 'savory'
    required String vibe, // sub-vibe or 'any'
    required String timeframe, // 'under_10' | '15_20' | 'any'
    required String constraint, // 'strict_have' | 'minimal_3_4' | 'open'
    String? methodPref, // 'any_method' | 'oven' | 'stovetop' | 'quick_device'
  }) {
    // CRITICAL: Explore must NEVER show dishes that are already on the user's dashboard!
    final dashboardTitles = _recipes.map((r) => r.title.trim().toLowerCase()).toSet();
    final dashboardIds = _recipes.map((r) => r.id).toSet();

    final Set<String> seenIds = {};
    final List<Recipe> pool = [];
    for (final r in [...MockData.discoveryCatalog, ...MockData.extendedMinimalistRecipes, ...MockData.seedRecipes]) {
      if (!seenIds.contains(r.id)) {
        seenIds.add(r.id);
        if (dashboardIds.contains(r.id) || dashboardTitles.contains(r.title.trim().toLowerCase())) {
          continue;
        }
        pool.add(_resolveRecipeWithInventory(r));
      }
    }

    final scored = pool.map((recipe) {
      double score = 0;

      // Pantry match factor
      score += recipe.kitchenMatchPercent * 1.5;

      // Simplicity bonus (3-4 ingredients)
      if (recipe.ingredients.length <= 4) score += 25;

      // Timeframe match
      if (timeframe == 'under_10' && recipe.cookingTimeMinutes <= 10) {
        score += 35;
      } else if (timeframe == '15_20' && recipe.cookingTimeMinutes <= 20) {
        score += 25;
      }

      final lowerTitle = '${recipe.title} ${recipe.koreanTitle} ${recipe.category} ${recipe.cookingMethod}'.toLowerCase();
      final lowerMethod = recipe.cookingMethod.toLowerCase();

      // Method preference bonus
      if (methodPref == 'oven' && (lowerMethod.contains('oven') || lowerMethod.contains('air fryer'))) {
        score += 30;
      } else if (methodPref == 'stovetop' && lowerMethod.contains('stovetop')) {
        score += 25;
      } else if (methodPref == 'quick_device' && (lowerMethod.contains('microwave') || lowerMethod.contains('no-cook'))) {
        score += 30;
      }

      // 1. I Want to Bake
      if (mood == 'bake') {
        if (lowerMethod.contains('oven') ||
            lowerMethod.contains('air fryer') ||
            lowerTitle.contains('baking') ||
            lowerTitle.contains('pastry') ||
            lowerTitle.contains('toast') ||
            lowerTitle.contains('cookie') ||
            lowerTitle.contains('shortbread') ||
            lowerTitle.contains('bread') ||
            lowerTitle.contains('cake') ||
            lowerTitle.contains('apple')) {
          score += 70;
        }
        if (vibe == 'sweet_bake' && (lowerTitle.contains('cookie') || lowerTitle.contains('honey') || lowerTitle.contains('cake') || lowerTitle.contains('sugar'))) {
          score += 30;
        } else if (vibe == 'savory_bake' && (lowerTitle.contains('garlic') || lowerTitle.contains('cheese') || lowerTitle.contains('toast'))) {
          score += 35;
        }
      }
      // 2. I Want Dessert
      else if (mood == 'dessert') {
        if (lowerTitle.contains('dessert') ||
            lowerTitle.contains('cake') ||
            lowerTitle.contains('honey') ||
            lowerTitle.contains('cookie') ||
            lowerTitle.contains('sweet potato') ||
            lowerTitle.contains('apple') ||
            lowerTitle.contains('banana') ||
            lowerTitle.contains('toast') ||
            lowerTitle.contains('빙수') ||
            lowerTitle.contains('sweet')) {
          score += 70;
        }
        if (vibe == 'warm_dessert' && (lowerTitle.contains('mug cake') || lowerTitle.contains('baked') || lowerTitle.contains('banana') || lowerTitle.contains('toast') || lowerTitle.contains('sweet potato'))) {
          score += 30;
        } else if (vibe == 'quick_sweet' && (recipe.cookingTimeMinutes <= 6 || lowerTitle.contains('latte') || lowerTitle.contains('mug cake') || lowerTitle.contains('banana'))) {
          score += 30;
        }
      }
      // 3. Just Craving Something / Snack
      else if (mood == 'craving') {
        if (lowerTitle.contains('dumpling') ||
            lowerTitle.contains('pancake') ||
            lowerTitle.contains('corn cheese') ||
            lowerTitle.contains('noodle') ||
            lowerTitle.contains('toast') ||
            lowerTitle.contains('crispy') ||
            lowerTitle.contains('전') ||
            lowerTitle.contains('만두') ||
            lowerTitle.contains('sweet potato') ||
            lowerTitle.contains('snack')) {
          score += 65;
        }
        if (vibe == 'crispy_snack' && (lowerTitle.contains('pancake') || lowerTitle.contains('dumpling') || lowerTitle.contains('crispy') || lowerTitle.contains('toast'))) {
          score += 35;
        } else if (vibe == 'sweet_craving' && (lowerTitle.contains('sweet') || lowerTitle.contains('banana') || lowerTitle.contains('cake') || lowerTitle.contains('toast') || lowerTitle.contains('potato'))) {
          score += 35;
        }
      }
      // 4. Comforting Savory Meal
      else if (mood == 'savory') {
        if (lowerTitle.contains('rice') ||
            lowerTitle.contains('밥') ||
            lowerTitle.contains('soup') ||
            lowerTitle.contains('국') ||
            lowerTitle.contains('찌개') ||
            lowerTitle.contains('stew') ||
            lowerTitle.contains('tofu') ||
            lowerTitle.contains('두부') ||
            lowerTitle.contains('noodle') ||
            lowerTitle.contains('면') ||
            lowerTitle.contains('skillet') ||
            lowerTitle.contains('kimchi')) {
          score += 65;
        }
        if (vibe == 'rice_noodles' && (lowerTitle.contains('rice') || lowerTitle.contains('noodle') || lowerTitle.contains('밥') || lowerTitle.contains('면'))) {
          score += 35;
        } else if (vibe == 'warm_soup' && (lowerTitle.contains('soup') || lowerTitle.contains('국') || lowerTitle.contains('stew') || lowerTitle.contains('찌개'))) {
          score += 35;
        } else if (vibe == 'skillet_mains' && (lowerTitle.contains('tofu') || lowerTitle.contains('skillet') || lowerTitle.contains('kimchi'))) {
          score += 35;
        }
      }

      // Kitchen constraint
      if (constraint == 'strict_have' && recipe.kitchenMatchPercent >= 75) {
        score += 50;
      } else if (constraint == 'minimal_3_4' && recipe.ingredients.length <= 4) {
        score += 35;
      }

      return (recipe: recipe, score: score);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));

    // Strictly capped at 4 cards
    return scored.take(4).map((s) => s.recipe).toList();
  }

  void updateRecipeImage(String recipeId, String imageUrl) {
    final index = _recipes.indexWhere((r) => r.id == recipeId);
    if (index != -1) {
      final current = _recipes[index];
      _recipes[index] = current.copyWith(imageUrl: imageUrl);
      notifyListeners();
    }
  }

  // Shopping List / Want List Actions
  void addToWantList(String ingredientName) {
    if (!_wantList.contains(ingredientName)) {
      _wantList.add(ingredientName);
      StorageService.saveWantList(_wantList);
      notifyListeners();
    }
  }

  void removeFromWantList(String ingredientName) {
    _wantList.remove(ingredientName);
    StorageService.saveWantList(_wantList);
    notifyListeners();
  }

  void addMultipleToWantList(List<String> ingredients) {
    bool updated = false;
    for (final ing in ingredients) {
      if (!_wantList.contains(ing)) {
        _wantList.add(ing);
        updated = true;
      }
    }
    if (updated) {
      StorageService.saveWantList(_wantList);
      notifyListeners();
    }
  }

  // Want → Fridge Transition Handler
  void markWantItemBought(String ingredientName) {
    _wantList.remove(ingredientName);
    StorageService.saveWantList(_wantList);

    final newFridgeItem = FridgeItem(
      id: 'f_${DateTime.now().millisecondsSinceEpoch}',
      name: ingredientName,
      location: StorageLocation.fridge,
      quantityMode: QuantityMode.approximate,
      quantityDisplay: 'Plenty',
      status: 'Have',
    );
    _fridgeItems.insert(0, newFridgeItem);
    _saveFridgeItemsToStorage();
    _syncSynthesizedRecipes();
    _autoCheckAndSurfaceUnlockedRecipes();
    notifyListeners();
  }

  // Fridge Item Management
  void addFridgeItem(FridgeItem item) {
    _fridgeItems.insert(0, item);
    _saveFridgeItemsToStorage();
    _syncSynthesizedRecipes();
    _autoCheckAndSurfaceUnlockedRecipes();
    notifyListeners();
  }

  void updateFridgeItem(FridgeItem item) {
    final index = _fridgeItems.indexWhere((f) => f.id == item.id);
    if (index != -1) {
      _fridgeItems[index] = item;
      _saveFridgeItemsToStorage();
      _syncSynthesizedRecipes();
      _autoCheckAndSurfaceUnlockedRecipes();
      notifyListeners();
    }
  }

  void removeFridgeItem(String itemId) {
    _fridgeItems.removeWhere((f) => f.id == itemId);
    _saveFridgeItemsToStorage();
    _syncSynthesizedRecipes();
    _autoCheckAndSurfaceUnlockedRecipes();
    notifyListeners();
  }

  void clearInventory() {
    _fridgeItems.clear();
    _recipes.clear();
    _saveFridgeItemsToStorage();
    notifyListeners();
  }

  void resetInventoryToDefault() {
    _fridgeItems.clear();
    _recipes.clear();
    _fridgeItems.addAll(MockData.seedFridgeItems);
    _saveFridgeItemsToStorage();
    _syncSynthesizedRecipes();
    _autoCheckAndSurfaceUnlockedRecipes();
    notifyListeners();
  }

  void addToCookedHistory(Recipe recipe) {
    _cookedHistory.insert(0, recipe);
    notifyListeners();
  }

  /// Applies post-cooking deductions & status updates across inventory,
  /// adds depleted or requested items to shopping list, and logs the cooking record.
  void applyPostCookingInventoryUpdate({
    required Recipe recipe,
    required List<FridgeItem> updatedItems,
    required List<String> depletedItemIdsToRemove,
    required List<String> itemsToAddToWantList,
    String? cookingNotes,
    int rating = 5,
  }) {
    // 1. Update fridge items that had deductions or status changes
    for (final updated in updatedItems) {
      final idx = _fridgeItems.indexWhere((f) => f.id == updated.id);
      if (idx != -1) {
        _fridgeItems[idx] = updated;
      }
    }

    // 2. Remove items that were marked as completely depleted/finished (if requested)
    if (depletedItemIdsToRemove.isNotEmpty) {
      _fridgeItems.removeWhere((f) => depletedItemIdsToRemove.contains(f.id));
    }

    _saveFridgeItemsToStorage();

    // 3. Add any depleted or missing items to Want/Shopping list
    if (itemsToAddToWantList.isNotEmpty) {
      addMultipleToWantList(itemsToAddToWantList);
    }

    // 4. Record to Cooked History
    addToCookedHistory(recipe);

    // 5. Add to Cooking Records / Calendar Journal
    addCookingRecord(
      CookingRecord(
        id: 'cr_${DateTime.now().millisecondsSinceEpoch}',
        recipeTitle: recipe.title,
        koreanTitle: recipe.koreanTitle,
        date: DateTime.now(),
        photoUrl: recipe.imageUrl,
        rating: rating,
        notes: cookingNotes ?? 'Cooked with kitchen ingredients. Inventory updated.',
        tags: [recipe.cookingMethod, recipe.difficulty, if (recipe.category.isNotEmpty) recipe.category],
      ),
    );

    _syncSynthesizedRecipes();
    _autoCheckAndSurfaceUnlockedRecipes();
    notifyListeners();
  }

  // Reset to Defaults
  void resetStateToDefaults() {
    _accentColor = AppTheme.defaultAccent;
    _userRegion = MockData.defaultRegion;
    _preferredCuisines = List.from(MockData.defaultCuisines);
    _dietaryRestrictions = List.from(MockData.defaultDietaryRestrictions);
    _kitchenAppliances = List.from(MockData.defaultAppliances);
    _wantList.clear();
    _wantList.addAll(['Green Onion', 'Gochujang Paste']);
    _recipes.clear();
    _apiKey = AppConfig.resolveApiKey(null);
    StorageService.clearAll();
    notifyListeners();
  }

  // AI Recipe Modification Engine
  void applyAiModification({
    required String recipeId,
    required AiModificationDiff diff,
    required List<RecipeIngredient> updatedIngredients,
    int? newCookingTime,
    String? newCookingMethod,
    int? newKitchenMatch,
  }) {
    final index = _recipes.indexWhere((r) => r.id == recipeId);
    if (index != -1) {
      final current = _recipes[index];
      _recipes[index] = current.copyWith(
        ingredients: updatedIngredients,
        cookingTimeMinutes: newCookingTime ?? current.cookingTimeMinutes,
        cookingMethod: newCookingMethod ?? current.cookingMethod,
        kitchenMatchPercent: newKitchenMatch ?? 100,
        isAiModified: true,
        diff: diff,
      );
      notifyListeners();
    }
  }

  void saveAiModifiedAsNewRecipe({
    required Recipe originalRecipe,
    required AiModificationDiff diff,
    required List<RecipeIngredient> updatedIngredients,
    int? newCookingTime,
    String? newCookingMethod,
  }) {
    final newId = 'ai_${DateTime.now().millisecondsSinceEpoch}';
    final newRecipe = originalRecipe.copyWith(
      id: newId,
      title: '${originalRecipe.title} (AI Custom)',
      ingredients: updatedIngredients,
      cookingTimeMinutes: newCookingTime ?? originalRecipe.cookingTimeMinutes,
      cookingMethod: newCookingMethod ?? originalRecipe.cookingMethod,
      kitchenMatchPercent: 100,
      isAiModified: true,
      isSaved: true,
      diff: diff,
    );
    _recipes.insert(0, newRecipe);
    notifyListeners();
  }
}
