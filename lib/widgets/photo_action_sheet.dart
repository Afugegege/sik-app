import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class PhotoActionSheet {
  static void show(BuildContext context, Recipe recipe) {
    final appState = context.read<AppState>();
    final accentColor = appState.accentColor;
    final urlController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.camera_alt_rounded, size: 18, color: accentColor),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Record Your Dish Photo',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textMain,
                                  ),
                                ),
                                Text(
                                  'Snap, select, or choose a preset',
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
                    const SizedBox(height: 20),

                    // Primary Actions: Snap Photo & Device Gallery
                    Row(
                      children: [
                        // Snap Photo
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              final samplePhoto = _getSamplePhotoForRecipe(recipe);
                              appState.updateRecipeImage(recipe.id, samplePhoto);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Photo captured and attached'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: accentColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Snap Photo',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: accentColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Use your camera',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Device Gallery
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              final samplePhoto = _getGalleryPhotoForRecipe(recipe);
                              appState.updateRecipeImage(recipe.id, samplePhoto);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Selected photo from gallery!'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                color: AppTheme.bgSurface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: appState.bgSubtle),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: appState.bgCard,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.photo_library_rounded, color: AppTheme.textMain, size: 20),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'From Gallery',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textMain,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Pick from photos',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Aesthetic Food Photography Presets
                    Text(
                      'Aesthetic Dish Presets',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '1-tap to attach a styled food photo',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPresetChip(context, 'Crispy Pan Sear',
                              'https://images.unsplash.com/photo-1603133872878-684f208fb84b?q=80&w=800&auto=format&fit=crop',
                              recipe, appState),
                          _buildPresetChip(context, 'Steaming Broth',
                              'https://images.unsplash.com/photo-1583032015879-6617a26f32e9?w=600&q=80',
                              recipe, appState),
                          _buildPresetChip(context, 'Plated Bowl',
                              'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=800&auto=format&fit=crop',
                              recipe, appState),
                          _buildPresetChip(context, 'Café Style',
                              'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?q=80&w=800&auto=format&fit=crop',
                              recipe, appState),
                          _buildPresetChip(context, 'Grilled Perfection',
                              'https://images.unsplash.com/photo-1632778149955-e80f8ceca2e8?w=600&q=80',
                              recipe, appState),
                          _buildPresetChip(context, 'Noodle Shot',
                              'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600&q=80',
                              recipe, appState),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // URL / Path input
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: appState.bgSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.link_rounded, size: 15, color: AppTheme.textMuted),
                              const SizedBox(width: 6),
                              Text(
                                'Custom URL / File Path',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textMain,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: urlController,
                                  decoration: InputDecoration(
                                    hintText: 'Paste image URL or file path...',
                                    hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textLight, fontSize: 12),
                                    filled: true,
                                    fillColor: appState.bgCard,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    isDense: true,
                                  ),
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  final input = urlController.text.trim();
                                  final photoUrl = input.isNotEmpty ? input : _getSamplePhotoForRecipe(recipe);
                                  appState.updateRecipeImage(recipe.id, photoUrl);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Photo saved!'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.textMain,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  minimumSize: Size.zero,
                                ),
                                child: Text(
                                  'Save',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Reset to Graphic Card (only if recipe currently has a photo)
                    if (recipe.hasImage) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () {
                            appState.updateRecipeImage(recipe.id, '');
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Reset to Graphic Card'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.palette_outlined, size: 15, color: AppTheme.textMuted),
                          label: Text(
                            'Remove Photo (Use Graphic Card)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildPresetChip(
    BuildContext context,
    String label,
    String url,
    Recipe recipe,
    AppState appState,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          appState.updateRecipeImage(recipe.id, url);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Attached $label preset!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: appState.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: appState.bgSubtle),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMain,
            ),
          ),
        ),
      ),
    );
  }

  static String _getSamplePhotoForRecipe(Recipe recipe) {
    final lower = recipe.title.toLowerCase();
    if (lower.contains('kimchi')) {
      return 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?q=80&w=800&auto=format&fit=crop';
    } else if (lower.contains('tofu')) {
      return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=800&auto=format&fit=crop';
    } else if (lower.contains('sweet potato')) {
      return 'https://images.unsplash.com/photo-1596560548464-f010549b84d7?q=80&w=800&auto=format&fit=crop';
    } else if (lower.contains('egg')) {
      return 'https://images.unsplash.com/photo-1525351484163-7529414344d8?q=80&w=800&auto=format&fit=crop';
    } else if (lower.contains('cucumber')) {
      return 'https://images.unsplash.com/photo-1540420773420-3366772f4999?q=80&w=800&auto=format&fit=crop';
    } else if (lower.contains('matcha')) {
      return 'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?q=80&w=800&auto=format&fit=crop';
    } else {
      return 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?q=80&w=800&auto=format&fit=crop';
    }
  }

  static String _getGalleryPhotoForRecipe(Recipe recipe) {
    final lower = recipe.title.toLowerCase();
    if (lower.contains('kimchi')) {
      return 'https://images.unsplash.com/photo-1583032015879-6617a26f32e9?w=600&q=80';
    } else if (lower.contains('tofu')) {
      return 'https://images.unsplash.com/photo-1553163147-622ab57be1c7?w=600&q=80';
    } else if (lower.contains('sweet potato')) {
      return 'https://images.unsplash.com/photo-1596560548464-f010549b84d7?w=600&q=80';
    } else if (lower.contains('egg')) {
      return 'https://images.unsplash.com/photo-1525351484163-7529414344d8?q=80&w=800&auto=format&fit=crop';
    } else if (lower.contains('cucumber')) {
      return 'https://images.unsplash.com/photo-1540420773420-3366772f4999?q=80&w=800&auto=format&fit=crop';
    } else {
      return 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?q=80&w=800&auto=format&fit=crop';
    }
  }
}
