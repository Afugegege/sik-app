import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/ai_chat_message.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

/// A sleek, tactile Korean Ins studio selection card that displays a curated shortlist
/// of recipe title options, allowing the user to select which one they want to explore or cook.
class AiRecipeOptionsCard extends StatelessWidget {
  final List<AiRecipeOption> options;
  final ValueChanged<String> onSelectOption;

  const AiRecipeOptionsCard({
    super.key,
    required this.options,
    required this.onSelectOption,
  });

  IconData _getIconForCategory(String category, String title) {
    final lower = '${category.toLowerCase()} ${title.toLowerCase()}';
    if (lower.contains('latte') ||
        lower.contains('coffee') ||
        lower.contains('tea') ||
        lower.contains('drink') ||
        lower.contains('beverage')) {
      return Icons.local_cafe_outlined;
    }
    if (lower.contains('cookie') ||
        lower.contains('cake') ||
        lower.contains('pancake') ||
        lower.contains('bake') ||
        lower.contains('dessert') ||
        lower.contains('pastry')) {
      return Icons.bakery_dining_outlined;
    }
    if (lower.contains('noodle') ||
        lower.contains('ramen') ||
        lower.contains('pasta') ||
        lower.contains('soup')) {
      return Icons.ramen_dining_outlined;
    }
    return Icons.restaurant_menu_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final accentColor = appState.accentColor;

    return Container(
      margin: const EdgeInsets.only(left: 36, top: 8, bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appState.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: appState.bgSubtle,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.style_outlined, size: 12, color: accentColor),
                    const SizedBox(width: 5),
                    Text(
                      '식 STUDIO SELECTION',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${options.length} ${options.length == 1 ? 'choice' : 'choices'}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'Tap a recipe to view studio details & cooking steps:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMuted,
            ),
          ),

          const SizedBox(height: 12),

          // Options List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: options.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final opt = options[index];
              final cleanTitle = opt.title.replaceAll('**', '').trim();
              final cleanTime = opt.cookingTime.replaceAll('**', '').trim();
              final cleanDiff = opt.difficulty.replaceAll('**', '').trim();
              final cleanCat = opt.category.replaceAll('**', '').trim();
              final cleanDesc = opt.description.replaceAll('**', '').trim();
              final icon = _getIconForCategory(cleanCat, cleanTitle);

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelectOption(cleanTitle),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: appState.bgSubtle.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: appState.bgSubtle,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left category icon circle
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: appState.bgCard,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: appState.bgSubtle,
                              width: 1.0,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              icon,
                              size: 18,
                              color: accentColor,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Title & Meta details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cleanTitle,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textMain,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (cleanTime.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: appState.bgCard,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.timer_outlined, size: 10, color: AppTheme.textMuted),
                                          const SizedBox(width: 3),
                                          Text(
                                            cleanTime,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (cleanDiff.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: appState.bgCard,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        cleanDiff,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                  if (cleanCat.isNotEmpty)
                                    Text(
                                      cleanCat,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textLight,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                              if (cleanDesc.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  cleanDesc,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w400,
                                    color: AppTheme.textMuted,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Trailing Action Arrow
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Select',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: accentColor,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 10,
                                color: accentColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
