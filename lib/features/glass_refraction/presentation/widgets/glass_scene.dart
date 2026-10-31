import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shader_studio/features/glass_refraction/rendering/glass_background_capture.dart';

/// Provides a captured background texture to descendant [GlassRefraction]s.
///
/// Place colorful content in [background]. Overlay interactive glass panels
/// in [child] (typically a [Stack]). The background is wrapped in a
/// [RepaintBoundary] and rasterized into a texture the glass shader samples.
///
/// ```dart
/// GlassScene(
///   background: MyWallpaper(),
///   child: Center(
///     child: GlassRefraction(
///       width: 280,
///       height: 160,
///       child: Text('Hello'),
///     ),
///   ),
/// )
/// ```
///
/// Call [GlassSceneState.scheduleCapture] (via a [GlobalKey]) when the
/// background animates. Glass drag/resize only updates UV uniforms.
class GlassScene extends StatefulWidget {
  /// Creates a scene that owns background capture.
  const GlassScene({
    required this.background,
    required this.child,
    this.pixelRatio = 1.25,
    this.autoCapture = true,
    this.captureInterval = const Duration(milliseconds: 48),
    super.key,
  });

  /// Content rasterized into the refraction texture.
  final Widget background;

  /// Overlay tree. Glass widgets look up this scene's capture.
  final Widget child;

  /// Capture scale. 1.0 is cheapest; device pixel ratio is sharper.
  final double pixelRatio;

  /// When true, captures after the first frame and when the size changes.
  final bool autoCapture;

  /// Throttle for automatic captures while [autoCapture] is true.
  final Duration captureInterval;

  /// Nearest scene state, or null when missing.
  static GlassSceneState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<GlassSceneState>();
  }

  /// Nearest scene state. Throws if no [GlassScene] ancestor exists.
  static GlassSceneState of(BuildContext context) {
    final state = maybeOf(context);
    assert(state != null, 'GlassRefraction requires a GlassScene ancestor');
    return state!;
  }

  @override
  State<GlassScene> createState() => GlassSceneState();
}

/// State that owns [GlassBackgroundCapture] for a [GlassScene].
class GlassSceneState extends State<GlassScene>
    with SingleTickerProviderStateMixin {
  late GlassBackgroundCapture capture;
  Ticker? _ticker;
  Size? _lastSize;

  /// Shared capture controller.
  GlassBackgroundCapture get backgroundCapture => capture;

  @override
  void initState() {
    super.initState();
    capture = GlassBackgroundCapture(
      pixelRatio: widget.pixelRatio,
      minInterval: widget.captureInterval,
    );
    if (widget.autoCapture) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          capture.scheduleCapture(force: true);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant GlassScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pixelRatio != widget.pixelRatio ||
        oldWidget.captureInterval != widget.captureInterval) {
      final previous = capture;
      capture = GlassBackgroundCapture(
        pixelRatio: widget.pixelRatio,
        minInterval: widget.captureInterval,
      );
      previous.dispose();
      capture.scheduleCapture(force: true);
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    capture.dispose();
    super.dispose();
  }

  /// Requests a new background snapshot.
  void scheduleCapture({bool force = false}) {
    capture.scheduleCapture(force: force);
  }

  /// Starts periodic captures while [enabled] is true.
  ///
  /// Used by the demo when the wallpaper animates. Stops automatically on
  /// dispose.
  void setContinuousCapture(bool enabled) {
    if (enabled) {
      _ticker ??= createTicker((_) {
        capture.scheduleCapture();
      });
      if (!(_ticker?.isActive ?? false)) {
        _ticker?.start();
      }
    } else {
      _ticker?.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      // fit: StackFit.expand,
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RepaintBoundary(
          key: capture.boundaryKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              if (_lastSize != size) {
                _lastSize = size;
                if (widget.autoCapture) {
                  capture.scheduleCapture(force: true);
                }
              }
              return SizedBox.expand(child: widget.background);
            },
          ),
        ),
        widget.child,
      ],
    );
  }
}
