import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/inventory_batch_action.dart';
import '../models/fridge_item.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class AiBatchInventoryCard extends StatefulWidget {
  final List<InventoryBatchActionItem> initialItems;

  const AiBatchInventoryCard({
    super.key,
    required this.initialItems,
  });

  @override
  State<AiBatchInventoryCard> createState() => _AiBatchInventoryCardState();
}

class _AiBatchInventoryCardState extends State<AiBatchInventoryCard> {
  late List<InventoryBatchActionItem> _items;
  bool _isApplied = false;
  int _appliedCount = 0;

  @override
  void initState() {
    super.initState();
    _items = widget.initialItems
        .map(
          (item) => item.copyWith(),
        )
        .toList();
  }

  void _addNewItemDialog() {
    final nameController = TextEditingController();
    final qtyController = TextEditingController(text: 'Plenty');
    StorageLocation location = StorageLocation.fridge;
    BatchActionType action = BatchActionType.add;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final appState = context.read<AppState>();
          final accentColor = appState.accentColor;

          return AlertDialog(
            backgroundColor: appState.bgCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.add_circle_outline_rounded, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Add Item to Staged List',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMain,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Item Name',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'e.g. Eggs, Firm Tofu, Scallions',
                      filled: true,
                      fillColor: appState.bgSubtle,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Quantity',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: qtyController,
                    decoration: InputDecoration(
                      hintText: 'e.g. 2 packs, 500g, Low, Plenty',
                      filled: true,
                      fillColor: appState.bgSubtle,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Storage Location',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildLocationOption(
                        location == StorageLocation.fridge,
                        'Fridge',
                        accentColor,
                        () => setDlgState(() => location = StorageLocation.fridge),
                      ),
                      _buildLocationOption(
                        location == StorageLocation.freezer,
                        'Freezer',
                        accentColor,
                        () => setDlgState(() => location = StorageLocation.freezer),
                      ),
                      _buildLocationOption(
                        location == StorageLocation.pantry,
                        'Pantry',
                        accentColor,
                        () => setDlgState(() => location = StorageLocation.pantry),
                      ),
                      _buildLocationOption(
                        location == StorageLocation.seasoning,
                        'Seasoning',
                        accentColor,
                        () => setDlgState(() => location = StorageLocation.seasoning),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    setState(() {
                      _items.add(
                        InventoryBatchActionItem(
                          id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          location: location,
                          quantityDisplay: qtyController.text.trim().isNotEmpty
                              ? qtyController.text.trim()
                              : 'Plenty',
                          actionType: action,
                          isSelected: true,
                        ),
                      );
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: Text(
                  'Add',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLocationOption(
    bool isSelected,
    String label,
    Color accentColor,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.15)
                : Colors.transparent,
            border: Border.all(
              color: isSelected ? accentColor : AppTheme.glassBorder,
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? accentColor : AppTheme.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _editItemDialog(InventoryBatchActionItem item) {
    final nameCtrl = TextEditingController(text: item.name);
    final qtyCtrl = TextEditingController(text: item.quantityDisplay);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.read<AppState>().bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Item Details',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMain,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item Name',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                filled: true,
                fillColor: context.read<AppState>().bgSubtle,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Quantity / Description',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: qtyCtrl,
              decoration: InputDecoration(
                filled: true,
                fillColor: context.read<AppState>().bgSubtle,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
            ),
          ],
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
            style: ElevatedButton.styleFrom(
              backgroundColor: context.read<AppState>().accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  item.name = nameCtrl.text.trim();
                  item.quantityDisplay = qtyCtrl.text.trim();
                });
                Navigator.pop(ctx);
              }
            },
            child: Text(
              'Save',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _applyUpdates(AppState appState) {
    final count = appState.applyBatchInventoryChanges(_items);
    setState(() {
      _isApplied = true;
      _appliedCount = count;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Updated $count items in Kitchen Inventory!',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final accentColor = appState.accentColor;
    final selectedCount = _items.where((i) => i.isSelected).length;

    return Container(
      margin: const EdgeInsets.only(left: 40),
      decoration: BoxDecoration(
        color: appState.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Luminous top accent bar
            Container(
              height: 3.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.2),
                    accentColor,
                    accentColor.withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),

            // Card Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: accentColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'AI Action Preview',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _isApplied
                                    ? AppTheme.accentGreen.withValues(alpha: 0.15)
                                    : accentColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _isApplied ? 'Applied' : '$selectedCount / ${_items.length} selected',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _isApplied ? AppTheme.accentGreen : accentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _isApplied
                              ? 'Saved to your Kitchen Inventory'
                              : 'Review & edit items before saving',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isApplied)
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                      color: accentColor,
                      tooltip: 'Add another item',
                      visualDensity: VisualDensity.compact,
                      onPressed: _addNewItemDialog,
                    ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppTheme.glassBorder),

            // Item rows list
            if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'No items staged. Tap + to add items.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: _items.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  indent: 48,
                  endIndent: 16,
                  color: AppTheme.glassBorder,
                ),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return _buildItemRow(item, appState, accentColor);
                },
              ),

            // Footer / Action Buttons
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: appState.bgSubtle.withValues(alpha: 0.5),
                border: const Border(
                  top: BorderSide(color: AppTheme.glassBorder),
                ),
              ),
              child: _isApplied
                  ? _buildAppliedStateFooter(context, appState, accentColor)
                  : _buildPendingStateFooter(context, appState, accentColor, selectedCount),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ITEM ROW WITH INLINE CONTROLS
  // ---------------------------------------------------------------------------
  Widget _buildItemRow(
    InventoryBatchActionItem item,
    AppState appState,
    Color accentColor,
  ) {
    Color actionBadgeColor;
    String actionBadgeLabel;
    IconData actionBadgeIcon;

    switch (item.actionType) {
      case BatchActionType.add:
        actionBadgeColor = AppTheme.accentGreen;
        actionBadgeLabel = 'Add';
        actionBadgeIcon = Icons.add_rounded;
        break;
      case BatchActionType.update:
        actionBadgeColor = const Color(0xFFD97706);
        actionBadgeLabel = 'Update';
        actionBadgeIcon = Icons.edit_rounded;
        break;
      case BatchActionType.remove:
        actionBadgeColor = const Color(0xFFDC2626);
        actionBadgeLabel = 'Remove';
        actionBadgeIcon = Icons.delete_outline_rounded;
        break;
    }

    String locEmoji;
    switch (item.location) {
      case StorageLocation.fridge:
        locEmoji = 'Fridge';
        break;
      case StorageLocation.freezer:
        locEmoji = 'Freezer';
        break;
      case StorageLocation.pantry:
        locEmoji = 'Pantry';
        break;
      case StorageLocation.seasoning:
        locEmoji = 'Seasoning';
        break;
    }

    return Opacity(
      opacity: item.isSelected ? 1.0 : 0.45,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            Checkbox(
              value: item.isSelected,
              activeColor: accentColor,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              onChanged: _isApplied
                  ? null
                  : (val) {
                      setState(() {
                        item.isSelected = val ?? false;
                      });
                    },
            ),

            // Content Area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Item Name & Action Type Badge
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: _isApplied ? null : () => _editItemDialog(item),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    item.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textMain,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!_isApplied) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 13,
                                    color: AppTheme.textMuted.withValues(alpha: 0.6),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Action Type Toggle Chip (Tapping cycles Add -> Update -> Remove)
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: _isApplied
                            ? null
                            : () {
                                setState(() {
                                  if (item.actionType == BatchActionType.add) {
                                    item.actionType = BatchActionType.update;
                                  } else if (item.actionType == BatchActionType.update) {
                                    item.actionType = BatchActionType.remove;
                                  } else {
                                    item.actionType = BatchActionType.add;
                                  }
                                });
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: actionBadgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: actionBadgeColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(actionBadgeIcon, size: 12, color: actionBadgeColor),
                              const SizedBox(width: 3),
                              Text(
                                actionBadgeLabel,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: actionBadgeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  // Row 2: Location Toggle Chip & Quantity Display
                  Row(
                    children: [
                      // Location Toggle (Tap to cycle Fridge -> Freezer -> Pantry)
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: _isApplied
                            ? null
                            : () {
                                setState(() {
                                  if (item.location == StorageLocation.fridge) {
                                    item.location = StorageLocation.freezer;
                                  } else if (item.location == StorageLocation.freezer) {
                                    item.location = StorageLocation.pantry;
                                  } else if (item.location == StorageLocation.pantry) {
                                    item.location = StorageLocation.seasoning;
                                  } else {
                                    item.location = StorageLocation.fridge;
                                  }
                                });
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: appState.bgSubtle,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.glassBorder),
                          ),
                          child: Text(
                            locEmoji,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMain,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),

                      // Quantity Pill (Tap to edit)
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: _isApplied ? null : () => _editItemDialog(item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: appState.bgSubtle,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.glassBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.quantityDisplay,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Delete item from list button
            if (!_isApplied)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 16),
                color: AppTheme.textMuted,
                tooltip: 'Remove from list',
                onPressed: () {
                  setState(() {
                    _items.remove(item);
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FOOTER (PENDING STATE)
  // ---------------------------------------------------------------------------
  Widget _buildPendingStateFooter(
    BuildContext context,
    AppState appState,
    Color accentColor,
    int selectedCount,
  ) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: Text(
              selectedCount == 0
                  ? 'Select Items to Apply'
                  : 'Apply Updates to Inventory ($selectedCount)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: selectedCount == 0 ? null : () => _applyUpdates(appState),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FOOTER (APPLIED STATE)
  // ---------------------------------------------------------------------------
  Widget _buildAppliedStateFooter(
    BuildContext context,
    AppState appState,
    Color accentColor,
  ) {
    return Column(
      children: [
        Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppTheme.accentGreen,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Applied $_appliedCount changes to Kitchen Inventory',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentGreen,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: accentColor,
              side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.kitchen_rounded, size: 16),
            label: Text(
              'View Kitchen Inventory Tab',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () {
              appState.setActiveTab(AppState.tabFridge); // Switch to Fridge / Inventory tab
              Navigator.pop(context); // Return to main shell
            },
          ),
        ),
      ],
    );
  }
}
