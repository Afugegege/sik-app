import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class ViewModeToggle extends StatelessWidget {
  final bool isGrid;
  final ValueChanged<bool> onChanged;

  const ViewModeToggle({
    super.key,
    required this.isGrid,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Container(
      decoration: BoxDecoration(
        color: appState.bgCard.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: appState.bgSubtle,
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.all(2.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // List View Button
          _buildItem(
            context: context,
            isSelected: !isGrid,
            icon: Icons.view_agenda_rounded,
            label: 'List',
            onTap: () => onChanged(false),
          ),
          const SizedBox(width: 2),
          // Grid View Button
          _buildItem(
            context: context,
            isSelected: isGrid,
            icon: Icons.grid_view_rounded,
            label: 'Grid',
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required BuildContext context,
    required bool isSelected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final accentColor = context.watch<AppState>().accentColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.bgSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x0C000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? accentColor : AppTheme.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? accentColor : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
