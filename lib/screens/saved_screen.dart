import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/recipe_card.dart';
import '../widgets/view_mode_toggle.dart';
import '../utils/responsive_utils.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildPillTab(BuildContext context, int index, String label) {
    final isSelected = _tabController.index == index;
    final appState = context.watch<AppState>();
    final bgCard = appState.bgCard;
    final accentColor = appState.accentColor;

    return InkWell(
      onTap: () {
        _tabController.animateTo(index);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : appState.bgSubtle,
            width: 0.8,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final allRecipes = appState.recipes;
    final savedRecipes = allRecipes.where((r) => r.isSaved).toList();
    final favoriteRecipes = allRecipes.where((r) => r.isFavorite || r.isSaved).toList();
    final wantToTryRecipes = allRecipes.where((r) => r.kitchenMatchPercent >= 90).toList();
    final cookedRecipes = appState.cookedHistory;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Atelier Mark
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '식',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: appState.accentColor,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ARCHIVE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Personal collection · Favorites · Cooked history',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Sub-Navigation Horizontal Pill List (Clean Korean Minimalist Aesthetics)
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildPillTab(context, 0, 'Saved Recipes'),
                const SizedBox(width: 6),
                _buildPillTab(context, 1, 'Favorites'),
                const SizedBox(width: 6),
                _buildPillTab(context, 2, 'Want to Try'),
                const SizedBox(width: 6),
                _buildPillTab(context, 3, 'Cooked History'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // TabBarView Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRecipeGrid(context, savedRecipes, 'No saved recipes yet', 'Tap the heart icon on any recipe to save it here.'),
                _buildRecipeGrid(context, favoriteRecipes, 'No favorites yet', 'Starred favorites will appear in this section.'),
                _buildRecipeGrid(context, wantToTryRecipes, 'No high-match recipes found', 'Recipes matching 90%+ of your fridge will appear here.'),
                _buildRecipeGrid(context, cookedRecipes, 'No cooked recipes yet', 'Recipes you finish cooking will be saved in your history.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeGrid(BuildContext context, List<Recipe> recipes, String emptyTitle, String emptySub) {
    final appState = context.watch<AppState>();

    if (recipes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: appState.bgCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: appState.bgSubtle, width: 0.8),
                ),
                child: const Center(
                  child: Icon(Icons.bookmark_border_rounded, size: 24, color: AppTheme.textLight),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                emptyTitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                emptySub,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: AppTheme.textMuted,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Sub-toolbar with count & view mode toggle
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${recipes.length} ${recipes.length == 1 ? 'recipe' : 'recipes'}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                ),
              ),
              ViewModeToggle(
                isGrid: appState.isRecipeGridView,
                onChanged: (isGrid) => appState.setRecipeViewMode(isGrid),
              ),
            ],
          ),
        ),

        // List or Grid View Content
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cols = ResponsiveUtils.getGridColumnCount(constraints.maxWidth);

              return appState.isRecipeGridView
                  ? GridView.builder(
                      padding: EdgeInsets.fromLTRB(
                        constraints.maxWidth >= 900 ? 28 : 20,
                        0,
                        constraints.maxWidth >= 900 ? 28 : 20,
                        150,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: constraints.maxWidth >= 768 ? 1.34 : 1.10,
                      ),
                      itemCount: recipes.length,
                      itemBuilder: (context, index) {
                        final recipe = recipes[index];
                        return RecipeCard(recipe: recipe, isGrid: true);
                      },
                    )
                  : constraints.maxWidth >= 768
                      ? ListView.builder(
                          padding: EdgeInsets.fromLTRB(
                            constraints.maxWidth >= 900 ? 28 : 20,
                            0,
                            constraints.maxWidth >= 900 ? 28 : 20,
                            150,
                          ),
                          itemCount: (recipes.length / 2).ceil(),
                          itemBuilder: (context, rowIndex) {
                            final firstIndex = rowIndex * 2;
                            final secondIndex = firstIndex + 1;
                            final hasSecond = secondIndex < recipes.length;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: RecipeCard(
                                      recipe: recipes[firstIndex],
                                      isGrid: false,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: hasSecond
                                        ? RecipeCard(
                                            recipe: recipes[secondIndex],
                                            isGrid: false,
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(
                            constraints.maxWidth >= 900 ? 28 : 20,
                            0,
                            constraints.maxWidth >= 900 ? 28 : 20,
                            150,
                          ),
                          itemCount: recipes.length,
                          itemBuilder: (context, index) {
                            final recipe = recipes[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: RecipeCard(recipe: recipe, isGrid: false),
                            );
                          },
                        );
            },
          ),
        ),
      ],
    );
  }
}
