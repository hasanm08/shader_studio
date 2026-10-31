import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shader_studio/core/rendering/shader_controller.dart';
import 'package:shader_studio/core/rendering/shader_uniforms.dart';
import 'package:shader_studio/features/glass_refraction/domain/models/glass_refraction_config.dart';
import 'package:shader_studio/features/glass_refraction/domain/models/glass_shape.dart';
import 'package:shader_studio/features/glass_refraction/presentation/widgets/glass_scene.dart';
import 'package:shader_studio/features/glass_refraction/rendering/glass_background_capture.dart';
import 'package:shader_studio/features/glass_refraction/rendering/glass_shader_renderer.dart';

/// Production glass surface that refracts a [GlassScene] background.
///
/// Place this under a [GlassScene]. The scene captures the wallpaper into a
/// texture; this widget maps its layout rectangle into that texture and runs
/// `shaders/glass_refraction.frag`.
///
/// ```dart
/// GlassRefraction(
///   width: 300,
///   height: 180,
///   config: const GlassRefractionConfig(
///     refractionStrength: 0.035,
///     curvature: 0.65,
///   ),
///   shape: GlassShape.roundedRectangle,
///   borderRadius: BorderRadius.circular(28),
///   child: YourContent(),
/// )
/// ```
///
/// **Rendering limits**
/// - Requires a [GlassScene] ancestor (or an explicit [capture] override).
/// - Refracts a *snapshot*, not a live layer. Animate the background → call
///   [GlassSceneState.scheduleCapture].
/// - Child widgets are drawn *on top* of the glass for legibility; they are
///   not themselves refracted.
/// - Prefer one shared capture for many panels. Dozens of full-screen captures
///   will hitch.
class GlassRefraction extends StatefulWidget {
  /// Creates a glass panel.
  const GlassRefraction({
    this.child,
    this.config = const GlassRefractionConfig(),
    this.shape = GlassShape.roundedRectangle,
    this.borderRadius,
    this.width,
    this.height,
    this.capture,
    this.enableInteraction = false,
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
    super.key,
  });

  /// Content composited above the glass (icons, text, controls).
  final Widget? child;

  /// Shader parameters.
  final GlassRefractionConfig config;

  /// Silhouette.
  final GlassShape shape;

  /// Corner radii for [GlassShape.roundedRectangle]. Other shapes ignore this
  /// except as a clip hint for the child.
  final BorderRadius? borderRadius;

  /// Optional fixed width.
  final double? width;

  /// Optional fixed height.
  final double? height;

  /// Optional capture override. Defaults to the nearest [GlassScene].
  final GlassBackgroundCapture? capture;

  /// When true, the panel absorbs pointer events (for ink / taps).
  final bool enableInteraction;

  /// Optional tap handler.
  final VoidCallback? onTap;

  /// Clip mode for the child overlay.
  final Clip clipBehavior;

  @override
  State<GlassRefraction> createState() => _GlassRefractionState();
}

