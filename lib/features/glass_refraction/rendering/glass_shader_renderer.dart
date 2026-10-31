import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shader_studio/core/rendering/shader_uniforms.dart';
import 'package:shader_studio/features/glass_refraction/domain/models/glass_refraction_config.dart';
import 'package:shader_studio/features/glass_refraction/domain/models/glass_shape.dart';

/// Asset path registered under `flutter: shaders` in pubspec.yaml.
const String kGlassRefractionShaderAsset = 'shaders/glass_refraction.frag';

/// Writes glass uniforms and paints one panel with a bound background image.
///
/// The [FragmentProgram] is loaded once per isolate via [GlassShaderProgram].
/// Each painter owns its own [ui.FragmentShader] so multiple panels can show
/// different configs without fighting over uniform storage.
class GlassShaderPainter extends CustomPainter {
  /// Creates a painter for a single glass surface.
  GlassShaderPainter({
    required this.shader,
    required this.sink,
    required this.background,
    required this.sampleOrigin,
    required this.sampleExtent,
    required this.config,
    required this.shape,
    required this.timeSeconds,
    super.repaint,
  });

  final ui.FragmentShader shader;
  final FragmentShaderSink sink;
  final ui.Image background;
  final Offset sampleOrigin;
  final Size sampleExtent;
  final GlassRefractionConfig config;
  final GlassShape shape;

  /// Read on every paint so a ticker can advance highlights without rebuilds.
  final ValueGetter<double> timeSeconds;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final c = config.clamp();
    sink.setVec2('uResolution', size.width, size.height);
    sink.setVec2('uSampleOrigin', sampleOrigin.dx, sampleOrigin.dy);
    sink.setVec2('uSampleExtent', sampleExtent.width, sampleExtent.height);
    sink.setFloat('uTime', c.animateHighlights ? timeSeconds() : 0);
    sink.setFloat('uRefraction', c.refractionStrength);
    sink.setFloat('uCurvature', c.curvature);
    // Map blurSigma (0–8) into a 0–1ish control the shader scales to pixels.
    sink.setFloat('uBlur', (c.blurSigma / GlassRefractionConfig.maxBlurSigma));
    sink.setFloat('uReflection', c.reflectionIntensity);
    sink.setFloat('uEdgeHighlight', c.edgeHighlight);
    sink.setFloat('uChromatic', c.chromaticAberration);
    sink.setFloat('uOpacity', c.opacity);
    sink.setFloat('uShape', shape.shaderCode);
    sink.setFloat('uCornerRadius', c.cornerRadius);
    shader.setImageSampler(0, background);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant GlassShaderPainter oldDelegate) {
    return oldDelegate.shader != shader ||
        oldDelegate.background != background ||
        oldDelegate.sampleOrigin != sampleOrigin ||
        oldDelegate.sampleExtent != sampleExtent ||
        oldDelegate.config != config ||
        oldDelegate.shape != shape;
  }
}

/// Loads and caches the glass [FragmentProgram].
class GlassShaderProgram {
  GlassShaderProgram._();

  static Future<ui.FragmentProgram>? _future;

  /// Asset path used for loading.
  static const String assetPath = kGlassRefractionShaderAsset;

  /// Returns the shared program future.
  static Future<ui.FragmentProgram> load() {
    return _future ??= ui.FragmentProgram.fromAsset(assetPath);
  }

  /// Clears the Dart-side future cache. Used by tests.
  @visibleForTesting
  static void debugReset() {
    _future = null;
  }
}

/// Semi-transparent fallback when the shader cannot compile or bind.
class GlassFallbackPainter extends CustomPainter {
  /// Creates a soft frosted stand-in.
  GlassFallbackPainter({
    required this.config,
    required this.shape,
    required this.borderRadius,
  });

  final GlassRefractionConfig config;
  final GlassShape shape;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = switch (shape) {
      GlassShape.circle => RRect.fromRectAndRadius(
        rect,
        Radius.circular(size.shortestSide / 2),
      ),
      GlassShape.lens => RRect.fromRectAndRadius(
        rect,
        Radius.circular(size.shortestSide / 2),
      ),
      GlassShape.capsule => RRect.fromRectAndRadius(
        rect,
        Radius.circular(size.shortestSide / 2),
      ),
      GlassShape.roundedRectangle => borderRadius.toRRect(rect),
    };
    final fill = Paint()
      ..color = Color.fromRGBO(200, 220, 230, 0.18 + config.opacity * 0.25);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Color.fromRGBO(
        220,
        240,
        255,
        0.35 + config.edgeHighlight * 0.25,
      );
    canvas.drawRRect(rrect, fill);
    canvas.drawRRect(rrect, stroke);
  }

  @override
  bool shouldRepaint(covariant GlassFallbackPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.shape != shape ||
        oldDelegate.borderRadius != borderRadius;
  }
}
