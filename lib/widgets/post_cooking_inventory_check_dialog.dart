import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/fridge_item.dart';
import '../models/recipe.dart';
import '../providers/app_state.dart';
import '../services/pantry_recipe_synthesizer.dart';
import '../services/quantity_scrubber_helper.dart';
import '../theme/app_theme.dart';

enum PostCookingDeductionAction {
  deduct,
  finished,
  keepUnchanged,
}

class PostCookingInventoryCheckSheet extends StatefulWidget {
  final Recipe recipe;

  const PostCookingInventoryCheckSheet({
    super.key,
    required this.recipe,
  });

  static Future<bool?> show(BuildContext context, Recipe recipe) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostCookingInventoryCheckSheet(recipe: recipe),
    );
  }

  @override
  State<PostCookingInventoryCheckSheet> createState() => _PostCookingInventoryCheckSheetState();
}

class _PostCookingInventoryCheckSheetState extends State<PostCookingInventoryCheckSheet> {
  // Matched items state
  late final List<FridgeItem> _matchedFridgeItems;
  late final List<RecipeIngredient> _missingRecipeIngredients;

  // Deduction decisions per matched item ID
  final Map<String, PostCookingDeductionAction> _actions = {};
  final Map<String, String> _calculatedRemainingQty = {};
  final Set<String> _itemsToAddShoppingList = {};
  final Set<String> _missingItemsToAddShoppingList = {};
  final Set<String> _itemsToRemoveCompletely = {};

  int _cookingRating = 5;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    final inventory = appState.fridgeItems;

    _matchedFridgeItems = [];
    _missingRecipeIngredients = [];

    for (final ing in widget.recipe.ingredients) {
      FridgeItem? match;
      for (final f in inventory) {
        if (PantryRecipeSynthesizer.hasIngredient(ing.name, [f])) {
          match = f;
          break;
        }
      }

      if (match != null) {
        if (!_matchedFridgeItems.any((m) => m.id == match!.id)) {
          _matchedFridgeItems.add(match);
        }
      } else {
        _missingRecipeIngredients.add(ing);
      }
    }

