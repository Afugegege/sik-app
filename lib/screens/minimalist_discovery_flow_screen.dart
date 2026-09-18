import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

enum DiscoveryPhase {
  questionnaire,
  processing,
  swipeDeck,
  completed,
}

class MinimalistDiscoveryFlowScreen extends StatefulWidget {
  const MinimalistDiscoveryFlowScreen({super.key});

  @override
  State<MinimalistDiscoveryFlowScreen> createState() => _MinimalistDiscoveryFlowScreenState();
}

class _MinimalistDiscoveryFlowScreenState extends State<MinimalistDiscoveryFlowScreen>
    with SingleTickerProviderStateMixin {
  DiscoveryPhase _currentPhase = DiscoveryPhase.questionnaire;

  // Questionnaire State
  int _questionStep = 0; // 0, 1, 2
  String? _selectedMood; // 'warm', 'crisp', 'staple'
  String? _selectedVibe; // 'spicy', 'mild'
  String? _selectedTimeframe; // 'under_10', '15_20', 'any'
  String? _selectedMethodPref; // 'stovetop', 'quick_device'
  String? _selectedConstraint; // 'strict_have', 'minimal_3_4', 'open'

  // Card Deck State
  List<Recipe> _deck = [];
  final List<Recipe> _savedInSession = [];
  final List<Recipe> _wishlistInSession = [];

  // Drag & Swipe Animation Controller
  Offset _dragOffset = Offset.zero;
  late AnimationController _springController;
  late Animation<Offset> _springAnimation;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _springAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(
      CurvedAnimation(parent: _springController, curve: Curves.easeOutCubic),
    );
    _springController.addListener(() {
      setState(() {
        _dragOffset = _springAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _proceedToNextQuestion() {
    if (_questionStep < 2) {
      setState(() {
        _questionStep++;
      });
    } else {
      _startBackgroundFormulation();
    }
  }

  void _startBackgroundFormulation() {
    setState(() {
      _currentPhase = DiscoveryPhase.processing;
    });

    final appState = context.read<AppState>();
    final curatedCards = appState.curateDiscoveryDeck(
      mood: _selectedMood ?? 'craving',
      vibe: _selectedVibe ?? 'any',
      timeframe: _selectedTimeframe ?? 'under_10',
      constraint: _selectedConstraint ?? 'minimal_3_4',
      methodPref: _selectedMethodPref,
    );

    // Simulate clean background processing
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() {
        _deck = List.from(curatedCards);
        _currentPhase = DiscoveryPhase.swipeDeck;
      });
    });
  }

  void _onSwipeRight() {
    if (_deck.isEmpty) return;
    final topRecipe = _deck.removeAt(0);
    _savedInSession.add(topRecipe);
    context.read<AppState>().saveRecipeFromDiscovery(topRecipe);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved "${topRecipe.title}" to your recipes'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    _resetDrag();
    _checkDeckCompletion();
  }

  void _onSwipeLeft() {
    if (_deck.isEmpty) return;
    _deck.removeAt(0);
    _resetDrag();
    _checkDeckCompletion();
  }

  void _onSwipeUp() {
    if (_deck.isEmpty) return;
    final topRecipe = _deck.removeAt(0);
    _wishlistInSession.add(topRecipe);
    context.read<AppState>().addToWishlist(topRecipe);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved "${topRecipe.title}" to later wishlist'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    _resetDrag();
    _checkDeckCompletion();
  }

  void _resetDrag() {
    setState(() {
      _dragOffset = Offset.zero;
    });
  }

  void _checkDeckCompletion() {
    if (_deck.isEmpty) {
      setState(() {
        _currentPhase = DiscoveryPhase.completed;
      });
    } else {
      setState(() {});
    }
  }

  void _springBack() {
    _springAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _springController, curve: Curves.easeOutCubic),
    );
    _springController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final accentColor = appState.accentColor;

    return Scaffold(
      backgroundColor: appState.bgPrimary,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _buildCurrentPhaseView(context, appState, accentColor),
        ),
      ),
    );
  }

  Widget _buildCurrentPhaseView(BuildContext context, AppState appState, Color accentColor) {
    switch (_currentPhase) {
      case DiscoveryPhase.questionnaire:
        return _buildQuestionnaireView(context, appState, accentColor);
      case DiscoveryPhase.processing:
        return _buildProcessingView(context, appState, accentColor);
      case DiscoveryPhase.swipeDeck:
        return _buildSwipeDeckView(context, appState, accentColor);
      case DiscoveryPhase.completed:
        return _buildCompletedView(context, appState, accentColor);
    }
  }

  // ==========================================
  // PHASE 1: MINIMALIST BLANK QUESTIONNAIRE
  // ==========================================
  Widget _buildQuestionnaireView(BuildContext context, AppState appState, Color accentColor) {
    final bool canProceed;
    if (_questionStep == 0) {
      canProceed = _selectedMood != null;
    } else if (_questionStep == 1) {
      canProceed = _selectedTimeframe != null;
    } else {
      canProceed = _selectedConstraint != null;
    }

    return Column(
      key: ValueKey('question_step_$_questionStep'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Minimalist Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '식',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'DISCOVERY',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: appState.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: appState.bgSubtle),
                    ),
                    child: Text(
                      '0${_questionStep + 1} / 03',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.read<AppState>().setActiveTab(AppState.tabDishes);
                      }
                    },
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppTheme.textLight,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Question Content (Scrollable blank canvas)
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_questionStep == 0) ...[
                  _buildQuestionHeader(
                    title: 'What are you in the mood for?',
                    subtitle: 'Choose a direction to curate your deck',
                  ),
                  const SizedBox(height: 20),
                  _buildOptionTile(
                    title: 'I want to bake',
                    isSelected: _selectedMood == 'bake',
                    onTap: () => setState(() {
                      _selectedMood = 'bake';
                      _selectedVibe = 'any_bake';
                    }),
                    accentColor: accentColor,
                    appState: appState,
                  ),
                  const SizedBox(height: 10),
                  _buildOptionTile(
                    title: 'Just craving something',
                    isSelected: _selectedMood == 'craving',
                    onTap: () => setState(() {
                      _selectedMood = 'craving';
                      _selectedVibe = 'any_craving';
                    }),
                    accentColor: accentColor,
                    appState: appState,
                  ),
                  const SizedBox(height: 10),
                  _buildOptionTile(
                    title: 'I want dessert',
                    isSelected: _selectedMood == 'dessert',
                    onTap: () => setState(() {
                      _selectedMood = 'dessert';
                      _selectedVibe = 'any_dessert';
                    }),
                    accentColor: accentColor,
                    appState: appState,
                  ),
                  const SizedBox(height: 10),
                  _buildOptionTile(
                    title: 'Comforting savory meal',
                    isSelected: _selectedMood == 'savory',
                    onTap: () => setState(() {
                      _selectedMood = 'savory';
                      _selectedVibe = 'any_savory';
                    }),
                    accentColor: accentColor,
                    appState: appState,
                  ),

                  // Progressive follow-up sub-options
                  if (_selectedMood != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      _selectedMood == 'bake'
                          ? 'BAKING DIRECTION (OPTIONAL)'
                          : (_selectedMood == 'dessert'
                              ? 'DESSERT STYLE (OPTIONAL)'
                              : (_selectedMood == 'craving'
                                  ? 'CRAVING VIBE (OPTIONAL)'
                                  : 'MEAL FOCUS (OPTIONAL)')),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_selectedMood == 'bake')
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildSubChip(
                            label: 'Sweet Bake',
                            isSelected: _selectedVibe == 'sweet_bake',
                            onTap: () => setState(() => _selectedVibe = 'sweet_bake'),
                            accentColor: accentColor,
                            appState: appState,
                          ),
                          _buildSubChip(
                            label: 'Savory Bake',
                            isSelected: _selectedVibe == 'savory_bake',
                            onTap: () => setState(() => _selectedVibe = 'savory_bake'),
                            accentColor: accentColor,
                            appState: appState,
                          ),
                          _buildSubChip(
                            label: 'Any Baked Treat',
                            isSelected: _selectedVibe == 'any_bake',
                            onTap: () => setState(() => _selectedVibe = 'any_bake'),
                            accentColor: accentColor,
                            appState: appState,
                          ),
                        ],
                      )
                    else if (_selectedMood == 'dessert')
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildSubChip(
                            label: 'Warm Desserts',
                            isSelected: _selectedVibe == 'warm_dessert',
                            onTap: () => setState(() => _selectedVibe = 'warm_dessert'),
                            accentColor: accentColor,
                            appState: appState,
                          ),
                          _buildSubChip(
                            label: 'Quick & Light',
                            isSelected: _selectedVibe == 'quick_sweet',
                            onTap: () => setState(() => _selectedVibe = 'quick_sweet'),
                            accentColor: accentColor,
                            appState: appState,
                          ),
                          _buildSubChip(
                            label: 'Any Dessert',
                            isSelected: _selectedVibe == 'any_dessert',
                            onTap: () => setState(() => _selectedVibe = 'any_dessert'),
                            accentColor: accentColor,
                            appState: appState,
                          ),
                        ],
                      )
                    else if (_selectedMood == 'craving')
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildSubChip(
                            label: 'Crispy & Savory',
                            isSelected: _selectedVibe == 'crispy_snack',
                            onTap: () => setState(() => _selectedVibe = 'crispy_snack'),
                            accentColor: accentColor,
                            appState: appState,
                          ),
                          _buildSubChip(
                            label: 'Sweet Craving',
                            isSelected: _selectedVibe == 'sweet_craving',
                            onTap: () => setState(() => _selectedVibe = 'sweet_craving'),
                            accentColor: accentColor,
                            appState: appState,
                          ),
                          _buildSubChip(
                            label: 'Any Craving',
                            isSelected: _selectedVibe == 'any_craving',
                            onTap: () => setState(() => _selectedVibe = 'any_craving'),
                            accentColor: accentColor,
                            appState: appState,
                          ),
                        ],
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildSubChip(
                            label: 'Rice & Noodles',
                            isSelected: _selectedVibe == 'rice_noodles',
                            onTap: () => setState(() => _selectedVibe = 'rice_noodles'),
                            accentColor: accentColor,
                            appState: appState,
                          ),
                          _buildSubChip(
                            label: 'Warm Soups',
                            isSelected: _selectedVibe == 'warm_soup',
                            onTap: () => setState(() => _selectedVibe = 'warm_soup'),
                            accentColor: accentColor,
                            appState: appState,
                          ),
                          _buildSubChip(
                            label: 'Skillet & Mains',
                            isSelected: _selectedVibe == 'skillet_mains',
                            onTap: () => setState(() => _selectedVibe = 'skillet_mains'),
                            accentColor: accentColor,
                            appState: appState,
                          ),
                        ],
                      ),
                  ],
                ] else if (_questionStep == 1) ...[
                  _buildQuestionHeader(
                    title: 'How much time do you have?',
                    subtitle: 'Set your cooking timeframe',
                  ),
                  const SizedBox(height: 20),
                  _buildOptionTile(
                    title: 'Under 10 Minutes',
                    isSelected: _selectedTimeframe == 'under_10',
                    onTap: () => setState(() => _selectedTimeframe = 'under_10'),
                    accentColor: accentColor,
                    appState: appState,
                  ),
                  const SizedBox(height: 10),
                  _buildOptionTile(
                    title: '15 to 20 Minutes',
                    isSelected: _selectedTimeframe == '15_20',
                    onTap: () => setState(() => _selectedTimeframe = '15_20'),
                    accentColor: accentColor,
                    appState: appState,
                  ),
                  const SizedBox(height: 10),
                  _buildOptionTile(
                    title: 'Relaxed Kitchen Time',
                    isSelected: _selectedTimeframe == 'any',
                    onTap: () => setState(() => _selectedTimeframe = 'any'),
                    accentColor: accentColor,
                    appState: appState,
                  ),

                  // Progressive follow-up sub-options
                  if (_selectedTimeframe != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      'APPLIANCE / METHOD (OPTIONAL)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildSubChip(
                          label: 'Any Method',
                          isSelected: _selectedMethodPref == null || _selectedMethodPref == 'any_method',
                          onTap: () => setState(() => _selectedMethodPref = 'any_method'),
                          accentColor: accentColor,
                          appState: appState,
                        ),
                        _buildSubChip(
                          label: 'Oven / Air Fryer',
                          isSelected: _selectedMethodPref == 'oven',
                          onTap: () => setState(() => _selectedMethodPref = 'oven'),
                          accentColor: accentColor,
                          appState: appState,
                        ),
                        _buildSubChip(
                          label: 'Stovetop / Skillet',
                          isSelected: _selectedMethodPref == 'stovetop',
                          onTap: () => setState(() => _selectedMethodPref = 'stovetop'),
                          accentColor: accentColor,
                          appState: appState,
                        ),
                        _buildSubChip(
                          label: 'Microwave / Quick',
                          isSelected: _selectedMethodPref == 'quick_device',
                          onTap: () => setState(() => _selectedMethodPref = 'quick_device'),
                          accentColor: accentColor,
                          appState: appState,
                        ),
                      ],
                    ),
                  ],
                ] else ...[
                  _buildQuestionHeader(
                    title: 'What is your kitchen focus?',
                    subtitle: 'Setting your deck curation priority',
                  ),
                  const SizedBox(height: 20),
                  _buildOptionTile(
                    title: 'Strictly What I Have',
                    isSelected: _selectedConstraint == 'strict_have',
                    onTap: () => setState(() => _selectedConstraint = 'strict_have'),
                    accentColor: accentColor,
                    appState: appState,
                  ),
                  const SizedBox(height: 10),
                  _buildOptionTile(
                    title: 'Simple Pantry Staples (3–4 Items)',
                    isSelected: _selectedConstraint == 'minimal_3_4',
                    onTap: () => setState(() => _selectedConstraint = 'minimal_3_4'),
                    accentColor: accentColor,
                    appState: appState,
                  ),
                  const SizedBox(height: 10),
                  _buildOptionTile(
                    title: 'Open to All Ideas',
                    isSelected: _selectedConstraint == 'open',
                    onTap: () => setState(() => _selectedConstraint = 'open'),
                    accentColor: accentColor,
                    appState: appState,
                  ),
                ],
                const SizedBox(height: 24),

                // Inline Proceed Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canProceed ? _proceedToNextQuestion : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.textMain,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTheme.textLight.withValues(alpha: 0.2),
                      disabledForegroundColor: AppTheme.textLight,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: Text(
                      _questionStep == 2 ? 'Formulate Discovery Deck (4 Cards)' : 'Proceed',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),

                // Generous bottom spacing for floating chat bar
                const SizedBox(height: 140),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionHeader({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textMain,
            letterSpacing: -0.6,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required Color accentColor,
    required AppState appState,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.07) : appState.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : appState.bgSubtle,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? accentColor : AppTheme.textMain,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? accentColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? accentColor : AppTheme.textLight,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color accentColor,
    required AppState appState,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.textMain : appState.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.textMain : appState.bgSubtle,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textMain,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // PHASE 2: BACKGROUND FORMULATION / LOADER
  // ==========================================
  Widget _buildProcessingView(BuildContext context, AppState appState, Color accentColor) {
    return Center(
      key: const ValueKey('processing_phase'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: accentColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '식 STUDIO FORMULATION',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.2,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Curating your 4 minimalist cards...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMain,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Cross-referencing kitchen pantry, cooking time & staple ratios.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: AppTheme.textMuted,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PHASE 3: DATING-APP SWIPEABLE CARD DECK
  // ==========================================
  Widget _buildSwipeDeckView(BuildContext context, AppState appState, Color accentColor) {
    return Column(
      key: const ValueKey('swipe_deck_phase'),
      children: [
        // Top Navigation Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 20, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '식',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'CURATED PILE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${_deck.length} ${_deck.length == 1 ? 'card' : 'cards'} remaining',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 20),
                color: AppTheme.textLight,
              ),
            ],
          ),
        ),

        // Interactive Swipeable Pile
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Bottom underlying cards (up to 3 in stack)
                  for (int i = math.min(_deck.length - 1, 2); i >= 1; i--)
                    _buildBackgroundCard(index: i, appState: appState),

                  // Top interactive card
                  if (_deck.isNotEmpty)
                    _buildTopDraggableCard(recipe: _deck.first, appState: appState, accentColor: accentColor),
                ],
              ),
            ),
          ),
        ),

        // Bottom Tactile Action Buttons (Dating-app Style)
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Pass / Swipe Left
              _buildRoundActionButton(
                icon: Icons.close_rounded,
                iconColor: AppTheme.textMuted,
                bgColor: appState.bgCard,
                size: 52,
                tooltip: 'Pass (Swipe Left)',
                onTap: _onSwipeLeft,
              ),
              // Interested / Bookmark / Swipe Up
              _buildRoundActionButton(
                icon: Icons.bookmark_border_rounded,
                iconColor: const Color(0xFFD97706),
                bgColor: appState.bgCard,
                size: 46,
                tooltip: 'Interested, but not now (Swipe Up)',
                onTap: _onSwipeUp,
              ),
              // Save / Swipe Right
              _buildRoundActionButton(
                icon: Icons.favorite_rounded,
                iconColor: Colors.white,
                bgColor: accentColor,
                size: 56,
                tooltip: 'Save Recipe (Swipe Right)',
                onTap: _onSwipeRight,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundCard({required int index, required AppState appState}) {
    final double scale = 1.0 - (index * 0.04);
    final double offsetY = index * 12.0;
    final recipe = _deck[index];

    return Transform.translate(
      offset: Offset(0, offsetY),
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: double.infinity,
          height: 440,
          decoration: BoxDecoration(
            color: appState.bgCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: appState.bgSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipe.categoryTag,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                recipe.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMain,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopDraggableCard({
    required Recipe recipe,
    required AppState appState,
    required Color accentColor,
  }) {
    final double rotation = (_dragOffset.dx / 300) * 0.22;
    final double dragX = _dragOffset.dx;
    final double dragY = _dragOffset.dy;

    final double progressX = (dragX.abs() / 100.0).clamp(0.0, 1.0);
    final double progressY = ((-dragY) / 80.0).clamp(0.0, 1.0);
    final double dragProgress = math.max(progressX, dragY < 0 ? progressY : 0.0);

    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _dragOffset += details.delta;
        });
      },
      onPanEnd: (details) {
        if (dragX > 100) {
          _onSwipeRight();
        } else if (dragX < -100) {
          _onSwipeLeft();
        } else if (dragY < -90) {
          _onSwipeUp();
        } else {
          _springBack();
        }
      },
      child: Transform.translate(
        offset: _dragOffset,
        child: Transform.rotate(
          angle: rotation,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                height: 440,
                decoration: BoxDecoration(
                  color: appState.bgCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: appState.bgSubtle, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(22),
                child: Opacity(
                  opacity: (1.0 - (dragProgress * 0.78)).clamp(0.16, 1.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Card Header: Tag & Match Pill
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                recipe.categoryTag,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.6,
                                  color: accentColor,
                                ),
                              ),
                              if (recipe.koreanTitle.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '· ${recipe.koreanTitle}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: recipe.kitchenMatchPercent >= 60
                                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                  : appState.bgSubtle,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${recipe.kitchenMatchPercent}% Match',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: recipe.kitchenMatchPercent >= 60
                                    ? const Color(0xFF059669)
                                    : AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Recipe Title
                      Text(
                        recipe.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMain,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 12),

                      // Meta Chips
                      Row(
                        children: [
                          _buildCardMetaChip(Icons.timer_outlined, '${recipe.cookingTimeMinutes}m', appState),
                          const SizedBox(width: 6),
                          _buildCardMetaChip(Icons.soup_kitchen_outlined, recipe.cookingMethod, appState),
                          const SizedBox(width: 6),
                          _buildCardMetaChip(Icons.restaurant_menu_outlined, '${recipe.ingredients.length} items', appState),
                        ],
                      ),

                      const SizedBox(height: 18),
                      Divider(height: 1, color: appState.bgSubtle),
                      const SizedBox(height: 16),

                      // Ingredients Preview (Minimalist 3–4 items)
                      Text(
                        'MINIMALIST STAPLES',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Expanded(
                        child: ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: math.min(recipe.ingredients.length, 4),
                          separatorBuilder: (context, index) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final ing = recipe.ingredients[index];
                            final hasIt = ing.status == 'have';
                            return Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: hasIt ? const Color(0xFF10B981) : AppTheme.textLight,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    ing.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textMain,
                                    ),
                                  ),
                                ),
                                Text(
                                  ing.amount ?? '',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      // Quick Step Preview
                      if (recipe.cookingSteps.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: appState.bgSubtle,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            recipe.cookingSteps.first,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: AppTheme.textMuted,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Centered, Big, Bold Visual Swipe Indicators on Drag
              // 1. SAVE (Swipe Right)
              if (dragX > 20)
                Positioned.fill(
                  child: Center(
                    child: Transform.rotate(
                      angle: -0.08,
                      child: Transform.scale(
                        scale: 0.8 + (0.28 * progressX),
                        child: Opacity(
                          opacity: progressX,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.40),
                                  blurRadius: 28,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.favorite_rounded, color: Colors.white, size: 28),
                                const SizedBox(width: 10),
                                Text(
                                  'SAVE',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 3.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // 2. PASS (Swipe Left)
              if (dragX < -20)
                Positioned.fill(
                  child: Center(
                    child: Transform.rotate(
                      angle: 0.08,
                      child: Transform.scale(
                        scale: 0.8 + (0.28 * progressX),
                        child: Opacity(
                          opacity: progressX,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE11D48),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x45E11D48),
                                  blurRadius: 28,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                                const SizedBox(width: 10),
                                Text(
                                  'PASS',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 3.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // 3. INTERESTED (Swipe Up)
              if (dragY < -20 && dragX.abs() < 40)
                Positioned.fill(
                  child: Center(
                    child: Transform.scale(
                      scale: 0.8 + (0.28 * progressY),
                      child: Opacity(
                        opacity: progressY,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x45D97706),
                                blurRadius: 28,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bookmark_rounded, color: Colors.white, size: 28),
                              const SizedBox(width: 10),
                              Text(
                                'INTERESTED',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 2.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardMetaChip(IconData icon, String label, AppState appState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: appState.bgSubtle,
        borderRadius: BorderRadius.circular(8),
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

  Widget _buildRoundActionButton({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required double size,
    required String tooltip,
    required VoidCallback onTap,
    Color? borderColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor ?? Colors.black.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, size: size * 0.44, color: iconColor),
        ),
      ),
    );
  }

  // ==========================================
  // PHASE 4: COMPLETED SUMMARY VIEW
  // ==========================================
  Widget _buildCompletedView(BuildContext context, AppState appState, Color accentColor) {
    return Center(
      key: const ValueKey('completed_phase'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, size: 32, color: accentColor),
            ),
            const SizedBox(height: 20),
            Text(
              'Discovery Complete',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMain,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You saved ${_savedInSession.length} ${_savedInSession.length == 1 ? 'recipe' : 'recipes'} and marked ${_wishlistInSession.length} for later.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                  appState.setActiveTab(AppState.tabSaved); // Navigate to Saved Screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.textMain,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: Text(
                  'View Saved Recipes',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _questionStep = 0;
                    _selectedMood = null;
                    _selectedVibe = null;
                    _selectedTimeframe = null;
                    _selectedMethodPref = null;
                    _selectedConstraint = null;
                    _deck.clear();
                    _savedInSession.clear();
                    _wishlistInSession.clear();
                    _currentPhase = DiscoveryPhase.questionnaire;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textMain,
                  side: BorderSide(color: appState.bgSubtle),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Discover Again',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  appState.setActiveTab(AppState.tabDishes);
                }
              },
              child: Text(
                'Back to Dishes',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
