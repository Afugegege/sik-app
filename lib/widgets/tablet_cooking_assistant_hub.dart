import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/kitchen_timer_item.dart';
import '../models/recipe.dart';
import '../providers/app_state.dart';
import '../screens/ai_chat_screen.dart';
import '../screens/cooking_mode_screen.dart';
import '../theme/app_theme.dart';
import 'circular_timer_dial.dart';

/// A modern, state-of-the-art Kitchen Cooking Assistant Hub designed specifically
/// for tablets, iPads, and wide laptop screens in the kitchen.
class TabletCookingAssistantHub extends StatefulWidget {
  const TabletCookingAssistantHub({super.key});

  @override
  State<TabletCookingAssistantHub> createState() => _TabletCookingAssistantHubState();
}

class _TabletCookingAssistantHubState extends State<TabletCookingAssistantHub> {
  Timer? _ticker;

  final List<KitchenTimerItem> _timers = [
    KitchenTimerItem(
      id: 't_1',
      label: 'Steaming Egg',
      totalSeconds: 300,
      secondsRemaining: 185,
      isRunning: false,
    ),
    KitchenTimerItem(
      id: 't_2',
      label: 'Simmering Broth',
      totalSeconds: 900,
      secondsRemaining: 720,
      isRunning: false,
    ),
  ];