    // Default action setup
    for (final item in _matchedFridgeItems) {
      _actions[item.id] = PostCookingDeductionAction.deduct;
      // Pre-compute remaining quantity if exact or approximate
      _calculatedRemainingQty[item.id] = _computeDeductionPreview(item, widget.recipe);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _computeDeductionPreview(FridgeItem item, Recipe recipe) {
    final rawQty = item.quantityDisplay?.trim() ?? '';
    if (rawQty.isEmpty) return '1 piece';

    final stepped = QuantityScrubberHelper.stepQuantity(
      currentQuantity: rawQty,
      currentStatus: item.status,
      increment: false,
    );
    return stepped.quantityDisplay;
  }

  void _onConfirm(BuildContext context) {
    final appState = context.read<AppState>();
    final trackQuantities = appState.trackQuantities;

    final List<FridgeItem> updatedItems = [];
    final List<String> itemsToRemove = [];
    final List<String> wantListItems = [];

    for (final item in _matchedFridgeItems) {
      final action = _actions[item.id] ?? PostCookingDeductionAction.deduct;

      if (action == PostCookingDeductionAction.keepUnchanged) {
        continue;
      }

      if (action == PostCookingDeductionAction.finished) {
        if (_itemsToRemoveCompletely.contains(item.id)) {
          itemsToRemove.add(item.id);
        } else {
          updatedItems.add(item.copyWith(
            status: 'Missing',
            quantityDisplay: trackQuantities ? 'Almost empty' : null,
          ));
        }
      } else if (action == PostCookingDeductionAction.deduct) {
        if (trackQuantities) {
          final newQty = _calculatedRemainingQty[item.id] ?? item.quantityDisplay;
          final isDepleted = newQty != null && (newQty.contains('0') || newQty.toLowerCase().contains('empty'));
          updatedItems.add(item.copyWith(
            quantityDisplay: newQty,
            status: isDepleted ? 'Running low' : item.status,
          ));
        } else {
          // If quantities are not tracked, action deduct keeps status Have
          updatedItems.add(item.copyWith(status: 'Have'));
        }
      }

      if (_itemsToAddShoppingList.contains(item.name)) {
        wantListItems.add(item.name);
      }
    }

    // Add selected missing ingredients to shopping list
    for (final missing in _missingRecipeIngredients) {
      if (_missingItemsToAddShoppingList.contains(missing.name)) {
        wantListItems.add(missing.name);
      }
    }

    appState.applyPostCookingInventoryUpdate(
      recipe: widget.recipe,
      updatedItems: updatedItems,
      depletedItemIdsToRemove: itemsToRemove,
      itemsToAddToWantList: wantListItems,
      cookingNotes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      rating: _cookingRating,
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final accentColor = appState.accentColor;
    final trackQuantities = appState.trackQuantities;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: appState.bgPrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 20, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle pill
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textLight.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.accentGreen,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cooked & Plated',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMain,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Review used ingredients to update your kitchen pantry.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1),

          // Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              children: [
                // Dish Summary Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: appState.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: appState.bgSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.restaurant_menu_rounded, color: accentColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.recipe.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textMain,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${widget.recipe.cookingMethod} · ${widget.recipe.cookingTimeMinutes}m · ${_matchedFridgeItems.length} pantry items used',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Rating stars
                      Row(
                        children: List.generate(5, (index) {
                          final star = index + 1;
                          return GestureDetector(
                            onTap: () => setState(() => _cookingRating = star),
                            child: Icon(
                              star <= _cookingRating ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 19,
                              color: star <= _cookingRating ? AppTheme.accentAmber : AppTheme.textLight,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Section Title: Matched Fridge Items
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pantry Items Used (${_matchedFridgeItems.length})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                      ),
                    ),
                    if (!trackQuantities)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: appState.bgSubtle,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Checklist mode',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                if (_matchedFridgeItems.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: appState.bgCard,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        'No tracked inventory items matched this recipe directly.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  )
                else
                  ..._matchedFridgeItems.map((item) {
                    final action = _actions[item.id] ?? PostCookingDeductionAction.deduct;
                    final currentQty = item.quantityDisplay ?? 'Some';
                    final remainingPreview = _calculatedRemainingQty[item.id] ?? currentQty;
                    final isAddToShopping = _itemsToAddShoppingList.contains(item.name);

                    // Find recipe ingredient callout
                    final recipeIng = widget.recipe.ingredients.firstWhere(
                      (i) => PantryRecipeSynthesizer.hasIngredient(i.name, [item]),
                      orElse: () => RecipeIngredient(name: item.name),
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: appState.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: action == PostCookingDeductionAction.finished
                              ? AppTheme.accentOrange.withValues(alpha: 0.3)
                              : appState.bgSubtle,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Storage zone badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: appState.bgSubtle,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.location.name.toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textMuted,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textMain,
                                  ),
                                ),
                              ),
                              if (recipeIng.amount != null && recipeIng.amount!.isNotEmpty)
                                Text(
                                  'Used: ${recipeIng.amount}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: accentColor,
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // If Quantity Tracking is Active
                          if (trackQuantities) ...[
                            Row(
                              children: [
                                Text(
                                  'Current: $currentQty',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_forward_rounded, size: 13, color: AppTheme.textLight),
                                const SizedBox(width: 6),
                                Text(
                                  action == PostCookingDeductionAction.finished
                                      ? 'Empty'
                                      : action == PostCookingDeductionAction.keepUnchanged
                                          ? currentQty
                                          : remainingPreview,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: action == PostCookingDeductionAction.finished
                                        ? AppTheme.accentOrange
                                        : AppTheme.accentGreen,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],

                          // Action Chips
                          Row(
                            children: [
                              _buildActionPill(
                                label: trackQuantities ? 'Deduct Amount' : 'Still Have',
                                icon: Icons.remove_circle_outline_rounded,
                                isSelected: action == PostCookingDeductionAction.deduct,
                                activeColor: accentColor,
                                appState: appState,
                                onTap: () {
                                  setState(() {
                                    _actions[item.id] = PostCookingDeductionAction.deduct;
                                    _itemsToAddShoppingList.remove(item.name);
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildActionPill(
                                label: 'Ran Out / Finished',
                                icon: Icons.cancel_outlined,
                                isSelected: action == PostCookingDeductionAction.finished,
                                activeColor: AppTheme.accentOrange,
                                appState: appState,
                                onTap: () {
                                  setState(() {
                                    _actions[item.id] = PostCookingDeductionAction.finished;
                                    _itemsToAddShoppingList.add(item.name);
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildActionPill(
                                label: 'Unchanged',
                                icon: Icons.pause_circle_outline_rounded,
                                isSelected: action == PostCookingDeductionAction.keepUnchanged,
                                activeColor: AppTheme.textMuted,
                                appState: appState,
                                onTap: () {
                                  setState(() {
                                    _actions[item.id] = PostCookingDeductionAction.keepUnchanged;
                                  });
                                },
                              ),
                            ],
                          ),

                          // Option: Add to Want list if finished or low
                          if (action == PostCookingDeductionAction.finished) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (isAddToShopping) {
                                    _itemsToAddShoppingList.remove(item.name);
                                  } else {
                                    _itemsToAddShoppingList.add(item.name);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      isAddToShopping ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                      size: 18,
                                      color: isAddToShopping ? accentColor : AppTheme.textMuted,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Add to Shopping List (Want)',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isAddToShopping ? accentColor : AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),

                // Section: Missing Recipe Ingredients (Groceries used or to restock)
                if (_missingRecipeIngredients.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Other Recipe Ingredients (${_missingRecipeIngredients.length})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMain,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Did you buy or need to restock any of these?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: appState.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: appState.bgSubtle),
                    ),
                    child: Column(
                      children: _missingRecipeIngredients.map((missing) {
                        final isChecked = _missingItemsToAddShoppingList.contains(missing.name);
                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (isChecked) {
                                _missingItemsToAddShoppingList.remove(missing.name);
                              } else {
                                _missingItemsToAddShoppingList.add(missing.name);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(
                                  isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                  size: 18,
                                  color: isChecked ? accentColor : AppTheme.textLight,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    missing.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textMain,
                                    ),
                                  ),
                                ),
                                if (missing.amount != null)
                                  Text(
                                    missing.amount!,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Cooking Journal Notes (Optional)
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    hintText: 'Chef notes / modifications you made (optional)',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppTheme.textLight),
                    filled: true,
                    fillColor: appState.bgCard,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: appState.bgSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: appState.bgSubtle),
                    ),
                  ),
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMain),
                  maxLines: 2,
                ),
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: BoxDecoration(
              color: appState.bgPrimary,
              border: Border(top: BorderSide(color: appState.bgSubtle)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      // Still record history, skip pantry updates
                      appState.addToCookedHistory(widget.recipe);
                      Navigator.pop(context, false);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Keep As-Is',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _onConfirm(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Confirm & Update',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required AppState appState,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : appState.bgSubtle.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? activeColor : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : AppTheme.textMuted,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.textMain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
