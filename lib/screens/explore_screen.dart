import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/explore_filters.dart';
import '../widgets/floating_draggable_random_picker.dart';
import '../widgets/recipe_card.dart';
import '../widgets/view_mode_toggle.dart';
import '../utils/responsive_utils.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final recipes = appState.filteredRecipes;
    final accentColor = appState.accentColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            SafeArea(
              child: RefreshIndicator(
                color: accentColor,
                backgroundColor: appState.bgCard,
                onRefresh: () async {
                  final result = await appState.refreshPantryMatchesWithThinking();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result.message),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: CustomScrollView(
                  slivers: [
                    // 1. Editorial Minimalist Brand Header (Ins style)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Brand Mark: 식 · SIK · STUDIO
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '식',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: accentColor,
                                        letterSpacing: -0.8,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'SIK',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textMain,
                                        letterSpacing: 2.0,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 3,
                                      height: 3,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.textLight,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'STUDIO',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.6,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),

                                // Location & Actions
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () async {
                                        final result = await appState.refreshPantryMatchesWithThinking();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(result.message),
                                              duration: const Duration(seconds: 2),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: appState.bgCard,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: appState.bgSubtle, width: 0.8),
                                        ),
                                        child: Center(
                                          child: appState.isThinkingPantry
                                              ? SizedBox(
                                                  width: 13,
                                                  height: 13,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 1.8,
                                                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.refresh_rounded,
                                                  size: 15,
                                                  color: AppTheme.textMuted,
                                                ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () => appState.toggleRandomPickerVisible(),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: appState.isRandomPickerVisible
                                              ? accentColor.withValues(alpha: 0.12)
                                              : appState.bgCard,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: appState.isRandomPickerVisible
                                                ? accentColor
                                                : appState.bgSubtle,
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            appState.isRandomPickerVisible
                                                ? Icons.shuffle_rounded
                                                : Icons.shuffle_outlined,
                                            size: 15,
                                            color: appState.isRandomPickerVisible
                                                ? accentColor
                                                : AppTheme.textMuted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Cook with what you have  ·  Change it your way',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textMuted.withValues(alpha: 0.85),
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 1.5 Studio Culinary Engine Thinking State Banner
                    if (appState.isThinkingPantry)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: appState.bgCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: accentColor.withValues(alpha: 0.35)),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '식 CULINARY ENGINE',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.2,
                                              color: accentColor,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            width: 4,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: accentColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'ANALYZING',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1.0,
                                              color: AppTheme.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Reasoning through pantry items & synthesizing 100% matched dishes...',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

              // 2. Active AI Search Banner (if user typed prompt in floating AI bar)
              if (appState.currentAiQuery.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 13.5,
                            color: accentColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Showing matches for "${appState.currentAiQuery}"',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, size: 16, color: accentColor),
                            onPressed: () => appState.clearAiQuery(),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // 2.5 Inventory Empty Notice Banner
              if (appState.fridgeItems.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: appState.bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: appState.bgSubtle),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 15, color: AppTheme.textMuted),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'Kitchen inventory is empty · Add items in Fridge to calculate pantry match suggestions',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => appState.setActiveTab(AppState.tabFridge),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Text(
                                '+ Add',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: accentColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 3. Unified Editorial Action Bar (Dishes Count, Filter Pill & View Mode)
              // 3. Unified Editorial Action Bar (Dishes Count, Filter, Sort & View Mode)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth - 40,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${recipes.length} ${recipes.length == 1 ? 'dish' : 'dishes'}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textMain,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: const BoxDecoration(
                                  color: AppTheme.textLight,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: _buildInlineFilterSortPill(context, appState),
                              ),
                            ],
                          ),
                          ViewModeToggle(
                            isGrid: appState.isRecipeGridView,
                            onChanged: (isGrid) => appState.setRecipeViewMode(isGrid),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Category Pills & Cooking Method Filters (Seamless Drawer)
              const SliverToBoxAdapter(
                child: ExploreFilters(),
              ),

              // 5. Recipe Feed (Grid or List View)
              recipes.isNotEmpty
                  ? SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        constraints.maxWidth >= 900 ? 28 : 20,
                        0,
                        constraints.maxWidth >= 900 ? 28 : 20,
                        12,
                      ),
                      sliver: appState.isRecipeGridView
                          ? SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: ResponsiveUtils.getGridColumnCount(constraints.maxWidth),
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: constraints.maxWidth >= 768 ? 1.34 : 1.10,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final recipe = recipes[index];
                                  return RecipeCard(recipe: recipe, isGrid: true);
                                },
                                childCount: recipes.length,
                              ),
                            )
                          : constraints.maxWidth >= 768
                              ? SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, rowIndex) {
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
                                    childCount: (recipes.length / 2).ceil(),
                                  ),
                                )
                              : SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final recipe = recipes[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 14),
                                        child: RecipeCard(recipe: recipe, isGrid: false),
                                      );
                                    },
                                    childCount: recipes.length,
                                  ),
                                ),
                    )
              // 6. Bottom "Explore More" Discovery Card
              : const SliverToBoxAdapter(child: SizedBox.shrink()),
              if (recipes.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      constraints.maxWidth >= 900 ? 28 : 20,
                      4,
                      constraints.maxWidth >= 900 ? 28 : 20,
                      150,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: appState.bgCard,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: appState.bgSubtle,
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.025),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Studio Badge & Tag
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '식',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: accentColor,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'STUDIO CURATION',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.8,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '3–4 Staples',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: accentColor,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Headline
                          Text(
                            'Minimalist Everyday Recipes',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textMain,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 5),

                          // Description
                          Text(
                            'Quick, authentic dishes made with few ingredients and high pantry compatibility. No complex ingredients required.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textMuted.withValues(alpha: 0.9),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Feature Micro-Tags
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildDiscoveryPill(Icons.kitchen_outlined, 'Pantry Staples', appState),
                              _buildDiscoveryPill(Icons.timer_outlined, 'Under 15 Mins', appState),
                              _buildDiscoveryPill(Icons.auto_awesome, 'High Match Rate', appState),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (recipes.isEmpty)
                SliverToBoxAdapter(
                  child: appState.fridgeItems.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(36, 48, 36, 150),
                          child: Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.kitchen_outlined, size: 28, color: accentColor),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Your kitchen inventory is empty',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textMain,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add ingredients to your kitchen inventory to automatically discover recipes tailored to what you have.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: AppTheme.textMuted,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () => appState.setActiveTab(AppState.tabFridge),
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Go to Kitchen'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                                  elevation: 0,
                                ),
                              ),
                            ],
                          ),
                        )
                          : Padding(
                              padding: const EdgeInsets.fromLTRB(40, 40, 40, 150),
                              child: Column(
                                children: [
                                  const Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textLight),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No recipes found',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textMain,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Try clearing your filters or asking 식 AI for ideas.',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      appState.setFilter('All');
                                      appState.setCookingMethod('All');
                                      appState.clearAiQuery();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.textMain,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Clear Filters'),
                                  ),
                                ],
                              ),
                            ),
                    ),
              ],
            ),
          ),
        ),
        if (appState.isRandomPickerVisible)
          FloatingDraggableRandomPicker(
            parentWidth: constraints.maxWidth,
            parentHeight: constraints.maxHeight,
            onClose: () => appState.setRandomPickerVisible(false),
          ),
      ],
    );
  },
);
  }

  // Refined, Minimalist Merged Filter & Sort Pill
  Widget _buildInlineFilterSortPill(BuildContext context, AppState appState) {
    final hasCategoryFilter = appState.selectedFilter != 'All';
    final hasMethodFilter = appState.selectedCookingMethod != 'All';
    final hasCustomSort = appState.selectedSortOption != 'match';
    final hasActiveSettings = hasCategoryFilter || hasMethodFilter || hasCustomSort;
    final isExpanded = appState.isFilterExpanded;
    final accentColor = appState.accentColor;

    String label = 'Filter & Sort';
    if (hasCategoryFilter && hasMethodFilter) {
      label = '${appState.selectedFilter} · ${appState.selectedCookingMethod}';
    } else if (hasCategoryFilter) {
      label = appState.selectedFilter;
    } else if (hasMethodFilter) {
      label = appState.selectedCookingMethod;
    } else if (hasCustomSort) {
      String sortLabel = 'Pantry Match';
      if (appState.selectedSortOption == 'time') sortLabel = 'Quickest';
      if (appState.selectedSortOption == 'fewest_ingredients') sortLabel = 'Fewest Items';
      if (appState.selectedSortOption == 'alphabetical') sortLabel = 'A to Z';
      label = 'Sort: $sortLabel';
    }

    final activeColor = isExpanded || hasActiveSettings ? accentColor : AppTheme.textMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => appState.toggleFilterExpanded(),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
            decoration: BoxDecoration(
              color: isExpanded || hasActiveSettings
                  ? accentColor.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: isExpanded || hasActiveSettings ? FontWeight.w700 : FontWeight.w600,
                      color: isExpanded || hasActiveSettings ? accentColor : AppTheme.textMain,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 3),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: activeColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasActiveSettings) ...[
          const SizedBox(width: 6),
          InkWell(
            onTap: () {
              appState.setFilter('All');
              appState.setCookingMethod('All');
              appState.setSortOption('match');
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                'Clear',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textLight,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDiscoveryPill(IconData icon, String label, AppState appState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: appState.bgSubtle,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.5, color: AppTheme.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
