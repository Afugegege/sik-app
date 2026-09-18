import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class VoiceMessageResult {
  final String text;
  final int durationSeconds;

  const VoiceMessageResult({
    required this.text,
    required this.durationSeconds,
  });
}

/// A modern, tactile Voice Message Recording modal designed for kitchen & hands-free cooking use.
class VoiceMessageDialog extends StatefulWidget {
  final String? initialPrompt;

  const VoiceMessageDialog({
    super.key,
    this.initialPrompt,
  });

  static Future<VoiceMessageResult?> show(BuildContext context, {String? initialPrompt}) {
    return showModalBottomSheet<VoiceMessageResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VoiceMessageDialog(initialPrompt: initialPrompt),
    );
  }

  @override
  State<VoiceMessageDialog> createState() => _VoiceMessageDialogState();
}

class _VoiceMessageDialogState extends State<VoiceMessageDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Timer? _timer;
  int _seconds = 0;
  final bool _isListening = true;
  String _transcribedText = '';

  final List<String> _samplePrompts = [
    'How do I know if the dish is done?',
    'Can I substitute mirin with white wine?',
    'What side dish pairs well with this?',
    'Set a 4-minute timer for eggs',
    'How do I fix if it gets too salty?',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _transcribedText = widget.initialPrompt ?? _samplePrompts[Random().nextInt(_samplePrompts.length)];

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted && _isListening) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _formatTimer(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  void _sendResult() {
    final duration = _seconds > 0 ? _seconds : 3;
    final text = _transcribedText.trim().isNotEmpty
        ? _transcribedText.trim()
        : 'Cooking advice & tips';

    Navigator.pop(
      context,
      VoiceMessageResult(text: text, durationSeconds: duration),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final accentColor = appState.accentColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 34),
      decoration: BoxDecoration(
        color: appState.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20000000),
            blurRadius: 30,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isListening ? AppTheme.accentGreen : AppTheme.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isListening ? 'Listening (Hands-Free)...' : 'Recorded',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMain,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _formatTimer(_seconds),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Glowing Concentric Mic Button
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              final scale = 1.0 + (_animController.value * 0.15);
              final glowOpacity = 0.15 + (_animController.value * 0.15);

              return Container(
                width: 90 * scale,
                height: 90 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: glowOpacity),
                ),
                child: Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Audio Waveform Equalizer simulation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(16, (i) {
              return AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final randomFactor = sin((i * 0.6) + (_animController.value * 2 * pi)).abs();
                  final barHeight = 8.0 + (randomFactor * 24.0);

                  return Container(
                    width: 3.5,
                    height: barHeight,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i % 2 == 0 ? accentColor : AppTheme.textMain.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                },
              );
            }),
          ),

          const SizedBox(height: 20),

          // Live Transcribed Query Bubble
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: appState.bgSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SPEECH TRANSCRIBED',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _transcribedText = _samplePrompts[Random().nextInt(_samplePrompts.length)];
                        });
                      },
                      child: Text(
                        'Shuffle Prompt',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '"$_transcribedText"',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMain,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Quick Topic Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _samplePrompts.map((p) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(p, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600)),
                    backgroundColor: AppTheme.bgSurface,
                    side: BorderSide(color: appState.bgSubtle),
                    onPressed: () {
                      setState(() {
                        _transcribedText = p;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Send / Cancel Buttons
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Send Voice Message'),
                  onPressed: _sendResult,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
