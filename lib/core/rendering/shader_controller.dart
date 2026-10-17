import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A notifier that does not carry a value.
///
/// Time ticks ping [ShaderController.paintTick] only. Slider edits ping
/// [ShaderController.controlsTick]. The playground listens to the second one,
/// so a running clock does not rebuild the sliders on every frame.
class Signal extends ChangeNotifier {
  /// Notifies current listeners.
  void ping() {
    notifyListeners();
  }
}

/// One stored ripple origin.
///
/// [startTime] is on the same wrapped clock as `uTime`. A negative start
/// means the slot is empty; the shader also treats a future start as expired
/// after the clock wraps.
class RippleEvent {
  /// Creates a ripple that began at [startTime].
  const RippleEvent(this.origin, this.startTime);

  /// Normalized preview position, origin at the top-left, Y down.
  final Offset origin;

  /// Clock time, in seconds, when the ripple was emitted.
  final double startTime;
}

/// Four ripple slots, overwritten in a ring.
///
/// The shader has four `uRippleN` uniforms and no history beyond that.
/// Spacing is measured in aspect-corrected normalized units so a wide
/// preview does not emit a tighter trail horizontally than vertically.
class RippleBuffer {
  /// Number of slots. Matches `uRipple0` through `uRipple3`.
  static const int capacity = 4;

  /// Minimum travel, in aspect-corrected UV units, before another emit.
  static const double emitSpacing = 0.04;

  /// Slot storage. A null entry is written as start time -1.
  final List<RippleEvent?> slots = List<RippleEvent?>.filled(capacity, null);

  /// Next slot to overwrite.
  int cursor = 0;

  Offset? _lastOrigin;

  /// Emits when [origin] has moved at least [emitSpacing] from the last emit.
  ///
  /// Returns true when a new slot was written. [size] is the preview size in
  /// logical pixels and is only used for the aspect ratio. A zero height
  /// skips the aspect correction instead of dividing by zero.
  bool consider(Offset origin, double time, Size size) {
    final last = _lastOrigin;
    if (last != null && _distance(origin, last, size) < emitSpacing) {
      return false;
    }
    emit(origin, time);
    return true;
  }

  /// Writes [origin] into the oldest slot.
  void emit(Offset origin, double time) {
    slots[cursor] = RippleEvent(origin, time);
    cursor = (cursor + 1) % capacity;
    _lastOrigin = origin;
  }

  /// Drops every slot.
  void clear() {
    for (var i = 0; i < capacity; i++) {
      slots[i] = null;
    }
    cursor = 0;
    _lastOrigin = null;
  }

  /// Places two ripples so a paused thumbnail is not an empty surface.
  ///
  /// A still at time zero with no slots would show only the background. The
  /// gallery documents this as an authored still, not a live trail.
  void seedPreview(double time) {
    clear();
    slots[0] = RippleEvent(const Offset(0.38, 0.46), time - 0.85);
    slots[1] = RippleEvent(const Offset(0.62, 0.58), time - 0.35);
    cursor = 2;
    _lastOrigin = const Offset(0.62, 0.58);
  }

  static double _distance(Offset a, Offset b, Size size) {
    final aspect = size.height <= 0 ? 1.0 : size.width / size.height;
    final dx = (a.dx - b.dx) * aspect;
    final dy = a.dy - b.dy;
    return math.sqrt(dx * dx + dy * dy);
  }
}

/// Mean frame interval measured from ticker deltas.
///
/// This is not a GPU timestamp and it is not a promise about frame rate.
/// [add] records up to 30 deltas and refreshes [label] about twice a second.
/// The label is what the debug overlay prints.
class FrameTimeEstimate {
  final List<double> _samplesMs = <double>[];
  double _sinceRefresh = 0;

  /// Text for the debug overlay, including the unit and the method.
  String label = 'Ticker —';

  /// Records a frame that lasted [seconds]. Returns true when [label] changed.
  bool add(double seconds) {
    _samplesMs.add(seconds * 1000);
    if (_samplesMs.length > 30) {
      _samplesMs.removeAt(0);
    }
    _sinceRefresh += seconds;
    if (_sinceRefresh < 0.5 || _samplesMs.isEmpty) {
      return false;
    }
    _sinceRefresh = 0;
    var sum = 0.0;
    for (final sample in _samplesMs) {
      sum += sample;
    }
    final meanMs = sum / _samplesMs.length;
    if (meanMs <= 0) {
      return false;
    }
    label = 'Ticker ~${(1000 / meanMs).toStringAsFixed(0)} fps';
    return true;
  }

  /// Clears the window. Used by reset.
  void reset() {
    _samplesMs.clear();
    _sinceRefresh = 0;
    label = 'Ticker —';
  }
}

