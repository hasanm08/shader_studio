import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Captures a [RepaintBoundary] into a reusable [ui.Image] for glass sampling.
///
/// Flutter fragment shaders cannot read live widget layers. This helper
/// rasterizes the background once (or on a throttle) and notifies listeners
/// when a new frame is ready. Glass panels map their layout rect into UV
/// space over this image; dragging a panel does **not** require a new
/// capture — only background content changes do.
///
/// Limitations
/// - Capture cost scales with pixel area × device pixel ratio. Prefer a
///   dedicated backdrop region, not the entire app route.
/// - The image is a snapshot. Animating backgrounds need periodic
///   [scheduleCapture] calls.
/// - Nested glass panels do not appear inside each other's refraction
///   unless they are part of the captured subtree (usually they are not).
class GlassBackgroundCapture extends ChangeNotifier {
  /// Creates a capture controller.
  ///
  /// [pixelRatio] defaults to 1 so captures stay cheap; the demo may raise
  /// it toward the device pixel ratio for sharper refraction.
  GlassBackgroundCapture({
    this.pixelRatio = 1,
    this.minInterval = const Duration(milliseconds: 32),
  });

  /// Raster scale passed to [RenderRepaintBoundary.toImage].
  final double pixelRatio;

  /// Minimum time between automatic captures.
  final Duration minInterval;

  final GlobalKey boundaryKey = GlobalKey(debugLabel: 'GlassBackgroundCapture');

  ui.Image? _image;
  Size _logicalSize = Size.zero;
  bool _captureQueued = false;
  bool _capturing = false;
  bool _disposed = false;
  DateTime? _lastCaptureAt;

  /// Latest background texture. Null until the first successful capture.
  ui.Image? get image => _image;

  /// Logical size of the captured boundary.
  Size get logicalSize => _logicalSize;

  /// True after at least one image has been produced.
  bool get hasImage => _image != null;

  bool _withinThrottle() {
    final last = _lastCaptureAt;
    if (last == null) {
      return false;
    }
    return DateTime.now().difference(last) < minInterval;
  }

  /// Queues a capture for the end of this frame.
  ///
  /// Safe to call from layout, paint, and gesture callbacks. Duplicate
  /// requests in the same frame collapse into one.
  void scheduleCapture({bool force = false}) {
    if (_disposed) {
      return;
    }
    if (!force && _captureQueued) {
      return;
    }
    if (!force && _image != null && _withinThrottle()) {
      return;
    }
    _captureQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureQueued = false;
      if (!_disposed) {
        captureNow(force: force);
      }
    });
  }

  /// Synchronously attempts a capture. Prefer [scheduleCapture] from build.
  Future<void> captureNow({bool force = false}) async {
    if (_disposed || _capturing) {
      return;
    }
    final boundary =
        boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null || !boundary.hasSize) {
      return;
    }
    final size = boundary.size;
    if (size.isEmpty) {
      return;
    }
    if (!force &&
        _image != null &&
        _withinThrottle() &&
        size == _logicalSize) {
      return;
    }

    _capturing = true;
    try {
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      if (_disposed) {
        image.dispose();
        return;
      }
      final previous = _image;
      _image = image;
      _logicalSize = size;
      _lastCaptureAt = DateTime.now();
      previous?.dispose();
      notifyListeners();
    } catch (_) {
      // Capture can fail during teardown or when the boundary is not
      // composited yet. Keep the previous image if any.
    } finally {
      _capturing = false;
    }
  }

  /// Maps a glass [Rect] in the same coordinate space as the boundary into
  /// normalized background UV origin + extent.
  ///
  /// [glassRect] and the boundary share the local origin of the capture
  /// target (typically both are children of the same stack parent).
  ({Offset origin, Size extent}) sampleRectFor(Rect glassRect) {
    final size = _logicalSize;
    if (size.width <= 0 || size.height <= 0) {
      return (origin: Offset.zero, extent: Size.zero);
    }
    final origin = Offset(
      (glassRect.left / size.width).clamp(0.0, 1.0),
      (glassRect.top / size.height).clamp(0.0, 1.0),
    );
    final extent = Size(
      (glassRect.width / size.width).clamp(0.0, 1.0 - origin.dx),
      (glassRect.height / size.height).clamp(0.0, 1.0 - origin.dy),
    );
    return (origin: origin, extent: extent);
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _image?.dispose();
    _image = null;
    super.dispose();
  }
}
