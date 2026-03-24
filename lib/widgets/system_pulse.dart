
import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Animated pulsing dot that indicates the data source status:
///   • [isLive] = true  → green pulse  (real / live data from API)
///   • [isLive] = false → red pulse    (mock / demo data)
class SystemPulse extends StatefulWidget {
  const SystemPulse({
    super.key,
    required this.isLive,
    this.label,
    this.size = 10.0,
  });

  /// true = green live dot, false = red mock dot
  final bool isLive;

  /// Optional text label rendered to the right of the dot
  final String? label;

  /// Diameter of the core dot
  final double size;

  @override
  State<SystemPulse> createState() => _SystemPulseState();
}

class _SystemPulseState extends State<SystemPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _pulseAnim; // 0 → 1
  late final Animation<double>   _fadeAnim;  // 1 → 0

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _pulseAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _fadeAnim = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _color => widget.isLive ? AppColors.success : AppColors.accent;
  String get _statusText => widget.isLive ? 'Live Data' : 'Mock Data';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated ripple + core dot
        SizedBox(
          width: widget.size * 3.2,
          height: widget.size * 3.2,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, child) {
              return CustomPaint(
                painter: _PulsePainter(
                  progress: _pulseAnim.value,
                  opacity:  _fadeAnim.value,
                  color:    _color,
                  dotSize:  widget.size,
                ),
              );
            },
          ),
        ),

        const SizedBox(width: 8),

        // Label
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label ?? _statusText,
              style: TextStyle(
                color: _color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            Text(
              widget.isLive
                  ? 'Connected to server'
                  : 'Using demo values',
              style: const TextStyle(
                color: AppColors.textDisabled,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Painter ────────────────────────────────────────────────────────────────────

class _PulsePainter extends CustomPainter {
  _PulsePainter({
    required this.progress,
    required this.opacity,
    required this.color,
    required this.dotSize,
  });

  final double progress;
  final double opacity;
  final Color  color;
  final double dotSize;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Ripple rings
    for (int i = 0; i < 2; i++) {
      final offset = i * 0.4;
      final p = (progress + offset) % 1.0;
      final ringOpacity = opacity * (1 - p) * 0.5;
      if (ringOpacity <= 0) continue;

      canvas.drawCircle(
        center,
        dotSize / 2 + (maxRadius - dotSize / 2) * p,
        Paint()
          ..color = color.withAlpha((ringOpacity * 255).round().clamp(0, 255))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Core dot with inner glow
    final glowPaint = Paint()
      ..color = color.withAlpha(60)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, dotSize / 2 + 3, glowPaint);

    // Solid core
    canvas.drawCircle(
      center,
      dotSize / 2,
      Paint()..color = color,
    );

    // Highlight
    canvas.drawCircle(
      center - Offset(dotSize * 0.12, dotSize * 0.12),
      dotSize * 0.22,
      Paint()..color = Colors.white.withAlpha(120),
    );
  }

  @override
  bool shouldRepaint(_PulsePainter old) =>
      old.progress != progress || old.opacity != opacity;
}

// Ignore unused import that only lints in test environments
// ignore: unused_import
// final _ = math.pi; // keeps the math import used
