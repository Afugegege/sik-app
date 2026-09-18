import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'random_recipe_picker_modal.dart';

/// A moveable (draggable) floating round icon for the Random Recipe Picker.
/// Features smooth clamping to viewport edges, tactile tap feedback, and a close button.
class FloatingDraggableRandomPicker extends StatefulWidget {
  final VoidCallback onClose;
  final double parentWidth;
  final double parentHeight;

  const FloatingDraggableRandomPicker({
    super.key,
    required this.onClose,
    required this.parentWidth,
    required this.parentHeight,
  });

  @override
  State<FloatingDraggableRandomPicker> createState() =>
      _FloatingDraggableRandomPickerState();
}

class _FloatingDraggableRandomPickerState
    extends State<FloatingDraggableRandomPicker> {
  double? _rightOffset;
  double? _bottomOffset;
  bool _isDragging = false;
  static const double _buttonSize = 48.0;
  static const double _extraSize = 8.0;
  static const double _totalSize = _buttonSize + _extraSize; // 56.0
  static const double _horizontalMargin = 20.0;
  static const double _topMargin = 20.0;
  static const double _bottomMargin = 145.0;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

    final minX = _horizontalMargin;
    final maxX = (widget.parentWidth - _totalSize - _horizontalMargin).clamp(minX, double.infinity);
    final minY = topPadding + _topMargin;
    final maxY = (widget.parentHeight - _totalSize - bottomPadding - _bottomMargin).clamp(minY, double.infinity);

    // Default position: firmly anchored in the bottom-right corner across phone, tablet, and laptop
    final posX = _rightOffset == null
        ? maxX
        : (widget.parentWidth - _totalSize - _rightOffset!).clamp(minX, maxX);
    final posY = _bottomOffset == null
        ? maxY
        : (widget.parentHeight - _totalSize - bottomPadding - _bottomOffset!).clamp(minY, maxY);

    return Positioned(
      left: posX,
      top: posY,
      child: GestureDetector(
        onPanStart: (_) {},
        onPanUpdate: (details) {
          if (!_isDragging) {
            _isDragging = true;
          }
          setState(() {
            final newX = (posX + details.delta.dx).clamp(minX, maxX);
            final newY = (posY + details.delta.dy).clamp(minY, maxY);
            _rightOffset = widget.parentWidth - _totalSize - newX;
            _bottomOffset = widget.parentHeight - _totalSize - bottomPadding - newY;
          });
        },
        onPanEnd: (_) {
          Future.delayed(const Duration(milliseconds: 80), () {
            if (mounted) {
              setState(() {
                _isDragging = false;
              });
            }
          });
        },
        onPanCancel: () {
          if (mounted) {
            setState(() {
              _isDragging = false;
            });
          }
        },
        child: SizedBox(
          width: _totalSize,
          height: _totalSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main Round Floating Button
              Positioned(
                left: 0,
                bottom: 0,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (!_isDragging) {
                        RandomRecipePickerModal.show(context);
                      }
                    },
                    borderRadius: BorderRadius.circular(_buttonSize / 2),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: _buttonSize,
                      height: _buttonSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: appState.bgCard,
                        border: Border.all(
                          color: appState.bgSubtle,
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: _isDragging ? 12 : 6,
                            offset: _isDragging
                                ? const Offset(0, 5)
                                : const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.style_outlined,
                          size: 20,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Small Close / Dismiss Badge on Top Right
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: widget.onClose,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: appState.bgCard,
                      border: Border.all(
                        color: appState.bgSubtle,
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.close_rounded,
                        size: 11,
                        color: AppTheme.textLight,
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
}
