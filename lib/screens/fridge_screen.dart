import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/fridge_item.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ingredient_tile.dart';
import 'shopping_screen.dart';
import 'ai_chat_screen.dart';

class FridgeScreen extends StatefulWidget {
  const FridgeScreen({super.key});

  @override
  State<FridgeScreen> createState() => _FridgeScreenState();
}

class _FridgeScreenState extends State<FridgeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddItemDialog(BuildContext context) {
    final appState = context.read<AppState>();
    final accentColor = appState.accentColor;
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    // Default to fridge if on overview tab, otherwise match selected tab
    StorageLocation selectedLoc = _tabController.index == 0
        ? StorageLocation.fridge
        : StorageLocation.values[_tabController.index - 1];
    QuantityMode selectedMode = QuantityMode.approximate;
    String selectedStatus = 'Have';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: appState.bgPrimary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add Ingredient',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMain,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Ingredient Name Input
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Ingredient name (e.g. Eggs, Tofu, Milk)',
                        filled: true,
                        fillColor: AppTheme.bgSurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Storage Location
                    Text(
                      'Storage Location',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _locChoice(StorageLocation.fridge, 'Fridge', selectedLoc, (l) => setModalState(() => selectedLoc = l), appState),
                        _locChoice(StorageLocation.freezer, 'Freezer', selectedLoc, (l) => setModalState(() => selectedLoc = l), appState),
                        _locChoice(StorageLocation.pantry, 'Pantry', selectedLoc, (l) => setModalState(() => selectedLoc = l), appState),
                        _locChoice(StorageLocation.seasoning, 'Seasoning', selectedLoc, (l) => setModalState(() => selectedLoc = l), appState),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Status
                    Text(
                      'Stock Status',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _statusChoice('Have', selectedStatus, (s) => setModalState(() => selectedStatus = s), appState),
                        const SizedBox(width: 8),
                        _statusChoice('Running Low', selectedStatus, (s) => setModalState(() => selectedStatus = s), appState),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Quantity Mode Toggle
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setModalState(() => selectedMode = QuantityMode.approximate),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: selectedMode == QuantityMode.approximate ? accentColor : appState.bgCard,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: selectedMode == QuantityMode.approximate ? accentColor : appState.bgSubtle),
                            ),
                            child: Text(
                              'Approximate',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: selectedMode == QuantityMode.approximate ? FontWeight.w700 : FontWeight.w500,
                                color: selectedMode == QuantityMode.approximate ? Colors.white : AppTheme.textMain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => setModalState(() => selectedMode = QuantityMode.exact),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: selectedMode == QuantityMode.exact ? accentColor : appState.bgCard,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: selectedMode == QuantityMode.exact ? accentColor : appState.bgSubtle),
                            ),
                            child: Text(
                              'Exact',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: selectedMode == QuantityMode.exact ? FontWeight.w700 : FontWeight.w500,
                                color: selectedMode == QuantityMode.exact ? Colors.white : AppTheme.textMain,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (selectedMode == QuantityMode.approximate) ...[
                      Wrap(
                        spacing: 6,
                        children: ['A little', 'Some', 'Plenty', 'Almost empty'].map((opt) {
                          final isSel = quantityController.text == opt;
                          return GestureDetector(
                            onTap: () => setModalState(() => quantityController.text = opt),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isSel ? accentColor : appState.bgCard,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isSel ? accentColor : appState.bgSubtle),
                              ),
                              child: Text(
                                opt,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                  color: isSel ? Colors.white : AppTheme.textMain,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ] else ...[
                      TextField(
                        controller: quantityController,
                        decoration: InputDecoration(
                          hintText: 'e.g. 500 ml, 300 g, 6 pieces',
                          filled: true,
                          fillColor: AppTheme.bgSurface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final name = nameController.text.trim();
                          if (name.isNotEmpty) {
                            final newItem = FridgeItem(
                              id: 'f_${DateTime.now().millisecondsSinceEpoch}',
                              name: name,
                              location: selectedLoc,
                              quantityMode: selectedMode,
                              quantityDisplay: quantityController.text.trim(),
                              status: selectedStatus,
                            );
                            context.read<AppState>().addFridgeItem(newItem);
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Text(
                          'Add to Kitchen',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _locChoice(StorageLocation loc, String label, StorageLocation current, Function(StorageLocation) onSel, AppState appState) {
    final isSel = current == loc;
    final accentColor = appState.accentColor;
    return GestureDetector(
      onTap: () => onSel(loc),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? accentColor : appState.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSel ? accentColor : appState.bgSubtle,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
            color: isSel ? Colors.white : AppTheme.textMain,
          ),
        ),
      ),
    );
  }

  Widget _statusChoice(String status, String current, Function(String) onSel, AppState appState) {
    final isSel = current == status;
    final accentColor = appState.accentColor;
    return GestureDetector(
      onTap: () => onSel(status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? accentColor : appState.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSel ? accentColor : appState.bgSubtle,
            width: 1,
          ),
        ),
        child: Text(
          status,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
            color: isSel ? Colors.white : AppTheme.textMain,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final allItems = appState.fridgeItems;
    final accentColor = appState.accentColor;
    final isMobile = MediaQuery.sizeOf(context).width < 440;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Kitchen Inventory',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isMobile ? 18.5 : 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMain,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${allItems.length} total items tracked',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Header Actions: AI Chat, Shopping List & Add Item
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: '식 AI Chat',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AiChatScreen()),
                        );
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: accentColor,
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Shopping List',
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ShoppingScreen()),
                        );
                      },
                      icon: Badge(
                        isLabelVisible: appState.wantList.isNotEmpty,
                        label: Text('${appState.wantList.length}'),
                        backgroundColor: accentColor,
                        child: const Icon(Icons.shopping_cart_outlined, color: AppTheme.textMain, size: 21),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      onPressed: () => _showAddItemDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 17),
                      label: Text(isMobile ? 'Add' : 'Add Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                    if (allItems.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Delete Everything',
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        onPressed: () => _showClearAllDialog(context, appState),
                        icon: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppTheme.accentOrange.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete_sweep_outlined,
                            size: 16,
                            color: AppTheme.accentOrange,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Category TabBar: Overview | Fridge | Freezer | Pantry
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: appState.bgCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                labelPadding: EdgeInsets.zero,
                indicatorPadding: EdgeInsets.zero,
                indicator: BoxDecoration(
                  color: AppTheme.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0C000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: AppTheme.textMain,
                unselectedLabelColor: AppTheme.textMuted,
                labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Fridge'),
                  Tab(text: 'Freezer'),
                  Tab(text: 'Pantry'),
                  Tab(text: 'Seasoning'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // TabBarView displaying category items
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(context, allItems, appState),
                _buildCategoryList(context, allItems, StorageLocation.fridge),
                _buildCategoryList(context, allItems, StorageLocation.freezer),
                _buildCategoryList(context, allItems, StorageLocation.pantry),
                _buildCategoryList(context, allItems, StorageLocation.seasoning),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Overview Tab ──────────────────────────────────────────────────────────
  Widget _buildOverviewTab(BuildContext context, List<FridgeItem> allItems, AppState appState) {
    final fridgeItems = allItems.where((i) => i.location == StorageLocation.fridge).toList();
    final freezerItems = allItems.where((i) => i.location == StorageLocation.freezer).toList();
    final pantryItems = allItems.where((i) => i.location == StorageLocation.pantry).toList();
    final seasoningItems = allItems.where((i) => i.location == StorageLocation.seasoning).toList();

    final lowItems = allItems.where((i) => i.status.toLowerCase() == 'running low').toList();
    final missingItems = allItems.where((i) => i.status.toLowerCase() == 'missing').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 150),
      children: [
        // Summary Stats Row with Drag & Drop Targets
        Row(
          children: [
            Expanded(child: _buildZoneCard(
              context,
              icon: Icons.kitchen_rounded,
              label: 'Fridge',
              count: fridgeItems.length,
              color: AppTheme.textMain,
              tabIndex: 1,
              location: StorageLocation.fridge,
            )),
            const SizedBox(width: 8),
            Expanded(child: _buildZoneCard(
              context,
              icon: Icons.ac_unit_rounded,
              label: 'Freezer',
              count: freezerItems.length,
              color: AppTheme.textMain,
              tabIndex: 2,
              location: StorageLocation.freezer,
            )),
            const SizedBox(width: 8),
            Expanded(child: _buildZoneCard(
              context,
              icon: Icons.inventory_2_outlined,
              label: 'Pantry',
              count: pantryItems.length,
              color: AppTheme.textMain,
              tabIndex: 3,
              location: StorageLocation.pantry,
            )),
            const SizedBox(width: 8),
            Expanded(child: _buildZoneCard(
              context,
              icon: Icons.soup_kitchen_outlined,
              label: 'Seasoning',
              count: seasoningItems.length,
              color: AppTheme.textMain,
              tabIndex: 4,
              location: StorageLocation.seasoning,
            )),
          ],
        ),

        const SizedBox(height: 16),

        // Alert banner for low / missing items
        if (lowItems.isNotEmpty || missingItems.isNotEmpty)
          _buildAlertBanner(lowItems, missingItems, appState),

        if (lowItems.isNotEmpty || missingItems.isNotEmpty)
          const SizedBox(height: 16),

        // Grouped sections with Drop Target support
        if (fridgeItems.isNotEmpty) ...[
          _buildSectionHeader(context, 'Fridge', fridgeItems.length, Icons.kitchen_rounded, AppTheme.textMain, StorageLocation.fridge),
          const SizedBox(height: 8),
          _buildResponsiveIngredientGrid(context, fridgeItems),
          const SizedBox(height: 20),
        ],

        if (freezerItems.isNotEmpty) ...[
          _buildSectionHeader(context, 'Freezer', freezerItems.length, Icons.ac_unit_rounded, AppTheme.textMain, StorageLocation.freezer),
          const SizedBox(height: 8),
          _buildResponsiveIngredientGrid(context, freezerItems),
          const SizedBox(height: 20),
        ],

        if (pantryItems.isNotEmpty) ...[
          _buildSectionHeader(context, 'Pantry', pantryItems.length, Icons.inventory_2_outlined, AppTheme.textMain, StorageLocation.pantry),
          const SizedBox(height: 8),
          _buildResponsiveIngredientGrid(context, pantryItems),
          const SizedBox(height: 20),
        ],

        if (seasoningItems.isNotEmpty) ...[
          _buildSectionHeader(context, 'Seasonings & Spices', seasoningItems.length, Icons.soup_kitchen_outlined, AppTheme.textMain, StorageLocation.seasoning),
          const SizedBox(height: 8),
          _buildResponsiveIngredientGrid(context, seasoningItems),
          const SizedBox(height: 20),
        ],

        if (allItems.isEmpty)
          _buildEmptyState(),
      ],
    );
  }

  Widget _buildZoneCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required int tabIndex,
    required StorageLocation location,
  }) {
    final appState = context.read<AppState>();
    final isTablet = MediaQuery.sizeOf(context).width >= 768;

    return DragTarget<FridgeItem>(
      onWillAcceptWithDetails: (details) => details.data.location != location,
      onAcceptWithDetails: (details) {
        final item = details.data;
        appState.updateFridgeItem(item.copyWith(location: location));
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text('Moved "${item.name}" to $label'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            duration: const Duration(milliseconds: 1800),
          ),
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return GestureDetector(
          onTap: () {
            _tabController.animateTo(tabIndex);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(
              vertical: isTablet ? 10 : 11,
              horizontal: isTablet ? 12 : 6,
            ),
            decoration: BoxDecoration(
              color: isHovered ? color.withValues(alpha: 0.12) : AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isHovered ? color : appState.bgSubtle,
                width: isHovered ? 2 : 1,
              ),
              boxShadow: isHovered
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 14, color: color),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMain,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isHovered ? 'Drop' : label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isHovered ? FontWeight.w700 : FontWeight.w600,
                      color: isHovered ? color : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlertBanner(List<FridgeItem> lowItems, List<FridgeItem> missingItems, AppState appState) {
    final parts = <String>[];
    if (lowItems.isNotEmpty) {
      parts.add('${lowItems.length} running low');
    }
    if (missingItems.isNotEmpty) {
      parts.add('${missingItems.length} missing');
    }
    final allAlertNames = [...lowItems, ...missingItems].map((i) => i.name).join(', ');

    final accentColor = appState.accentColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.20), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.warning_amber_rounded, size: 14, color: accentColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Text(
                  'Attention: ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMain,
                  ),
                ),
                Expanded(
                  child: Text(
                    '${parts.join(" and ")} -- $allAlertNames',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count, IconData icon, Color color, StorageLocation targetLoc) {
    final appState = context.read<AppState>();

    return DragTarget<FridgeItem>(
      onWillAcceptWithDetails: (details) => details.data.location != targetLoc,
      onAcceptWithDetails: (details) {
        final item = details.data;
        appState.updateFridgeItem(item.copyWith(location: targetLoc));
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text('Moved "${item.name}" to $title'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            duration: const Duration(milliseconds: 1800),
          ),
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(horizontal: isHovered ? 8 : 0, vertical: isHovered ? 6 : 0),
          decoration: isHovered
              ? BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color, width: 1.5),
                )
              : null,
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isHovered ? color : AppTheme.textMain,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isHovered ? 'Drop' : '$count',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showClearAllDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: appState.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Everything?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMain,
          ),
        ),
        content: Text(
          'This will permanently delete all ${appState.fridgeItems.length} items across your Fridge, Freezer, Pantry, and Seasoning shelves. Your kitchen will be empty.',
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
                const SnackBar(content: Text('All kitchen inventory deleted.')),
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

  Widget _buildEmptyState() {
    final appState = context.read<AppState>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: appState.accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inventory_2_outlined, size: 40, color: appState.accentColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Your kitchen is completely empty',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMain,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add ingredients via "+ Add Item", type/speak grocery hauls to 식 AI, or restore sample pantry items.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showAddItemDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appState.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    appState.resetInventoryToDefault();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sample pantry loaded.')),
                    );
                  },
                  icon: const Icon(Icons.replay_rounded, size: 16),
                  label: const Text('Load Sample Pantry'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textMuted,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    side: BorderSide(color: appState.bgSubtle),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveIngredientGrid(BuildContext context, List<FridgeItem> items) {
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 768;

    if (!isTablet) {
      return Column(
        children: items.map((item) => IngredientTile(item: item)).toList(),
      );
    }

    final crossAxisCount = width >= 1100 ? 3 : 2;
    final columns = List.generate(crossAxisCount, (_) => <FridgeItem>[]);
    for (int i = 0; i < items.length; i++) {
      columns[i % crossAxisCount].add(items[i]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int c = 0; c < crossAxisCount; c++) ...[
          if (c > 0) const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: columns[c].map((item) => IngredientTile(item: item)).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryList(BuildContext context, List<FridgeItem> allItems, StorageLocation targetLoc) {
    final appState = context.read<AppState>();
    final categoryItems = allItems.where((i) => i.location == targetLoc).toList();
    final isSeasoning = targetLoc == StorageLocation.seasoning;

    if (categoryItems.isEmpty) {
      if (isSeasoning) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 150),
          children: [
            _buildQuickSeasoningShelf(context, allItems, appState),
            const SizedBox(height: 32),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.soup_kitchen_outlined, size: 44, color: AppTheme.textLight),
                  const SizedBox(height: 12),
                  Text(
                    'No custom seasonings yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap any spice above to add it to your shelf, or tap "+ Add Item" below.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        );
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.textLight),
            const SizedBox(height: 12),
            Text(
              'No items in this section',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMain,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap "+ Add Item" to keep track of your ingredients.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 768;

    if (isTablet) {
      final crossAxisCount = width >= 1100 ? 3 : 2;
      final columns = List.generate(crossAxisCount, (_) => <FridgeItem>[]);
      for (int i = 0; i < categoryItems.length; i++) {
        columns[i % crossAxisCount].add(categoryItems[i]);
      }

      return ListView(
        padding: EdgeInsets.fromLTRB(width >= 900 ? 28 : 20, 8, width >= 900 ? 28 : 20, 150),
        children: [
          if (isSeasoning) _buildQuickSeasoningShelf(context, allItems, appState),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int c = 0; c < crossAxisCount; c++) ...[
                if (c > 0) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: columns[c].map((item) => IngredientTile(item: item)).toList(),
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 150),
      children: [
        if (isSeasoning) _buildQuickSeasoningShelf(context, allItems, appState),
        ...categoryItems.map((item) => IngredientTile(item: item)),
      ],
    );
  }

  Widget _buildQuickSeasoningShelf(BuildContext context, List<FridgeItem> allItems, AppState appState) {
    const commonSeasonings = [
      'Salt',
      'Black Pepper',
      'Sugar',
      'Soy Sauce',
      'Dark Soy Sauce',
      'Sesame Oil',
      'Garlic Powder',
      'Condensed Milk',
      'Gochugaru',
      'Oyster Sauce',
      'Fish Sauce',
      'Cooking Wine',
      'Vinegar',
      'Cumin',
      'Cinnamon',
      'Paprika',
      'White Miso Paste',
      '老干妈 (Lao Gan Ma)',
    ];

    final userItemNames = allItems.map((i) => i.name.toLowerCase().trim()).toSet();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appState.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: appState.bgSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.soup_kitchen_outlined, size: 16, color: appState.accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Quick Seasoning & Spice Shelf',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '1-tap to add',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: commonSeasonings.map((name) {
              final isPresent = userItemNames.any((u) => u == name.toLowerCase() || (name.contains('(') && u.contains('lao gan ma')));
              return GestureDetector(
                onTap: () {
                  if (isPresent) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name is already in your kitchen inventory.'),
                        duration: const Duration(milliseconds: 1400),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  } else {
                    final newItem = FridgeItem(
                      id: 'spice_${DateTime.now().millisecondsSinceEpoch}_${name.hashCode}',
                      name: name,
                      location: StorageLocation.seasoning,
                      quantityMode: QuantityMode.approximate,
                      quantityDisplay: 'Plenty',
                      status: 'Have',
                    );
                    appState.addFridgeItem(newItem);
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added $name to Seasonings & Spices'),
                        duration: const Duration(milliseconds: 1400),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: isPresent ? appState.accentColor.withValues(alpha: 0.12) : appState.bgSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPresent ? appState.accentColor : Colors.transparent,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPresent ? Icons.check_circle_rounded : Icons.add_rounded,
                        size: 13,
                        color: isPresent ? appState.accentColor : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: isPresent ? FontWeight.w700 : FontWeight.w500,
                          color: isPresent ? appState.accentColor : AppTheme.textMain,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
