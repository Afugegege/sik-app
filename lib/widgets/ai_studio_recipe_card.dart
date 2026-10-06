import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/ai_chat_message.dart';
import '../models/recipe.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../services/servings_scaler.dart';
import '../services/pantry_recipe_synthesizer.dart';
import '../screens/cooking_mode_screen.dart';
import 'cooking_timer_widget.dart';

/// An aesthetic, premium Korean Ins studio recipe card component that replaces
/// plain raw markdown text with an elegant, structured recipe design.
/// Connected deeply with the app's inventory, shopping list, servings scaler, and cooking mode.
class AiStudioRecipeCard extends StatefulWidget {
  final AiStructuredRecipe recipe;

  const AiStudioRecipeCard({
    super.key,
    required this.recipe,
  });

  @override
  State<AiStudioRecipeCard> createState() => _AiStudioRecipeCardState();
}

class _AiStudioRecipeCardState extends State<AiStudioRecipeCard> {
  bool _isSaved = false;
  bool _addedToShopping = false;
  late int _servings;
  final Set<int> _checkedIngredients = {};
  final Set<int> _addedSingleItems = {};

  @override
  void initState() {
    super.initState();
    _servings = widget.recipe.servings > 0 ? widget.recipe.servings : 2;
  }

  int get _baseServings => widget.recipe.servings > 0 ? widget.recipe.servings : 2;

