import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class KitchenNotepadDialog extends StatefulWidget {
  final String initialText;
  final ValueChanged<String> onApply;
  final ValueChanged<String> onSend;

  const KitchenNotepadDialog({
    super.key,
    required this.initialText,
    required this.onApply,
    required this.onSend,
  });

  static Future<void> show({
    required BuildContext context,
    required String initialText,
    required ValueChanged<String> onApply,
    required ValueChanged<String> onSend,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      barrierDismissible: true,
      builder: (ctx) => KitchenNotepadDialog(
        initialText: initialText,
        onApply: onApply,
        onSend: onSend,
      ),
    );
  }

  @override
  State<KitchenNotepadDialog> createState() => _KitchenNotepadDialogState();
}

class _KitchenNotepadDialogState extends State<KitchenNotepadDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;
    final mediaQuery = MediaQuery.of(context);
    final isKeyboardOpen = mediaQuery.viewInsets.bottom > 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 440,
            maxHeight: 560,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFE7E4DE),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Korean Ins Minimalist Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Text(
                                'MEMO',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.6,
                                  color: AppTheme.textMain,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '·  메모',
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ],
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => Navigator.of(context).pop(),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Direct Pure Memo Writing Area (No nested boxes, no heavy borders)
                      TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        autofocus: true,
                        minLines: isKeyboardOpen ? 4 : 7,
                        maxLines: 12,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        cursorColor: AppTheme.textMain,
                        cursorWidth: 1.5,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          height: 1.6,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textMain,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Write a list or meal plan here...\n\ne.g.\n· 500g salmon, 2 avocados, olive oil\n· dinner for family of 4, warm soup & greens',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            height: 1.6,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.textLight.withValues(alpha: 0.75),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Subtle Hairline Divider
                      Container(
                        height: 0.8,
                        color: const Color(0xFFF1EFEA),
                      ),
                      const SizedBox(height: 12),

                      // Minimalist Action Row (Clean, responsive, matching app theme)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left: Subtle Clear action
                          if (hasText)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _controller.clear(),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    'Clear',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textLight,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            const SizedBox.shrink(),

                          // Right: Paste to bar & Send to AI
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Paste to bar
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: hasText
                                      ? () {
                                          final text = _controller.text.trim();
                                          Navigator.of(context).pop();
                                          widget.onApply(text);
                                        }
                                      : null,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    child: Text(
                                      'Paste to bar',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: hasText
                                            ? AppTheme.textMain
                                            : AppTheme.textLight.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Send button (Matching app's minimal pill style)
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: hasText
                                      ? () {
                                          final text = _controller.text.trim();
                                          Navigator.of(context).pop();
                                          widget.onSend(text);
                                        }
                                      : null,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: hasText
                                          ? AppTheme.textMain
                                          : const Color(0xFFEDEAE3),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Send',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: hasText
                                                ? Colors.white
                                                : AppTheme.textLight,
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        Icon(
                                          Icons.arrow_upward_rounded,
                                          size: 13,
                                          color: hasText
                                              ? Colors.white
                                              : AppTheme.textLight,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
