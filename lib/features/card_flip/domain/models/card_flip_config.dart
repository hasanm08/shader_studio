import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Which side of a flip card is settled or currently visible.
enum CardSide {
  /// The starting face.
  front,

  /// The reverse face.
  back,
}

/// Curves offered by the demo. Each maps to a Flutter [Curve] that stays
/// inside `0…1`, so the flip does not overshoot past the face.
enum CardFlipCurve {
  /// Slow start and end. Default.
  easeInOutCubic('easeInOutCubic', Curves.easeInOutCubic),

  /// Symmetric ease.
  easeInOut('easeInOut', Curves.easeInOut),

  /// Fast departure, gentle arrival.
  fastOutSlowIn('fastOutSlowIn', Curves.fastOutSlowIn);

  const CardFlipCurve(this.label, this.curve);

  /// Short name shown on the demo chips.
  final String label;

  /// Curve applied to the flip.
  final Curve curve;
}

/// Defaults and bounds for a 3D card flip.
///
/// Perspective is clamped. Very large values push the card through the
/// camera plane (`1 / perspective`) and the projection stops being finite
/// in a useful way.
@immutable
class CardFlipConfig {
  /// Creates a set of flip settings.
  const CardFlipConfig({
    this.duration = defaultDuration,
    this.curve = CardFlipCurve.easeInOutCubic,
    this.perspective = defaultPerspective,
    this.initiallyFlipped = false,
    this.enableTap = true,
    this.autoFlip = false,
    this.tiltEnabled = false,
    this.elevation = defaultElevation,
  });

  /// 800 ms. Long enough to read the edge-on moment.
  static const Duration defaultDuration = Duration(milliseconds: 800);

  /// Pause after each automatic flip, added to [duration].
  static const Duration autoFlipPause = Duration(milliseconds: 700);

  /// Mild perspective. Entry `(3, 2)` of the transform matrix.
  static const double defaultPerspective = 0.0015;

  /// Lowest perspective the slider and clamp will produce.
  static const double minPerspective = 0.0004;

  /// Highest perspective before a typical card width becomes unstable.
  static const double maxPerspective = 0.0028;

  /// Extra pointer tilt, in radians, about 8.6 degrees.
  static const double maxTilt = 0.15;

  /// Drop shadow strength used when the caller does not override it.
  static const double defaultElevation = 16;

  /// Corner radius shared by the shell and the demo faces.
  static const double defaultRadius = 28;

  /// How long one direction takes.
  final Duration duration;

  /// Demo curve selection. The widget itself accepts any [Curve].
  final CardFlipCurve curve;

  /// Perspective strength before clamping.
  final double perspective;

  /// When true, the back face is showing at rest.
  final bool initiallyFlipped;

  /// When false, taps and keys do not flip the card.
  final bool enableTap;

  /// Periodic demo flips. Off unless a caller opts in.
  final bool autoFlip;

  /// Pointer tilt. Ignored on touch-first platforms.
  final bool tiltEnabled;

  /// Shadow blur scale. Zero removes the shadow.
  final double elevation;

  /// Clamps [value] into the stable perspective range.
  ///
  /// Non-finite input returns [defaultPerspective]. [width] tightens the
  /// upper bound so a wide card cannot cross the camera plane.
  static double clampPerspective(double value, {double width = 300}) {
    if (!value.isFinite) {
      return defaultPerspective;
    }
    final safeMax = width.isFinite && width > 0
        ? math.min(maxPerspective, 0.85 / width)
        : maxPerspective;
    final upper = math.max(minPerspective, safeMax);
    return value.clamp(minPerspective, upper).toDouble();
  }

  /// Clamps pointer tilt so the card does not fold away from the pointer.
  static double clampTilt(double radians) {
    if (!radians.isFinite) {
      return 0;
    }
    return radians.clamp(-maxTilt, maxTilt).toDouble();
  }

  /// True once [angle] has passed the edge-on point (π/2).
  ///
  /// The card has no visible width at exactly π/2, so the front keeps that
  /// frame. Every larger angle shows the back.
  static bool showsBack(double angle) {
    if (!angle.isFinite) {
      return false;
    }
    return angle > math.pi / 2;
  }

  /// Hover tilt is a pointer feature. Touch platforms ignore it.
  static bool tiltSupportedOn(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia => false,
      TargetPlatform.macOS ||
      TargetPlatform.linux ||
      TargetPlatform.windows => true,
    };
  }

  /// Replaces negative durations with zero. Zero means an instant flip.
  static Duration normalizeDuration(Duration value) {
    if (value.isNegative) {
      return Duration.zero;
    }
    return value;
  }
}