class _GlassRefractionState extends State<GlassRefraction>
    with SingleTickerProviderStateMixin {
  final GlobalKey _glassKey = GlobalKey(debugLabel: 'GlassRefraction');
  final Signal _paintTick = Signal();
  ui.FragmentShader? _shader;
  FragmentShaderSink? _sink;
  Object? _error;
  Ticker? _ticker;
  double _timeSeconds = 0;
  var _loadGeneration = 0;
  var _layoutScheduled = false;
  GlassBackgroundCapture? _boundCapture;

  BorderRadius get _radius {
    return widget.borderRadius ?? widget.shape.defaultBorderRadius;
  }

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bindCapture();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant GlassRefraction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.animateHighlights != widget.config.animateHighlights) {
      _syncTicker();
    }
    if (oldWidget.capture != widget.capture) {
      _bindCapture();
    }
    if (oldWidget.config != widget.config || oldWidget.shape != widget.shape) {
      _paintTick.ping();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _boundCapture?.removeListener(_onCapture);
    _paintTick.dispose();
    _shader?.dispose();
    super.dispose();
  }

  void _bindCapture() {
    final next =
        widget.capture ?? GlassScene.maybeOf(context)?.backgroundCapture;
    if (identical(next, _boundCapture)) {
      return;
    }
    _boundCapture?.removeListener(_onCapture);
    _boundCapture = next;
    _boundCapture?.addListener(_onCapture);
  }

  void _onCapture() {
    if (mounted) {
      setState(() {});
    }
  }

  void _syncTicker() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final want =
        widget.config.animateHighlights &&
        !reduceMotion &&
        TickerMode.valuesOf(context).enabled;
    if (want) {
      _ticker ??= createTicker((elapsed) {
        _timeSeconds = elapsed.inMicroseconds / 1e6;
        _paintTick.ping();
      });
      if (!(_ticker?.isActive ?? false)) {
        _ticker?.start();
      }
    } else {
      _ticker?.stop();
    }
  }

  Future<void> _loadShader() async {
    final generation = ++_loadGeneration;
    try {
      final program = await GlassShaderProgram.load();
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      final shader = program.fragmentShader();
      setState(() {
        _shader?.dispose();
        _shader = shader;
        _sink = FragmentShaderSink(shader);
        _error = null;
      });
    } catch (error) {
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() => _error = error);
    }
  }

  Rect? _glassRectInCapture(GlassBackgroundCapture capture) {
    final glassBox = _glassKey.currentContext?.findRenderObject() as RenderBox?;
    final captureBox =
        capture.boundaryKey.currentContext?.findRenderObject() as RenderBox?;
    if (glassBox == null ||
        captureBox == null ||
        !glassBox.hasSize ||
        !captureBox.hasSize) {
      return null;
    }
    // Glass sits as a Stack sibling of the capture boundary, not a descendant,
    // so map both boxes through global coordinates.
    final glassOrigin = glassBox.localToGlobal(Offset.zero);
    final captureOrigin = captureBox.localToGlobal(Offset.zero);
    final topLeft = glassOrigin - captureOrigin;
    return topLeft & glassBox.size;
  }

  void _scheduleLayoutPass() {
    if (_layoutScheduled) {
      return;
    }
    _layoutScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _layoutScheduled = false;
      if (!mounted) {
        return;
      }
      _boundCapture?.scheduleCapture();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final capture = _boundCapture;
    final shader = _shader;
    final sink = _sink;
    final config = widget.config.clamp();

    Widget glassBody;
    if (_error != null || shader == null || sink == null || capture == null) {
      glassBody = CustomPaint(
        painter: GlassFallbackPainter(
          config: config,
          shape: widget.shape,
          borderRadius: _radius,
        ),
        child: const SizedBox.expand(),
      );
    } else {
      final image = capture.image;
      final glassRect = _glassRectInCapture(capture);
      if (image == null || glassRect == null) {
        glassBody = CustomPaint(
          painter: GlassFallbackPainter(
            config: config,
            shape: widget.shape,
            borderRadius: _radius,
          ),
          child: const SizedBox.expand(),
        );
        _scheduleLayoutPass();
      } else {
        final sample = capture.sampleRectFor(glassRect);
        glassBody = CustomPaint(
          painter: GlassShaderPainter(
            shader: shader,
            sink: sink,
            background: image,
            sampleOrigin: sample.origin,
            sampleExtent: sample.extent,
            config: config,
            shape: widget.shape,
            timeSeconds: () => _timeSeconds,
            repaint: _paintTick,
          ),
          child: const SizedBox.expand(),
        );
      }
    }

    final clippedChild = widget.child == null
        ? null
        : ClipRRect(
            borderRadius: _radius,
            clipBehavior: widget.clipBehavior,
            child: widget.child,
          );

    Widget panel = Stack(
      key: _glassKey,
      fit: StackFit.expand,
      children: [
        RepaintBoundary(child: glassBody),
        ?clippedChild,
      ],
    );

    if (widget.enableInteraction || widget.onTap != null) {
      panel = Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: _radius,
          child: panel,
        ),
      );
    }

    return SizedBox(width: widget.width, height: widget.height, child: panel);
  }
}