  Recipe _convertToRecipe() {
    final parsedMinutes = int.tryParse(
          widget.recipe.cookingTime.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        15;

    return Recipe(
      id: 'ai_studio_${DateTime.now().millisecondsSinceEpoch}',
      title: widget.recipe.title,
      koreanTitle: widget.recipe.koreanTitle,
      imageUrl: '',
      cookingTimeMinutes: parsedMinutes > 0 ? parsedMinutes : 15,
      cookingMethod: widget.recipe.category.isNotEmpty ? widget.recipe.category : 'Stovetop',
      difficulty: widget.recipe.difficulty.isNotEmpty ? widget.recipe.difficulty : 'Easy',
      kitchenMatchPercent: 100,
      category: widget.recipe.category.isNotEmpty ? widget.recipe.category : 'Cook with what you have',
      ingredients: widget.recipe.ingredients.map((item) {
        final scaled = ServingsScaler.scaleAmount(item, _baseServings, _servings) ?? item;
        return RecipeIngredient(name: scaled, status: 'have');
      }).toList(),
      cookingSteps: widget.recipe.instructions,
      isSaved: true,
      servings: _servings,
      inspirationNote: widget.recipe.chefNote.isNotEmpty ? widget.recipe.chefNote : null,
    );
  }

  void _handleSave(AppState appState) {
    final recipe = _convertToRecipe();
    appState.saveRecipeFromDiscovery(recipe);
    setState(() {
      _isSaved = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Saved "${widget.recipe.title}" to My Recipes!',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleAddMissingToShopping(AppState appState, List<String> missing) {
    if (missing.isEmpty) return;
    appState.addMultipleToWantList(missing);
    setState(() {
      _addedToShopping = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Added ${missing.length} missing items to Shopping Want List',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: appState.accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleAddSingleToShopping(AppState appState, int idx, String ingredient) {
    appState.addToWantList(ingredient);
    setState(() {
      _addedSingleItems.add(idx);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added "$ingredient" to Shopping Want List',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
        backgroundColor: appState.accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _handleCookNow(BuildContext context) {
    final recipe = _convertToRecipe();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CookingModeScreen(recipe: recipe),
      ),
    );
  }

  void _handleCopyRecipe(BuildContext context) {
    final r = widget.recipe;
    final sb = StringBuffer();
    sb.writeln(r.title);
    if (r.koreanTitle.isNotEmpty) sb.writeln(r.koreanTitle);
    sb.writeln('Time: ${r.cookingTime} | Difficulty: ${r.difficulty} | Servings: $_servings');
    sb.writeln('\nINGREDIENTS:');
    for (final ing in r.ingredients) {
      final scaled = ServingsScaler.scaleAmount(ing, _baseServings, _servings) ?? ing;
      sb.writeln('• $scaled');
    }
    sb.writeln('\nINSTRUCTIONS:');
    for (int i = 0; i < r.instructions.length; i++) {
      sb.writeln('${i + 1}. ${r.instructions[i]}');
    }
    if (r.chefNote.isNotEmpty) {
      sb.writeln('\nCHEF NOTE: ${r.chefNote}');
    }

    Clipboard.setData(ClipboardData(text: sb.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Recipe copied to clipboard!',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.textMain,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showTimerDialog(BuildContext context, int minutes) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${widget.recipe.title} Timer',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMain,
              ),
            ),
            const SizedBox(height: 12),
            CookingTimerWidget(initialMinutes: minutes > 0 ? minutes : 5),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final accentColor = appState.accentColor;
    final r = widget.recipe;

    final parsedMinutes = int.tryParse(
          r.cookingTime.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        15;

    // Evaluate live kitchen inventory matching
    final List<String> missingIngredients = [];
    int haveCount = 0;

    for (final ing in r.ingredients) {
      final isHave = PantryRecipeSynthesizer.hasIngredient(ing, appState.fridgeItems);
      if (isHave) {
        haveCount++;
      } else {
        missingIngredients.add(ing);
      }
    }

    final int totalCount = r.ingredients.length;
    final int matchPct = totalCount > 0 ? ((haveCount / totalCount) * 100).round() : 100;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: appState.bgCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: appState.bgSubtle,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -----------------------------------------------------------------
          // 1. CARD HEADER
          // -----------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        r.category.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: accentColor,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '식 STUDIO RECIPE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.copy_rounded, size: 14, color: AppTheme.textMuted),
                          tooltip: 'Copy Recipe',
                          onPressed: () => _handleCopyRecipe(context),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Title
                Text(
                  r.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMain,
                    letterSpacing: -0.4,
                    height: 1.25,
                  ),
                ),

                if (r.koreanTitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    r.koreanTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Live Inventory Match Badge & Meta Chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Pantry Match Badge connected to inventory
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: matchPct >= 70
                            ? AppTheme.bgGreenLight
                            : (matchPct >= 40 ? const Color(0xFFFEF3C7) : appState.bgSubtle),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            matchPct >= 70
                                ? Icons.check_circle_rounded
                                : (matchPct >= 40 ? Icons.inventory_2_outlined : Icons.kitchen_outlined),
                            size: 12,
                            color: matchPct >= 70
                                ? AppTheme.accentGreen
                                : (matchPct >= 40 ? const Color(0xFFD97706) : AppTheme.textMuted),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$matchPct% in kitchen ($haveCount/$totalCount)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: matchPct >= 70
                                  ? AppTheme.accentGreen
                                  : (matchPct >= 40 ? const Color(0xFFD97706) : AppTheme.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),

                    _buildMetaBadge(
                      Icons.timer_outlined,
                      r.cookingTime,
                      appState,
                    ),
                    _buildMetaBadge(
                      Icons.tune_rounded,
                      r.difficulty,
                      appState,
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1, color: appState.bgSubtle),

          // -----------------------------------------------------------------
          // 2. INGREDIENTS SECTION (WITH SERVINGS SCALER & INVENTORY STATUS)
          // -----------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'INGREDIENTS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: AppTheme.textMuted,
                      ),
                    ),

                    // Interactive Servings Scaler [-] 2 Servings [+]
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: appState.bgSubtle,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: _servings > 1
                                ? () {
                                    setState(() {
                                      _servings--;
                                    });
                                  }
                                : null,
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Icon(
                                Icons.remove_rounded,
                                size: 14,
                                color: _servings > 1 ? AppTheme.textMain : AppTheme.textLight,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '$_servings ${_servings == 1 ? 'serving' : 'servings'}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textMain,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: _servings < 12
                                ? () {
                                    setState(() {
                                      _servings++;
                                    });
                                  }
                                : null,
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Icon(
                                Icons.add_rounded,
                                size: 14,
                                color: _servings < 12 ? AppTheme.textMain : AppTheme.textLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Ingredients list with live inventory badge
                ...r.ingredients.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final rawIng = entry.value;
                  final scaledIng = ServingsScaler.scaleAmount(rawIng, _baseServings, _servings) ?? rawIng;
                  final isChecked = _checkedIngredients.contains(idx);

                  // Check if in fridge/pantry
                  final matchedItem = PantryRecipeSynthesizer.getMatchedFridgeItem(rawIng, appState.fridgeItems);
                  final bool isInKitchen = matchedItem != null;
                  final bool isSingleAdded = _addedSingleItems.contains(idx);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isChecked) {
                          _checkedIngredients.remove(idx);
                        } else {
                          _checkedIngredients.add(idx);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isChecked ? accentColor : Colors.transparent,
                              border: Border.all(
                                color: isChecked ? accentColor : AppTheme.textLight,
                                width: 1.4,
                              ),
                            ),
                            child: isChecked
                                ? const Center(
                                    child: Icon(Icons.check, size: 10, color: Colors.white),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              scaledIng,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: isChecked ? FontWeight.w400 : FontWeight.w500,
                                decoration: isChecked ? TextDecoration.lineThrough : null,
                                color: isChecked ? AppTheme.textMuted : AppTheme.textMain,
                                height: 1.35,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Live Inventory Tag or Add to Shopping Action
                          if (isInKitchen)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.bgGreenLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '✓ In ${matchedItem.location.name}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.accentGreen,
                                ),
                              ),
                            )
                          else
                            InkWell(
                              onTap: isSingleAdded
                                  ? null
                                  : () => _handleAddSingleToShopping(appState, idx, rawIng),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSingleAdded
                                      ? AppTheme.bgGreenLight
                                      : accentColor.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isSingleAdded ? Icons.check : Icons.add_shopping_cart_rounded,
                                      size: 10,
                                      color: isSingleAdded ? AppTheme.accentGreen : accentColor,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      isSingleAdded ? 'In List' : '+ Want',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isSingleAdded ? AppTheme.accentGreen : accentColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),

                // Batch add missing items action
                if (missingIngredients.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => _handleAddMissingToShopping(appState, missingIngredients),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _addedToShopping ? AppTheme.bgGreenLight : appState.bgSubtle,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _addedToShopping ? Icons.check_circle_rounded : Icons.shopping_bag_outlined,
                            size: 13,
                            color: _addedToShopping ? AppTheme.accentGreen : accentColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _addedToShopping
                                ? 'Added all ${missingIngredients.length} missing items to Want List'
                                : 'Add ${missingIngredients.length} missing items to Shopping Want List',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _addedToShopping ? AppTheme.accentGreen : accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Divider(height: 1, color: appState.bgSubtle),

          // -----------------------------------------------------------------
          // 3. STEP-BY-STEP INSTRUCTIONS SECTION
          // -----------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STEP-BY-STEP INSTRUCTIONS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: AppTheme.textMuted,
                  ),
                ),

                const SizedBox(height: 10),

                ...r.instructions.asMap().entries.map((entry) {
                  final stepNum = entry.key + 1;
                  final stepText = entry.value;

                  // Parse optional "Title: Description" in step
                  String stepTitle = '';
                  String stepBody = stepText;
                  if (stepText.contains(':') && stepText.indexOf(':') < 25) {
                    final split = stepText.split(':');
                    stepTitle = split[0].trim();
                    stepBody = split.sublist(1).join(':').trim();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Number Circle Badge
                        Container(
                          width: 22,
                          height: 22,
                          margin: const EdgeInsets.only(top: 1),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accentColor.withValues(alpha: 0.12),
                          ),
                          child: Center(
                            child: Text(
                              '$stepNum',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Step Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (stepTitle.isNotEmpty) ...[
                                Text(
                                  stepTitle,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textMain,
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],
                              Text(
                                stepBody,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.textMain,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Chef Tip if present
                if (r.chefNote.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 16,
                          color: Color(0xFFD97706),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r.chefNote,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF92400E),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          Divider(height: 1, color: appState.bgSubtle),

          // -----------------------------------------------------------------
          // 4. BOTTOM ACTION FOOTER (COOK NOW, SAVE, TIMER)
          // -----------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Primary: Cook Now Button
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleCookNow(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.restaurant_rounded, size: 16),
                    label: Text(
                      'Cook Now',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Save to My Recipes Button
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    onPressed: _isSaved ? null : () => _handleSave(appState),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _isSaved ? AppTheme.accentGreen : AppTheme.textMain,
                      side: BorderSide(
                        color: _isSaved ? AppTheme.accentGreen : appState.bgSubtle,
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      _isSaved ? Icons.check_circle_rounded : Icons.bookmark_add_outlined,
                      size: 15,
                    ),
                    label: Text(
                      _isSaved ? 'Saved' : 'Save',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Cooking Timer Button
                IconButton(
                  onPressed: () => _showTimerDialog(context, parsedMinutes),
                  style: IconButton.styleFrom(
                    backgroundColor: appState.bgSubtle,
                    padding: const EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.timer_outlined, size: 18),
                  tooltip: 'Timer (${parsedMinutes}m)',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaBadge(IconData icon, String label, AppState appState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: appState.bgSubtle,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
