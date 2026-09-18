import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../providers/app_state.dart';
import '../services/recipe_taste_evaluator.dart';
import '../services/recipe_step_adapter.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_modification_modal.dart';
import '../widgets/photo_action_sheet.dart';
import 'cooking_mode_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final Set<String> _removedIngredients = {};
  final Map<String, TasteAlternative> _substitutions = {};
  bool _isEnhancingDetail = false;
  bool _isDetailEnhanced = false;
  List<String>? _enhancedSteps;

  /// Enhances brief flash-generated recipe steps into detailed, serious cooking instructions.
  /// Adds specific temperatures, exact timings, technique cues, and sensory checkpoints.
  void _enhanceRecipeDetail(Recipe recipe) {
    if (_isEnhancingDetail || _isDetailEnhanced) return;
    setState(() => _isEnhancingDetail = true);

    // Simulate AI processing delay for realism
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      final enhanced = recipe.cookingSteps.map((step) {
        return _expandStepDetail(step, recipe);
      }).toList();
      setState(() {
        _enhancedSteps = enhanced;
        _isDetailEnhanced = true;
        _isEnhancingDetail = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recipe detail enhanced with precise instructions'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  /// Expands a single brief cooking step into a detailed instruction with specific
  /// temperatures, timings, techniques, and sensory cues based on culinary heuristics.
  String _expandStepDetail(String step, Recipe recipe) {
    final lower = step.toLowerCase();
    final buffer = StringBuffer(step);

    // Add heat-specific detail
    if (lower.contains('heat') || lower.contains('pan') || lower.contains('wok') || lower.contains('skillet')) {
      if (!lower.contains('°') && !lower.contains('degree')) {
        if (lower.contains('high heat')) {
          buffer.write(' (approx. 220°C / 430°F — oil should shimmer and lightly smoke)');
        } else if (lower.contains('medium-high') || lower.contains('medium high')) {
          buffer.write(' (approx. 190°C / 375°F — a drop of water should sizzle on contact)');
        } else if (lower.contains('medium heat') || lower.contains('medium')) {
          buffer.write(' (approx. 160°C / 320°F — steady gentle sizzle, no spattering)');
        } else if (lower.contains('low heat') || lower.contains('simmer')) {
          buffer.write(' (approx. 120°C / 250°F — tiny bubbles, no active boiling)');
        }
      }
    }

    // Add timing precision
    if (lower.contains('until golden') && !lower.contains('minute') && !lower.contains('min')) {
      buffer.write('. This typically takes 3–4 minutes per side — look for deep golden edges and a nutty aroma.');
    } else if (lower.contains('until soft') && !lower.contains('minute') && !lower.contains('min')) {
      buffer.write('. Usually 5–7 minutes — the pieces should yield easily when pressed with a spatula.');
    } else if (lower.contains('until fragrant') && !lower.contains('second') && !lower.contains('sec')) {
      buffer.write('. About 30–45 seconds — stir constantly to prevent burning. You should smell it before you see color change.');
    } else if (lower.contains('until tender') && !lower.contains('minute') && !lower.contains('min')) {
      buffer.write('. Roughly 8–12 minutes — test by piercing with a fork; it should slide in with minimal resistance.');
    }

    // Add boiling / water detail
    if (lower.contains('boil') && !lower.contains('minute') && !lower.contains('min')) {
      if (lower.contains('pasta') || lower.contains('noodle')) {
        buffer.write('. Use plenty of salted water (1 tbsp salt per liter). Stir within the first 30 seconds to prevent sticking.');
      } else if (lower.contains('egg')) {
        buffer.write('. For soft-boiled: 6–7 minutes from boiling. For hard-boiled: 10–12 minutes. Transfer immediately to ice water.');
      }
    }

    // Add oil detail
    if (lower.contains('add oil') || lower.contains('drizzle oil') || lower.contains('pour oil')) {
      if (!lower.contains('tbsp') && !lower.contains('tablespoon') && !lower.contains('ml')) {
        buffer.write(' (about 1–2 tablespoons, enough to coat the cooking surface evenly)');
      }
    }

    // Add rice-specific detail
    if (lower.contains('rice') && (lower.contains('cook') || lower.contains('steam'))) {
      if (!lower.contains('ratio') && !lower.contains('water')) {
        buffer.write('. Standard ratio: 1 cup rice to 1.2 cups water for short-grain, 1:1.5 for long-grain. Let it rest covered for 10 minutes after cooking.');
      }
    }

    // Add seasoning check
    if (lower.contains('season') || lower.contains('salt') || lower.contains('taste')) {
      if (!lower.contains('pinch') && !lower.contains('tsp')) {
        buffer.write(' — always season incrementally and taste as you go. You can add more, but you cannot take it back.');
      }
    }

    // Add garnish / plating cue
    if (lower.contains('serve') || lower.contains('plate') || lower.contains('garnish')) {
      buffer.write('. Plate while hot for best presentation — pre-warm your serving dishes if possible.');
    }

    // Add mixing / stirring precision
    if (lower.contains('mix') || lower.contains('stir') || lower.contains('combine')) {
      if (lower.contains('batter') || lower.contains('flour') || lower.contains('dough')) {
        buffer.write('. Fold gently to avoid overworking the gluten — stop as soon as no dry streaks remain.');
      }
    }

    // Add marinating specifics
    if (lower.contains('marinat') || lower.contains('marinate')) {
      if (!lower.contains('minute') && !lower.contains('hour') && !lower.contains('min')) {
        buffer.write('. Minimum 15 minutes at room temperature, or ideally 30 minutes to 2 hours refrigerated for deeper flavor penetration.');
      }
    }

    return buffer.toString();
  }


  void _showQuickAiPromptDialog(BuildContext context, Recipe currentRecipe) {
    final appState = context.read<AppState>();
    final accentColor = appState.accentColor;
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: appState.bgPrimary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: accentColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Modify Recipe with AI',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMain,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Preset Prompt Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _presetChip(context, currentRecipe, 'make it simpler', appState.bgCard),
                    _presetChip(context, currentRecipe, 'remove mushrooms', appState.bgCard),
                    _presetChip(context, currentRecipe, 'make this an air fryer recipe', appState.bgCard),
                    _presetChip(context, currentRecipe, 'I don\'t want to buy anything', appState.bgCard),
                  ],
                ),

                const SizedBox(height: 16),

                // Custom Input Field
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: appState.bgSubtle),
                  ),
                  child: TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      hintText: 'e.g. "make it spicy", "vegan version"',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textLight,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final query = textController.text.trim();
                      if (query.isNotEmpty) {
                        Navigator.pop(context);
                        AiModificationModal.show(context, currentRecipe, query);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Preview AI Diff',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _presetChip(BuildContext context, Recipe currentRecipe, String label, Color bgCard) {
    return ActionChip(
      label: Text(label),
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.textMain,
      ),
      backgroundColor: bgCard,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onPressed: () {
        Navigator.pop(context);
        AiModificationModal.show(context, currentRecipe, label);
      },
    );
  }

  void _showSubstitutesSheet(BuildContext context, Recipe currentRecipe, TasteImpactResult impact) {
    final appState = context.read<AppState>();
    final accentColor = appState.accentColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              decoration: BoxDecoration(
                color: appState.bgPrimary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.textLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.swap_horiz_rounded, color: AppTheme.textMain, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Ingredient Substitutes',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textMain,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  Text(
                    'Culinary substitutes to restore flavor profile & balance',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 18),

                  Expanded(
                    child: ListView(
                      children: _removedIngredients.map((removedIng) {
                        final alts = RecipeTasteEvaluator.getAlternativesForIngredient(removedIng);
                        final activeSub = _substitutions[removedIng];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 18),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: appState.bgCard,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: appState.bgSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.remove_circle_outline, size: 16, color: Colors.redAccent.shade200),
                                  const SizedBox(width: 6),
                                  Text(
                                    'For removed: $removedIng',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textMain,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              if (alts.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'No direct culinary substitute needed; seasoned to taste.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                )
                              else
                                ...alts.map((alt) {
                                  final isCurrentSub = activeSub?.name == alt.name;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isCurrentSub
                                          ? accentColor.withValues(alpha: 0.1)
                                          : AppTheme.bgSurface,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isCurrentSub
                                            ? accentColor
                                            : appState.bgSubtle,
                                        width: isCurrentSub ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Wrap(
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                spacing: 6,
                                                runSpacing: 4,
                                                children: [
                                                  Text(
                                                    alt.name,
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 13.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppTheme.textMain,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.bgGreenLight,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      '+${alt.tasteRestoration.toStringAsFixed(1)} Taste',
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.w700,
                                                        color: AppTheme.accentGreen,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                alt.culinaryNote,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 12,
                                                  color: AppTheme.textMuted,
                                                  height: 1.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              if (isCurrentSub) {
                                                _substitutions.remove(removedIng);
                                              } else {
                                                _substitutions[removedIng] = alt;
                                              }
                                            });
                                            setSheetState(() {});
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  isCurrentSub
                                                      ? 'Removed substitution for $removedIng'
                                                      : 'Applied ${alt.name}! Taste score updated.',
                                                ),
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isCurrentSub ? AppTheme.accentGreen : AppTheme.textMain,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: Text(
                                            isCurrentSub ? 'Active' : 'Use Alt',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textMain,
                        side: BorderSide(color: appState.bgSubtle),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Done',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final accentColor = appState.accentColor;

    final currentRecipe = appState.recipes.firstWhere(
      (r) => r.id == widget.recipe.id,
      orElse: () => widget.recipe,
    );

    final hasImage = currentRecipe.hasImage;
    final missingIngs = currentRecipe.ingredients.where((i) => i.status == 'missing').toList();

    // AI Taste impact calculation
    final TasteImpactResult? tasteImpact = _removedIngredients.isNotEmpty
        ? RecipeTasteEvaluator.evaluateCombined(
            recipe: currentRecipe,
            removedIngredients: _removedIngredients,
            substitutions: _substitutions,
          )
        : null;

    // Dynamic cooking step adaptation for removed ingredients / substitutions
    // Use enhanced steps when user has tapped 'Add Detail' for serious cooking
    final baseSteps = _enhancedSteps ?? currentRecipe.cookingSteps;
    final adaptedSteps = RecipeStepAdapter.adaptSteps(
      cookingSteps: baseSteps,
      removedIngredients: _removedIngredients,
      substitutions: _substitutions,
    );
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= 768;

    if (isTablet) {
      return _buildTabletLayout(
        context,
        appState,
        currentRecipe,
        accentColor,
        hasImage,
        missingIngs,
        tasteImpact,
        adaptedSteps,
      );
    }

    return _buildMobileLayout(
      context,
      appState,
      currentRecipe,
      accentColor,
      hasImage,
      missingIngs,
      tasteImpact,
      adaptedSteps,
    );
  }

  // ===========================================================================
  // MOBILE SINGLE-COLUMN LAYOUT (< 768px)
  // ===========================================================================
  Widget _buildMobileLayout(
    BuildContext context,
    AppState appState,
    Recipe currentRecipe,
    Color accentColor,
    bool hasImage,
    List<RecipeIngredient> missingIngs,
    TasteImpactResult? tasteImpact,
    List<AdaptedStep> adaptedSteps,
  ) {
    return Scaffold(
      backgroundColor: appState.bgPrimary,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 760),
          color: appState.bgPrimary,
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // App Bar: Compact navigation when no image, or Hero Image when image exists
                  if (hasImage)
                    SliverAppBar(
                      expandedHeight: 280,
                      pinned: true,
                      backgroundColor: appState.bgPrimary,
                      leading: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.white.withValues(alpha: 0.85),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textMain, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                      actions: [
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: CircleAvatar(
                            backgroundColor: Colors.white.withValues(alpha: 0.85),
                            child: IconButton(
                              icon: Icon(Icons.camera_alt_outlined, color: accentColor, size: 18),
                              tooltip: 'Record dish photo',
                              onPressed: () => PhotoActionSheet.show(context, currentRecipe),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: CircleAvatar(
                            backgroundColor: Colors.white.withValues(alpha: 0.85),
                            child: IconButton(
                              icon: const Icon(Icons.share_outlined, color: AppTheme.textMain, size: 18),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Recipe link copied to clipboard!')),
                                );
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircleAvatar(
                            backgroundColor: Colors.white.withValues(alpha: 0.85),
                            child: IconButton(
                              icon: Icon(
                                currentRecipe.isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: currentRecipe.isSaved ? Colors.redAccent : AppTheme.textMain,
                                size: 20,
                              ),
                              onPressed: () => appState.toggleSaveRecipe(currentRecipe.id),
                            ),
                          ),
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: Image.network(
                          currentRecipe.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: appState.bgCard,
                            child: Icon(currentRecipe.categoryIcon, color: AppTheme.textLight, size: 48),
                          ),
                        ),
                      ),
                    )
                  else
                    // COMPACT Header for non-image recipes
                    SliverAppBar(
                      pinned: true,
                      toolbarHeight: 64,
                      backgroundColor: appState.bgPrimary,
                      elevation: 0,
                      leading: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Center(
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: appState.bgCard,
                              shape: BoxShape.circle,
                              border: Border.all(color: appState.bgSubtle),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textMain, size: 19),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                      ),
                      actions: [
                        Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: appState.bgCard,
                            shape: BoxShape.circle,
                            border: Border.all(color: appState.bgSubtle),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(Icons.camera_alt_outlined, color: accentColor, size: 17),
                            tooltip: 'Record dish photo',
                            onPressed: () => PhotoActionSheet.show(context, currentRecipe),
                          ),
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: appState.bgCard,
                            shape: BoxShape.circle,
                            border: Border.all(color: appState.bgSubtle),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.share_outlined, color: AppTheme.textMain, size: 17),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Recipe link copied to clipboard!')),
                              );
                            },
                          ),
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: appState.bgCard,
                            shape: BoxShape.circle,
                            border: Border.all(color: appState.bgSubtle),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              currentRecipe.isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: currentRecipe.isSaved ? Colors.redAccent : AppTheme.textMain,
                              size: 18,
                            ),
                            onPressed: () => appState.toggleSaveRecipe(currentRecipe.id),
                          ),
                        ),
                      ],
                    ),

                  // Recipe Body Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, hasImage ? 20 : 12, 20, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCategoryKoreanRow(currentRecipe, accentColor),
                          const SizedBox(height: 8),

                          if (currentRecipe.isAiModified) ...[
                            _buildAiModifiedBadge(accentColor),
                            const SizedBox(height: 8),
                          ],

                          // Header: Title & Match Badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  currentRecipe.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textMain,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _buildMatchBadge(currentRecipe),
                            ],
                          ),

                          if (currentRecipe.inspirationNote != null && currentRecipe.inspirationNote!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              '“${currentRecipe.inspirationNote}”',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: AppTheme.textMuted,
                                height: 1.35,
                              ),
                            ),
                          ],

                          const SizedBox(height: 14),

                          // Meta Chips Row
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _detailMetaChip(context, Icons.timer_outlined, '${currentRecipe.cookingTimeMinutes} mins'),
                              _detailMetaChip(context, Icons.soup_kitchen_outlined, currentRecipe.cookingMethod),
                              _detailMetaChip(context, Icons.bar_chart_rounded, currentRecipe.difficulty),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Ingredients Header + Add Missing to Want Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ingredients',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textMain,
                                      ),
                                    ),
                                    Text(
                                      'Tap (–) to exclude an ingredient & preview taste impact',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (missingIngs.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () {
                                    final names = missingIngs.map((i) => i.name).toList();
                                    appState.addMultipleToWantList(names);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Added ${names.length} missing items to Want list!')),
                                    );
                                  },
                                  icon: Icon(Icons.add_shopping_cart_rounded, size: 15, color: accentColor),
                                  label: Text(
                                    'Want list',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: accentColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Interactive Ingredients List
                          ...currentRecipe.ingredients.map((ing) => _buildIngredientCard(context, ing, appState, accentColor)),

                          // Taste Balance Card (if modified)
                          if (tasteImpact != null) ...[
                            const SizedBox(height: 12),
                            _buildTasteBalanceCard(context, appState, currentRecipe, tasteImpact),
                          ],

                          const SizedBox(height: 28),

                          // Instructions Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Instructions',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textMain,
                                    ),
                                  ),
                                  if (adaptedSteps.any((s) => s.isAdapted)) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: appState.bgSubtle,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Adapted',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (_isDetailEnhanced) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: accentColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.auto_awesome, size: 10, color: accentColor),
                                          const SizedBox(width: 3),
                                          Text(
                                            'Enhanced',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: accentColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (!_isDetailEnhanced)
                                _buildEnhanceDetailButton(accentColor, currentRecipe),
                            ],
                          ),
                          const SizedBox(height: 12),

                          ...adaptedSteps.map((step) => _buildInstructionStepCard(context, step, appState, accentColor)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Fixed Bottom Action Bar with Gradient Fading Effect
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IgnorePointer(
                      child: Container(
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              appState.bgPrimary.withValues(alpha: 0.0),
                              appState.bgPrimary,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: appState.bgPrimary,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: OutlinedButton(
                              onPressed: () => _showQuickAiPromptDialog(context, currentRecipe),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: accentColor,
                                side: BorderSide(color: accentColor),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome, size: 15, color: accentColor),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Modify AI',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 6,
                            child: ElevatedButton(
                              onPressed: () => _startCooking(context, currentRecipe, adaptedSteps, accentColor),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Start Cooking',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TABLET DUAL-COLUMN MAGAZINE LAYOUT (>= 768px)
  // ===========================================================================
  Widget _buildTabletLayout(
    BuildContext context,
    AppState appState,
    Recipe currentRecipe,
    Color accentColor,
    bool hasImage,
    List<RecipeIngredient> missingIngs,
    TasteImpactResult? tasteImpact,
    List<AdaptedStep> adaptedSteps,
  ) {
    return Scaffold(
      backgroundColor: appState.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTabletTopBar(context, appState, currentRecipe, accentColor),

            // Dual Column Spread
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // LEFT COLUMN (~42%): Hero Image, Recipe Title, Meta chips, AI Taste card, Action Buttons
                  SizedBox(
                    width: 390,
                    child: Container(
                      decoration: BoxDecoration(
                        color: appState.bgPrimary,
                        border: Border(right: BorderSide(color: appState.bgSubtle, width: 1.0)),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Category & Korean Title
                                  _buildCategoryKoreanRow(currentRecipe, accentColor),
                                  const SizedBox(height: 10),

                                  // AI Modified badge
                                  if (currentRecipe.isAiModified) ...[
                                    _buildAiModifiedBadge(accentColor),
                                    const SizedBox(height: 8),
                                  ],

                                  // Title & Match Badge
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          currentRecipe.title,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.textMain,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildMatchBadge(currentRecipe),
                                    ],
                                  ),

                                  if (currentRecipe.inspirationNote != null && currentRecipe.inspirationNote!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      '“${currentRecipe.inspirationNote}”',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                        color: AppTheme.textMuted,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 12),

                                  // Meta Chips (Time, Method, Difficulty)
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _detailMetaChip(context, Icons.timer_outlined, '${currentRecipe.cookingTimeMinutes} mins'),
                                      _detailMetaChip(context, Icons.soup_kitchen_outlined, currentRecipe.cookingMethod),
                                      _detailMetaChip(context, Icons.bar_chart_rounded, currentRecipe.difficulty),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Hero Image Card ONLY when recipe has an image
                                  if (hasImage) ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: AspectRatio(
                                        aspectRatio: 16 / 10,
                                        child: Image.network(
                                          currentRecipe.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                  ],

                                  // Taste Impact Card if ingredients removed
                                  if (tasteImpact != null) ...[
                                    const SizedBox(height: 14),
                                    _buildTasteBalanceCard(context, appState, currentRecipe, tasteImpact),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // Pinned Action Buttons at Bottom of Left Column
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppTheme.bgSurface,
                              border: Border(top: BorderSide(color: appState.bgSubtle)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showQuickAiPromptDialog(context, currentRecipe),
                                    icon: const Icon(Icons.auto_awesome, size: 15),
                                    label: Text(
                                      'Modify AI',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: accentColor,
                                      side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 6,
                                  child: ElevatedButton(
                                    onPressed: () => _startCooking(context, currentRecipe, adaptedSteps, accentColor),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.textMain,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      'Start Cooking',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // RIGHT COLUMN (~58%): Ingredients & Step-by-Step Instructions
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ingredients Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ingredients',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textMain),
                                    ),
                                    Text(
                                      'Tap (–) to exclude an ingredient & preview taste impact',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              if (missingIngs.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () {
                                    final names = missingIngs.map((i) => i.name).toList();
                                    appState.addMultipleToWantList(names);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Added ${names.length} missing items to Want list!')),
                                    );
                                  },
                                  icon: Icon(Icons.add_shopping_cart_rounded, size: 14, color: accentColor),
                                  label: Text(
                                    'Want list (${missingIngs.length})',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: accentColor),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 2-Column Responsive Grid of Ingredients
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final cardWidth = constraints.maxWidth > 520
                                  ? (constraints.maxWidth - 12) / 2
                                  : constraints.maxWidth;
                              return Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: currentRecipe.ingredients.map((ing) {
                                  return SizedBox(
                                    width: cardWidth,
                                    child: _buildIngredientCard(context, ing, appState, accentColor),
                                  );
                                }).toList(),
                              );
                            },
                          ),

                          const SizedBox(height: 28),

                          // Instructions Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      'Step-by-Step Instructions',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textMain),
                                    ),
                                    if (adaptedSteps.any((s) => s.isAdapted))
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: appState.bgSubtle,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Adapted for your ingredients',
                                          style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
                                        ),
                                      ),
                                    if (_isDetailEnhanced)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: accentColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.auto_awesome, size: 10, color: accentColor),
                                            const SizedBox(width: 3),
                                            Text(
                                              'Enhanced',
                                              style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: accentColor),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (!_isDetailEnhanced)
                                _buildEnhanceDetailButton(accentColor, currentRecipe),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Step Cards
                          ...adaptedSteps.map((step) => _buildInstructionStepCard(context, step, appState, accentColor)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // REUSABLE SUB-COMPONENTS
  // ===========================================================================

  /// Compact "Enhance Detail" button that fits the Korean minimalist theme.
  /// Only visible before enhancement is applied. Shows a loading indicator while processing.
  Widget _buildEnhanceDetailButton(Color accentColor, Recipe recipe) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isEnhancingDetail
          ? Padding(
              key: const ValueKey('loading'),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accentColor,
                ),
              ),
            )
          : InkWell(
              key: const ValueKey('button'),
              onTap: () => _enhanceRecipeDetail(recipe),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded, size: 13, color: accentColor),
                    const SizedBox(width: 5),
                    Text(
                      'Add Detail',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTabletTopBar(BuildContext context, AppState appState, Recipe currentRecipe, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: appState.bgPrimary,
        border: Border(bottom: BorderSide(color: appState.bgSubtle)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 20, color: AppTheme.textMain),
            onPressed: () => Navigator.pop(context),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.camera_alt_outlined, color: accentColor, size: 18),
                tooltip: 'Record dish photo',
                onPressed: () => PhotoActionSheet.show(context, currentRecipe),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: AppTheme.textMain, size: 18),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Recipe link copied to clipboard!')),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  currentRecipe.isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: currentRecipe.isSaved ? Colors.redAccent : AppTheme.textMain,
                  size: 20,
                ),
                onPressed: () => appState.toggleSaveRecipe(currentRecipe.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryKoreanRow(Recipe currentRecipe, Color accentColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(currentRecipe.categoryIcon, size: 13, color: accentColor),
              const SizedBox(width: 5),
              Text(
                currentRecipe.categoryTag,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        if (currentRecipe.koreanTitle.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(
            currentRecipe.koreanTitle,
            style: GoogleFonts.notoSansGothic(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAiModifiedBadge(Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, color: accentColor, size: 12),
          const SizedBox(width: 5),
          Text(
            'AI Modified Version',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchBadge(Recipe currentRecipe) {
    if (currentRecipe.isSimpleClassic) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.accentAmber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.3), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department_rounded, size: 13, color: AppTheme.accentAmber),
            const SizedBox(width: 4),
            Text(
              currentRecipe.kitchenMatchPercent >= 80 ? 'Classic · Ready' : 'Everyday Classic',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.accentAmber,
              ),
            ),
          ],
        ),
      );
    }

    if (currentRecipe.isAspirational) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFDE68A), width: 0.8),
        ),
        child: Text(
          currentRecipe.missingIngredientsCount > 0
              ? '✨ Try This · Need ${currentRecipe.missingIngredientsCount} items'
              : '✨ Chef\'s Inspiration',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFD97706),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.bgGreenLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '${currentRecipe.kitchenMatchPercent}% Match',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.accentGreen,
        ),
      ),
    );
  }

  Widget _buildIngredientCard(
    BuildContext context,
    RecipeIngredient ing,
    AppState appState,
    Color accentColor,
  ) {
    final ingName = ing.name;
    final isRemoved = _removedIngredients.contains(ingName);
    final hasSub = _substitutions.containsKey(ingName);
    final sub = _substitutions[ingName];

    final isHave = ing.status == 'have';
    final isLow = ing.status == 'low';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isRemoved
            ? (hasSub
                ? accentColor.withValues(alpha: 0.07)
                : appState.bgCard.withValues(alpha: 0.5))
            : appState.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRemoved
              ? (hasSub
                  ? accentColor.withValues(alpha: 0.35)
                  : Colors.redAccent.withValues(alpha: 0.25))
              : appState.bgSubtle,
          width: isRemoved ? 1.2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isRemoved
                ? (hasSub ? Icons.swap_horiz_rounded : Icons.remove_circle_rounded)
                : (isHave
                    ? Icons.check_circle_rounded
                    : isLow
                        ? Icons.warning_amber_rounded
                        : Icons.add_circle_outline_rounded),
            size: 17,
            color: isRemoved
                ? (hasSub ? accentColor : Colors.redAccent.shade200)
                : (isHave
                    ? AppTheme.accentGreen
                    : isLow
                        ? AppTheme.accentAmber
                        : AppTheme.textMuted),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        ingName,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isRemoved ? AppTheme.textMuted : AppTheme.textMain,
                          decoration: isRemoved && !hasSub
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: Colors.redAccent,
                        ),
                      ),
                    ),
                    if (ing.amount != null) ...[
                      const SizedBox(width: 5),
                      Text(
                        '• ${ing.amount}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ],
                ),
                if (hasSub) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.swap_horiz_rounded, size: 11, color: AppTheme.textMain),
                      const SizedBox(width: 3),
                      Text(
                        'Sub: ${sub!.name}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMain,
                        ),
                      ),
                    ],
                  ),
                ] else if (isRemoved) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Excluded from recipe',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent.shade200,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isRemoved) ...[
            TextButton(
              onPressed: () {
                setState(() {
                  _removedIngredients.remove(ingName);
                  _substitutions.remove(ingName);
                });
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Restored $ingName'),
                    duration: const Duration(milliseconds: 1400),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                'Restore',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentGreen,
                ),
              ),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded, size: 17),
              color: AppTheme.textMuted,
              tooltip: 'Exclude ingredient',
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(3),
              constraints: const BoxConstraints(),
              onPressed: () {
                setState(() {
                  _removedIngredients.add(ingName);
                });
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Excluded $ingName · Instructions adapted'),
                    duration: const Duration(milliseconds: 1600),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTasteBalanceCard(
    BuildContext context,
    AppState appState,
    Recipe currentRecipe,
    TasteImpactResult tasteImpact,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appState.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: appState.bgSubtle,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Taste Balance',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMain,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: appState.bgSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '10',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textLight,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 9, color: AppTheme.textLight),
                    const SizedBox(width: 4),
                    Text(
                      '${tasteImpact.tasteRating.toStringAsFixed(1)} / 10',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            tasteImpact.explanation,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _showSubstitutesSheet(context, currentRecipe, tasteImpact),
            icon: const Icon(Icons.swap_horiz_rounded, size: 14),
            label: Text(
              _substitutions.isNotEmpty
                  ? 'Substitutes (${_substitutions.length} active)'
                  : 'Find Substitutes',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textMain,
              side: BorderSide(color: appState.bgSubtle, width: 1.2),
              backgroundColor: appState.bgCard,
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStepCard(
    BuildContext context,
    AdaptedStep step,
    AppState appState,
    Color accentColor,
  ) {
    final stepNum = step.stepIndex + 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.all(step.isAdapted ? 10 : 0),
        decoration: BoxDecoration(
          color: step.isAdapted ? appState.bgSubtle.withValues(alpha: 0.35) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: step.isAdapted
              ? Border.all(color: appState.bgSubtle.withValues(alpha: 0.6), width: 0.8)
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: step.isSkipped ? Colors.transparent : AppTheme.textMain,
                shape: BoxShape.circle,
                border: step.isSkipped ? Border.all(color: AppTheme.textLight, width: 1.2) : null,
              ),
              child: Center(
                child: step.isSkipped
                    ? const Icon(Icons.close_rounded, size: 13, color: AppTheme.textLight)
                    : Text(
                        '$stepNum',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (step.adaptationNote != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: appState.bgSubtle,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        step.adaptationNote!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                  Text.rich(
                    TextSpan(
                      children: step.segments.map((seg) {
                        if (seg.isStrikethrough) {
                          return TextSpan(
                            text: seg.text,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: AppTheme.textMuted,
                              color: AppTheme.textMuted,
                            ),
                          );
                        } else if (seg.isSubstitute) {
                          return TextSpan(
                            text: seg.text,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              height: 1.45,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textMain,
                            ),
                          );
                        } else if (seg.isOmittedNote) {
                          return TextSpan(
                            text: seg.text,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              height: 1.45,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textLight,
                            ),
                          );
                        }
                        return TextSpan(
                          text: seg.text,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            height: 1.45,
                            color: step.isSkipped ? AppTheme.textLight : AppTheme.textMain,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startCooking(BuildContext context, Recipe currentRecipe, List<AdaptedStep> adaptedSteps, Color accentColor) {
    final effectiveIngredients = currentRecipe.ingredients.map((ing) {
      if (_substitutions.containsKey(ing.name)) {
        final sub = _substitutions[ing.name]!;
        return RecipeIngredient(
          name: '${sub.name} (sub for ${ing.name})',
          amount: ing.amount,
          status: 'have',
        );
      }
      return ing;
    }).where((ing) => !_removedIngredients.contains(ing.name) || _substitutions.containsKey(ing.name)).toList();

    final cookRecipe = currentRecipe.copyWith(
      ingredients: effectiveIngredients,
      cookingSteps: adaptedSteps.where((s) => !s.isSkipped).map((s) => s.adaptedText).toList(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CookingModeScreen(recipe: cookRecipe),
      ),
    );
  }

  Widget _detailMetaChip(BuildContext context, IconData icon, String label) {
    final bgCard = context.watch<AppState>().bgCard;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.watch<AppState>().bgSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
