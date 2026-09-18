import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class CookingTimerWidget extends StatefulWidget {
  final int initialMinutes;
  final String label;

  const CookingTimerWidget({
    super.key,
    required this.initialMinutes,
    this.label = 'Timer',
  });

  @override
  State<CookingTimerWidget> createState() => _CookingTimerWidgetState();
}

class _CookingTimerWidgetState extends State<CookingTimerWidget> {
  Timer? _timer;
  late int _totalSeconds;
  late int _secondsRemaining;
  bool _isRunning = false;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.initialMinutes * 60;
    _secondsRemaining = _totalSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_secondsRemaining <= 0) return;
    setState(() {
      _isRunning = true;
      _isFinished = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isRunning = false;
          _isFinished = true;
        });
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = _totalSeconds;
      _isRunning = false;
      _isFinished = false;
    });
  }

  void _addMinute() {
    setState(() {
      _totalSeconds += 60;
      _secondsRemaining += 60;
    });
  }

  String _formatTime(int totalSecs) {
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final accentColor = appState.accentColor;
    final progress = _totalSeconds > 0 ? _secondsRemaining / _totalSeconds : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isFinished
              ? accentColor
              : _isRunning
                  ? AppTheme.accentGreen
                  : appState.bgSubtle,
          width: _isRunning || _isFinished ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.timer_rounded,
                    size: 18,
                    color: _isRunning ? AppTheme.accentGreen : accentColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMain,
                    ),
                  ),
                ],
              ),
              if (_isFinished)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Finished!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Circular Progress Indicator & Digital Clock
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5,
                      backgroundColor: appState.bgCard,
                      color: _isFinished ? accentColor : AppTheme.accentGreen,
                    ),
                  ),
                  Text(
                    _formatTime(_secondsRemaining),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMain,
                    ),
                  ),
                ],
              ),

              // Control Buttons: Play/Pause, Reset, +1 Min
              Row(
                children: [
                  IconButton(
                    onPressed: _isRunning ? _pauseTimer : _startTimer,
                    style: IconButton.styleFrom(
                      backgroundColor: _isRunning ? AppTheme.accentAmber : accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 24),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _resetTimer,
                    style: IconButton.styleFrom(
                      backgroundColor: appState.bgCard,
                      foregroundColor: AppTheme.textMain,
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _addMinute,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textMain,
                      side: BorderSide(color: appState.bgSubtle),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      '+1 min',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
