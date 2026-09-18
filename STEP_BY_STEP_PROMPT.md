# 식 (sik) — Flutter / Dart Step-by-Step AI Development Prompts

> **How to use this guide:**
> Copy and execute these prompts step-by-step with your AI coding assistant (or feed them in sequence into your agent). Each prompt is tailored specifically for **Flutter & Dart**, building the complete **식 (sik)** mobile/web application incrementally.

---

## 🎨 Master Context & Aesthetic Guidelines (Flutter / Dart)
> *Include this header context at the beginning of each step to maintain design consistency.*

**Framework:** Flutter (Dart 3.x, Material 3 minimalism)  
**App Name:** 식 (sik)  
**Concept:** A Korean minimalist AI kitchen app that helps users discover, modify, and cook recipes based on what they have in their fridge, what they want to eat, and how they want to cook.  
**Design Direction:** Korean Instagram-style minimalism — warm food photography, soft warm neutral background (`Color(0xFFFAF7F2)` / `Color(0xFFF5F0EB)`), generous whitespace, clean sans-serif typography (`GoogleFonts.plusJakartaSans` / `Inter`), soft rounded cards (`BorderRadius.circular(20)`), smooth micro-animations (`AnimatedContainer`, `PageTransition`, `Hero`), glassmorphic floating AI prompt bar (`BackdropFilter`), understated badges, zero visual clutter.

---

## 🚀 Step-by-Step Flutter Prompts

### 📍 STEP 1: Flutter Setup, Custom Theme & Responsive Shell

```text
Create a clean modern Flutter app shell for "식 (sik)" — a Korean minimalist AI cooking application.

Key Requirements:
1. Flutter Design System & ThemeData (lib/theme/app_theme.dart):
   - ColorScheme: Warm ceramic background (0xFFFAF7F2), surface (0xFFFFFFFF), dark stone text (0xFF1C1917), muted text (0xFF78716C), warm primary accent (0xFFE76F51 or 0xFFD97706).
   - Typography: Clean Google Fonts (Plus Jakarta Sans or Inter) with generous line height and clean letter spacing.
   - Rounded Card Theme: CardTheme with shape RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)).
2. App Shell & Responsive Container (lib/screens/main_shell.dart):
   - Mobile-first responsive container (max-width: 480 centered with subtle shadow on desktop/web, full-screen on mobile).
   - Bottom Navigation Bar with 4 tabs:
     - Explore (Icon(Icons.explore_outlined) / ⌂)
     - Fridge (Icon(Icons.kitchen_outlined) / 🧊)
     - Saved (Icon(Icons.favorite_border) / ♡)
     - Profile (Icon(Icons.person_outline) / ○)
3. Floating Contextual AI Prompt Bar Widget (lib/widgets/floating_ai_bar.dart):
   - Positioned fixed directly above the bottom tab bar.
   - Design: Rounded glassmorphic container using ClipRRect + BackdropFilter(filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12)) with a spark icon ("✦ tell 식 what you want... ↑").
   - Interactive: Tapping expands an inline prompt text field / overlay sheet.
4. Reactive Application State (lib/providers/app_state.dart):
   - Setup state management (using ChangeNotifier / Provider / Riverpod) to hold active Tab index, user Profile, Fridge inventory, Saved recipes, and AI prompt input state.
```

---

### 📍 STEP 2: Explore Discovery Feed & Contextual AI Search

```text
Implement the "Explore" screen for "식 (sik)" in Flutter with an Instagram-style discovery feed and smart contextual filters.

Key Requirements:
1. Category & Method Filter Bar (lib/widgets/explore_filters.dart):
   - Horizontal ListView for filter pills: "Cook with what you have", "Almost there", "Easy to find near you", "Quick & Simple", "Pastry & Dessert", "Baking", "Drinks".
   - ChoiceChips / FilterChips for appliances/methods: Stovetop · Oven · Air Fryer · Microwave · No-cook.
2. Instagram-Style Recipe Feed Grid (lib/widgets/recipe_card.dart):
   - Custom GridView / SliverGrid featuring warm food imagery.
   - Recipe Card Widget displaying:
     - Food hero image with ClipRRect(borderRadius: BorderRadius.circular(20)).
     - Recipe Title & Korean subtitle text.
     - Kitchen Match Badge pill (e.g. "95% Match · Have all ingredients" in soft green/warm amber).
     - Info chips: Cooking time (e.g., "18 min"), cooking method ("Air Fryer"), and difficulty.
3. AI Search & Floating Prompt Integration:
   - Submitting text in the floating AI prompt bar filters recipes or highlights suggested dish matches dynamically.
   - Tapping any recipe card navigates smoothly to the Recipe Detail Screen.
```

---

### 📍 STEP 3: Recipe Detail Screen & AI Recipe Modification Diff Engine

