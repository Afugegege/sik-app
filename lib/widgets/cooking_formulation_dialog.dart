import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../providers/app_state.dart';
import '../screens/cooking_mode_screen.dart';
import '../services/servings_scaler.dart';
import '../theme/app_theme.dart';

class CookingFormulationDialog extends StatefulWidget {
  final Recipe recipe;
  final int servings;

  const CookingFormulationDialog({
    super.key,
    required this.recipe,
    this.servings = 2,
  });

  static Future<void> startCookingWithFormulation(
    BuildContext context,
    Recipe recipe, {
    int? servings,
  }) async {
    final activeServings = servings ?? (recipe.servings <= 0 ? 2 : recipe.servings);
    final completed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CookingFormulationDialog(
        recipe: recipe,
        servings: activeServings,
      ),
    );

    if (completed == true && context.mounted) {
      final scaled = ServingsScaler.scaleRecipe(recipe, activeServings);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CookingModeScreen(recipe: scaled),
        ),
      );
    }
  }

  @override
  State<CookingFormulationDialog> createState() => _CookingFormulationDialogState();
}

class _CookingFormulationDialogState extends State<CookingFormulationDialog> with SingleTickerProviderStateMixin {
  int _activeStepIndex = 0;
  Timer? _stepTimer;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  final List<String> _formulationSteps = [
    'Calibrating appliance heat & temperature...',
    'Proportioning ingredient amounts for target servings...',
    'Synthesizing kitchen timers & doneness cues...',
    'Detailed cooking instructions assembled!',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _runFormulationAnimation();
  }

  void _runFormulationAnimation() {
    _stepTimer = Timer.periodic(const Duration(milliseconds: 280), (timer) {
      if (!mounted) return;
      if (_activeStepIndex < _formulationSteps.length - 1) {
        setState(() {
          _activeStepIndex++;
        });
      } else {
        timer.cancel();
        // Conclude formulation and transition to cooking mode
        Future.delayed(const Duration(milliseconds: 250), () {
          if (!mounted) return;
          _openDetailedCookingScreen();
        });
      }
    });
  }

  void _openDetailedCookingScreen() {
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final accentColor = appState.accentColor;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            decoration: BoxDecoration(
              color: appState.bgPrimary,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: appState.bgSubtle, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Pulsing Icon
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.soup_kitchen_rounded,
                        color: accentColor,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Title & Subtitle
                Text(
                  'Formulating Detailed Recipe',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMain,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.recipe.title} • ${widget.servings} ${widget.servings == 1 ? "serving" : "servings"}',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 18),

                // Animated Checklist of formulation steps
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: appState.bgCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: appState.bgSubtle),
                  ),
                  child: Column(
                    children: List.generate(_formulationSteps.length, (idx) {
                      final isDone = idx <= _activeStepIndex;
                      final isCurrent = idx == _activeStepIndex;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: isDone ? accentColor : appState.bgSubtle,
                                shape: BoxShape.circle,
                              ),
                              child: isDone
                                  ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _formulationSteps[idx],
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: isCurrent ? FontWeight.w700 : (isDone ? FontWeight.w600 : FontWeight.w400),
                                  color: isCurrent ? AppTheme.textMain : (isDone ? AppTheme.textMain : AppTheme.textLight),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 18),

                // Progress Indicator
                LinearProgressIndicator(
                  value: (_activeStepIndex + 1) / _formulationSteps.length,
                  backgroundColor: appState.bgSubtle,
                  color: accentColor,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
                const SizedBox(height: 14),

                // Quick Skip Button
                TextButton(
                  onPressed: _openDetailedCookingScreen,
                  child: Text(
                    'Start immediately',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