/// Clock, pointer, and ripple state shared by every sample.
///
/// Elapsed time is seconds accumulated from ticker deltas, then wrapped with
/// modulo [timeWrapSeconds]. Wrapping keeps `uTime` inside the range where
/// float32 still has a useful fraction of a millisecond. The wrap is visible:
/// domain warp and the aurora jump, and ripple slots whose start time is now
/// in the future expire. Pause stops accumulation but does not reset the
/// phase. The first delta after a ticker restart is ignored by the canvas,
/// because a stopped ticker reports a new elapsed origin.
class ShaderController {
  /// Creates a clock that starts [playing] or paused.
  ///
  /// The flag is stored in the constructor body so a subclass in another
  /// library can pass `playing:` without exposing a private initializing formal.
  ShaderController({bool playing = true}) {
    _playing = playing;
  }

  /// Wrap period passed to every shader as `uTime`.
  static const double timeWrapSeconds = 600;

  /// Fires on time and pointer changes. The painter listens to this.
  final Signal paintTick = Signal();

  /// Fires when a control, playback flag, or reset changes.
  final Signal controlsTick = Signal();

  /// Fires when the pointer moves. Separate from the clock.
  final Signal pointerTick = Signal();

  /// Fires when the debug frame-time label changes.
  final Signal frameTick = Signal();

  /// Ripple ring. Only the ripple sample reads it.
  final RippleBuffer ripples = RippleBuffer();

  /// Ticker-delta estimate. Debug overlay only.
  final FrameTimeEstimate frameTime = FrameTimeEstimate();

  /// Wrapped animation time in seconds.
  double timeSeconds = 0;

  /// Normalized pointer. `(0, 0)` is the top-left of the preview, Y down.
  Offset pointer = const Offset(0.5, 0.5);

  /// True while the pointer is inside the preview.
  bool pointerActive = false;

  /// When false, writers send `uPointerActive` as 0 and ripples do not emit.
  ///
  /// UI code should call [setInteractionEnabled] so the sample controller can
  /// notify listeners. Assigning the field directly skips that notification.
  bool interactionEnabled = true;

  bool _playing = false;

  /// Updates [interactionEnabled].
  ///
  /// The sample controller overrides this to repaint and rebuild controls.
  void setInteractionEnabled(bool value) {
    interactionEnabled = value;
  }

  /// Whether deltas advance [timeSeconds].
  bool get playing => _playing;

  set playing(bool value) {
    if (_playing == value) {
      return;
    }
    _playing = value;
    controlsTick.ping();
  }

  /// True when the shader should treat the pointer as inside the preview.
  bool get shaderPointerActive => pointerActive && interactionEnabled;

  /// Advances the clock by [delta] while playing.
  ///
  /// Non-positive and non-finite deltas are ignored. A paused controller
  /// does not notify.
  void addDelta(Duration delta) {
    if (!_playing || delta <= Duration.zero) {
      return;
    }
    final seconds = delta.inMicroseconds / 1000000.0;
    if (!seconds.isFinite || seconds <= 0) {
      return;
    }
    timeSeconds += seconds;
    if (timeSeconds >= timeWrapSeconds) {
      timeSeconds %= timeWrapSeconds;
    }
    if (frameTime.add(seconds)) {
      frameTick.ping();
    }
    paintTick.ping();
  }

  /// Stores a pointer in normalized preview space.
  ///
  /// [local] is clamped to 0..1. [size] is used only when this controller
  /// emits ripples. [forceEmit] writes a ripple even if the pointer barely
  /// moved, which is how a tap starts a wave.
  void setPointer(
    Offset local, {
    required bool active,
    required Size size,
    bool emitRipples = false,
    bool forceEmit = false,
  }) {
    final dx = local.dx.isFinite ? local.dx.clamp(0.0, 1.0).toDouble() : 0.5;
    final dy = local.dy.isFinite ? local.dy.clamp(0.0, 1.0).toDouble() : 0.5;
    final next = Offset(dx, dy);
    final moved = next != pointer || active != pointerActive;
    pointer = next;
    pointerActive = active;
    var emitted = false;
    if (emitRipples && active && interactionEnabled) {
      if (forceEmit) {
        ripples.emit(pointer, timeSeconds);
        emitted = true;
      } else {
        emitted = ripples.consider(pointer, timeSeconds, size);
      }
    }
    if (moved || emitted) {
      paintTick.ping();
      pointerTick.ping();
    }
  }

  /// Sets the clock back to zero without touching parameters.
  void resetClock() {
    timeSeconds = 0;
    frameTime.reset();
    frameTick.ping();
  }

  /// Releases the signals. The owner calls this after removing listeners.
  @mustCallSuper
  void dispose() {
    paintTick.dispose();
    controlsTick.dispose();
    pointerTick.dispose();
    frameTick.dispose();
  }
}
