import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../widgets/floating_ai_bar.dart';
import 'explore_screen.dart';
import 'fridge_screen.dart';
import 'cooking_calendar_screen.dart';
import 'saved_screen.dart';
import 'profile_screen.dart';
import 'cooking_mode_screen.dart';
import 'ai_chat_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final accentColor = appState.accentColor;

    // Enforce orientation policy: Phones locked to Portrait, Tablets/Laptops allow Landscape
    ResponsiveUtils.updateOrientationsForContext(context);

    final isWide = ResponsiveUtils.isWideScreen(context);
    final isDualPane = ResponsiveUtils.isDualPane(context);

    if (isWide) {
      return _buildTabletLaptopLayout(context, appState, accentColor, isDualPane);
    }

    return _buildMobileLayout(context, appState);
  }

  // ---------------------------------------------------------------------------
  // MOBILE PHONE LAYOUT (< 768px)
  // ---------------------------------------------------------------------------
  Widget _buildMobileLayout(BuildContext context, AppState appState) {
    final accentColor = appState.accentColor;

    return Scaffold(
      backgroundColor: appState.bgPrimary,
      body: Stack(
        children: [
          // Tab Views IndexedStack with 식 AI as the Hero Main Screen (Tab 0)
          IndexedStack(
            index: appState.activeTabIndex,
            children: const [
              AiChatScreen(isMainTab: true),
              ExploreScreen(),
              FridgeScreen(),
              CookingCalendarScreen(),
              SavedScreen(),
              ProfileScreen(),
            ],
          ),

          // Gradient fade and Floating AI Prompt Bar (shown only when NOT on Tab 0, since Tab 0 has its own dedicated composer)
          if (appState.activeTabIndex != AppState.tabAi) ...[
            Positioned(
              left: 0,
              right: 0,
              bottom: 64,
              height: 110,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        appState.bgPrimary.withValues(alpha: 0.0),
                        appState.bgPrimary.withValues(alpha: 0.85),
                        appState.bgPrimary,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const Positioned(
              left: 0,
              right: 0,
              bottom: 72,
              child: FloatingAiBar(),
            ),
          ],

          // Sticky Bottom Navigation Bar (Korean Minimalist Editorial)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                color: appState.bgPrimary,
                border: const Border(
                  top: BorderSide(
                    color: Color(0x10000000),
                    width: 0.8,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _bottomNavItem(0, Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, '식 AI', appState, accentColor),
                  _bottomNavItem(1, Icons.restaurant_menu_outlined, Icons.restaurant_menu, 'Dishes', appState, accentColor),
                  _bottomNavItem(2, Icons.kitchen_outlined, Icons.kitchen, 'Pantry', appState, accentColor),
                  _bottomNavItem(3, Icons.calendar_today_outlined, Icons.calendar_today_rounded, 'Journal', appState, accentColor),
                  _bottomNavItem(4, Icons.bookmark_border_rounded, Icons.bookmark_rounded, 'Saved', appState, accentColor),
                  _bottomNavItem(5, Icons.person_outline_rounded, Icons.person_rounded, 'Profile', appState, accentColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TABLET & LAPTOP ADAPTIVE LAYOUT (>= 768px, with Landscape & Dual-Pane)
  // ---------------------------------------------------------------------------
  Widget _buildTabletLaptopLayout(
    BuildContext context,
    AppState appState,
    Color accentColor,
    bool isDualPane,
  ) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: appState.bgPrimary,
      body: Row(
        children: [
          // 1. Korean Minimalist Navigation Rail
          _buildNavigationRail(context, appState, accentColor, isDualPane),

          // 2. Main Central Tab Content with Centered Floating AI Bar
          Expanded(
            child: Stack(
              children: [
                IndexedStack(
                  index: appState.activeTabIndex,
                  children: const [
                    AiChatScreen(isMainTab: true),
                    ExploreScreen(),
                    FridgeScreen(),
                    CookingCalendarScreen(),
                    SavedScreen(),
                    ProfileScreen(),
                  ],
                ),

                // Gradient fade & Floating AI Bar on tablet (shown only on tabs 1..5)
                if (appState.activeTabIndex != AppState.tabAi) ...[
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 120,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              appState.bgPrimary.withValues(alpha: 0.0),
                              appState.bgPrimary.withValues(alpha: 0.85),
                              appState.bgPrimary,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 24,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: const FloatingAiBar(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail(
    BuildContext context,
    AppState appState,
    Color accentColor,
    bool isDualPane,
  ) {
    return Container(
      width: 88,
      decoration: BoxDecoration(
        color: appState.bgCard,
        border: Border(
          right: BorderSide(color: appState.bgSubtle, width: 1.2),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Brand Logo: 식 · SIK STUDIO
          Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '식',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'SIK',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Navigation Icons
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _railNavItem(0, Icons.auto_awesome_outlined, Icons.auto_awesome_rounded, '식 AI', appState, accentColor),
                  const SizedBox(height: 10),
                  _railNavItem(1, Icons.restaurant_menu_outlined, Icons.restaurant_menu, 'Dishes', appState, accentColor),
                  const SizedBox(height: 10),
                  _railNavItem(2, Icons.kitchen_outlined, Icons.kitchen, 'Fridge', appState, accentColor),
                  const SizedBox(height: 10),
                  _railNavItem(3, Icons.calendar_today_outlined, Icons.calendar_today_rounded, 'Journal', appState, accentColor),
                  const SizedBox(height: 10),
                  _railNavItem(4, Icons.bookmark_border_rounded, Icons.bookmark_rounded, 'Saved', appState, accentColor),
                  const SizedBox(height: 10),
                  _railNavItem(5, Icons.person_outline_rounded, Icons.person_rounded, 'Profile', appState, accentColor),
                ],
              ),
            ),
          ),

          // Start Cooking Session Quick Action
          IconButton(
            tooltip: 'Start Cooking Session',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.restaurant_rounded, color: accentColor, size: 20),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CookingModeScreen()),
              );
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _railNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
    AppState appState,
    Color accentColor,
  ) {
    final isSelected = appState.activeTabIndex == index;

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: () => appState.setActiveTab(index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 58,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? accentColor.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? accentColor : AppTheme.textMuted,
                size: 24,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? accentColor : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
    AppState appState,
    Color accentColor,
  ) {
    final isSelected = appState.activeTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => appState.setActiveTab(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 19,
              color: isSelected ? accentColor : AppTheme.textMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
                color: isSelected ? accentColor : AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? accentColor : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
