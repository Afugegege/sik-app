import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../services/ai_command_processor.dart';
import '../screens/ai_chat_screen.dart';
import 'kitchen_notepad_dialog.dart';
import 'voice_message_dialog.dart';

class FloatingAiBar extends StatefulWidget {
  const FloatingAiBar({super.key});

  @override
  State<FloatingAiBar> createState() => _FloatingAiBarState();
}

class _FloatingAiBarState extends State<FloatingAiBar> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  bool _hasText = false;
  bool _isFocused = false;
  bool _isProcessing = false;
  ActionPreview? _currentPreview;
  String? _pendingQuery;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();

    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onTextChanged() {
    final text = _textController.text.trim();
    final hasText = text.isNotEmpty;
    setState(() {
      _hasText = hasText;
      if (!hasText) {
        _currentPreview = null;
        _pendingQuery = null;
      }
    });
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus != _isFocused) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleReject() {
    _textController.clear();
    _pendingQuery = null;
    _focusNode.unfocus();
    setState(() {
      _hasText = false;
      _currentPreview = null;
    });
  }

  void _openNotepad() {
    KitchenNotepadDialog.show(
      context: context,
      initialText: _textController.text,
      onApply: (text) {
        _textController.text = text;
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: text.length),
        );
        _focusNode.requestFocus();
      },
      onSend: (text) {
        _handleDirectQuery(text);
      },
    );
  }

  Future<void> _handleDirectQuery(String rawQuery, [ActionPreview? explicitPreview]) async {
    final query = rawQuery.trim();
    if (query.isEmpty || _isProcessing) return;

    _textController.clear();
    _pendingQuery = null;
    _focusNode.unfocus();
    setState(() {
      _hasText = false;
      _currentPreview = null;
    });

    final appState = context.read<AppState>();
    final preview = explicitPreview ?? _currentPreview ?? AiCommandProcessor.classifyAction(query, appState);

    if (preview.type == ActionPreviewType.openChat) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AiChatScreen(initialQuery: query),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final result = await AiCommandProcessor.processUserPrompt(context, query);
    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (result.feedbackMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(preview.icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.feedbackMessage,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: const Color(0xE61C1917),
          duration: const Duration(milliseconds: 2500),
        ),
      );
    }
  }

  Future<void> _handleApprove([ActionPreview? previewToRun]) async {
    final query = _pendingQuery ?? _textController.text.trim();
    if (query.isEmpty) return;
    _pendingQuery = null;
    await _handleDirectQuery(query, previewToRun);
  }

  void _handleSend() {
    final query = _textController.text.trim();
    if (query.isEmpty || _isProcessing) return;

    // If preview is already visible and user taps send again, execute approve
    if (_currentPreview != null) {
      _handleApprove(_currentPreview);
      return;
    }

    // Pop up the Action Card Preview after user submits input
    final appState = context.read<AppState>();
    final preview = AiCommandProcessor.classifyAction(query, appState);
    setState(() {
      _pendingQuery = query;
      _currentPreview = preview;
    });
    _focusNode.unfocus();
  }

  Widget _buildActionPreviewNotificationBar(AppState appState) {
    final preview = _currentPreview;
    if (preview == null) return const SizedBox.shrink();

    final accentColor = appState.accentColor;

    return Padding(
      key: const ValueKey('action_preview_bar'),
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: appState.bgCard.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.28),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Action Icon Badge
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      preview.icon,
                      size: 13,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Action Preview Text: "Title: Detail"
                Expanded(
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${preview.title}: ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMain,
                          ),
                        ),
                        TextSpan(
                          text: preview.detail,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Decline Button behind
                InkWell(
                  onTap: _handleReject,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0x14EF4444),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0x2EEF4444),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      'Decline',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),

                // Proceed Button behind
                InkWell(
                  onTap: () => _handleApprove(preview),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.28),
                          blurRadius: 6,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Proceed',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final activeQuery = appState.currentAiQuery;
    final accentColor = appState.accentColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.25),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            child: _currentPreview != null
                ? _buildActionPreviewNotificationBar(appState)
                : const SizedBox.shrink(),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _isFocused
                        ? accentColor
                        : const Color(0xFFD4D0C5),
                    width: _isFocused ? 1.6 : 1.3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: _isFocused ? 0.12 : 0.08),
                      blurRadius: _isFocused ? 24 : 18,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // AI Sparkle Badge (Prominent dark circular badge with white sparkle)
                    Tooltip(
                      message: 'Open 식 AI Chat',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AiChatScreen()),
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _isFocused ? accentColor : AppTheme.textMain,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                // Active Query Filter Pill (if not typing & query active)
                if (activeQuery.isNotEmpty && !_isFocused && !_hasText) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 100),
                          child: Text(
                            activeQuery,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => appState.clearAiQuery(),
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],

                // Direct Text Input Field
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    maxLines: 1,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSend(),
                    cursorColor: accentColor,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMain,
                    ),
                    decoration: InputDecoration(
                      hintText: activeQuery.isNotEmpty && !_isFocused && !_hasText
                          ? 'Ask or filter...'
                          : 'Ask 식 AI (e.g. cookie ingredients, dinner ideas)...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textMuted.withValues(alpha: 0.8),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),

                // Clear input icon button (when typing)
                if (_hasText)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        _textController.clear();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppTheme.textLight.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(width: 2),

                // Minimalist Notepad Pop-up Button
                Tooltip(
                  message: 'Open Notepad (Draft lists & dinner plans)',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _openNotepad,
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_note_rounded,
                            size: 20,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 2),

                // Hands-Free Voice Input / Microphone Button
                Tooltip(
                  message: 'Voice message (Hands-free kitchen speech)',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final res = await VoiceMessageDialog.show(context);
                        if (res != null && context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AiChatScreen(initialQuery: res.text),
                            ),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.mic_rounded,
                            size: 20,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 2),

                // Send Button with generous touch target & ripple
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _handleSend,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _hasText
                              ? accentColor
                              : const Color(0xFFEBE8E0),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _hasText
                                ? accentColor
                                : const Color(0xFFD8D4C8),
                            width: 1.0,
                          ),
                          boxShadow: _hasText
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
                          child: _isProcessing
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _hasText ? Colors.white : accentColor,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.arrow_upward_rounded,
                                  color: _hasText ? Colors.white : AppTheme.textMain,
                                  size: 18,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
);
  }
}
