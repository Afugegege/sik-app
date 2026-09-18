import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/fridge_item.dart';
import '../providers/app_state.dart';
import '../services/quantity_scrubber_helper.dart';
import '../theme/app_theme.dart';

class QuantityScrubberBadge extends StatefulWidget {
  final FridgeItem item;

  const QuantityScrubberBadge({
    super.key,
    required this.item,
  });

  @override
  State<QuantityScrubberBadge> createState() => _QuantityScrubberBadgeState();
}

class _QuantityScrubberBadgeState extends State<QuantityScrubberBadge> with SingleTickerProviderStateMixin {
  bool _isScrubbing = false;
  int _lastStep = 0;
  Offset _dragPosition = Offset.zero;
  late String _previewQuantity;
  late String _previewStatus;

  OverlayEntry? _overlayEntry;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _previewQuantity = widget.item.quantityDisplay ?? '1 piece';
    _previewStatus = widget.item.status;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(covariant QuantityScrubberBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isScrubbing) {
      _previewQuantity = widget.item.quantityDisplay ?? '1 piece';
      _previewStatus = widget.item.status;
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _animController.dispose();
    super.dispose();
  }

  void _onLongPressStart(LongPressStartDetails details) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isScrubbing = true;
      _lastStep = 0;
      _dragPosition = details.globalPosition;
      _previewQuantity = widget.item.quantityDisplay?.isNotEmpty == true
          ? widget.item.quantityDisplay!
          : '1 piece';
      _previewStatus = widget.item.status;
    });

    _animController.forward();
    _showOverlay(context);
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_isScrubbing) return;

    // Step every 24 logical pixels of horizontal displacement
    final currentStep = (details.offsetFromOrigin.dx / 24.0).truncate();

    setState(() {
      _dragPosition = details.globalPosition;
    });

    if (currentStep != _lastStep) {
      final diff = currentStep - _lastStep;
      final isIncrement = diff > 0;

      for (int i = 0; i < diff.abs(); i++) {
        final result = QuantityScrubberHelper.stepQuantity(
          currentQuantity: _previewQuantity,
          currentStatus: _previewStatus,
          increment: isIncrement,
        );
        _previewQuantity = result.quantityDisplay;
        _previewStatus = result.status;
      }

      _lastStep = currentStep;
      HapticFeedback.selectionClick();
    }

    _overlayEntry?.markNeedsBuild();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    _finishScrubbing();
  }

  void _onLongPressCancel() {
    _finishScrubbing();
  }

  void _finishScrubbing() {
    if (!_isScrubbing) return;

    HapticFeedback.lightImpact();
    _removeOverlay();
    _animController.reverse();

    setState(() {
      _isScrubbing = false;
      _lastStep = 0;
    });

    // Save changes if quantity or status changed
    if (_previewQuantity != widget.item.quantityDisplay || _previewStatus != widget.item.status) {
      final updated = widget.item.copyWith(
        quantityDisplay: _previewQuantity,
        status: _previewStatus,
      );
      context.read<AppState>().updateFridgeItem(updated);
    }
  }

  void _showOverlay(BuildContext context) {
    _removeOverlay();

    final overlay = Overlay.of(context);
    final appState = context.read<AppState>();

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        const hudWidth = 200.0;
        const hudHeight = 84.0;

        final left = (_dragPosition.dx - hudWidth / 2).clamp(12.0, screenWidth - hudWidth - 12.0);
        double top = _dragPosition.dy - hudHeight - 24.0;
        if (top < mediaQuery.padding.top + 10) {
          top = _dragPosition.dy + 30.0;
        }

        return Positioned(
          left: left,
          top: top,
          child: Material(
            color: Colors.transparent,
            child: _buildMagnifierHud(appState),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildMagnifierHud(AppState appState) {
    final statusColor = _getStatusColor(_previewStatus);

    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: appState.accentColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: appState.accentColor.withValues(alpha: 0.20),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Hint
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_rounded, size: 11, color: appState.accentColor),
                const SizedBox(width: 4),
                Text(
                  'SLIDE ◄  ► TO ADJUST',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textLight,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Central Stepper Preview
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _lastStep < 0 ? 1.0 : 0.4,
                child: Icon(
                  Icons.arrow_left_rounded,
                  size: 26,
                  color: _lastStep < 0 ? appState.accentColor : AppTheme.textMuted,
                ),
              ),
              Expanded(
                child: Text(
                  _previewQuantity,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMain,
                  ),
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _lastStep > 0 ? 1.0 : 0.4,
                child: Icon(
                  Icons.arrow_right_rounded,
                  size: 26,
                  color: _lastStep > 0 ? appState.accentColor : AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Synced Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _previewStatus,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  void _showQuickStepperSheet(BuildContext context) {
    final appState = context.read<AppState>();
    final accentColor = appState.accentColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String currentQty = widget.item.quantityDisplay ?? '1 piece';
        String currentStatus = widget.item.status;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: appState.bgPrimary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quantity: ${widget.item.name}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
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

                  // Quick Stepper Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: appState.bgSubtle),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.textMain,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(12),
                          ),
                          icon: const Icon(Icons.remove_rounded, color: Colors.white, size: 22),
                          onPressed: () {
                            final result = QuantityScrubberHelper.stepQuantity(
                              currentQuantity: currentQty,
                              currentStatus: currentStatus,
                              increment: false,
                            );
                            final updated = widget.item.copyWith(
                              quantityDisplay: result.quantityDisplay,
                              status: result.status,
                            );
                            appState.updateFridgeItem(updated);
                            HapticFeedback.selectionClick();
                            setSheetState(() {
                              currentQty = result.quantityDisplay;
                              currentStatus = result.status;
                            });
                          },
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                currentQty,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textMain,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentStatus,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(currentStatus),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.textMain,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(12),
                          ),
                          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                          onPressed: () {
                            final result = QuantityScrubberHelper.stepQuantity(
                              currentQuantity: currentQty,
                              currentStatus: currentStatus,
                              increment: true,
                            );
                            final updated = widget.item.copyWith(
                              quantityDisplay: result.quantityDisplay,
                              status: result.status,
                            );
                            appState.updateFridgeItem(updated);
                            HapticFeedback.selectionClick();
                            setSheetState(() {
                              currentQty = result.quantityDisplay;
                              currentStatus = result.status;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Long-Press Pro-Tip banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accentColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.touch_app_rounded, size: 20, color: accentColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Pro-tip: Long press and drag left or right directly on the quantity badge to scrub values in one motion!',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textMain,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final hasDisplay = widget.item.quantityDisplay != null && widget.item.quantityDisplay!.isNotEmpty;
    final displayQty = _isScrubbing
        ? _previewQuantity
        : (hasDisplay ? widget.item.quantityDisplay! : '+ Qty');

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showQuickStepperSheet(context),
        onLongPressStart: _onLongPressStart,
        onLongPressMoveUpdate: _onLongPressMoveUpdate,
        onLongPressEnd: _onLongPressEnd,
        onLongPressCancel: _onLongPressCancel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: _isScrubbing ? 9 : 7,
            vertical: _isScrubbing ? 4 : 3,
          ),
          decoration: BoxDecoration(
            color: _isScrubbing
                ? appState.accentColor.withValues(alpha: 0.14)
                : appState.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isScrubbing
                  ? appState.accentColor
                  : (hasDisplay ? appState.bgSubtle : appState.accentColor.withValues(alpha: 0.3)),
              width: _isScrubbing ? 1.4 : 1.0,
            ),
            boxShadow: _isScrubbing
                ? [
                    BoxShadow(
                      color: appState.accentColor.withValues(alpha: 0.25),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isScrubbing) ...[
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 120),
                  opacity: _lastStep < 0 ? 1.0 : 0.4,
                  child: Text(
                    '◀',
                    style: TextStyle(
                      fontSize: 9,
                      color: _lastStep < 0 ? appState.accentColor : AppTheme.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
              ] else if (hasDisplay) ...[
                const Icon(
                  Icons.tune_rounded,
                  size: 11,
                  color: AppTheme.textLight,
                ),
                const SizedBox(width: 3),
              ],

              Text(
                displayQty,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: _isScrubbing ? FontWeight.w800 : FontWeight.w600,
                  color: _isScrubbing
                      ? appState.accentColor
                      : (hasDisplay ? AppTheme.textMain : appState.accentColor),
                ),
              ),

              if (_isScrubbing) ...[
                const SizedBox(width: 4),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 120),
                  opacity: _lastStep > 0 ? 1.0 : 0.4,
                  child: Text(
                    '▶',
                    style: TextStyle(
                      fontSize: 10,
                      color: _lastStep > 0 ? appState.accentColor : AppTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
