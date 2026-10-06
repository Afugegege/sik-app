import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/ai_chat_message.dart';
import '../models/recipe.dart';
import '../models/fridge_item.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'recipe_detail_screen.dart';
import 'cooking_mode_screen.dart';
import '../widgets/ai_batch_inventory_card.dart';
import '../widgets/ai_recipe_options_card.dart';
import '../widgets/ai_studio_recipe_card.dart';
import '../widgets/voice_message_dialog.dart';
import '../widgets/kitchen_notepad_dialog.dart';
import '../services/ai_recipe_parser.dart';

class AiChatScreen extends StatefulWidget {
  final String? initialQuery;
  final bool isMainTab;

  const AiChatScreen({
    super.key,
    this.initialQuery,
    this.isMainTab = false,
  });

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final Set<String> _addedShoppingMessageIds = {};
  final Set<String> _addedFridgeMessageIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSendMessage(widget.initialQuery!.trim());
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _handleSendMessage(String text, {bool isVoice = false, int? voiceDuration}) async {
    final query = text.trim();
    if (query.isEmpty) return;

    final appState = context.read<AppState>();
    if (appState.isGeneratingChatResponse) return;

    _controller.clear();
    _scrollToBottom();

    await appState.sendUserChatMessage(
      query,
      isVoice: isVoice,
      voiceDuration: voiceDuration,
    );

    if (mounted) {
      _scrollToBottom();
    }
  }