  // Unit Converter state
  String _selectedConverter = 'tbsp → ml';
  double _converterInput = 2.0;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      bool changed = false;
      for (final t in _timers) {
        if (t.isRunning) {
          if (t.secondsRemaining > 0) {
            t.secondsRemaining--;
            changed = true;
          } else {
            t.isRunning = false;
            t.isFinished = true;
            changed = true;
          }
        }
      }
      if (changed && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _addQuickTimer(String label, int minutes) {
    setState(() {
      _timers.add(KitchenTimerItem(
        id: 't_${DateTime.now().millisecondsSinceEpoch}',
        label: label,
        totalSeconds: minutes * 60,
        secondsRemaining: minutes * 60,
        isRunning: true,
      ));
    });
  }

  void _showAddTimerDialog(BuildContext context, Color accentColor) {
    int min = 5;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Set Kitchen Timer',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 17),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => Navigator.pop(ctx),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Circular Round Bar Level to set the amount of time
                CircularTimerDial(
                  initialMinutes: min,
                  accentColor: accentColor,
                  onChanged: (newMin) {
                    min = newMin;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addQuickTimer('Timer', min);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Start Timer'),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateConversion() {
    switch (_selectedConverter) {
      case 'tbsp → ml':
        return '${(_converterInput * 15).toStringAsFixed(1)} ml';
      case 'cups → ml':
        return '${(_converterInput * 240).toStringAsFixed(0)} ml';
      case 'oz → grams':
        return '${(_converterInput * 28.35).toStringAsFixed(1)} g';
      case '°C → °F':
        return '${((_converterInput * 9 / 5) + 32).toStringAsFixed(0)} °F';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final accentColor = appState.accentColor;
    final featuredRecipe = appState.recipes.isNotEmpty ? appState.recipes.first : null;

    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: appState.bgCard,
        border: Border(
          left: BorderSide(color: appState.bgSubtle, width: 1.2),
        ),
      ),
      child: Column(
        children: [
          // Station Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: appState.bgSubtle, width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.microwave_rounded, color: accentColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '식 Cooking Hub',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textMain,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'TAB MODE',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.accentGreen,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Live Kitchen Assistant & Station',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Assistant Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                // 1. Multi-Timer Station Card
                _buildSectionHeader('Multi-Timer Station', Icons.timer_outlined, accentColor, () {
                  _showAddTimerDialog(context, accentColor);
                }, '+ Add'),
                const SizedBox(height: 10),

                // Timers list
                ..._timers.map((t) => _buildTimerTile(t, accentColor, appState)),

                // Quick presets
                Wrap(
                  spacing: 6,
                  children: [
                    _quickTimerPreset('+1m Boil', 1, accentColor),
                    _quickTimerPreset('+3m Rest', 3, accentColor),
                    _quickTimerPreset('+5m Steam', 5, accentColor),
                    _quickTimerPreset('+10m Bake', 10, accentColor),
                  ],
                ),

                const SizedBox(height: 24),

                // 2. Active Recipe Cockpit Launch
                if (featuredRecipe != null) ...[
                  _buildSectionHeader('Active Cooking Mode', Icons.restaurant_rounded, accentColor, null, null),
                  const SizedBox(height: 10),
                  _buildCookingCockpitLauncher(context, featuredRecipe, accentColor, appState),
                  const SizedBox(height: 24),
                ],

                // 3. Quick Unit & Measurement Converter
                _buildSectionHeader('Kitchen Unit Converter', Icons.balance_rounded, accentColor, null, null),
                const SizedBox(height: 10),
                _buildUnitConverterCard(appState, accentColor),

                const SizedBox(height: 24),

                // 4. Chef Instant Substitutions & Tips
                _buildSectionHeader('AI Chef Quick Tips', Icons.auto_awesome, accentColor, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen()));
                }, 'Chat'),
                const SizedBox(height: 10),
                _buildQuickTipsCard(context, appState, accentColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color accentColor, VoidCallback? actionTap, String? actionLabel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: accentColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMain,
              ),
            ),
          ],
        ),
        if (actionTap != null && actionLabel != null)
          InkWell(
            onTap: actionTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                actionLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimerTile(KitchenTimerItem t, Color accentColor, AppState appState) {
    final progress = t.totalSeconds > 0 ? (t.secondsRemaining / t.totalSeconds) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: t.isFinished
              ? AppTheme.accentAmber
              : t.isRunning
                  ? accentColor.withValues(alpha: 0.5)
                  : appState.bgSubtle,
          width: t.isRunning ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Circular round bar level with Play/Pause button in center
          InkWell(
            onTap: () {
              setState(() {
                if (t.secondsRemaining == 0) {
                  t.secondsRemaining = t.totalSeconds;
                  t.isFinished = false;
                }
                t.isRunning = !t.isRunning;
              });
            },
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              width: 46,
              height: 46,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3.5,
                    backgroundColor: appState.bgCard,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      t.isFinished ? AppTheme.accentAmber : accentColor,
                    ),
                  ),
                  Icon(
                    t.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: t.isRunning ? accentColor : AppTheme.textMain,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => _showAddTimerDialog(context, accentColor),
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        _formatTime(t.secondsRemaining),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: t.isFinished
                              ? AppTheme.accentAmber
                              : t.isRunning
                                  ? accentColor
                                  : AppTheme.textMain,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.tune_rounded, size: 13, color: AppTheme.textLight),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.restart_alt_rounded, size: 18, color: AppTheme.textMuted),
                onPressed: () {
                  setState(() {
                    t.secondsRemaining = t.totalSeconds;
                    t.isRunning = false;
                    t.isFinished = false;
                  });
                },
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textLight),
                onPressed: () {
                  setState(() {
                    _timers.removeWhere((item) => item.id == t.id);
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickTimerPreset(String title, int min, Color accentColor) {
    return ActionChip(
      label: Text(
        title,
        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
      ),
      backgroundColor: Colors.transparent,
      side: BorderSide(color: accentColor.withValues(alpha: 0.3)),
      padding: EdgeInsets.zero,
      onPressed: () => _addQuickTimer(title.replaceAll(RegExp(r'\+\d+m '), ''), min),
    );
  }

  Widget _buildCookingCockpitLauncher(BuildContext context, Recipe recipe, Color accentColor, AppState appState) {
    return Container(
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
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  recipe.imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    width: 50,
                    height: 50,
                    color: appState.bgSubtle,
                    child: const Icon(Icons.restaurant_rounded, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${recipe.cookingTimeMinutes} mins · ${recipe.cookingMethod}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Open Tablet Cooking Cockpit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.textMain,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CookingModeScreen(recipe: recipe)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitConverterCard(AppState appState, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appState.bgSubtle),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<String>(
                value: _selectedConverter,
                underline: const SizedBox.shrink(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
                items: const [
                  DropdownMenuItem(value: 'tbsp → ml', child: Text('tbsp → ml')),
                  DropdownMenuItem(value: 'cups → ml', child: Text('cups → ml')),
                  DropdownMenuItem(value: 'oz → grams', child: Text('oz → grams')),
                  DropdownMenuItem(value: '°C → °F', child: Text('°C → °F')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedConverter = val);
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _calculateConversion(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              activeTrackColor: accentColor,
              thumbColor: accentColor,
            ),
            child: Slider(
              value: _converterInput,
              min: 0.5,
              max: _selectedConverter.contains('°C') ? 250 : 10,
              divisions: _selectedConverter.contains('°C') ? 25 : 19,
              label: _converterInput.toStringAsFixed(1),
              onChanged: (val) => setState(() => _converterInput = val),
            ),
          ),
          Text(
            'Input: ${_converterInput.toStringAsFixed(1)} ${_selectedConverter.split(' ')[0]}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTipsCard(BuildContext context, AppState appState, Color accentColor) {
    final tips = [
      {'title': 'No Mirin?', 'sub': 'White wine + dash of sugar works 1:1'},
      {'title': 'Soft Steamed Egg', 'sub': 'Add lukewarm water 1:1 with beaten eggs'},
      {'title': 'Crispy Rice Base', 'sub': 'Drizzle sesame oil before turning off heat'},
    ];

    return Column(
      children: tips.map((tip) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.bgSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: appState.bgSubtle),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 16, color: accentColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip['title']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                      ),
                    ),
                    Text(
                      tip['sub']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
