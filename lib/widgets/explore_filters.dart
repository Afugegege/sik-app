import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class ExploreFilters extends StatelessWidget {
  const ExploreFilters({super.key});

  static const List<({String id, String label, IconData icon})> sortOptions = [
    (id: 'match', label: 'Pantry Match', icon: Icons.kitchen_outlined),
    (id: 'time', label: 'Quickest', icon: Icons.timer_outlined),
    (id: 'fewest_ingredients', label: 'Fewest Items', icon: Icons.restaurant_menu_outlined),
    (id: 'alphabetical', label: 'A to Z', icon: Icons.sort_by_alpha_rounded),
  ];

  static const List<String> categories = [
    'All',
    'Cook with what you have',
    'Almost there',
    'Need Groceries',
    'Easy to find near you',
    'Quick & Simple',
    'Pastry & Dessert',
    'Baking',
    'Drinks',
  ];

  static const List<String> methods = [
    'All',
    'Stovetop',
    'Oven',
    'Air Fryer',
    'Microwave',
    'No-cook',
  ];

  static IconData getCategoryIcon(String cat) {
    final lower = cat.toLowerCase();
    if (lower.contains('need groceries') || lower.contains('grocer')) {
      return Icons.shopping_cart_outlined;
    }
    if (lower.contains('dessert') || lower.contains('pastry')) {
      return Icons.icecream_rounded;
    }
    if (lower.contains('drink') || lower.contains('beverage')) {
      return Icons.local_cafe_rounded;
    }
    if (lower.contains('baking')) {
      return Icons.bakery_dining_rounded;
    }
    if (lower.contains('quick') || lower.contains('simple')) {
      return Icons.bolt_rounded;
    }
    if (lower.contains('cook with what you have')) {
      return Icons.kitchen_rounded;
    }
    if (lower.contains('almost there')) {
      return Icons.timelapse_rounded;
    }
    if (lower.contains('easy to find')) {
      return Icons.storefront_rounded;
    }
    return Icons.restaurant_menu_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final accentColor = appState.accentColor;
    final isExpanded = appState.isFilterExpanded;
    final hasCategoryFilter = appState.selectedFilter != 'All';
    final hasMethodFilter = appState.selectedCookingMethod != 'All';
    final hasCustomSort = appState.selectedSortOption != 'match';
    final hasActiveFilter = hasCategoryFilter || hasMethodFilter || hasCustomSort;

    return ClipRect(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOutCubic,
        alignment: Alignment.topCenter,
        child: isExpanded
            ? _buildExpandedDrawer(context, appState, accentColor, hasActiveFilter)
            : const SizedBox.shrink(),
      ),
    );
  }

  // Expanded Drawer View: Sort Options, Category Pills and Cooking Method Chips
  Widget _buildExpandedDrawer(
    BuildContext context,
    AppState appState,
    Color accentColor,
    bool hasActiveFilter,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Horizontal Sort Options Row
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: sortOptions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final opt = sortOptions[index];
                final isSelected = appState.selectedSortOption == opt.id;

                return InkWell(
                  onTap: () => appState.setSortOption(opt.id),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor.withValues(alpha: 0.12) : appState.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? accentColor : appState.bgSubtle,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          opt.icon,
                          size: 12.5,
                          color: isSelected ? accentColor : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          opt.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? accentColor : AppTheme.textMuted,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.check_rounded,
                            size: 11.5,
                            color: accentColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // 2. Horizontal Category Filter Pills
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = appState.selectedFilter == cat;
                final icon = getCategoryIcon(cat);

                return InkWell(
                  onTap: () => appState.setFilter(cat),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor : appState.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? accentColor : appState.bgSubtle,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 13,
                          color: isSelected ? Colors.white : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 5.5),
                        Text(
                          cat,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppTheme.textMain,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Horizontal Cooking Method Filter Chips
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: methods.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final method = methods[index];
                final isSelected = appState.selectedCookingMethod == method;

                return InkWell(
                  onTap: () => appState.setCookingMethod(method),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor.withValues(alpha: 0.12) : appState.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? accentColor : appState.bgSubtle,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          Icon(
                            Icons.check_rounded,
                            size: 12,
                            color: accentColor,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          method == 'All' ? 'Any Method' : method,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? accentColor : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
