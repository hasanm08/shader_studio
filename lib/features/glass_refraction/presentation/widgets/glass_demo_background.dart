import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shader_studio/app/theme/app_theme.dart';

/// Busy wallpaper that makes refraction obvious in the demo.
///
/// Gradients, a grid, large type, and drifting orbs give the lens something
/// high-contrast to bend. When [animate] is true the orbs drift slowly.
class GlassDemoBackground extends StatelessWidget {
  /// Creates the demo wallpaper.
  const GlassDemoBackground({
    this.animate = true,
    this.timeSeconds = 0,
    super.key,
  });

  final bool animate;
  final double timeSeconds;

  @override
  Widget build(BuildContext context) {
    final t = animate ? timeSeconds : 0.0;
    return ColoredBox(
      color: const Color(0xFF0A0D12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.55, -0.7),
                radius: 1.15,
                colors: <Color>[Color(0xFF1A3A42), Color(0xFF0A0D12)],
              ),
            ),
          ),
          CustomPaint(painter: _GridPainter()),
          _Orb(
            alignment: Alignment(
              math.sin(t * 0.4) * 0.55,
              math.cos(t * 0.33) * 0.4 - 0.1,
            ),
            diameter: 220,
            colors: const <Color>[Color(0xFF14E6CF), Color(0x0014E6CF)],
          ),
          _Orb(
            alignment: Alignment(
              math.cos(t * 0.28) * 0.65,
              math.sin(t * 0.37) * 0.5 + 0.15,
            ),
            diameter: 280,
            colors: const <Color>[Color(0xFF4DBBFF), Color(0x004DBBFF)],
          ),
          _Orb(
            alignment: Alignment(
              math.sin(t * 0.22 + 1.2) * 0.3 - 0.2,
              math.cos(t * 0.31 + 0.4) * 0.45 + 0.35,
            ),
            diameter: 180,
            colors: const <Color>[Color(0xFFFF8B7B), Color(0x00FF8B7B)],
          ),
          Align(
            alignment: const Alignment(0, -0.55),
            child: Text(
              'REFRACT',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 72,
                fontWeight: FontWeight.w800,
                letterSpacing: 8,
                color: AppColors.text.withValues(alpha: 0.14),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0.7, 0.65),
            child: Transform.rotate(
              angle: -0.35,
              child: Text(
                'GLASS',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF14E6CF).withValues(alpha: 0.22),
                ),
              ),
            ),
          ),
          const Align(alignment: Alignment(-0.75, 0.7), child: _PhotoPanel()),
          const Align(alignment: Alignment(0.75, -0.35), child: _ChipStrip()),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    required this.alignment,
    required this.diameter,
    required this.colors,
  });

  final Alignment alignment;
  final double diameter;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x14F4F7FB)
      ..strokeWidth = 1;
    const step = 36.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PhotoPanel extends StatelessWidget {
  const _PhotoPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF2A1B4A),
            Color(0xFF14B8A6),
            Color(0xFF4DBBFF),
            Color(0xFFFF8B7B),
          ],
          stops: <double>[0, 0.35, 0.7, 1],
        ),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      padding: const EdgeInsets.all(14),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Texture',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          Spacer(),
          Text(
            'High contrast\nfor refraction',
            style: TextStyle(color: Color(0xCCFFFFFF), height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _ChipStrip extends StatelessWidget {
  const _ChipStrip();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final label in <String>['SDF', 'Fresnel', 'Snell'])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x3314E6CF),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0x6614E6CF)),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Ticker-driven wrapper that rebuilds [GlassDemoBackground] while animating.
class AnimatedGlassDemoBackground extends StatefulWidget {
  /// Creates an animated wallpaper.
  const AnimatedGlassDemoBackground({
    this.enabled = true,
    this.onTick,
    super.key,
  });

  final bool enabled;
  final ValueChanged<double>? onTick;

  @override
  State<AnimatedGlassDemoBackground> createState() =>
      _AnimatedGlassDemoBackgroundState();
}

class _AnimatedGlassDemoBackgroundState
    extends State<AnimatedGlassDemoBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _seconds = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _seconds = elapsed.inMicroseconds / 1e6;
      widget.onTick?.call(_seconds);
      setState(() {});
    });
    if (widget.enabled) {
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedGlassDemoBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.enabled && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return GlassDemoBackground(
      animate: widget.enabled && !reduce,
      timeSeconds: _seconds,
    );
  }
}
