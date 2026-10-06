import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _addCustomItem(AppState appState) {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      appState.addToWantList(text);
      _textController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final wantList = appState.wantList;
    final accentColor = appState.accentColor;

    return Scaffold(
      backgroundColor: appState.bgPrimary,
      appBar: AppBar(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
              'MARKET LIST',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMain,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: appState.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textMain),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          color: appState.bgPrimary,
          child: Column(
            children: [
              // Info Banner: Want -> Fridge Transition Explanation
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart_checkout_rounded, color: AppTheme.accentGreen, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Swipe or check items marked "Bought" to automatically move them into your Fridge!',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accentGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Manual Quick-Add Input Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.bgSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: appState.bgSubtle),
                        ),
                        child: TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            hintText: 'Add grocery item...',
                            hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textLight, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: (_) => _addCustomItem(appState),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => _addCustomItem(appState),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Icon(Icons.add_rounded, size: 20),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Want List Items
              Expanded(
                child: wantList.isNotEmpty
                    ? ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                        itemCount: wantList.length,
                        itemBuilder: (context, index) {
                          final item = wantList[index];

                          return Dismissible(
                            key: Key(item),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.accentGreen,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Moved to Fridge',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.check_rounded, color: Colors.white),
                                ],
                              ),
                            ),
                            onDismissed: (direction) {
                              appState.markWantItemBought(item);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Moved "$item" to Fridge')),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.bgSurface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: appState.bgSubtle),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.circle_outlined, color: accentColor),
                                        onPressed: () {
                                          appState.markWantItemBought(item);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Moved "$item" to Fridge')),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        item,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textMain,
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.textLight),
                                    onPressed: () => appState.removeFromWantList(item),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shopping_bag_outlined, size: 48, color: AppTheme.textLight),
                            const SizedBox(height: 12),
                            Text(
                              'Your Shopping List is Empty',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textMain,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add missing ingredients from recipes or type above.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
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
