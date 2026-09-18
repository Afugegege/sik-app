import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// An interactive circular round bar dial to intuitively set cooking time.
/// Users can drag along the circular round bar level or tap quick minute presets.
class CircularTimerDial extends StatefulWidget {
  final int initialMinutes;
  final int maxMinutes;
  final ValueChanged<int> onChanged;
  final Color accentColor;
  final double size;

  const CircularTimerDial({
    super.key,
    required this.initialMinutes,
    this.maxMinutes = 60,
    required this.onChanged,
    required this.accentColor,
    this.size = 220,
  });

  @override
  State<CircularTimerDial> createState() => _CircularTimerDialState();
}

class _CircularTimerDialState extends State<CircularTimerDial> {
  late int _minutes;

  @override
  void initState() {
    super.initState();
    _minutes = widget.initialMinutes.clamp(1, widget.maxMinutes);
  }

  void _updateFromOffset(Offset localPos, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;

    // Angle in radians from top (12 o'clock / -pi/2) clockwise
    double angle = math.atan2(dy, dx) + math.pi / 2;
    if (angle < 0) {
      angle += 2 * math.pi;
    }

    final fraction = (angle / (2 * math.pi)).clamp(0.0, 1.0);
    int newMinutes = (fraction * widget.maxMinutes).round();
    if (newMinutes < 1) newMinutes = 1;
    if (newMinutes > widget.maxMinutes) newMinutes = widget.maxMinutes;

    if (newMinutes != _minutes) {
      HapticFeedback.selectionClick();
      setState(() {
        _minutes = newMinutes;
      });
      widget.onChanged(_minutes);
    }
  }

  void _setMinutes(int m) {
    HapticFeedback.lightImpact();
    setState(() {
      _minutes = m.clamp(1, widget.maxMinutes);
    });
    widget.onChanged(_minutes);
  }

  @override
  Widget build(BuildContext context) {
    final fraction = (_minutes / widget.maxMinutes).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Interactive Circular Dial
        GestureDetector(
          onPanStart: (details) => _updateFromOffset(details.localPosition, Size(widget.size, widget.size)),
          onPanUpdate: (details) => _updateFromOffset(details.localPosition, Size(widget.size, widget.size)),
          onTapDown: (details) => _updateFromOffset(details.localPosition, Size(widget.size, widget.size)),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _CircularLevelPainter(
                    fraction: fraction,
                    accentColor: widget.accentColor,
                    trackColor: widget.accentColor.withValues(alpha: 0.12),
                  ),
                ),
                // Center Display
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_minutes.toString().padLeft(2, '0')}:00',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: widget.size * 0.16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_minutes min',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: widget.accentColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Drag ring to adjust',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Quick Preset Level Buttons
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [1, 3, 5, 10, 15, 20, 30].map((m) {
            final isSel = _minutes == m;
            return InkWell(
              onTap: () => _setMinutes(m),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSel ? widget.accentColor : widget.accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSel ? widget.accentColor : widget.accentColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  '+${m}m',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                    color: isSel ? Colors.white : AppTheme.textMain,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CircularLevelPainter extends CustomPainter {
  final double fraction; // 0.0 to 1.0
  final Color accentColor;
  final Color trackColor;

  _CircularLevelPainter({
    required this.fraction,
    required this.accentColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 10.0;

    // 1. Background full track circle
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Tick marks at 5-minute notches (12 divisions)
    final tickPaint = Paint()
      ..color = AppTheme.textLight.withValues(alpha: 0.35)
      ..strokeWidth = 1.5;

    for (int i = 0; i < 12; i++) {
      final angle = -math.pi / 2 + (i * 2 * math.pi / 12);
      final outerP = Offset(
        center.dx + (radius + 8) * math.cos(angle),
        center.dy + (radius + 8) * math.sin(angle),
      );
      final innerP = Offset(
        center.dx + (radius + 4) * math.cos(angle),
        center.dy + (radius + 4) * math.sin(angle),
      );
      canvas.drawLine(innerP, outerP, tickPaint);
    }

    // 3. Active foreground round bar level arc
    if (fraction > 0) {
      final sweepAngle = 2 * math.pi * fraction;
      final activePaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        activePaint,
      );

      // 4. Draggable thumb knob at the end of the arc
      final endAngle = -math.pi / 2 + sweepAngle;
      final thumbCenter = Offset(
        center.dx + radius * math.cos(endAngle),
        center.dy + radius * math.sin(endAngle),
      );

      // Thumb shadow
      canvas.drawCircle(
        thumbCenter + const Offset(0, 1.5),
        9,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      // Thumb outer border
      canvas.drawCircle(
        thumbCenter,
        9,
        Paint()..color = Colors.white,
      );

      // Thumb inner accent dot
      canvas.drawCircle(
        thumbCenter,
        6,
        Paint()..color = accentColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircularLevelPainter oldDelegate) {
    return oldDelegate.fraction != fraction ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.trackColor != trackColor;
  }
}
