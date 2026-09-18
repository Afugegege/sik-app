import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../providers/app_state.dart';
import '../screens/recipe_detail_screen.dart';
import '../theme/app_theme.dart';
import 'floating_card_pile_icon.dart';

class RandomRecipePickerModal extends StatefulWidget {
  const RandomRecipePickerModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RandomRecipePickerModal(),
    );
  }

  @override
  State<RandomRecipePickerModal> createState() => _RandomRecipePickerModalState();
}

class _RandomRecipePickerModalState extends State<RandomRecipePickerModal> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _shuffleAnim;
  late Animation<double> _liftAnim;
  late Animation<double> _scaleAnim;

  String _filter = 'All'; // 'All', 'High Match', 'Quick (<25m)'
  Recipe? _drawnRecipe;
  bool _isShuffling = false;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _shuffleAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeInOut),
    );

    _liftAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.40, 1.0, curve: Curves.easeOutBack),
    );

    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.40, 0.85, curve: Curves.easeOutBack),
    );

    // Automatically draw initial recipe after modal opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _drawCard(initial: true);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<Recipe> _getFilteredPool(List<Recipe> allRecipes) {
    switch (_filter) {
      case 'High Match':
        final pool = allRecipes.where((r) => r.kitchenMatchPercent >= 75).toList();
        return pool.isNotEmpty ? pool : allRecipes;
      case 'Quick (<25m)':
        final pool = allRecipes.where((r) => r.cookingTimeMinutes <= 25).toList();
        return pool.isNotEmpty ? pool : allRecipes;
      default:
        return allRecipes;
    }
  }

  void _drawCard({bool initial = false}) {
    if (_isShuffling) return;

    final appState = context.read<AppState>();
    final pool = _getFilteredPool(appState.recipes);
    if (pool.isEmpty) return;

    setState(() {
      _isShuffling = true;
    });

    _animController.reset();
    _animController.forward().then((_) {
      if (mounted) {
        setState(() {
          _isShuffling = false;
        });
      }
    });

    // Pick a different recipe if possible
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        Recipe next;
        if (pool.length > 1 && _drawnRecipe != null) {
          final candidates = pool.where((r) => r.id != _drawnRecipe!.id).toList();
          next = candidates[_random.nextInt(candidates.length)];
        } else {
          next = pool[_random.nextInt(pool.length)];
        }
        setState(() {
          _drawnRecipe = next;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final accentColor = appState.accentColor;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: appState.bgPrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x25000000),
            blurRadius: 30,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle Pill
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.20),
                          width: 1,
                        ),
                      ),
                      child: FloatingCardPileIcon(
                        size: 24,
                        accentColor: accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'What to Cook?',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textMain,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Daily Draw',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Tap the pile to shuffle & draw recipe inspiration',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Filter Segment Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            child: Row(
              children: [
                _buildFilterChip('All', 'All Dishes'),
                const SizedBox(width: 8),
                _buildFilterChip('High Match', 'High Match (75%+)'),
                const SizedBox(width: 8),
                _buildFilterChip('Quick (<25m)', 'Under 25 mins'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Central Card Pile & Revealed Card Stage
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: GestureDetector(
                  onTap: () => _drawCard(),
                  child: AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // Under-card 1 (deepest, rotated -5 deg)
                          Transform.rotate(
                            angle: -0.09 + (_shuffleAnim.value * -0.06),
                            child: Transform.translate(
                              offset: Offset(-8 - (_shuffleAnim.value * 28), 10),
                              child: _buildDeckCardBack(appState, 0.90),
                            ),
                          ),

                          // Under-card 2 (rotated +4 deg)
                          Transform.rotate(
                            angle: 0.07 + (_shuffleAnim.value * 0.08),
                            child: Transform.translate(
                              offset: Offset(8 + (_shuffleAnim.value * 30), 6),
                              child: _buildDeckCardBack(appState, 0.93),
                            ),
                          ),

                          // Under-card 3 (rotated -2 deg)
                          Transform.rotate(
                            angle: -0.035 - (_shuffleAnim.value * 0.04),
                            child: Transform.translate(
                              offset: Offset(-3 - (_shuffleAnim.value * 14), 3),
                              child: _buildDeckCardBack(appState, 0.96),
                            ),
                          ),

                          // Top Active / Drawn Card
                          Transform.translate(
                            offset: Offset(
                              0,
                              // Float up during shuffle and spring settle
                              (_isShuffling ? -20 * math.sin(_shuffleAnim.value * math.pi) : 0) +
                                  (1.0 - _liftAnim.value) * -15,
                            ),
                            child: Transform.scale(
                              scale: 0.97 + (_scaleAnim.value * 0.03),
                              child: _drawnRecipe != null
                                  ? _buildRevealedRecipeCard(appState, _drawnRecipe!)
                                  : _buildDeckCardBack(appState, 1.0, isInteractive: true),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Quick Actions Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Shuffle / Draw Again Button
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: _isShuffling ? null : () => _drawCard(),
                    icon: AnimatedRotation(
                      turns: _isShuffling ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 600),
                      child: Icon(Icons.style_outlined, size: 18, color: accentColor),
                    ),
                    label: Text(
                      _drawnRecipe == null ? 'Draw Card' : 'Shuffle Deck',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: appState.bgSubtle, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: appState.bgCard,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Cook This Recipe Primary Button
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: _drawnRecipe == null
                        ? null
                        : () {
                            final recipeToCook = _drawnRecipe!;
                            Navigator.pop(context); // Close picker modal
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecipeDetailScreen(recipe: recipeToCook),
                              ),
                            );
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Cook This',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filter == key;
    final appState = context.read<AppState>();

    return InkWell(
      onTap: () {
        if (_filter != key) {
          setState(() {
            _filter = key;
          });
          _drawCard();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.textMain : appState.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.textMain : appState.bgSubtle,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildDeckCardBack(AppState appState, double scale, {bool isInteractive = false}) {
    return Container(
      width: 295 * scale,
      height: 390 * scale,
      decoration: BoxDecoration(
        color: appState.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appState.bgSubtle.withValues(alpha: 0.8), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Geometric aesthetic subtle inner frame
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: appState.bgSubtle.withValues(alpha: 0.5),
                    width: 0.8,
                  ),
                ),
              ),
            ),
          ),

          // Center Editorial Seal
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '식',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: appState.accentColor.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'SIK KITCHEN DECK',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  color: AppTheme.textLight,
                ),
              ),
              if (isInteractive) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: appState.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Tap to draw',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: appState.accentColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevealedRecipeCard(AppState appState, Recipe recipe) {
    final matchColor = recipe.kitchenMatchPercent >= 90
        ? AppTheme.accentGreen
        : recipe.kitchenMatchPercent >= 75
            ? AppTheme.accentAmber
            : AppTheme.textMuted;
    final matchBgColor = recipe.kitchenMatchPercent >= 90
        ? AppTheme.bgGreenLight
        : recipe.kitchenMatchPercent >= 75
            ? const Color(0xFFFEF3C7)
            : appState.bgCard;

    if (recipe.hasImage) {
      return _buildRevealedCardWithImage(appState, recipe, matchColor);
    }

    return _buildRevealedCardWithoutImage(appState, recipe, matchColor, matchBgColor);
  }

  Widget _buildRevealedCardWithImage(AppState appState, Recipe recipe, Color matchColor) {
    return Container(
      width: 295,
      height: 390,
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appState.bgSubtle.withValues(alpha: 0.8), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Top Image with floating badges
            Stack(
              children: [
                SizedBox(
                  height: 155,
                  width: double.infinity,
                  child: Image.network(
                    recipe.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, err, stack) => _buildMinimalImageFallback(appState, recipe),
                  ),
                ),

                // Match Pill
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Color(0x12000000), blurRadius: 6),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: matchColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${recipe.kitchenMatchPercent}% Match',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: matchColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Category Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Color(0x12000000), blurRadius: 6),
                      ],
                    ),
                    child: Text(
                      recipe.categoryTag,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Card Body (Middle-Center Aligned)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(
                          recipe.koreanTitle.isNotEmpty
                              ? '${recipe.categoryTag}   ·   ${recipe.koreanTitle}'
                              : recipe.categoryTag,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: AppTheme.textMuted.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          recipe.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMain,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 24,
                          height: 1.5,
                          decoration: BoxDecoration(
                            color: appState.bgSubtle,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),

                    // Badges: Borderless & seamless!
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildInfoBadge(appState, Icons.timer_outlined, '${recipe.cookingTimeMinutes}m'),
                        _buildInfoBadge(appState, _getMethodIcon(recipe.cookingMethod), recipe.cookingMethod),
                        _buildInfoBadge(appState, Icons.bar_chart_rounded, recipe.difficulty),
                      ],
                    ),

                    // Borderless status line
                    _buildStatusLine(recipe),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevealedCardWithoutImage(AppState appState, Recipe recipe, Color matchColor, Color matchBgColor) {
    return Container(
      width: 295,
      height: 390,
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appState.bgSubtle.withValues(alpha: 0.8), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top Badges Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Match Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: matchBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: matchColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${recipe.kitchenMatchPercent}% Match',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: matchColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Category Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: appState.bgCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    recipe.categoryTag,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),

            // Middle Center Editorial Body
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Editorial watermark mark
                    Text(
                      '식',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: appState.accentColor.withValues(alpha: 0.20),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category & Korean Subtitle
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

                    // Dish Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        recipe.title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMain,
                          letterSpacing: -0.4,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subtle center divider line
                    Container(
                      width: 28,
                      height: 1.5,
                      decoration: BoxDecoration(
                        color: appState.bgSubtle,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Badges: Borderless & minimalist!
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildInfoBadge(appState, Icons.timer_outlined, '${recipe.cookingTimeMinutes}m'),
                        _buildInfoBadge(appState, _getMethodIcon(recipe.cookingMethod), recipe.cookingMethod),
                        _buildInfoBadge(appState, Icons.bar_chart_rounded, recipe.difficulty),
                        _buildInfoBadge(appState, Icons.inventory_2_outlined, '${recipe.ingredients.length} items'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Borderless Status Line
            _buildStatusLine(recipe),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalImageFallback(AppState appState, Recipe recipe) {
    return Container(
      color: appState.bgCard,
      child: Center(
        child: Text(
          recipe.koreanTitle.isNotEmpty
              ? '${recipe.categoryTag} · ${recipe.koreanTitle}'
              : recipe.categoryTag,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBadge(AppState appState, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
      decoration: BoxDecoration(
        color: appState.bgCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textMuted),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusLine(Recipe recipe) {
    final isComplete = recipe.missingIngredientsCount == 0;
    final statusColor = isComplete ? AppTheme.accentGreen : AppTheme.textMuted;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isComplete ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
          size: 13,
          color: statusColor,
        ),
        const SizedBox(width: 5),
        Text(
          isComplete
              ? 'All ingredients ready in fridge'
              : 'Missing ${recipe.missingIngredientsCount} ingredient${recipe.missingIngredientsCount > 1 ? 's' : ''}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: statusColor,
          ),
        ),
      ],
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
}
