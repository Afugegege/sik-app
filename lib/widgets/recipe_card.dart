import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';
import '../models/recipe.dart';
import '../screens/recipe_detail_screen.dart';
import 'photo_action_sheet.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final bool isGrid;

  const RecipeCard({
    super.key,
    required this.recipe,
    this.isGrid = false,
  });

  Color _getMatchColor(int percent) {
    if (percent >= 90) return AppTheme.accentGreen;
    if (percent >= 75) return AppTheme.accentAmber;
    return AppTheme.textLight;
  }

  Color _getMatchBgColor(int percent, AppState appState) {
    if (percent >= 90) return AppTheme.bgGreenLight;
    if (percent >= 75) return const Color(0xFFFEF3C7);
    return appState.bgSubtle;
  }

  Widget _buildSlotBadge(AppState appState, {bool isGrid = false, bool onImage = false}) {
    if (recipe.isSimpleClassic) {
      final color = appState.accentColor;
      final bgColor = onImage ? Colors.white.withValues(alpha: 0.94) : appState.accentColor.withValues(alpha: 0.12);
      final label = isGrid
          ? 'Classic'
          : (recipe.kitchenMatchPercent >= 80
              ? 'Classic · Ready'
              : (recipe.missingIngredientsCount > 0
                  ? 'Classic · ${recipe.missingIngredientsCount} to get'
                  : 'Everyday Classic'));

      return Container(
        padding: EdgeInsets.symmetric(horizontal: isGrid ? 7 : 10, vertical: isGrid ? 3.5 : 4.5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(isGrid ? (onImage ? 8 : 10) : 12),
          border: onImage ? null : Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
          boxShadow: onImage
              ? const [BoxShadow(color: Color(0x15000000), blurRadius: 4)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department_rounded, size: isGrid ? 10 : 12, color: color),
            SizedBox(width: isGrid ? 3 : 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isGrid ? 9.5 : 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (recipe.isAspirational) {
      const color = Color(0xFFD97706);
      final bgColor = onImage ? Colors.white.withValues(alpha: 0.94) : const Color(0xFFFFFBEB);
      final label = isGrid
          ? '✨ Try This'
          : (recipe.missingIngredientsCount > 0
              ? '✨ Try This · ${recipe.missingIngredientsCount} to get'
              : '✨ Try This');

      return Container(
        padding: EdgeInsets.symmetric(horizontal: isGrid ? 7 : 10, vertical: isGrid ? 3.5 : 4.5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(isGrid ? (onImage ? 8 : 10) : 12),
          border: onImage ? null : Border.all(color: const Color(0xFFFDE68A), width: 0.8),
          boxShadow: onImage
              ? const [BoxShadow(color: Color(0x15000000), blurRadius: 4)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isGrid ? 9.5 : 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Default: Pantry Utility
    final matchColor = _getMatchColor(recipe.kitchenMatchPercent);
    final bgColor = onImage ? Colors.white.withValues(alpha: 0.94) : _getMatchBgColor(recipe.kitchenMatchPercent, appState);
    final label = isGrid ? '${recipe.kitchenMatchPercent}%' : '${recipe.kitchenMatchPercent}% Match';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isGrid ? 7 : 10, vertical: isGrid ? 3.5 : 4.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(isGrid ? (onImage ? 8 : 10) : 12),
        boxShadow: onImage
            ? const [BoxShadow(color: Color(0x15000000), blurRadius: 4)]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isGrid ? 5 : 6,
            height: isGrid ? 5 : 6,
            decoration: BoxDecoration(
              color: matchColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isGrid ? 4 : 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isGrid ? 9.5 : 11,
              fontWeight: FontWeight.w700,
              color: matchColor,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMethodIcon(String method) {
    final m = method.toLowerCase();
    if (m.contains('air fryer')) return Icons.air_rounded;
    if (m.contains('oven')) return Icons.cookie_outlined;
    if (m.contains('microwave')) return Icons.microwave_outlined;
    if (m.contains('stovetop') || m.contains('pan') || m.contains('pot')) {
      return Icons.soup_kitchen_outlined;
    }
    if (m.contains('no-cook') || m.contains('raw')) return Icons.eco_outlined;
    return Icons.restaurant_menu_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (isGrid) {
      return _buildGridCard(context, appState);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 768) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: _buildListCard(context, appState),
            ),
          );
        }
        return _buildListCard(context, appState);
      },
    );
  }

  // ==========================================
  // LIST VIEW: Minimalist High-End Recipe Card
  // ==========================================
  Widget _buildListCard(BuildContext context, AppState appState) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(recipe: recipe),
          ),
        );
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: appState.bgSubtle.withValues(alpha: 0.85),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Hero Photo ONLY when recipe has an image
            if (recipe.hasImage)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    child: AspectRatio(
                      aspectRatio: 1.85,
                      child: Image.network(
                        recipe.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                  ),

                  // Match / Slot Pill
                  Positioned(
                    top: 12,
                    left: 14,
                    child: _buildSlotBadge(appState, isGrid: false, onImage: true),
                  ),

                  // Actions on Photo
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => PhotoActionSheet.show(context, recipe),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.90),
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(color: Color(0x15000000), blurRadius: 4),
                              ],
                            ),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 15,
                              color: appState.accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => context.read<AppState>().toggleSaveRecipe(recipe.id),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.90),
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(color: Color(0x15000000), blurRadius: 4),
                              ],
                            ),
                            child: Icon(
                              recipe.isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: recipe.isSaved ? Colors.redAccent : AppTheme.textMain,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            // Card Body Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top Row for cards WITHOUT image
                  if (!recipe.hasImage)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Slot Badge
                        Flexible(
                          child: _buildSlotBadge(appState, isGrid: false, onImage: false),
                        ),
                        const SizedBox(width: 8),

                        // Action Buttons: Camera & Heart
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => PhotoActionSheet.show(context, recipe),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: appState.bgCard.withValues(alpha: 0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 15,
                                  color: appState.accentColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => context.read<AppState>().toggleSaveRecipe(recipe.id),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: appState.bgCard.withValues(alpha: 0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  recipe.isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  color: recipe.isSaved ? Colors.redAccent : AppTheme.textMuted,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                  if (!recipe.hasImage) const SizedBox(height: 14),

                  // Category & Korean Subtitle (Mentioned Once)
                  Text(
                    recipe.koreanTitle.isNotEmpty
                        ? '${recipe.categoryTag}   ·   ${recipe.koreanTitle}'
                        : recipe.categoryTag,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: AppTheme.textMuted.withValues(alpha: 0.85),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Recipe Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      recipe.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        height: 1.3,
                        color: AppTheme.textMain,
                      ),
                    ),
                  ),

                  if (recipe.inspirationNote != null && recipe.inspirationNote!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '“${recipe.inspirationNote}”',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.textMuted,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Delicate Center Divider
                  Container(
                    width: 32,
                    height: 1.5,
                    decoration: BoxDecoration(
                      color: appState.bgSubtle,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Centered Info Chips (Time · Method · Difficulty · Items)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildPillChip(
                        context,
                        Icons.timer_outlined,
                        '${recipe.cookingTimeMinutes}m',
                        appState,
                      ),
                      _buildPillChip(
                        context,
                        _getMethodIcon(recipe.cookingMethod),
                        recipe.cookingMethod,
                        appState,
                      ),
                      _buildPillChip(
                        context,
                        Icons.bar_chart_rounded,
                        recipe.difficulty,
                        appState,
                      ),
                      if (recipe.ingredients.isNotEmpty)
                        _buildPillChip(
                          context,
                          Icons.inventory_2_outlined,
                          '${recipe.ingredients.length} items',
                          appState,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // GRID VIEW: Minimalist High-End Recipe Card
  // ==========================================
  Widget _buildGridCard(BuildContext context, AppState appState) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(recipe: recipe),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: appState.bgSubtle.withValues(alpha: 0.85),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: recipe.hasImage
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Photo with floating match badge and actions
                  AspectRatio(
                    aspectRatio: 2.1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: Image.network(
                            recipe.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                          ),
                        ),
                        // Match % / Slot Badge
                        Positioned(
                          top: 8,
                          left: 8,
                          child: _buildSlotBadge(appState, isGrid: true, onImage: true),
                        ),
                        // Action buttons
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Material(
                                color: Colors.white.withValues(alpha: 0.88),
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () => PhotoActionSheet.show(context, recipe),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      size: 13,
                                      color: appState.accentColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Material(
                                color: Colors.white.withValues(alpha: 0.88),
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () => context.read<AppState>().toggleSaveRecipe(recipe.id),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Icon(
                                      recipe.isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                      color: recipe.isSaved ? Colors.redAccent : AppTheme.textMain,
                                      size: 14,
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

                  // Content below photo
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                recipe.koreanTitle.isNotEmpty
                                    ? recipe.koreanTitle
                                    : recipe.categoryTag,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                recipe.title,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textMain,
                                  height: 1.25,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          _buildGridSpecChip(context, appState),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Row: Match Pill (left) & Actions (right)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: _buildSlotBadge(appState, isGrid: true, onImage: false),
                        ),
                        const SizedBox(width: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => PhotoActionSheet.show(context, recipe),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 14,
                                  color: appState.accentColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            InkWell(
                              onTap: () => context.read<AppState>().toggleSaveRecipe(recipe.id),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  recipe.isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  color: recipe.isSaved ? Colors.redAccent : AppTheme.textMuted,
                                  size: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Centered Category & Title
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          recipe.koreanTitle.isNotEmpty
                              ? '${recipe.categoryTag}  ·  ${recipe.koreanTitle}'
                              : recipe.categoryTag,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppTheme.textMuted.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          recipe.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMain,
                            height: 1.25,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                    // Centered Bottom Spec Chip
                    _buildGridSpecChip(context, appState),
                  ],
                ),
              ),
      ),
    );
  }

  // Centered Bottom Spec Pill for Grid Card
  Widget _buildGridSpecChip(BuildContext context, AppState appState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: appState.bgCard.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: appState.bgSubtle, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 11, color: AppTheme.textMuted),
          const SizedBox(width: 3),
          Text(
            '${recipe.cookingTimeMinutes}m',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 3,
            height: 3,
            decoration: const BoxDecoration(
              color: AppTheme.textLight,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Icon(_getMethodIcon(recipe.cookingMethod), size: 11, color: AppTheme.textMuted),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              recipe.cookingMethod,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reusable Pill Chip for List View specs
  Widget _buildPillChip(
    BuildContext context,
    IconData icon,
    String label,
    AppState appState,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: appState.bgCard.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: appState.bgSubtle,
          width: 0.8,
        ),
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
