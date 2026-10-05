import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const List<String> availableRegions = [
    'Ireland',
    'South Korea',
    'United States',
    'United Kingdom',
  ];

  static const List<String> availableCuisines = [
    'Western & Italian',
    'Japanese',
    'Chinese & Asian Fusion',
    'Korean',
    'Mexican & Latin',
    'Mediterranean',
    'Quick & Easy Comfort',
    'Healthy & Fitness',
    'Pastry & Baking',
    'Desserts',
    'Drinks',
  ];

  static const List<String> availableDietary = [
    'Vegetarian',
    'Vegan',
    'Gluten-free',
    'Nut-free',
    'Dairy-free',
  ];

  static const List<String> availableAppliances = [
    'Air Fryer',
    'Oven',
    'Microwave',
    'Blender',
    'Rice Cooker',
    'Stovetop',
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isWide = MediaQuery.sizeOf(context).width >= 860;

    return Container(
      color: appState.bgPrimary,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile & Settings',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMain,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Customize your theme color, kitchen, region & dietary preferences',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Body Settings Sections
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 150),
                  sliver: isWide
                      ? SliverToBoxAdapter(
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left Column
                                  Expanded(
                                    child: Column(
                                      children: [
                                        _buildAccentThemeCard(context, appState),
                                        const SizedBox(height: 16),
                                        _buildQuantityTrackingCard(context, appState),
                                        const SizedBox(height: 16),
                                        _buildRegionCard(context, appState),
                                        const SizedBox(height: 16),
                                        _buildAppliancesCard(context, appState),
                                        const SizedBox(height: 16),
                                        _buildKitchenDataCard(context, appState),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Right Column
                                  Expanded(
                                    child: Column(
                                      children: [
                                        _buildPreferredCuisinesCard(context, appState),
                                        const SizedBox(height: 16),
                                        _buildDietaryCard(context, appState),
                                        const SizedBox(height: 16),
                                        _buildApiKeyCard(context, appState),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _buildFooter(context, appState),
                            ],
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildListDelegate([
                            _buildAccentThemeCard(context, appState),
                            const SizedBox(height: 16),
                            _buildQuantityTrackingCard(context, appState),
                            const SizedBox(height: 16),
                            _buildRegionCard(context, appState),
                            const SizedBox(height: 16),
                            _buildPreferredCuisinesCard(context, appState),
                            const SizedBox(height: 16),
                            _buildDietaryCard(context, appState),
                            const SizedBox(height: 16),
                            _buildAppliancesCard(context, appState),
                            const SizedBox(height: 16),
                            _buildKitchenDataCard(context, appState),
                            const SizedBox(height: 16),
                            _buildApiKeyCard(context, appState),
                            const SizedBox(height: 24),
                            _buildFooter(context, appState),
                          ]),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Section 1: Accent Color Theme ──────────────────────────────────────────
  Widget _buildAccentThemeCard(BuildContext context, AppState appState) {
    return _sectionCard(
      context: context,
      title: 'App Accent Color Theme',
      subtitle: 'Applies dynamically to buttons, badges, icons & highlights',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 14,
          crossAxisSpacing: 8,
          childAspectRatio: 0.96,
        ),
        itemCount: AppTheme.accentPresets.length,
        itemBuilder: (context, index) {
          final preset = AppTheme.accentPresets[index];
          final isSelected = appState.accentColor.toARGB32() == preset.color.toARGB32();

          return InkWell(
            onTap: () => appState.setAccentColor(preset.color),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: preset.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppTheme.textMain : Colors.transparent,
                      width: isSelected ? 3 : 0,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: preset.color.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                ),
                const SizedBox(height: 6),
                Text(
                  preset.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppTheme.textMain : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Section 2: Region Selection ────────────────────────────────────────────
  Widget _buildRegionCard(BuildContext context, AppState appState) {
    return _sectionCard(
      context: context,
      title: 'Location & Region',
      subtitle: 'Affects local supermarket substitution intelligence',
      child: DropdownButtonFormField<String>(
        initialValue: appState.userRegion.contains('Ireland') ? 'Ireland' : (appState.userRegion.contains('Korea') ? 'South Korea' : 'Ireland'),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppTheme.bgSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: appState.bgSubtle),
          ),
        ),
        items: availableRegions.map((region) {
          return DropdownMenuItem(
            value: region,
            child: Text(
              region,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMain,
              ),
            ),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) appState.setUserRegion(val);
        },
      ),
    );
  }

  // ── Section 3: Preferred Cuisines ──────────────────────────────────────────
  Widget _buildPreferredCuisinesCard(BuildContext context, AppState appState) {
    return _sectionCard(
      context: context,
      title: 'Preferred Cuisines',
      subtitle: 'Personalize your Explore recommendation feed',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: availableCuisines.map((cuisine) {
          final isSelected = appState.preferredCuisines.contains(cuisine);
          return FilterChip(
            label: Text(cuisine),
            selected: isSelected,
            selectedColor: appState.accentColor.withValues(alpha: 0.15),
            checkmarkColor: appState.accentColor,
            labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? appState.accentColor : AppTheme.textMain,
            ),
            backgroundColor: AppTheme.bgSurface,
            side: BorderSide(
              color: isSelected ? appState.accentColor : appState.bgSubtle,
            ),
            onSelected: (_) => appState.togglePreferredCuisine(cuisine),
          );
        }).toList(),
      ),
    );
  }

  // ── Section 4: Dietary Restrictions ────────────────────────────────────────
  Widget _buildDietaryCard(BuildContext context, AppState appState) {
    return _sectionCard(
      context: context,
      title: 'Dietary Restrictions',
      subtitle: 'Recipes will automatically flag or substitute non-matching ingredients',
      child: Column(
        children: availableDietary.map((dietary) {
          final isChecked = appState.dietaryRestrictions.contains(dietary);
          return CheckboxListTile(
            value: isChecked,
            title: Text(
              dietary,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMain,
              ),
            ),
            activeColor: appState.accentColor,
            contentPadding: EdgeInsets.zero,
            dense: true,
            onChanged: (_) => appState.toggleDietaryRestriction(dietary),
          );
        }).toList(),
      ),
    );
  }

  // ── Section 5: Kitchen Appliances ──────────────────────────────────────────
  Widget _buildAppliancesCard(BuildContext context, AppState appState) {
    return _sectionCard(
      context: context,
      title: 'Kitchen Appliances',
      subtitle: 'Appliance-specific step guidance in Cooking Mode',
      child: Column(
        children: availableAppliances.map((appliance) {
          final isEnabled = appState.kitchenAppliances.contains(appliance);
          return SwitchListTile(
            value: isEnabled,
            title: Text(
              appliance,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMain,
              ),
            ),
            activeThumbColor: appState.accentColor,
            contentPadding: EdgeInsets.zero,
            dense: true,
            onChanged: (_) => appState.toggleKitchenAppliance(appliance),
          );
        }).toList(),
      ),
    );
  }

  // ── Section 6: AI Key Configuration ────────────────────────────────────────
  Widget _buildApiKeyCard(BuildContext context, AppState appState) {
    return _sectionCard(
      context: context,
      title: 'AI Intelligence & API Key',
      subtitle: 'Enter your OpenAI API Key (or Gemini key) for real-time AI recipe & image generation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatefulBuilder(
            builder: (context, setCardState) {
              final keyController = TextEditingController(text: appState.apiKey);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: keyController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Paste your OpenAI API key (sk-...)',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textLight,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: AppTheme.bgSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: appState.bgSubtle),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      prefixIcon: const Icon(Icons.key_rounded, size: 18, color: AppTheme.textMuted),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          final newKey = keyController.text.trim();
                          appState.setApiKey(newKey);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                newKey.isEmpty
                                    ? 'API Key cleared.'
                                    : 'AI API Key saved securely to local storage!',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.save_rounded, size: 16),
                        label: const Text('Save API Key'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appState.accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (appState.apiKey.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.bgGreenLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.accentGreen),
                              const SizedBox(width: 4),
                              Text(
                                'Key Active',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.accentGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Section 6.5: Kitchen Data & Memory ──────────────────────────────────────
  Widget _buildKitchenDataCard(BuildContext context, AppState appState) {
    return _sectionCard(
      context: context,
      title: 'Kitchen Data & Memory',
      subtitle: 'Manage local inventory persistence and clear options',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: appState.accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.inventory_2_outlined, size: 18, color: appState.accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${appState.fridgeItems.length} items saved in memory',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                      ),
                    ),
                    Text(
                      'Persisted locally across app restarts',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showClearInventoryConfirmDialog(context, appState);
                  },
                  icon: const Icon(Icons.delete_sweep_rounded, size: 18, color: AppTheme.accentOrange),
                  label: Text(
                    'Clear All Data',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentOrange,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    side: BorderSide(color: AppTheme.accentOrange.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    appState.resetInventoryToDefault();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sample pantry items restored to kitchen.')),
                    );
                  },
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: Text(
                    'Restore Defaults',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textMuted,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    side: BorderSide(color: appState.bgSubtle),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showClearInventoryConfirmDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: appState.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear Entire Kitchen?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMain,
          ),
        ),
        content: Text(
          'This will delete all items across your Fridge, Freezer, Pantry, and Seasonings. Your kitchen will be completely empty. This cannot be undone.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            color: AppTheme.textMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              appState.clearInventory();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All kitchen inventory cleared.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }

  // ── Footer: Reset Defaults & Version ───────────────────────────────────────
  Widget _buildFooter(BuildContext context, AppState appState) {
    return Center(
      child: Column(
        children: [
          OutlinedButton.icon(
            onPressed: () {
              appState.resetStateToDefaults();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reset settings to default preferences.')),
              );
            },
            icon: const Icon(Icons.restore_rounded, size: 16),
            label: const Text('Reset to Defaults'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textMuted,
              side: BorderSide(color: appState.bgSubtle),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '식 (sik) v1.0.0 • Korean Minimalist Kitchen',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section: Inventory Quantity Tracking Setting ───────────────────────────
  Widget _buildQuantityTrackingCard(BuildContext context, AppState appState) {
    return _sectionCard(
      context: context,
      title: 'Inventory Quantity Tracking',
      subtitle: 'Choose between tracking exact quantities or running a minimal checklist',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: appState.bgPrimary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: appState.bgSubtle),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: appState.accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                appState.trackQuantities ? Icons.scale_rounded : Icons.checklist_rounded,
                color: appState.accentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Track Quantities in Inventory',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    appState.trackQuantities
                        ? 'Quantities & scrubbers shown on pantry items.'
                        : 'Checklist mode active. Saved quantities are preserved in background.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: appState.trackQuantities,
              activeTrackColor: appState.accentColor,
              onChanged: (val) => appState.setTrackQuantities(val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final appState = context.watch<AppState>();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: appState.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: appState.bgSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMain,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
