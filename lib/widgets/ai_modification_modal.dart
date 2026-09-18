import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class AiModificationModal extends StatelessWidget {
  final Recipe recipe;
  final String promptQuery;

  const AiModificationModal({
    super.key,
    required this.recipe,
    required this.promptQuery,
  });

  AiModificationDiff _generateDiffForPrompt(String prompt) {
    final lower = prompt.toLowerCase();

    if (lower.contains('simple') || lower.contains('simpler') || lower.contains('quick')) {
      return const AiModificationDiff(
        removed: ['Gochugaru (Chili Flakes)', 'Sesame Oil'],
        substituted: ['Fresh garlic → Garlic powder'],
        timeChange: '15 min → 10 min',
        missingChange: '1 missing → 0 missing',
      );
    } else if (lower.contains('air fryer') || lower.contains('airfryer')) {
      return const AiModificationDiff(
        removed: [],
        substituted: ['Stovetop frying → Air Fryer at 200°C'],
        timeChange: '25 min → 18 min',
        missingChange: '0 missing',
      );
    } else if (lower.contains('mushrooms') || lower.contains('remove')) {
      return const AiModificationDiff(
        removed: ['Shiitake Mushrooms'],
        substituted: ['Soy sauce → Tamari'],
        timeChange: '18 min → 15 min',
        missingChange: '0 missing',
      );
    } else {
      return const AiModificationDiff(
        removed: ['Optional garnish'],
        substituted: ['Soy sauce → Fish sauce', 'Fresh garlic → Garlic paste'],
        timeChange: '20 min → 14 min',
        missingChange: '2 missing → 0 missing (Used fridge stock)',
      );
    }
  }

  List<RecipeIngredient> _generateNewIngredients(Recipe current, AiModificationDiff diff) {
    return current.ingredients.where((ing) => !diff.removed.contains(ing.name)).map((ing) {
      return RecipeIngredient(
        name: ing.name,
        amount: ing.amount,
        status: 'have',
      );
    }).toList();
  }

  static void show(BuildContext context, Recipe recipe, String promptQuery) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AiModificationModal(
        recipe: recipe,
        promptQuery: promptQuery,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final diff = _generateDiffForPrompt(promptQuery);
    final appState = context.read<AppState>();
    final accentColor = appState.accentColor;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: appState.bgPrimary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: AI Spark Icon & Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: accentColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Recipe Modification',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMain,
                      ),
                    ),
                    Text(
                      '"$promptQuery"',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            'Modification Preview',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 12),

          // Diff Cards Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: appState.bgSubtle),
            ),
            child: Column(
              children: [
                if (diff.removed.isNotEmpty)
                  ...diff.removed.map((item) => _diffRow(
                        icon: Icons.remove_circle_outline_rounded,
                        label: '− $item',
                        color: const Color(0xFFE53935),
                        bgColor: const Color(0xFFFFEBEE),
                      )),
                if (diff.substituted.isNotEmpty)
                  ...diff.substituted.map((sub) => _diffRow(
                        icon: Icons.autorenew_rounded,
                        label: '↻ $sub',
                        color: AppTheme.accentAmber,
                        bgColor: const Color(0xFFFEF3C7),
                      )),
                if (diff.timeChange != null)
                  _diffRow(
                    icon: Icons.timer_outlined,
                    label: diff.timeChange!,
                    color: accentColor,
                    bgColor: accentColor.withValues(alpha: 0.1),
                  ),
                if (diff.missingChange != null)
                  _diffRow(
                    icon: Icons.check_circle_outline_rounded,
                    label: diff.missingChange!,
                    color: AppTheme.accentGreen,
                    bgColor: AppTheme.bgGreenLight,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final updatedIngs = _generateNewIngredients(recipe, diff);
                appState.applyAiModification(
                  recipeId: recipe.id,
                  diff: diff,
                  updatedIngredients: updatedIngs,
                  newCookingTime: promptQuery.contains('simple') ? 10 : null,
                  newCookingMethod: promptQuery.contains('air fryer') ? 'Air Fryer' : null,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Applied AI recipe modifications')),
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
              child: Text(
                'Use this version',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                final updatedIngs = _generateNewIngredients(recipe, diff);
                appState.saveAiModifiedAsNewRecipe(
                  originalRecipe: recipe,
                  diff: diff,
                  updatedIngredients: updatedIngs,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saved as new AI recipe')),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textMain,
                side: BorderSide(color: appState.bgSubtle),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Save as New Recipe',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _diffRow({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