  void _showPantryQuickSheet(BuildContext context, AppState appState) {
    final accentColor = appState.accentColor;
    final fridge = appState.fridgeItems.where((i) => i.location == StorageLocation.fridge).toList();
    final freezer = appState.fridgeItems.where((i) => i.location == StorageLocation.freezer).toList();
    final pantry = appState.fridgeItems.where((i) => i.location == StorageLocation.pantry).toList();
    final seasonings = appState.fridgeItems.where((i) => i.location == StorageLocation.seasoning).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: appState.bgPrimary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kitchen Inventory',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMain,
                      ),
                    ),
                    Text(
                      '${appState.fridgeItems.length} ingredients tracked',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    appState.setActiveTab(AppState.tabFridge);
                  },
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Manage'),
                  style: TextButton.styleFrom(
                    foregroundColor: accentColor,
                    textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (fridge.isNotEmpty) _buildPantrySection('Fridge', fridge, accentColor, appState),
                    if (freezer.isNotEmpty) _buildPantrySection('Freezer', freezer, accentColor, appState),
                    if (pantry.isNotEmpty) _buildPantrySection('Pantry', pantry, accentColor, appState),
                    if (seasonings.isNotEmpty) _buildPantrySection('Seasonings', seasonings, accentColor, appState),
                    if (appState.fridgeItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                          child: Text(
                            'Your kitchen is currently empty.\nAdd groceries or tell the AI what you bought!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: appState.fridgeItems.isEmpty
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        final topNames = appState.fridgeItems.take(6).map((e) => e.name).join(', ');
                        _handleSendMessage('What can I cook with my kitchen ingredients: $topNames?');
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.restaurant_menu_rounded, size: 16),
                label: Text(
                  'Cook with What I Have',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPantrySection(String title, List<FridgeItem> items, Color accentColor, AppState appState) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: appState.bgCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: appState.bgSubtle, width: 1),
                ),
                child: Text(
                  item.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMain,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showAttachmentMenu(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: appState.bgPrimary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: appState.accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.kitchen_rounded, color: appState.accentColor, size: 20),
              ),
              title: Text(
                'Attach My Kitchen Ingredients',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              subtitle: Text(
                'Inserts your current fridge & pantry items into the chat',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
              ),
              onTap: () {
                Navigator.pop(ctx);
                final items = appState.fridgeItems.map((e) => e.name).join(', ');
                if (items.isNotEmpty) {
                  _controller.text = 'I have $items. What can I cook?';
                  _controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: _controller.text.length),
                  );
                  _focusNode.requestFocus();
                }
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_note_rounded, color: Color(0xFFD97706), size: 20),
              ),
              title: Text(
                'Open Kitchen Notepad',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              subtitle: Text(
                'Draft a long recipe, meal idea, or grocery memo',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
              ),
              onTap: () {
                Navigator.pop(ctx);
                KitchenNotepadDialog.show(
                  context: context,
                  initialText: _controller.text,
                  onApply: (text) {
                    _controller.text = text;
                    _controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: text.length),
                    );
                    _focusNode.requestFocus();
                  },
                  onSend: (text) {
                    _handleSendMessage(text);
                  },
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shopping_cart_outlined, color: AppTheme.accentGreen, size: 20),
              ),
              title: Text(
                'Log Grocery Haul',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              subtitle: Text(
                'Quickly batch update inventory from recent shopping',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _controller.text = 'I bought: ';
                _controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: _controller.text.length),
                );
                _focusNode.requestFocus();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final accentColor = appState.accentColor;
    final messages = appState.chatMessages;
    final isGenerating = appState.isGeneratingChatResponse;

    return Scaffold(
      backgroundColor: appState.bgPrimary,
      appBar: AppBar(
        backgroundColor: appState.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: widget.isMainTab
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                color: AppTheme.textMain,
                tooltip: 'Back',
                onPressed: () => Navigator.maybePop(context),
              ),
        automaticallyImplyLeading: !widget.isMainTab,
        titleSpacing: widget.isMainTab ? 20 : 0,
        title: Row(
          children: [
            Text(
              '식',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMain,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 12,
              width: 1,
              color: AppTheme.textLight.withValues(alpha: 0.35),
            ),
            const SizedBox(width: 8),
            Text(
              'ATELIER',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.2,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          // Quick Pantry Glance Pill (Korean Minimalist)
          InkWell(
            onTap: () => _showPantryQuickSheet(context, appState),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: appState.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: appState.bgSubtle, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'pantry ${appState.fridgeItems.length}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMain,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Clear / Reset Conversation
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              size: 18,
              color: AppTheme.textMuted,
            ),
            tooltip: 'Reset session',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: appState.bgCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(
                    'Reset Conversation?',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMain,
                    ),
                  ),
                  content: Text(
                    'This will clear the conversation history and start a fresh session.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppTheme.textMuted,
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
                        Navigator.pop(ctx);
                        appState.clearChatMessages();
                      },
                      child: Text(
                        'Reset',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: (messages.length <= 1 ? 1 : messages.length) + (isGenerating ? 1 : 0),
                itemBuilder: (context, index) {
                  if (messages.length <= 1 && index == 0) {
                    return _buildIntroHero(appState, accentColor);
                  }
                  if (index == messages.length && isGenerating) {
                    return _buildThinkingIndicator(accentColor, appState);
                  }
                  final msg = messages[index];
                  return _buildMessageItem(msg, appState, accentColor);
                },
              ),
            ),

            // Bottom Composer Area
            _buildInputComposer(appState, accentColor),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // KOREAN MINIMALIST ATELIER HERO (EDITORIAL CURATION)
  // ---------------------------------------------------------------------------
  Widget _buildIntroHero(AppState appState, Color accentColor) {
    final pantryCount = appState.fridgeItems.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Editorial Badge
          Row(
            children: [
              Text(
                '식 · 食',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3.0,
                  color: accentColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: appState.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: appState.bgSubtle, width: 0.9),
                ),
                child: Text(
                  'ATELIER CURATION',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'What would you like\nto prepare today?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.22,
              letterSpacing: -0.8,
              color: AppTheme.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell me what ingredients you hold, describe a dish,\nor batch-log items from your market haul.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 24),

          // Architectural Editorial Index Card (No Emojis)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0x12000000),
                width: 0.9,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildCuratedIndexRow(
                  index: '01',
                  title: 'Pantry Tasting',
                  subtitle: pantryCount > 0
                      ? 'Compose a dish with your $pantryCount kitchen ingredients'
                      : 'Explore dishes from your fresh ingredients',
                  accentColor: accentColor,
                  onTap: () {
                    final names = appState.fridgeItems.take(5).map((e) => e.name).join(', ');
                    _handleSendMessage(names.isNotEmpty
                        ? 'What can I cook with my kitchen ingredients: $names?'
                        : 'What can I cook with what I have?');
                  },
                ),
                const Divider(height: 1, thickness: 0.8, color: Color(0x0E000000)),
                _buildCuratedIndexRow(
                  index: '02',
                  title: '15-Minute Hearth Bowl',
                  subtitle: 'Simple, balanced cooking for busy weeknights',
                  accentColor: accentColor,
                  onTap: () {
                    _handleSendMessage('Give me 15-minute quick dinner ideas');
                  },
                ),
                const Divider(height: 1, thickness: 0.8, color: Color(0x0E000000)),
                _buildCuratedIndexRow(
                  index: '03',
                  title: 'Seasonal Market Haul',
                  subtitle: 'Batch-log fresh produce & pantry essentials',
                  accentColor: accentColor,
                  onTap: () {
                    _handleSendMessage('I bought groceries: salmon, eggs, rice, avocado');
                  },
                ),
                const Divider(height: 1, thickness: 0.8, color: Color(0x0E000000)),
                _buildCuratedIndexRow(
                  index: '04',
                  title: 'Essential Jang & Ratios',
                  subtitle: 'Traditional Korean pastes, sauces & balance formulas',
                  accentColor: accentColor,
                  onTap: () {
                    _handleSendMessage('Korean sauce substitutions');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildCuratedIndexRow({
    required String index,
    required String title,
    required String subtitle,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                index,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: AppTheme.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MESSAGE BUBBLES
  // ---------------------------------------------------------------------------
  Widget _buildMessageItem(
    AiChatMessage msg,
    AppState appState,
    Color accentColor,
  ) {
    final isUser = msg.isUser;

    final effectiveOptions = msg.recipeOptions.isNotEmpty
        ? msg.recipeOptions
        : (!isUser && msg.structuredRecipe == null
            ? AiRecipeParser.parse(msg.text).options
            : const <AiRecipeOption>[]);

    final effectiveRecipe = msg.structuredRecipe ??
        (!isUser && msg.recipeOptions.isEmpty
            ? AiRecipeParser.parse(msg.text).recipe
            : null);

    final bubbleText = (!isUser && (effectiveRecipe != null || effectiveOptions.isNotEmpty))
        ? AiRecipeParser.parse(msg.text).cleanText
        : msg.text;

    final showBubble = isUser || bubbleText.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showBubble)
            Row(
              mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isUser) ...[
                  Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 10, top: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.20),
                        width: 0.8,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '식',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ),
                ],
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? AppTheme.textMain : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isUser ? 18 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 18),
                      ),
                      border: isUser
                          ? null
                          : Border.all(
                              color: const Color(0x0F000000),
                              width: 1,
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: isUser ? const Color(0x12000000) : const Color(0x06000000),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: msg.isVoiceMessage
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isUser
                                          ? Colors.white.withValues(alpha: 0.22)
                                          : accentColor.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.play_arrow_rounded,
                                      size: 20,
                                      color: isUser ? Colors.white : accentColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Row(
                                    children: [4.0, 14.0, 8.0, 20.0, 12.0, 18.0, 10.0, 6.0].map((h) {
                                      return Container(
                                        width: 2.5,
                                        height: h,
                                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                        decoration: BoxDecoration(
                                          color: isUser
                                              ? Colors.white.withValues(alpha: 0.75)
                                              : accentColor,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '0:0${msg.voiceDurationSeconds ?? 3}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isUser ? Colors.white70 : AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '"${msg.text}"',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: isUser
                                      ? Colors.white.withValues(alpha: 0.95)
                                      : AppTheme.textMain,
                                ),
                              ),
                            ],
                          )
                        : _formatMessageText(bubbleText, isUser, accentColor),
                  ),
                ),
              ],
            ),

          // -----------------------------------------------------------------
          // 1. Action: Curated Recipe Options Card with Select UI
          // -----------------------------------------------------------------
          if (effectiveOptions.isNotEmpty) ...[
            const SizedBox(height: 10),
            AiRecipeOptionsCard(
              options: effectiveOptions,
              onSelectOption: (recipeTitle) {
                _handleSendMessage(recipeTitle);
              },
            ),
          ],

          // -----------------------------------------------------------------
          // 2. Action: Aesthetic Studio Recipe Card (Connected w/ Inventory)
          // -----------------------------------------------------------------
          if (effectiveRecipe != null) ...[
            const SizedBox(height: 10),
            AiStudioRecipeCard(recipe: effectiveRecipe),
          ],

          // -----------------------------------------------------------------
          // 3. Action: Suggested Ingredients Card
          // -----------------------------------------------------------------
          if (msg.suggestedIngredients.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildIngredientsActionCard(msg, appState, accentColor),
          ],

          // -----------------------------------------------------------------
          // 4. Action: Recommended Recipes Carousel
          // -----------------------------------------------------------------
          if (msg.recommendedRecipes.isNotEmpty && effectiveOptions.isEmpty && effectiveRecipe == null) ...[
            const SizedBox(height: 12),
            _buildRecipesCarousel(msg.recommendedRecipes, appState, accentColor),
          ],

          // -----------------------------------------------------------------
          // 5. Action: AI Action Preview & Batch Inventory List Editor Card
          // -----------------------------------------------------------------
          if (msg.batchInventoryActions.isNotEmpty) ...[
            const SizedBox(height: 12),
            AiBatchInventoryCard(initialItems: msg.batchInventoryActions),
          ],

          // -----------------------------------------------------------------
          // 6. Action Chips (Quick Replies)
          // -----------------------------------------------------------------
          if (msg.quickReplies.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildQuickRepliesRow(msg.quickReplies, accentColor, appState),
          ],
        ],
      ),
    );
  }

  // Formats AI text with superior readability, clean headings, bullet points, and numbered steps
  Widget _formatMessageText(String text, bool isUser, Color accentColor) {
    final textColor = isUser ? Colors.white : AppTheme.textMain;
    final lines = text.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((rawLine) {
        final line = rawLine.trim();
        if (line.isEmpty) {
          return const SizedBox(height: 6);
        }

        // Headings: ###, ##, #
        if (line.startsWith('### ') || line.startsWith('## ') || line.startsWith('# ')) {
          final headingText = line.replaceFirst(RegExp(r'^#{1,3}\s+'), '').replaceAll('**', '');
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 3,
                  height: 14,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.white70 : accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Text(
                    headingText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Numbered lines (e.g. "1. ", "2. ")
        final numberedMatch = RegExp(r'^(\d+)\.\s+(.*)').firstMatch(line);
        if (numberedMatch != null) {
          final number = numberedMatch.group(1)!;
          final content = numberedMatch.group(2)!;

          return Padding(
            padding: const EdgeInsets.only(bottom: 6, top: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(right: 8, top: 1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isUser
                        ? Colors.white.withValues(alpha: 0.20)
                        : accentColor.withValues(alpha: 0.12),
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: isUser ? Colors.white : accentColor,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _buildRichInlineText(content, textColor),
                ),
              ],
            ),
          );
        }

        // Bullet lines (•, -, *)
        if (line.startsWith('• ') || line.startsWith('- ') || line.startsWith('* ')) {
          final content = line.substring(2);
          return Padding(
            padding: const EdgeInsets.only(bottom: 5, left: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(top: 8, right: 8, left: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isUser ? Colors.white70 : accentColor,
                  ),
                ),
                Expanded(
                  child: _buildRichInlineText(content, textColor),
                ),
              ],
            ),
          );
        }

        // Section labels like "Ingredients:" or "Instructions:"
        if (line.endsWith(':') && line.length < 35 && !line.contains('.')) {
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              line.replaceAll('**', ''),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: isUser ? Colors.white70 : AppTheme.textMuted,
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: _buildRichInlineText(line, textColor),
        );
      }).toList(),
    );
  }

  Widget _buildRichInlineText(String text, Color baseColor) {
    final spans = <TextSpan>[];
    final parts = text.split('**');

    for (int i = 0; i < parts.length; i++) {
      final isBold = i % 2 == 1;
      final part = parts[i];

      if (!isBold && part.contains('*') && part.indexOf('*') != part.lastIndexOf('*')) {
        final subParts = part.split('*');
        for (int j = 0; j < subParts.length; j++) {
          final isItalic = j % 2 == 1;
          spans.add(
            TextSpan(
              text: subParts[j],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 1.48,
                fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                fontWeight: FontWeight.w500,
                color: baseColor,
              ),
            ),
          );
        }
      } else {
        spans.add(
          TextSpan(
            text: part,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              height: 1.48,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: baseColor,
            ),
          ),
        );
      }
    }

    return Text.rich(TextSpan(children: spans));
  }

  Widget _buildIngredientsActionCard(
    AiChatMessage msg,
    AppState appState,
    Color accentColor,
  ) {
    final isAddedShop = _addedShoppingMessageIds.contains(msg.id);
    final isAddedFridge = _addedFridgeMessageIds.contains(msg.id);

    return Container(
      margin: const EdgeInsets.only(left: 38),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist_rounded, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Ingredients (${msg.suggestedIngredients.length} items)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: msg.suggestedIngredients.map((ing) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: appState.bgSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.glassBorder,
                  ),
                ),
                child: Text(
                  ing,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMain,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAddedShop ? AppTheme.accentGreen : accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: Icon(
                    isAddedShop ? Icons.check_circle_rounded : Icons.shopping_cart_outlined,
                    size: 16,
                  ),
                  label: Text(
                    isAddedShop ? 'Added to Want List' : 'Add to Shopping List',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: isAddedShop
                      ? null
                      : () {
                          appState.addMultipleToWantList(msg.suggestedIngredients);
                          setState(() {
                            _addedShoppingMessageIds.add(msg.id);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Added ${msg.suggestedIngredients.length} items to Shopping Want List',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: AppTheme.accentGreen,
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: accentColor,
                  side: BorderSide(
                    color: isAddedFridge ? AppTheme.accentGreen : accentColor.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  isAddedFridge ? Icons.check_rounded : Icons.kitchen_rounded,
                  size: 16,
                  color: isAddedFridge ? AppTheme.accentGreen : accentColor,
                ),
                label: Text(
                  isAddedFridge ? 'In Fridge' : 'To Pantry',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isAddedFridge ? AppTheme.accentGreen : accentColor,
                  ),
                ),
                onPressed: isAddedFridge
                    ? null
                    : () {
                        appState.addMultipleFridgeItems(msg.suggestedIngredients);
                        setState(() {
                          _addedFridgeMessageIds.add(msg.id);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Added ${msg.suggestedIngredients.length} items to Kitchen Inventory',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: accentColor,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecipesCarousel(
    List<Recipe> recipes,
    AppState appState,
    Color accentColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(left: 38),
      height: 155,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return Container(
            width: 220,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: appState.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${recipe.cookingTimeMinutes}m',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ),
                    Text(
                      '${recipe.kitchenMatchPercent}% match',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  recipe.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMain,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecipeDetailScreen(recipe: recipe),
                            ),
                          );
                        },
                        child: Text(
                          'View Recipe',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: appState.bgSubtle,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(
                        Icons.play_arrow_rounded,
                        size: 18,
                        color: AppTheme.textMain,
                      ),
                      tooltip: 'Cook now',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CookingModeScreen(recipe: recipe),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickRepliesRow(
    List<String> replies,
    Color accentColor,
    AppState appState,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 38, top: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: replies.map((reply) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _handleSendMessage(reply),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6.5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.24),
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 6,
                          offset: Offset(0, 1.5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          reply,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMain,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Icon(
                          Icons.arrow_outward_rounded,
                          size: 12,
                          color: accentColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildThinkingIndicator(Color accentColor, AppState appState) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: accentColor.withValues(alpha: 0.20),
                width: 0.8,
              ),
            ),
            child: Center(
              child: Text(
                '식',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x0F000000)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '식 is cooking up an answer...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INPUT COMPOSER (FLOATING MINIMALIST DOCK WITH QUICK ACTION CAPSULES)
  // ---------------------------------------------------------------------------
  Widget _buildInputComposer(AppState appState, Color accentColor) {
    final hasText = _controller.text.trim().isNotEmpty;
    final isGenerating = appState.isGeneratingChatResponse;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            6,
            16,
            widget.isMainTab ? 76 : 14,
          ),
          decoration: BoxDecoration(
            color: appState.glassBg,
            border: Border(
              top: BorderSide(
                color: appState.bgSubtle,
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Minimalist Editorial Quick Actions Strip
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      _buildQuickActionCapsule(
                        label: 'pantry dishes (${appState.fridgeItems.length})',
                        onTap: () {
                          final names = appState.fridgeItems.take(5).map((e) => e.name).join(', ');
                          if (names.isNotEmpty) {
                            _handleSendMessage('What can I cook with: $names?');
                          } else {
                            _handleSendMessage('What can I cook with my fridge?');
                          }
                        },
                        appState: appState,
                      ),
                      const SizedBox(width: 6),
                      _buildQuickActionCapsule(
                        label: '15m hearth',
                        onTap: () => _handleSendMessage('15-minute quick meal recipe'),
                        appState: appState,
                      ),
                      const SizedBox(width: 6),
                      _buildQuickActionCapsule(
                        label: 'market log',
                        onTap: () {
                          _controller.text = 'I bought: ';
                          _controller.selection = TextSelection.fromPosition(
                            TextPosition(offset: _controller.text.length),
                          );
                          _focusNode.requestFocus();
                        },
                        appState: appState,
                      ),
                      const SizedBox(width: 6),
                      _buildQuickActionCapsule(
                        label: 'jang & ratios',
                        onTap: () => _handleSendMessage('Korean sauce substitutions'),
                        appState: appState,
                      ),
                    ],
                  ),
                ),
              ),

              // Unified Floating Input Capsule
              Container(
                padding: const EdgeInsets.fromLTRB(4, 4, 6, 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0x18000000),
                    width: 0.9,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 14,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Attachment Action
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _showAttachmentMenu(context, appState),
                        child: const Padding(
                          padding: EdgeInsets.all(7),
                          child: Icon(
                            Icons.add_rounded,
                            color: AppTheme.textMuted,
                            size: 21,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),

                    // Main Text Input Field
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (val) => _handleSendMessage(val),
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMain,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Tell AI what you have or want to make...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.textLight,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Microphone Voice Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () async {
                          final res = await VoiceMessageDialog.show(context);
                          if (res != null) {
                            _handleSendMessage(res.text, isVoice: true, voiceDuration: res.durationSeconds);
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(7),
                          child: Icon(
                            Icons.mic_none_rounded,
                            color: AppTheme.textMuted,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),

                    // Modern Send Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _handleSendMessage(_controller.text),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: hasText ? AppTheme.textMain : appState.bgSubtle,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isGenerating
                                ? SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.8,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        hasText ? Colors.white : accentColor,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.arrow_upward_rounded,
                                    color: hasText ? Colors.white : AppTheme.textLight,
                                    size: 17,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCapsule({
    required String label,
    required VoidCallback onTap,
    required AppState appState,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: appState.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: appState.bgSubtle,
            width: 0.9,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: AppTheme.textMain,
          ),
        ),
      ),
    );
  }
}