```text
Build the "Recipe Detail Screen" and the interactive "AI Modification Diff Preview" modal in Flutter.

Key Requirements:
1. Recipe Detail Screen (lib/screens/recipe_detail_screen.dart):
   - CustomScrollView with SliverAppBar hero image, back button, share icon, and animated favorite heart toggle.
   - Metadata section: Recipe title, cuisine type, cooking method, prep time, difficulty, and Kitchen Match % badge.
   - Ingredients List Widget:
     - Visual status indicators: Have (✓ green icon), Running low (⚠️ amber icon), Missing (+ red/grey button).
     - Quick "Add missing to Want list" action button.
   - Floating Action / Bottom bar: "Start Cooking" primary button & "Modify with AI" button.
2. AI Modification Preview Modal (Diff Engine) (lib/widgets/ai_modification_modal.dart):
   - When user prompts AI (e.g. "make it simpler", "remove mushrooms", "make this an air fryer recipe"), show a showModalBottomSheet with blur background displaying precise recipe diffs:
     - − mushrooms (removed item)
     - ↻ soy sauce → fish sauce (substituted ingredient)
     - ⏱️ 25 min → 18 min (time adjustment)
     - 🛒 3 missing ingredients → 0 (fridge match fix)
   - Actions: ElevatedButton("Use this version") and TextButton("Cancel").
   - Accepting updates the current recipe state instantly with smooth widget animations.
```

---

### 📍 STEP 4: Fridge & Pantry Inventory Intelligence Engine

```text
Develop the "Fridge" inventory screen in Flutter supporting exact/approximate quantity tracking and local ingredient intelligence.

Key Requirements:
1. Category Navigation (lib/screens/fridge_screen.dart):
   - TabBar / SegmentedButton: Fridge 🧊 | Freezer ❄️ | Pantry 🧺.
2. Flexible Ingredient Tile (lib/widgets/ingredient_tile.dart):
   - List view displaying ingredient items with visual status badges (Have, Running Low, Missing).
   - Support dual quantity modes:
     - Exact mode: `6 pieces`, `500 ml`, `300 g`, `2 packs`.
     - Approximate mode: `A little`, `Some`, `Plenty`, `Almost empty`.
     - Quantity is optional — users can simply list the ingredient name.
   - Quick inline edit modal & Add New Ingredient dialog.
3. Ingredient Intelligence & Regional Substitution (lib/services/ingredient_intelligence.dart):
   - Region selector logic (e.g. 🇮🇪 Ireland context).
   - AI logic maps fuzzy amounts (e.g., "Milk — some") to recipe requirements ("Probably enough for 2 cups").
   - Smart substitution suggestions tailored to local supermarket availability in Ireland/Europe.
```

---

### 📍 STEP 5: Shopping List ("Want") & Saved Recipe Library

```text
Build the "Shopping List (Want)" system and the "Saved Library" screen in Flutter.

Key Requirements:
1. Shopping / Want List Screen (lib/screens/shopping_screen.dart):
   - Accessible from Recipe view ("Add missing to Want list") and Fridge tab.
   - Checked item transition: Checking an item as "Bought" triggers a smooth Dismissible / slide animation that automatically moves the item into the active **Fridge/Pantry state**.
   - Manual quick-add text field for extra groceries.
2. Saved Library Screen (lib/screens/saved_screen.dart):
   - TabBar sub-navigation:
     - Saved Recipes
     - Favorites
     - Want to Try
     - Cooked History
   - Recipe cards with a distinct "✦ AI Modified" badge on modified recipes vs original recipes.
   - Tap recipe card to navigate to detail view or start cooking mode.
```

---

### 📍 STEP 6: Distraction-Free Cooking Mode & Step Timers

```text
Implement the "Distraction-Free Cooking Mode" with integrated countdown timers and post-cooking inventory updates in Flutter.

Key Requirements:
1. Distraction-Free UI (lib/screens/cooking_mode_screen.dart):
   - Full-screen step-by-step PageView with large readable typography and high-contrast step controls.
   - Header displaying current recipe title, step indicator (e.g., Step 3 of 6), step progress bar, and exit button.
2. Appliance-Specific Step Cards:
   - Customized step card views for Stovetop, Oven, Air Fryer, Microwave, and No-cook methods.
   - Displays temperature settings, precise ingredient measurements, and inline substitution notes.
3. Built-in Interactive Timer Widget (lib/widgets/cooking_timer_widget.dart):
   - Interactive countdown timer (e.g., "Simmer for 8 mins") with Play/Pause/Reset buttons and visual completion alert.
4. Post-Cooking Completion Flow:
   - Celebration dialog ("Cooked ✓").
   - "Update Fridge Inventory?" prompt showing ingredients used in cooking, offering auto-deduct or mark as "Running Low".
```

---

### 📍 STEP 7: User Profile, Preferences & Local State Persistence

```text
Build the "Profile & Settings" screen and wire up state persistence using shared_preferences / JSON storage in Flutter.

Key Requirements:
1. Profile Screen (lib/screens/profile_screen.dart):
   - Region selection Dropdown (e.g., 🇮🇪 Ireland, 🇰🇷 South Korea, 🇺🇸 United States, 🇬🇧 UK).
   - Preferred Cuisines multi-select chips (Korean, Asian fusion, Quick & Easy, Pastry, Desserts, Drinks).
   - Dietary restrictions checkboxes (Vegetarian, Vegan, Gluten-free, Nut-free, Dairy-free).
   - Kitchen Appliances toggles (Air Fryer, Oven, Microwave, Blender, Rice Cooker).
2. Data Persistence (lib/services/storage_service.dart):
   - Store user preferences, fridge inventory, saved recipes, and want list to local storage (shared_preferences / JSON file) so state persists across app restarts.
3. Default Mock Data & Final Polish (lib/models/mock_data.dart):
   - Provide rich default mock data (sample fridge items with approximate quantities, pre-built recipes with match %, and sample AI modified recipes).
   - Ensure responsive layout looks gorgeous on both mobile devices and web browser windows.
```
