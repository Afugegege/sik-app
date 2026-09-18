import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/ai_chat_message.dart';
import '../models/kitchen_timer_item.dart';
import '../models/recipe.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/voice_message_dialog.dart';
import '../widgets/circular_timer_dial.dart';

class CookingModeScreen extends StatefulWidget {
  final Recipe? recipe;

  const CookingModeScreen({
    super.key,
    this.recipe,
  });

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen>
    with SingleTickerProviderStateMixin {
  Recipe? _activeRecipe;
  late PageController _pageController;
  int _currentStep = 0;
  final Set<String> _checkedIngredients = {};

  // Right Panel Tab Selection (0 = 식 AI, 1 = Kitchen Tools)
  int _activePanelTab = 0;

  // Hub: Multi-Timers
  Timer? _ticker;
  final List<KitchenTimerItem> _timers = [];

  // Hub: Unit Converter & Student Everyday Tools
  int _converterMode = 0; // 0 = Student Everyday (No Tools), 1 = Standard Units
  String _selectedStudentTool = 'dining_spoon';
  String _selectedConverter = 'tbsp → ml';
  double _converterInput = 2.0;

  // AI Chat
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final List<AiChatMessage> _chatMessages = [];
  bool _isAiResponding = false;

  @override
  void initState() {
    super.initState();
    _activeRecipe = widget.recipe;
    // Vertical PageView controller tuned for natural lyrics line spacing and smooth slide-snapping
    // Use larger viewportFraction on mobile so each step takes more vertical space
    _pageController = PageController(viewportFraction: 0.52, initialPage: _currentStep);

    // Initial Kitchen Timer
    if (_activeRecipe != null) {
      _timers.add(KitchenTimerItem(
        id: 't_step',
        label: 'Step 1 Timer',
        totalSeconds: 180,
        secondsRemaining: 180,
        isRunning: false,
      ));
      _syncStepTimer(_currentStep);

      // Editorial welcome message from 식 AI
      _chatMessages.add(AiChatMessage(
        id: 'welcome',
        text: '안녕하세요! I am 식 AI, your kitchen companion for "${_activeRecipe!.title}". Tap any quick question below or use the mic whenever your hands are occupied.',
        isUser: false,
        timestamp: DateTime.now(),
        quickReplies: const [
          'Check doneness cues',
          'Ingredient substitutes',
          'Adjust heat level',
        ],
      ));
    } else {
      // Free cooking mode timer
      _timers.add(KitchenTimerItem(
        id: 't_free',
        label: 'Kitchen Timer',
        totalSeconds: 300,
        secondsRemaining: 300,
        isRunning: false,
      ));

      // Free cooking welcome from 식 AI
      _chatMessages.add(AiChatMessage(
        id: 'welcome',
        text: '안녕하세요! Welcome to your open Kitchen Session. I am here to help you freestyle, convert student measurements, time dishes, or suggest cooking ideas.',
        isUser: false,
        timestamp: DateTime.now(),
        quickReplies: const [
          'Everyday measurement tips',
          'How to balance flavors',
          'Quick dinner ideas',
          'Surprise me with a dish',
        ],
      ));
    }

    // 1-second timer ticker for multi-timers
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

  void _selectRecipe(Recipe recipe) {
    setState(() {
      _activeRecipe = recipe;
      _currentStep = 0;
      _checkedIngredients.clear();
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
    _syncStepTimer(0);
    _chatMessages.add(AiChatMessage(
      id: 'sel_${DateTime.now().millisecondsSinceEpoch}',
      text: 'Now following "${recipe.title}". Step 1 is ready on your screen! Let me know if you need any adjustments.',
      isUser: false,
      timestamp: DateTime.now(),
      quickReplies: const [
        'Check doneness cues',
        'Ingredient substitutes',
        'Adjust heat level',
      ],
    ));
    _scrollChatToBottom();
  }

  void _switchToFreeCooking() {
    setState(() {
      _activeRecipe = null;
    });
  }

  void _pickRandomRecipe(AppState appState) {
    if (appState.recipes.isEmpty) return;
    final shuffled = List<Recipe>.from(appState.recipes)..shuffle();
    _selectRecipe(shuffled.first);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  int? _parseStepDuration(String text) {
    // Looks for pattern like "3 minutes", "3 mins", "15 minutes", "30 seconds", "45 secs"
    final minMatch = RegExp(r'(\d+)\s*(?:minutes?|mins?|min\b)', caseSensitive: false).firstMatch(text);
    if (minMatch != null) {
      final mins = int.tryParse(minMatch.group(1) ?? '');
      if (mins != null && mins > 0) return mins * 60;
    }
    final secMatch = RegExp(r'(\d+)\s*(?:seconds?|secs?|sec\b)', caseSensitive: false).firstMatch(text);
    if (secMatch != null) {
      final secs = int.tryParse(secMatch.group(1) ?? '');
      if (secs != null && secs > 0) return secs;
    }
    return null;
  }

  void _syncStepTimer(int stepIndex) {
    if (_activeRecipe == null) return;
    if (stepIndex < 0 || stepIndex >= _activeRecipe!.cookingSteps.length) return;
    final stepText = _activeRecipe!.cookingSteps[stepIndex];
    final durationSeconds = _parseStepDuration(stepText);

    final stepTimerIdx = _timers.indexWhere((t) => t.id == 't_step');
    if (durationSeconds != null) {
      final label = durationSeconds >= 60
          ? 'Step ${stepIndex + 1} (${durationSeconds ~/ 60}m)'
          : 'Step ${stepIndex + 1} (${durationSeconds}s)';
      if (stepTimerIdx != -1) {
        final currentTimer = _timers[stepTimerIdx];
        if (!currentTimer.isRunning) {
          _timers[stepTimerIdx] = currentTimer.copyWith(
            label: label,
            totalSeconds: durationSeconds,
            secondsRemaining: durationSeconds,
            isFinished: false,
          );
        }
      } else {
        _timers.insert(
          0,
          KitchenTimerItem(
            id: 't_step',
            label: label,
            totalSeconds: durationSeconds,
            secondsRemaining: durationSeconds,
            isRunning: false,
          ),
        );
      }
    } else {
      if (stepTimerIdx != -1 && !_timers[stepTimerIdx].isRunning) {
        _timers[stepTimerIdx] = _timers[stepTimerIdx].copyWith(
          label: 'Step ${stepIndex + 1} Timer',
        );
      }
    }
  }

  void _goToStep(int step) {
    if (_activeRecipe == null) return;
    if (step >= 0 && step < _activeRecipe!.cookingSteps.length) {
      _syncStepTimer(step);
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          step,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      } else {
        setState(() => _currentStep = step);
      }
    }
  }

  void _finishCookingFlow(BuildContext context) {
    final appState = context.read<AppState>();
    final accentColor = appState.accentColor;
    if (_activeRecipe != null) {
      appState.addToCookedHistory(_activeRecipe!);
    }
    final dishTitle = _activeRecipe?.title ?? 'your freestyle meal';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: appState.bgPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Column(
            children: [
              const Icon(Icons.check_circle_outline_rounded, size: 48, color: AppTheme.accentGreen),
              const SizedBox(height: 10),
              Text(
                'Complete & Plated',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMain,
                ),
              ),
            ],
          ),
          content: Text(
            'Delicious work making $dishTitle! Would you like to update your kitchen pantry status?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              height: 1.5,
              color: AppTheme.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text(
                'Keep as is',
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pantry inventory updated for cooked recipe!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text('Update Pantry', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  String _getApplianceTemp(String method) {
    switch (method.toLowerCase()) {
      case 'microwave':
        return 'High · 700-800W';
      case 'oven':
        return '180°C (350°F) · Preheated';
      case 'air fryer':
        return '190°C · 12 mins';
      case 'stovetop':
        return 'Medium-High Flame';
      case 'no-cook':
        return 'Chilled / Room Temp';
      default:
        return 'Standard Heat';
    }
  }

  String _formatTimer(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
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

  void _sendChatMessage(String text, {bool isVoice = false, int? voiceDuration}) {
    final query = text.trim();
    if (query.isEmpty) return;

    _chatController.clear();
    setState(() {
      _chatMessages.add(AiChatMessage(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        text: query,
        isUser: true,
        timestamp: DateTime.now(),
        isVoiceMessage: isVoice,
        voiceDurationSeconds: voiceDuration,
      ));
      _isAiResponding = true;
    });

    _scrollChatToBottom();

    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;

      String aiAnswer;
      final q = query.toLowerCase();

      if (q.contains('done') || q.contains('cook') || q.contains('ready')) {
        aiAnswer = 'For ${_activeRecipe?.title ?? 'your dish'}, observe color and aroma. A fragrant sizzle and deep golden edges indicate it is ready to plate.';
      } else if (q.contains('substitute') || q.contains('replace') || q.contains('butter') || q.contains('honey') || q.contains('oil')) {
        aiAnswer = 'Culinary pivot: Neutral vegetable oil or perilla oil works wonderfully. Add a dash of soy sauce or toasted sesame seeds for rich depth.';
      } else if (q.contains('timer') || q.contains('minute')) {
        _addQuickTimer('식 Kitchen Alert', 3);
        aiAnswer = 'Started a 3-minute kitchen alert for you in the Tools station!';
      } else if (q.contains('hot') || q.contains('heat') || q.contains('burn')) {
        aiAnswer = 'Ease heat to medium-low immediately. Lift the pan briefly off the heat to let residual temperature finish the step evenly.';
      } else {
        aiAnswer = _activeRecipe != null
            ? 'Noted! Chef hint for Step ${_currentStep + 1}: Keep a calm pace and keep your ingredients staged within easy reach.'
            : 'Noted! Take your time, taste along the way, and let me know if you need any substitution or timing advice!';
      }

      setState(() {
        _isAiResponding = false;
        _chatMessages.add(AiChatMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          text: aiAnswer,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });

      _scrollChatToBottom();
    });
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
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

  /// Extracts ingredients specific to this step for rich context.
  List<RecipeIngredient> _getIngredientsForStep(String stepText) {
    if (_activeRecipe == null) return [];
    final lower = stepText.toLowerCase();
    final matched = _activeRecipe!.ingredients.where((ing) {
      final nameLower = ing.name.toLowerCase();
      final words = nameLower.split(RegExp(r'\s+'));
      return words.any((w) => w.length > 2 && lower.contains(w));
    }).toList();

    if (matched.isEmpty && _activeRecipe!.ingredients.isNotEmpty) {
      return _activeRecipe!.ingredients.take(2).toList();
    }
    return matched;
  }

  /// Generates a curated, editorial culinary cue (감각 가이드).
  Map<String, String> _getStepSensoryCue(String stepText, int index) {
    final lower = stepText.toLowerCase();
    if (lower.contains('wash') || lower.contains('slice') || lower.contains('peel') || lower.contains('cut') || lower.contains('chop') || lower.contains('prep')) {
      return {
        'tag': 'PREPARATION',
        'title': 'Uniform Cut & Dryness',
        'tip': 'Cut into even bite-sized pieces for consistent cooking. Pat dry thoroughly before heat.',
      };
    } else if (lower.contains('bake') || lower.contains('oven') || lower.contains('roast')) {
      return {
        'tag': 'THERMAL CUE',
        'title': 'Even Heat Circulation',
        'tip': 'Place flat sides down on baking paper so edges caramelize while the flesh turns tender.',
      };
    } else if (lower.contains('butter') || lower.contains('melt') || lower.contains('honey') || lower.contains('drizzle') || lower.contains('glaze')) {
      return {
        'tag': 'FINISHING TOUCH',
        'title': 'Warm Emulsion & Aroma',
        'tip': 'Drizzle glazes over warm butter off high heat to create a glossy, aromatic lacquer.',
      };
    } else if (lower.contains('saute') || lower.contains('fry') || lower.contains('pan') || lower.contains('oil')) {
      return {
        'tag': 'PAN HEAT',
        'title': 'Active Sizzle',
        'tip': 'Maintain steady medium heat so flavors soften and caramelize without burning.',
      };
    } else {
      return {
        'tag': 'CHEF NOTE',
        'title': 'Tasting & Texture',
        'tip': 'Check doneness at the center with a gentle fork press. Rest briefly before plating.',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final accentColor = appState.accentColor;
    final steps = _activeRecipe?.cookingSteps ?? const <String>[];
    final totalSteps = steps.length;
    final progress = (totalSteps > 0) ? (_currentStep + 1) / totalSteps : 1.0;
    final applianceTemp = _activeRecipe != null ? _getApplianceTemp(_activeRecipe!.cookingMethod) : 'Kitchen Session';

    // Explicit threshold: Phone portrait mode is activated whenever screen width < 768px
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTabletMode = screenWidth >= 768;

    return Scaffold(
      backgroundColor: appState.bgPrimary,
      body: SafeArea(
        child: isTabletMode
            ? _buildEditorialStudio(context, appState, accentColor, steps, totalSteps, progress, applianceTemp)
            : _buildMobileFlow(context, appState, accentColor, steps, totalSteps, progress, applianceTemp),
      ),
    );
  }

  // ===========================================================================
  // TABLET / DESKTOP: DUAL-PANE EDITORIAL CULINARY STUDIO (WIDTH >= 768)
  // ===========================================================================
  Widget _buildEditorialStudio(
    BuildContext context,
    AppState appState,
    Color accentColor,
    List<String> steps,
    int totalSteps,
    double progress,
    String applianceTemp,
  ) {
    final currentStepText = steps.isNotEmpty ? steps[_currentStep] : '';
    final stepIngredients = _getIngredientsForStep(currentStepText);
    final sensoryCue = _getStepSensoryCue(currentStepText, _currentStep);

    return Column(
      children: [
        // 1. Refined Minimalist Editorial Header
        _buildStudioHeader(context, appState, accentColor, totalSteps, applianceTemp),

        // Thin progress line
        LinearProgressIndicator(
          value: progress,
          minHeight: 2.5,
          backgroundColor: appState.bgSubtle,
          color: accentColor,
        ),

        // 2. Dual-Pane Spread
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // LEFT PANE: Compact Step Preview & Context OR Free Cooking Hub
              Expanded(
                flex: 60,
                child: Container(
                  color: appState.bgPrimary,
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
                  child: _activeRecipe == null
                      ? _buildFreeCookingHub(context, appState, accentColor, isTablet: true)
                      : Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 840),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Step Eyebrow Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppTheme.textMain,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'STEP 0${_currentStep + 1}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.1,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'OF 0$totalSteps',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.8,
                                            color: AppTheme.textLight,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Recipe Method Pill
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: appState.bgCard,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: appState.bgSubtle),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.local_fire_department_rounded, size: 12, color: accentColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            _activeRecipe?.cookingMethod ?? 'Freestyle',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textMain,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // SPOTIFY LYRICS VERTICAL SCROLLER STAGE (Auto-detects height and fills space)
                                Expanded(
                                  child: _buildSpotifyLyricsScroller(
                                    context: context,
                                    appState: appState,
                                    accentColor: accentColor,
                                    steps: steps,
                                    isTablet: true,
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // COMPACT ACTIVE STEP CONTEXT CARD (Ingredients & Tip combined)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.bgSurface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: appState.bgSubtle, width: 1.0),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Step-Specific Ingredients Row
                                      if (stepIngredients.isNotEmpty) ...[
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(right: 2),
                                              child: Text(
                                                'INGREDIENTS',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 1.0,
                                                  color: AppTheme.textLight,
                                                ),
                                              ),
                                            ),
                                            ...stepIngredients.map((ing) {
                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                                decoration: BoxDecoration(
                                                  color: appState.bgPrimary,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: appState.bgSubtle),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: 5,
                                                      height: 5,
                                                      decoration: BoxDecoration(
                                                        color: accentColor,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      ing.name,
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 11.5,
                                                        fontWeight: FontWeight.w700,
                                                        color: AppTheme.textMain,
                                                      ),
                                                    ),
                                                    if (ing.amount != null) ...[
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '(${ing.amount})',
                                                        style: GoogleFonts.plusJakartaSans(
                                                          fontSize: 11,
                                                          color: AppTheme.textMuted,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              );
                                            }),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                      ],

                                      // Compact Sensory Tip
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: accentColor.withValues(alpha: 0.12),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(Icons.lightbulb_outline_rounded, size: 13, color: accentColor),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: RichText(
                                              text: TextSpan(
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11.5,
                                                  height: 1.4,
                                                  color: AppTheme.textMuted,
                                                ),
                                                children: [
                                                  TextSpan(
                                                    text: '${sensoryCue['title']}: ',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontWeight: FontWeight.w800,
                                                      color: AppTheme.textMain,
                                                    ),
                                                  ),
                                                  TextSpan(text: sensoryCue['tip']),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // ALWAYS VISIBLE BOTTOM NAVIGATION CONTROLS
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Previous Button
                                    if (_currentStep > 0)
                                      OutlinedButton.icon(
                                        onPressed: () => _goToStep(_currentStep - 1),
                                        icon: const Icon(Icons.arrow_back_rounded, size: 15),
                                        label: Text(
                                          'Previous',
                                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.textMain,
                                          side: BorderSide(color: appState.bgSubtle, width: 1.2),
                                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        ),
                                      )
                                    else
                                      const SizedBox(width: 90),

                                    // Center Step Dots
                                    Row(
                                      children: List.generate(totalSteps, (i) {
                                        final isActive = i == _currentStep;
                                        return GestureDetector(
                                          onTap: () => _goToStep(i),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            margin: const EdgeInsets.symmetric(horizontal: 3),
                                            width: isActive ? 18 : 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: isActive ? AppTheme.textMain : appState.bgSubtle,
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),

                                    // Next / Complete Button
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        if (_currentStep < totalSteps - 1) {
                                          _goToStep(_currentStep + 1);
                                        } else {
                                          _finishCookingFlow(context);
                                        }
                                      },
                                      icon: Icon(
                                        _currentStep < totalSteps - 1 ? Icons.arrow_forward_rounded : Icons.check_rounded,
                                        size: 16,
                                      ),
                                      label: Text(
                                        _currentStep < totalSteps - 1
                                            ? 'Next Step (${_currentStep + 2}/$totalSteps)'
                                            : 'Finish Plating',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.textMain,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        elevation: 0,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),

              // RIGHT PANE: Clean High-End Assistant & Tools Panel
              Expanded(
                flex: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgSurface,
                    border: Border(left: BorderSide(color: appState.bgSubtle, width: 1.2)),
                  ),
                  child: Column(
                    children: [
                      // Editorial Segmented Tab Switcher (No harsh material underlines)
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: appState.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: appState.bgSubtle),
                        ),
                        child: Row(
                          children: [
                            _buildSegmentTab(
                              tabIndex: 0,
                              label: '식 AI',
                              icon: Icons.auto_awesome_rounded,
                              appState: appState,
                              accentColor: accentColor,
                            ),
                            _buildSegmentTab(
                              tabIndex: 1,
                              label: 'Kitchen Tools',
                              icon: Icons.tune_rounded,
                              appState: appState,
                              accentColor: accentColor,
                            ),
                          ],
                        ),
                      ),

                      // Tab View Content
                      Expanded(
                        child: _activePanelTab == 0
                            ? _buildAiChatSpread(context, appState, accentColor)
                            : _buildKitchenToolsSpread(context, appState, accentColor),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SPOTIFY-STYLE RECIPE STEP SCROLLER
  // Fluid vertical slide & snap, current step is bold & dark, next step is readable preview
  // ---------------------------------------------------------------------------
  Widget _buildSpotifyLyricsScroller({
    required BuildContext context,
    required AppState appState,
    required Color accentColor,
    required List<String> steps,
    required bool isTablet,
    double? height,
  }) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: appState.bgSubtle, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ShaderMask(
          shaderCallback: (rect) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black,
                Colors.black,
                Colors.transparent,
              ],
              stops: [0.0, 0.08, 0.92, 1.0],
            ).createShader(rect);
          },
          blendMode: BlendMode.dstIn,
          child: AnimatedBuilder(
            animation: _pageController,
            builder: (context, _) {
              double currentPage = _currentStep.toDouble();
              if (_pageController.hasClients && _pageController.page != null) {
                currentPage = _pageController.page!;
              }

              return PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: steps.length,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (idx) {
                  if (_currentStep != idx) {
                    setState(() => _currentStep = idx);
                    _syncStepTimer(idx);
                  }
                },
                itemBuilder: (context, index) {
                  final stepText = steps[index];
                  final diff = (currentPage - index).abs().clamp(0.0, 1.0);

                  // Dynamic Spotify lyrics scaling:
                  // Active: dark stone, prominent 21.5px on tablet (18px mobile), bold w800, full 1.0 opacity
                  // Preview / Faded: readable 16px on tablet (14.5px mobile), medium w500, soft 0.48 opacity
                  final isCurrent = diff < 0.35;
                  final opacity = (1.0 - (diff * 0.52)).clamp(0.48, 1.0);
                  final fontSize = isTablet
                      ? (21.5 - (diff * 5.5))
                      : (21.0 - (diff * 4.0));
                  final textColor = Color.lerp(
                    AppTheme.textMain,
                    AppTheme.textMuted,
                    diff,
                  )!;
                  final fontWeight = isCurrent ? FontWeight.w800 : FontWeight.w500;

                  return Center(
                    child: InkWell(
                      onTap: () => _goToStep(index),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 22 : 16,
                          vertical: 6,
                        ),
                        child: Opacity(
                          opacity: opacity,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Step Number Badge
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? AppTheme.textMain
                                      : appState.bgSubtle,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: isCurrent ? Colors.white : AppTheme.textMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Step Text (Slideable, natural readable spacing)
                              Expanded(
                                child: Text(
                                  stepText,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: fontSize,
                                    height: 1.45,
                                    fontWeight: fontWeight,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EDITORIAL HEADER
  // ---------------------------------------------------------------------------
  Widget _buildStudioHeader(
    BuildContext context,
    AppState appState,
    Color accentColor,
    int totalSteps,
    String applianceTemp,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        border: Border(bottom: BorderSide(color: appState.bgSubtle)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Exit Session',
                icon: const Icon(Icons.close_rounded, size: 22, color: AppTheme.textMain),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _activeRecipe?.title ?? 'Open Kitchen Session',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMain,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: appState.bgCard,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: appState.bgSubtle),
                        ),
                        child: Text(
                          _activeRecipe != null ? '식 · STUDIO' : 'FREESTYLE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _activeRecipe != null
                        ? '${_activeRecipe!.koreanTitle} · Step ${_currentStep + 1} of $totalSteps'
                        : '식 AI Sous-Chef & Kitchen Tools Active',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Actions: Switch Recipe / Random + Appliance Heat Gauge Pill
          Row(
            children: [
              if (_activeRecipe != null)
                TextButton.icon(
                  onPressed: _switchToFreeCooking,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: Text(
                    'Change Recipe',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textMuted,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                )
              else
                TextButton.icon(
                  onPressed: () => _pickRandomRecipe(appState),
                  icon: const Icon(Icons.casino_outlined, size: 16),
                  label: Text(
                    'Random Dish',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: appState.bgPrimary,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: appState.bgSubtle),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 14, color: accentColor),
                    const SizedBox(width: 7),
                    Text(
                      applianceTemp,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SEGMENTED TAB BUTTON
  // ---------------------------------------------------------------------------
  Widget _buildSegmentTab({
    required int tabIndex,
    required String label,
    required IconData icon,
    required AppState appState,
    required Color accentColor,
  }) {
    final isSelected = _activePanelTab == tabIndex;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activePanelTab = tabIndex),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.bgSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? const [
                    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? AppTheme.textMain : AppTheme.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppTheme.textMain : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RIGHT PANE: 식 AI CHAT SPREAD (HIGH-END CONCIERGE AESTHETIC)
  // ---------------------------------------------------------------------------
  Widget _buildAiChatSpread(BuildContext context, AppState appState, Color accentColor) {
    return Column(
      children: [
        // Sub-header
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppTheme.accentGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Live culinary intelligence tuned to your session',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),

        // Messages Flow
        Expanded(
          child: ListView.builder(
            controller: _chatScrollController,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            itemCount: _chatMessages.length + (_isAiResponding ? 1 : 0),
            itemBuilder: (ctx, idx) {
              if (idx == _chatMessages.length && _isAiResponding) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: appState.bgCard,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, color: accentColor),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '식 is analyzing...',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              final msg = _chatMessages[idx];
              final isUser = msg.isUser;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isUser) ...[
                      Container(
                        width: 26,
                        height: 26,
                        margin: const EdgeInsets.only(right: 8, top: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.textMain,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '식',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isUser ? AppTheme.textMain : appState.bgPrimary,
                          borderRadius: BorderRadius.circular(16),
                          border: isUser ? null : Border.all(color: appState.bgSubtle),
                        ),
                        child: msg.isVoiceMessage
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.graphic_eq_rounded, color: isUser ? Colors.white : accentColor, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Voice 0:0${msg.voiceDurationSeconds ?? 3}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isUser ? Colors.white70 : AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '"${msg.text}"',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontStyle: FontStyle.italic,
                                      color: isUser ? Colors.white : AppTheme.textMain,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                msg.text,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  height: 1.45,
                                  color: isUser ? Colors.white : AppTheme.textMain,
                                  fontWeight: isUser ? FontWeight.w500 : FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Quick Topic Pills (Responsive Wrap - all suggestions visible, no truncation)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              'Check doneness cues',
              'Substitutions',
              'Heat too high',
              'Set 4m timer',
            ].map((topic) {
              return ActionChip(
                label: Text(
                  topic,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMain,
                  ),
                ),
                backgroundColor: appState.bgCard,
                side: BorderSide(color: appState.bgSubtle),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                onPressed: () => _sendChatMessage(topic),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 6),

        // Minimalist Input Composer Bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          decoration: BoxDecoration(
            color: AppTheme.bgSurface,
            border: Border(top: BorderSide(color: appState.bgSubtle)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                  decoration: BoxDecoration(
                    color: appState.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: appState.bgSubtle),
                  ),
                  child: TextField(
                    controller: _chatController,
                    onSubmitted: (val) => _sendChatMessage(val),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMain),
                    decoration: InputDecoration(
                      hintText: 'Ask 식 anything...',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppTheme.textLight),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Tactile Voice Message Trigger
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    final res = await VoiceMessageDialog.show(context);
                    if (res != null && mounted) {
                      _sendChatMessage(res.text, isVoice: true, voiceDuration: res.durationSeconds);
                    }
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.mic_rounded, color: accentColor, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Send Action Button
              IconButton(
                icon: const Icon(Icons.arrow_upward_rounded, color: AppTheme.textMain, size: 19),
                onPressed: () => _sendChatMessage(_chatController.text),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // RIGHT PANE: KITCHEN TOOLS SPREAD (TIMERS, CONVERTER, INGREDIENTS)
  // ---------------------------------------------------------------------------
  Widget _buildKitchenToolsSpread(BuildContext context, AppState appState, Color accentColor) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Timers Station
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 15, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  'Multi-Timers',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textMain),
                ),
              ],
            ),
            InkWell(
              onTap: () => _showAddTimerModal(context, accentColor),
              child: Text(
                '+ Custom',
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: accentColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        ..._timers.map((t) => _buildTimerCard(t, accentColor, appState)),

        const SizedBox(height: 4),

        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _quickChip('+1m Boil', 1, accentColor, appState),
            _quickChip('+3m Rest', 3, accentColor, appState),
            _quickChip('+5m Steam', 5, accentColor, appState),
            _quickChip('+10m Bake', 10, accentColor, appState),
          ],
        ),

        const SizedBox(height: 20),

        // 2. Kitchen Measurement & Student Approximate Converter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.balance_rounded, size: 15, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  'Kitchen Measurements',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textMain),
                ),
              ],
            ),
            // Mode switcher pill: Student Everyday vs Standard
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                color: appState.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: appState.bgSubtle),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _converterMode = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: _converterMode == 0 ? AppTheme.bgSurface : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 11,
                            color: _converterMode == 0 ? AppTheme.textMain : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Student Guide',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: _converterMode == 0 ? FontWeight.w800 : FontWeight.w600,
                              color: _converterMode == 0 ? AppTheme.textMain : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _converterMode = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: _converterMode == 1 ? AppTheme.bgSurface : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.scale_rounded,
                            size: 11,
                            color: _converterMode == 1 ? AppTheme.textMain : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Standard',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: _converterMode == 1 ? FontWeight.w800 : FontWeight.w600,
                              color: _converterMode == 1 ? AppTheme.textMain : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildKitchenConverterContent(context, appState, accentColor),

        const SizedBox(height: 20),

        // 3. Ingredients Checklist or Kitchen Pantry
        if (_activeRecipe != null) ...[
          Row(
            children: [
              Icon(Icons.checklist_rounded, size: 15, color: accentColor),
              const SizedBox(width: 8),
              Text(
                'Recipe Ingredients',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textMain),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: appState.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: appState.bgSubtle),
            ),
            child: Column(
              children: _activeRecipe!.ingredients.map((ing) {
                final isChecked = _checkedIngredients.contains(ing.name);

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isChecked) {
                        _checkedIngredients.remove(ing.name);
                      } else {
                        _checkedIngredients.add(ing.name);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(
                          isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: isChecked ? accentColor : AppTheme.textLight,
                          size: 17,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            ing.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isChecked ? AppTheme.textLight : AppTheme.textMain,
                              decoration: isChecked ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        if (ing.amount != null)
                          Text(
                            ing.amount!,
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ] else ...[
          Row(
            children: [
              Icon(Icons.kitchen_rounded, size: 15, color: accentColor),
              const SizedBox(width: 8),
              Text(
                'Pantry Ingredients on Hand',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textMain),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: appState.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: appState.bgSubtle),
            ),
            child: appState.fridgeItems.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'No kitchen inventory items logged yet.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  )
                : Column(
                    children: appState.fridgeItems.take(8).map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.name,
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              item.quantityDisplay ?? '',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ],
    );
  }

  Widget _buildKitchenConverterContent(BuildContext context, AppState appState, Color accentColor) {
    if (_converterMode == 0) {
      // Student Everyday Approximate Converter (No Equipment Needed)
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: appState.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: appState.bgSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tool selector chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _studentToolChip('dining_spoon', Icons.restaurant_menu_rounded, 'Dining Spoon', accentColor, appState),
                  const SizedBox(width: 5),
                  _studentToolChip('tea_spoon', Icons.coffee_rounded, 'Teaspoon', accentColor, appState),
                  const SizedBox(width: 5),
                  _studentToolChip('mug', Icons.local_cafe_outlined, 'Mug / Cup', accentColor, appState),
                  const SizedBox(width: 5),
                  _studentToolChip('paper_cup', Icons.local_drink_outlined, 'Paper Cup', accentColor, appState),
                  const SizedBox(width: 5),
                  _studentToolChip('hand_guide', Icons.pan_tool_outlined, 'Hand Portions', accentColor, appState),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildStudentToolCard(accentColor, appState),
          ],
        ),
      );
    }

    // Standard Units (with slider)
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appState.bgCard,
        borderRadius: BorderRadius.circular(14),
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
                dropdownColor: AppTheme.bgSurface,
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.textMain),
                items: const [
                  DropdownMenuItem(value: 'tbsp → ml', child: Text('tbsp → ml')),
                  DropdownMenuItem(value: 'cups → ml', child: Text('cups → ml')),
                  DropdownMenuItem(value: 'oz → grams', child: Text('oz → grams')),
                  DropdownMenuItem(value: '°C → °F', child: Text('°C → °F')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _selectedConverter = v);
                },
              ),
              Text(
                _calculateConversion(),
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textMain),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 2.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: AppTheme.textMain,
              inactiveTrackColor: appState.bgSubtle,
              thumbColor: AppTheme.textMain,
            ),
            child: Slider(
              value: _converterInput,
              min: 0.5,
              max: _selectedConverter.contains('°C') ? 250 : 10,
              onChanged: (val) => setState(() => _converterInput = val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentToolChip(String id, IconData icon, String label, Color accentColor, AppState appState) {
    final isSelected = _selectedStudentTool == id;
    return InkWell(
      onTap: () => setState(() => _selectedStudentTool = id),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : appState.bgPrimary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? accentColor : appState.bgSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected ? Colors.white : AppTheme.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentToolCard(Color accentColor, AppState appState) {
    switch (_selectedStudentTool) {
      case 'dining_spoon':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _toolInfoRow('Level Dining Spoon', '≈ 10 ml (~⅔ measuring tbsp)'),
            _toolInfoRow('Heaping Dining Spoon', '≈ 15 ml (Equal to 1 full tbsp!)'),
            _toolInfoRow('Soy Sauce / Oil / Water', '1 spoon ≈ 10 grams liquid'),
            _toolInfoRow('Gochujang / Honey / Sugar', '1 heaping spoon ≈ 12–15 grams'),
          ],
        );
      case 'tea_spoon':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _toolInfoRow('Coffee / Tea Spoon', '≈ 3–5 ml (Equal to 1 measuring tsp)'),
            _toolInfoRow('Salt / Fine Pepper', '1 level small spoon ≈ 4–5 grams'),
            _toolInfoRow('Minced Garlic', '1 small spoon ≈ 5 grams'),
          ],
        );
      case 'mug':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _toolInfoRow('Standard Ceramic Mug', '≈ 240–250 ml (Equal to 1 US Cup!)'),
            _toolInfoRow('Dry White / Jasmine Rice', '1 mug ≈ 160–170g uncooked'),
            _toolInfoRow('Cooked Rice / Broth', '1 mug ≈ 200–220g (1 standard bowl)'),
          ],
        );
      case 'paper_cup':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _toolInfoRow('Standard Paper Cup', '≈ 180–190 ml (~¾ US Cup)'),
            _toolInfoRow('Classic Kitchen Standard', '1 cup rice = 150g, water = 180ml'),
            _toolInfoRow('Flour / Starch', '1 level paper cup ≈ 100 grams'),
          ],
        );
      case 'hand_guide':
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _toolInfoRow('Closed Fist', '≈ 1 Cup (Rice, chopped veggies, pasta)'),
            _toolInfoRow('Open Palm', '≈ 85–100g (Meat, chicken, tofu block)'),
            _toolInfoRow('Whole Thumb', '≈ 1 Tablespoon (~15ml butter/paste)'),
            _toolInfoRow('Thumb Tip', '≈ 1 Teaspoon (~5ml oil/dressing)'),
            _toolInfoRow('3-Finger Pinch', '≈ ⅛ Teaspoon (~0.5g salt/pepper)'),
          ],
        );
    }
  }

  Widget _toolInfoRow(String title, String detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(color: AppTheme.textMain, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppTheme.textMuted, height: 1.35),
                children: [
                  TextSpan(text: '$title: ', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppTheme.textMain)),
                  TextSpan(text: detail),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TIMERS HELPERS
  // ---------------------------------------------------------------------------
  Widget _buildTimerCard(KitchenTimerItem t, Color accentColor, AppState appState) {
    final isStepTimer = t.id == 't_step';
    final progress = t.totalSeconds > 0 ? (t.secondsRemaining / t.totalSeconds).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: t.isFinished
              ? AppTheme.accentAmber
              : t.isRunning
                  ? accentColor
                  : appState.bgSubtle,
          width: t.isRunning ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Circular Round Bar Level with Play/Pause button in center
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
              width: 44,
              height: 44,
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
          const SizedBox(width: 10),

          // Label and formatted timer time (tap to adjust with circular dial)
          Expanded(
            child: InkWell(
              onTap: () => _showAddTimerModal(context, accentColor, existingTimer: t),
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        t.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isStepTimer) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Step Timer',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Text(
                        _formatTimer(t.secondsRemaining),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: t.isFinished
                              ? AppTheme.accentAmber
                              : t.isRunning
                                  ? accentColor
                                  : AppTheme.textMain,
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

          // Reset & Delete Buttons
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.restart_alt_rounded, size: 17, color: AppTheme.textMuted),
                tooltip: 'Reset',
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
                icon: const Icon(Icons.close_rounded, size: 15, color: AppTheme.textLight),
                tooltip: 'Remove',
                onPressed: () => setState(() => _timers.removeWhere((i) => i.id == t.id)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickChip(String label, int min, Color accentColor, AppState appState) {
    return ActionChip(
      label: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.textMain)),
      backgroundColor: appState.bgCard,
      side: BorderSide(color: appState.bgSubtle),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      onPressed: () => _addQuickTimer(label.replaceAll(RegExp(r'\+\d+m '), ''), min),
    );
  }

  void _showAddTimerModal(BuildContext context, Color accentColor, {KitchenTimerItem? existingTimer}) {
    int min = existingTimer != null ? math.max(1, (existingTimer.totalSeconds / 60).round()) : 5;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                existingTimer != null ? 'Adjust Timer' : 'Set Kitchen Timer',
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
                final label = existingTimer?.label ?? 'Kitchen Timer';
                if (existingTimer != null) {
                  setState(() {
                    final idx = _timers.indexWhere((item) => item.id == existingTimer.id);
                    if (idx != -1) {
                      _timers[idx] = existingTimer.copyWith(
                        label: label,
                        totalSeconds: min * 60,
                        secondsRemaining: min * 60,
                        isFinished: false,
                        isRunning: true,
                      );
                    }
                  });
                } else {
                  _addQuickTimer(label, min);
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(existingTimer != null ? 'Save & Start' : 'Start Timer'),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // FREE COOKING / RECIPE SELECTION HUB
  // ===========================================================================
  Widget _buildFreeCookingHub(
    BuildContext context,
    AppState appState,
    Color accentColor, {
    required bool isTablet,
  }) {
    final recipes = appState.recipes;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 8 : 4,
        vertical: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hero Freestyle Banner
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: appState.bgCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: appState.bgSubtle),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.textMain,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'OPEN CULINARY STUDIO',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 12, color: accentColor),
                          const SizedBox(width: 5),
                          Text(
                            'Tools & AI Ready',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Freestyle Kitchen Session',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMain,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cook without following a specific recipe. Multi-timers, student everyday converters, and live 식 AI sous-chef assistance are active and available in your companion tools panel.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    height: 1.45,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 18),
                // Random Recipe Action Button
                ElevatedButton.icon(
                  onPressed: () => _pickRandomRecipe(appState),
                  icon: const Icon(Icons.shuffle_rounded, size: 18),
                  label: Text(
                    'Surprise Me · Random Recipe',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. Curated Recipe Selection Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select a Recipe to Follow',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Choose any dish to start step-by-step lyrics and synced timers',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              Text(
                '${recipes.length} dishes',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textLight,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 3. Selectable Recipe Grid or List
          if (isTablet)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recipes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 116,
              ),
              itemBuilder: (context, index) {
                final r = recipes[index];
                return _buildRecipeSelectionTile(r, appState, accentColor);
              },
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recipes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final r = recipes[index];
                return _buildRecipeSelectionTile(r, appState, accentColor);
              },
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRecipeSelectionTile(Recipe r, AppState appState, Color accentColor) {
    return InkWell(
      onTap: () => _selectRecipe(r),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: appState.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: appState.bgSubtle),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        r.categoryTag.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '·  ${r.koreanTitle}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    r.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMain,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: appState.bgPrimary,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: appState.bgSubtle),
                        ),
                        child: Text(
                          '${r.cookingTimeMinutes}m',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: appState.bgPrimary,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: appState.bgSubtle),
                        ),
                        child: Text(
                          r.cookingMethod,
                          style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${r.kitchenMatchPercent}% match',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: accentColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppTheme.textMain,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // MOBILE FLOW (DEDICATED PHONE PORTRAIT MODE - SCREEN WIDTH < 768)
  // ===========================================================================
  Widget _buildMobileFlow(
    BuildContext context,
    AppState appState,
    Color accentColor,
    List<String> steps,
    int totalSteps,
    double progress,
    String applianceTemp,
  ) {
    final currentStepText = steps.isNotEmpty ? steps[_currentStep] : '';
    final stepIngredients = _getIngredientsForStep(currentStepText);
    final cue = _getStepSensoryCue(currentStepText, _currentStep);

    return Column(
      children: [
        // Top Mobile Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _activeRecipe?.title ?? 'Kitchen Session · Freestyle',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      _activeRecipe != null
                          ? 'Step ${_currentStep + 1} of $totalSteps · $applianceTemp'
                          : '식 AI Sous-Chef & Tools Active',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  // Switch / Random Recipe Trigger
                  if (_activeRecipe != null)
                    IconButton(
                      tooltip: 'Change Recipe',
                      icon: const Icon(Icons.swap_horiz_rounded, size: 20, color: AppTheme.textMuted),
                      onPressed: _switchToFreeCooking,
                    )
                  else
                    IconButton(
                      tooltip: 'Surprise Me',
                      icon: Icon(Icons.casino_outlined, size: 20, color: accentColor),
                      onPressed: () => _pickRandomRecipe(appState),
                    ),

                  // 식 AI Trigger Pill
                  IconButton(
                    tooltip: '식 AI Assistant',
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppTheme.textMain,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '식',
                        style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                    onPressed: () => _openMobileAssistantSheet(context, appState, accentColor, 0),
                  ),

                  // Kitchen Tools Trigger
                  IconButton(
                    tooltip: 'Kitchen Tools',
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: appState.bgCard,
                        shape: BoxShape.circle,
                        border: Border.all(color: appState.bgSubtle),
                      ),
                      child: const Icon(Icons.tune_rounded, size: 16, color: AppTheme.textMain),
                    ),
                    onPressed: () => _openMobileAssistantSheet(context, appState, accentColor, 1),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Progress Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: appState.bgSubtle,
              color: accentColor,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Mobile Scrollable Content
        Expanded(
          child: _activeRecipe == null
              ? _buildFreeCookingHub(context, appState, accentColor, isTablet: false)
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step Eyebrow
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: AppTheme.textMain,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'STEP 0${_currentStep + 1}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            _activeRecipe!.cookingMethod,
                            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // SPOTIFY LYRICS SCROLLER ON MOBILE (Slides smoothly, comfortable height)
                      _buildSpotifyLyricsScroller(
                        context: context,
                        appState: appState,
                        accentColor: accentColor,
                        steps: steps,
                        isTablet: false,
                        height: 320,
                      ),

                      const SizedBox(height: 12),

                      // Step Ingredients
                      if (stepIngredients.isNotEmpty) ...[
                        Text(
                          'ACTIVE INGREDIENTS',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: stepIngredients.map((ing) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.bgSurface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: appState.bgSubtle),
                              ),
                              child: Text(
                                '${ing.name}${ing.amount != null ? ' · ${ing.amount}' : ''}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Compact Sensory Tip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.bgSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: appState.bgSubtle),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lightbulb_outline_rounded, size: 14, color: accentColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${cue['title']}: ${cue['tip']}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, height: 1.35, color: AppTheme.textMuted),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),
                    ],
                  ),
                ),
        ),

        // Docked Mobile Bottom Navigation Bar (Only for active recipe)
        if (_activeRecipe != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              border: Border(top: BorderSide(color: appState.bgSubtle)),
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _goToStep(_currentStep - 1),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textMain,
                        side: BorderSide(color: appState.bgSubtle),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentStep < totalSteps - 1) {
                        _goToStep(_currentStep + 1);
                      } else {
                        _finishCookingFlow(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.textMain,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentStep < totalSteps - 1 ? 'Next Step →' : 'Finish Plating',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _openMobileAssistantSheet(BuildContext context, AppState appState, Color accentColor, int initialTab) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SizedBox(
              height: MediaQuery.sizeOf(ctx).height * 0.8,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: AppTheme.textLight, borderRadius: BorderRadius.circular(2)),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: appState.bgCard,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => _activePanelTab = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _activePanelTab == 0 ? AppTheme.bgSurface : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '식 AI',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => _activePanelTab = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _activePanelTab == 1 ? AppTheme.bgSurface : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Kitchen Tools',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _activePanelTab == 0
                        ? _buildAiChatSpread(ctx, appState, accentColor)
                        : _buildKitchenToolsSpread(ctx, appState, accentColor),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
