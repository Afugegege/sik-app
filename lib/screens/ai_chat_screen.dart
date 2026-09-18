import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/ai_chat_message.dart';
import '../models/recipe.dart';
import '../providers/app_state.dart';
import '../services/ai_chat_service.dart';
import '../theme/app_theme.dart';
import 'recipe_detail_screen.dart';
import 'cooking_mode_screen.dart';
import '../widgets/ai_batch_inventory_card.dart';
import '../widgets/ai_recipe_options_card.dart';
import '../widgets/ai_studio_recipe_card.dart';
import '../widgets/voice_message_dialog.dart';
import '../services/ai_recipe_parser.dart';

class AiChatScreen extends StatefulWidget {
  final String? initialQuery;

  const AiChatScreen({super.key, this.initialQuery});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isGenerating = false;
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
    if (query.isEmpty || _isGenerating) return;

    final appState = context.read<AppState>();
    _controller.clear();

    // 1. Add user message
    final userMsg = AiChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: query,
      isUser: true,
      timestamp: DateTime.now(),
      isVoiceMessage: isVoice,
      voiceDurationSeconds: voiceDuration,
    );
    appState.addChatMessage(userMsg);
    _scrollToBottom();

    setState(() {
      _isGenerating = true;
    });

    try {
      // 2. Generate response from AI Chat Service
      final response = await AiChatService.generateResponse(
        prompt: query,
        fridgeItems: appState.fridgeItems,
        availableRecipes: appState.recipes,
        apiKey: appState.apiKey,
        preferredCuisines: appState.preferredCuisines,
        conversationHistory: appState.chatMessages,
      );

      if (!mounted) return;

      final aiMsg = AiChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text: response.text,
        isUser: false,
        timestamp: DateTime.now(),
        quickReplies: response.quickReplies,
        suggestedIngredients: response.suggestedIngredients,
        recommendedRecipes: response.recommendedRecipes,
        actions: response.actions,
        batchInventoryActions: response.batchInventoryActions,
        recipeOptions: response.recipeOptions,
        structuredRecipe: response.structuredRecipe,
      );

      appState.addChatMessage(aiMsg);
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      appState.addChatMessage(
        AiChatMessage(
          id: 'ai_err_${DateTime.now().millisecondsSinceEpoch}',
          text: 'I ran into a temporary issue, but you can try asking about recipe ideas or ingredients anytime!',
          isUser: false,
          timestamp: DateTime.now(),
          quickReplies: const [
            'What ingredients do I need for cookies?',
            'What can I cook with my fridge?',
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final accentColor = appState.accentColor;
    final messages = appState.chatMessages;

    return Scaffold(
      backgroundColor: appState.bgPrimary,
      appBar: AppBar(
        backgroundColor: appState.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AppTheme.textMain,
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Text(
              '식',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: accentColor,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'studio',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMain,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
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
                  const SizedBox(width: 4),
                  Text(
                    'assistant',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: appState.bgCard,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.refresh_rounded,
                size: 16,
                color: AppTheme.textMuted,
              ),
            ),
            tooltip: 'Clear Chat History',
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
                    'This will clear the current conversation history.',
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
        child: Column(
          children: [
            // Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: (messages.length <= 1 ? 1 : 0) + messages.length + (_isGenerating ? 1 : 0),
                itemBuilder: (context, index) {
                  final showHero = messages.length <= 1;
                  if (showHero && index == 0) {
                    return _buildIntroHero(appState, accentColor);
                  }
                  final msgIndex = showHero ? index - 1 : index;
                  if (msgIndex == messages.length && _isGenerating) {
                    return _buildThinkingIndicator(accentColor, appState);
                  }
                  final msg = messages[msgIndex];
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
  // MINIMALIST INS HERO CARD
  // ---------------------------------------------------------------------------
  Widget _buildIntroHero(AppState appState, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.20),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  '식',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '식 studio',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMain,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mindful kitchen companion & recipe studio',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted,
              ),
            ),
          ],
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

    // Extract dynamic recipe options or structured recipe card
    final effectiveOptions = msg.recipeOptions.isNotEmpty
        ? msg.recipeOptions
        : (!isUser && msg.structuredRecipe == null
            ? AiRecipeParser.parse(msg.text).options
            : const <AiRecipeOption>[]);

    final effectiveRecipe = msg.structuredRecipe ??
        (!isUser && msg.recipeOptions.isEmpty
            ? AiRecipeParser.parse(msg.text).recipe
            : null);

    // If options or recipe exist, bubble only renders the clean introductory text!
    final bubbleText = (!isUser && (effectiveRecipe != null || effectiveOptions.isNotEmpty))
        ? AiRecipeParser.parse(msg.text).cleanText
        : msg.text;

    final showBubble = isUser || bubbleText.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showBubble)
            Row(
              mainAxisAlignment:
                  isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                          color: isUser
                              ? const Color(0x12000000)
                              : const Color(0x06000000),
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
          // 1. Action: Small Curated List of Recipe Title Options with Select UI
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
          // 2. Action: Aesthetic Studio Recipe Card (Instead of Raw Text)
          // -----------------------------------------------------------------
          if (effectiveRecipe != null) ...[
            const SizedBox(height: 10),
            AiStudioRecipeCard(recipe: effectiveRecipe),
          ],

          // -----------------------------------------------------------------
          // 3. Action: Suggested Ingredients Card with 1-tap "Add to Shopping List"
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

        // Check for Headings: ###, ##, #
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

        // Check for numbered lines (e.g. "1. ", "2. ")
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

        // Check for bullet lines (•, -, *)
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

        // Standard paragraph line
        return Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: _buildRichInlineText(line, textColor),
        );
      }).toList(),
    );
  }

  // Enhanced parser for **bold** and *italic* text in markdown
  Widget _buildRichInlineText(String text, Color baseColor) {
    final spans = <TextSpan>[];
    final parts = text.split('**');

    for (int i = 0; i < parts.length; i++) {
      final isBold = i % 2 == 1;
      final part = parts[i];

      // Also support *italic* within regular text
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

  // ---------------------------------------------------------------------------
  // INGREDIENTS ACTION CARD (e.g. Cookie ingredients 1-tap add)
  // ---------------------------------------------------------------------------
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
              // Add to Shopping List Button
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

              // Add to Fridge Button
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

  // ---------------------------------------------------------------------------
  // RECIPES CAROUSEL (Recipe cards inside chat)
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // QUICK REPLIES HORIZONTAL ROW (INS CHIC PILLS)
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // THINKING INDICATOR
  // ---------------------------------------------------------------------------
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
                  '식 is thinking...',
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
  // INPUT COMPOSER (FLOATING MINIMALIST DOCK)
  // ---------------------------------------------------------------------------
  Widget _buildInputComposer(AppState appState, Color accentColor) {
    final hasText = _controller.text.trim().isNotEmpty;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
          decoration: BoxDecoration(
            color: appState.glassBg,
            border: Border(
              top: BorderSide(
                color: appState.bgSubtle,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0x14000000),
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (val) => _handleSendMessage(val),
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMain,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ask anything (e.g. cookie ingredients, dinner)...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textLight,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Microphone Voice Message Button
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
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.mic_rounded, color: accentColor, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _handleSendMessage(_controller.text),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: hasText ? accentColor : appState.bgSubtle,
                      shape: BoxShape.circle,
                      boxShadow: hasText
                          ? [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: _isGenerating
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  hasText ? Colors.white : accentColor,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.arrow_upward_rounded,
                              color: hasText ? Colors.white : AppTheme.textLight,
                              size: 18,
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
