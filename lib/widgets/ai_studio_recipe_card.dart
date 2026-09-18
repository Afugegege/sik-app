import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/ai_chat_message.dart';
import '../models/recipe.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'cooking_timer_widget.dart';

/// An aesthetic, premium Korean Ins studio recipe card component that replaces
/// plain raw markdown text with an elegant, structured recipe design.
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
  final Set<int> _checkedIngredients = {};

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
      cookingMethod: widget.recipe.category,
      difficulty: widget.recipe.difficulty,
      kitchenMatchPercent: 100,
      category: widget.recipe.category,
      ingredients: widget.recipe.ingredients
          .map((item) => RecipeIngredient(name: item, status: 'have'))
          .toList(),
      cookingSteps: widget.recipe.instructions,
      isSaved: true,
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

  void _handleAddShopping(AppState appState) {
    appState.addMultipleToWantList(widget.recipe.ingredients);
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
                'Added ${widget.recipe.ingredients.length} items to Shopping Want List',
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

    return Container(
      margin: const EdgeInsets.only(left: 36, top: 8, bottom: 4),
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

                // Meta Chips Row
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
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
                    if (r.servings > 0)
                      _buildMetaBadge(
                        Icons.people_outline_rounded,
                        '${r.servings} ${r.servings == 1 ? 'serving' : 'servings'}',
                        appState,
                      ),
                    _buildMetaBadge(
                      Icons.kitchen_outlined,
                      '${r.ingredients.length} items',
                      appState,
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1, color: appState.bgSubtle),

          // -----------------------------------------------------------------
          // 2. INGREDIENTS SECTION
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
                    InkWell(
                      onTap: () => _handleAddShopping(appState),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _addedToShopping ? Icons.check_circle_rounded : Icons.add_shopping_cart_rounded,
                              size: 13,
                              color: _addedToShopping ? AppTheme.accentGreen : accentColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _addedToShopping ? 'Added to List' : 'Add to Want List',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _addedToShopping ? AppTheme.accentGreen : accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Ingredients list
                ...r.ingredients.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final ing = entry.value;
                  final isChecked = _checkedIngredients.contains(idx);

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
                              ing,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: isChecked ? FontWeight.w400 : FontWeight.w500,
                                decoration: isChecked ? TextDecoration.lineThrough : null,
                                color: isChecked ? AppTheme.textMuted : AppTheme.textMain,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
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
          // 4. BOTTOM ACTION FOOTER
          // -----------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Save to My Recipes Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaved ? null : () => _handleSave(appState),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSaved ? AppTheme.accentGreen : accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: Icon(
                      _isSaved ? Icons.check_circle_rounded : Icons.bookmark_add_outlined,
                      size: 16,
                    ),
                    label: Text(
                      _isSaved ? 'Saved to Recipes' : 'Save to My Recipes',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Cooking Timer Button
                OutlinedButton.icon(
                  onPressed: () => _showTimerDialog(context, parsedMinutes),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accentColor,
                    side: BorderSide(color: accentColor.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.timer_outlined, size: 16),
                  label: Text(
                    'Timer (${parsedMinutes}m)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
