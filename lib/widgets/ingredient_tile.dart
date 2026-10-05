import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/fridge_item.dart';
import '../providers/app_state.dart';
import '../services/ingredient_intelligence.dart';
import '../theme/app_theme.dart';
import 'quantity_scrubber_badge.dart';

class IngredientTile extends StatefulWidget {
  final FridgeItem item;

  const IngredientTile({
    super.key,
    required this.item,
  });

  @override
  State<IngredientTile> createState() => _IngredientTileState();
}

class _IngredientTileState extends State<IngredientTile> {
  bool _isDragging = false;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'have':
        return AppTheme.accentGreen;
      case 'running low':
        return AppTheme.accentAmber;
      case 'missing':
        return const Color(0xFFE53935);
      default:
        return AppTheme.textMuted;
    }
  }

  Color _getStatusBgColor(String status, Color defaultBgCard) {
    switch (status.toLowerCase()) {
      case 'have':
        return AppTheme.bgGreenLight;
      case 'running low':
        return const Color(0xFFFEF3C7);
      case 'missing':
        return const Color(0xFFFFEBEE);
      default:
        return defaultBgCard;
    }
  }

  void _showEditItemModal(BuildContext context, FridgeItem currentItem) {
    final appState = context.read<AppState>();
    final nameController = TextEditingController(text: currentItem.name);
    final quantityController = TextEditingController(text: currentItem.quantityDisplay ?? '');
    StorageLocation selectedLoc = currentItem.location;
    String selectedStatus = currentItem.status;
    QuantityMode selectedMode = currentItem.quantityMode;

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Edit Ingredient',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMain,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Name Input
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Ingredient Name',
                        filled: true,
                        fillColor: AppTheme.bgSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.bgSubtle),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Location Picker
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _locChip(StorageLocation.fridge, 'Fridge', selectedLoc, (loc) {
                          setModalState(() => selectedLoc = loc);
                        }, appState),
                        _locChip(StorageLocation.freezer, 'Freezer', selectedLoc, (loc) {
                          setModalState(() => selectedLoc = loc);
                        }, appState),
                        _locChip(StorageLocation.pantry, 'Pantry', selectedLoc, (loc) {
                          setModalState(() => selectedLoc = loc);
                        }, appState),
                        _locChip(StorageLocation.seasoning, 'Seasoning', selectedLoc, (loc) {
                          setModalState(() => selectedLoc = loc);
                        }, appState),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (!appState.trackQuantities) ...[
                      // Note that background quantity is preserved
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: appState.bgSubtle.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.textMuted),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                currentItem.quantityDisplay?.isNotEmpty == true
                                    ? 'Saved background quantity: "${currentItem.quantityDisplay}" (Kept safe)'
                                    : 'Quantity tracking is currently off. Saved in background.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ] else ...[
                      // Quantity Mode Segment
                      Row(
                        children: [
                          Text('Quantity Mode:', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => setModalState(() => selectedMode = QuantityMode.approximate),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: selectedMode == QuantityMode.approximate ? AppTheme.textMain : appState.bgCard,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: selectedMode == QuantityMode.approximate ? AppTheme.textMain : appState.bgSubtle),
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
                                color: selectedMode == QuantityMode.exact ? AppTheme.textMain : appState.bgCard,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: selectedMode == QuantityMode.exact ? AppTheme.textMain : appState.bgSubtle),
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
                      const SizedBox(height: 14),

                      // Quantity Value Input
                      TextField(
                        controller: quantityController,
                        decoration: InputDecoration(
                          labelText: selectedMode == QuantityMode.exact ? 'Quantity (e.g. 500g, 2 packs)' : 'Approximate Level (e.g. Plenty, Low)',
                          hintText: selectedMode == QuantityMode.exact ? '500g' : 'Plenty',
                          filled: true,
                          fillColor: AppTheme.bgSurface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.bgSubtle),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    const SizedBox(height: 14),

                    // Status Picker
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        filled: true,
                        fillColor: AppTheme.bgSurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Have', child: Text('Have')),
                        DropdownMenuItem(value: 'Running low', child: Text('Running low')),
                        DropdownMenuItem(value: 'Missing', child: Text('Missing')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedStatus = val);
                      },
                    ),

                    const SizedBox(height: 20),

                    // Save & Delete Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              context.read<AppState>().removeFridgeItem(currentItem.id);
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textMuted,
                              side: BorderSide(color: appState.bgSubtle),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Delete'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              final updated = currentItem.copyWith(
                                name: nameController.text.trim(),
                                location: selectedLoc,
                                quantityMode: selectedMode,
                                quantityDisplay: appState.trackQuantities
                                    ? quantityController.text.trim()
                                    : currentItem.quantityDisplay,
                                status: selectedStatus,
                              );
                              context.read<AppState>().updateFridgeItem(updated);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.textMain,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: const Text('Save Changes'),
                          ),
                        ),
                      ],
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

  Widget _locChip(StorageLocation loc, String label, StorageLocation selectedLoc, Function(StorageLocation) onTap, AppState appState) {
    final isSel = selectedLoc == loc;
    return GestureDetector(
      onTap: () => onTap(loc),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? AppTheme.textMain : appState.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSel ? AppTheme.textMain : appState.bgSubtle,
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

  Widget _buildDragFeedback(BuildContext context, AppState appState) {
    return Material(
      color: Colors.transparent,
      elevation: 8,
      child: Container(
        width: 280,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: appState.accentColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: appState.accentColor.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.drag_indicator_rounded, color: appState.accentColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.item.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: appState.accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Drop in zone',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: appState.accentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final item = widget.item;
    final statusColor = _getStatusColor(item.status);
    final statusBgColor = _getStatusBgColor(item.status, appState.bgCard);
    final fuzzyNote = IngredientIntelligence.evaluateFuzzyQuantity(item.name, item.quantityDisplay);
    final regionalSub = IngredientIntelligence.getSubstitution(item.name, appState.userRegion);

    return Opacity(
      opacity: _isDragging ? 0.3 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: appState.bgSubtle, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 1. Dedicated Drag Handle (Immediate drag to move between fridge zones)
                Draggable<FridgeItem>(
                  data: item,
                  onDragStarted: () => setState(() => _isDragging = true),
                  onDragEnd: (_) => setState(() => _isDragging = false),
                  onDraggableCanceled: (velocity, offset) => setState(() => _isDragging = false),
                  feedback: _buildDragFeedback(context, appState),
                  childWhenDragging: const SizedBox.shrink(),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 10, 2, 10),
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        size: 18,
                        color: AppTheme.textLight.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ),

                // 2. Main Card Body (Tappable for Edit Modal, Long-pressable for Moving)
                Expanded(
                  child: LongPressDraggable<FridgeItem>(
                    data: item,
                    delay: const Duration(milliseconds: 350),
                    onDragStarted: () => setState(() => _isDragging = true),
                    onDragEnd: (_) => setState(() => _isDragging = false),
                    onDraggableCanceled: (velocity, offset) => setState(() => _isDragging = false),
                    feedback: _buildDragFeedback(context, appState),
                    childWhenDragging: const SizedBox.shrink(),
                    child: InkWell(
                      onTap: () => _showEditItemModal(context, item),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Icon(
                                  item.status == 'Have'
                                      ? Icons.check_circle_outline_rounded
                                      : item.status == 'Running low'
                                          ? Icons.warning_amber_rounded
                                          : Icons.shopping_bag_outlined,
                                  color: statusColor,
                                  size: 17,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textMain,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    appState.trackQuantities
                                        ? fuzzyNote
                                        : '${item.location.name.toUpperCase()} · ${item.status}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Quantity Scrubber Badge or Checklist Status Pill
                if (appState.trackQuantities)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 8, 10, 8),
                    child: QuantityScrubberBadge(item: item),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 8, 12, 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.status,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Regional Substitution Intelligence Callout
            if (regionalSub != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: appState.accentColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: appState.accentColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: appState.accentColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Local Sub: ${regionalSub.localSubstitute} (${regionalSub.localSupermarketNote})',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: appState.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
