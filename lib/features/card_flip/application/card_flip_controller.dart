import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:shader_studio/features/card_flip/domain/models/card_flip_config.dart';

/// Flip progress and programmatic commands for [FlipCard3D].
///
/// Value `0` is the front face and `1` is the back. The displayed angle is
/// the eased value times π. A request made while a flip is running reverses
/// direction for [toggle] and [flip], or continues toward the requested face
/// for [flipForward] and [flipBack].
///
/// The controller does not create a ticker until [attach] or [createAndAttach].
/// Dispose it when the owner goes away. If a widget attached the ticker,
/// call [detachAndDisposeAnimation] from that widget's dispose so the ticker
/// dies with its [TickerProvider].
class CardFlipController extends ChangeNotifier {
  /// Creates a controller resting on [initiallyFlipped].
  CardFlipController({
    bool initiallyFlipped = false,
    Duration duration = CardFlipConfig.defaultDuration,
    this._curve = Curves.easeInOutCubic,
  }) : _isFlipped = initiallyFlipped,
       _duration = CardFlipConfig.normalizeDuration(duration);

  AnimationController? _animation;
  CurvedAnimation? _curved;
  bool _ownsAnimation = false;
  bool _disposed = false;
  bool _ignoreStatus = false;
  bool _completionPending = false;
  int _runId = 0;
  bool _isFlipped;
  Duration _duration;
  Curve _curve;

  /// Fired when the settled side changes, including an instant jump.
  void Function(bool isFlipped)? onFlipChanged;

  /// Fired when a flip finishes on [isFlipped]. Not fired for [reset].
  void Function(bool isFlipped)? onCompleted;

  /// Fired when a running flip starts, so a demo timer can stand down.
  VoidCallback? onStarted;

  /// Settled side. Stays on the previous face until the flip finishes.
  bool get isFlipped => _isFlipped;

  /// True when the settled side is the front.
  bool get isFront => !_isFlipped;

  /// Settled side as an enum.
  CardSide get orientation => _isFlipped ? CardSide.back : CardSide.front;

  /// True while the ticker is moving.
  bool get isAnimating => _animation?.isAnimating ?? false;

  /// True after [dispose].
  bool get isDisposed => _disposed;

  /// True after [attach] until the ticker is detached.
  bool get isAttached => _animation != null;

  /// True when this controller created the [AnimationController].
  bool get ownsAnimation => _ownsAnimation;

  /// Duration of the next flip. Zero jumps instead of animating.
  Duration get duration => _duration;

  /// Easing applied to the linear controller value.
  Curve get curve => _curve;

  /// Linear progress, 0 front → 1 back.
  double get progress {
    final animation = _animation;
    if (animation == null) {
      return _isFlipped ? 1 : 0;
    }
    return animation.value;
  }

  /// Eased progress used for the visible rotation.
  double get curvedProgress {
    final curved = _curved;
    final raw = curved != null
        ? curved.value
        : _curve.transform(progress.clamp(0.0, 1.0));
    if (!raw.isFinite) {
      return _isFlipped ? 1 : 0;
    }
    return raw.clamp(0.0, 1.0);
  }

  /// Y-axis rotation in radians, from 0 to π.
  double get angle => curvedProgress * math.pi;

  /// Face that should be painted for the current angle.
  bool get showBack => CardFlipConfig.showsBack(angle);

  /// Face currently painted.
  CardSide get visibleSide => showBack ? CardSide.back : CardSide.front;

  /// Visible rotation in whole degrees, 0–180.
  int get rotationDegrees => (angle * 180 / math.pi).round().clamp(0, 180);

  /// Short status line for the demo, for example `Front · 42° · animating`.
  String get statusLabel {
    final side = showBack ? 'Back' : 'Front';
    final motion = isAnimating ? ' · animating' : '';
    return '$side · $rotationDegrees°$motion';
  }

  /// Updates the duration used by the next, and current, flip.
  set duration(Duration value) {
    _duration = CardFlipConfig.normalizeDuration(value);
    _animation?.duration = _duration;
    notifyListeners();
  }

  /// Updates the easing curve. Takes effect on the next frame.
  set curve(Curve value) {
    _curve = value;
    final animation = _animation;
    if (animation != null) {
      _replaceCurve(animation);
    }
    notifyListeners();
  }

  /// Binds [controller]. Replaces any ticker already attached.
  void attach(AnimationController controller, {bool ownsAnimation = false}) {
    _detachAnimation();
    _ownsAnimation = ownsAnimation;
    _animation = controller;
    controller.duration = _duration;
    _isFlipped = controller.value >= 0.5;
    _replaceCurve(controller);
    controller.addStatusListener(_onStatus);
    controller.addListener(_onTick);
  }

  /// Creates a ticker owned by this controller.
  void createAndAttach(TickerProvider vsync) {
    attach(
      AnimationController(
        vsync: vsync,
        duration: _duration,
        value: _isFlipped ? 1 : 0,
        debugLabel: 'card-flip',
      ),
      ownsAnimation: true,
    );
  }

  /// Drops the ticker without disposing this notifier.
  void detachAndDisposeAnimation() {
    _detachAnimation();
  }

  /// Flips toward the other settled face. Reverses a flip already running.
  Future<void> flip({bool instant = false}) => toggle(instant: instant);

  /// Same contract as [flip].
  Future<void> toggle({bool instant = false}) {
    final animation = _animation;
    if (animation == null || _disposed) {
      _jump(!_isFlipped, reportCompletion: true);
      return Future<void>.value();
    }
    if (instant || _duration == Duration.zero) {
      final toBack = animation.isAnimating
          ? animation.status != AnimationStatus.forward
          : !_isFlipped;
      _jump(toBack, reportCompletion: true);
      return Future<void>.value();
    }
    if (animation.isAnimating) {
      if (animation.status == AnimationStatus.forward) {
        return _run(toBack: false);
      }
      return _run(toBack: true);
    }
    return _run(toBack: !_isFlipped);
  }

  /// Animates until the back face is settled.
  ///
  /// If the card is already traveling toward the front, it turns around.
  Future<void> flipForward({bool instant = false}) {
    if (instant || _duration == Duration.zero) {
      _jump(true, reportCompletion: true);
      return Future<void>.value();
    }
    return _run(toBack: true);
  }

  /// Animates until the front face is settled.
  ///
  /// If the card is already traveling toward the back, it turns around.
  Future<void> flipBack({bool instant = false}) {
    if (instant || _duration == Duration.zero) {
      _jump(false, reportCompletion: true);
      return Future<void>.value();
    }
    return _run(toBack: false);
  }

  /// Snaps to the front without an animation or completion callback.
  void reset() => _jump(false);

  Future<void> _run({required bool toBack}) async {
    final animation = _animation;
    if (animation == null || _disposed) {
      _jump(toBack, reportCompletion: true);
      return;
    }
    final atTarget = toBack
        ? animation.value >= 1 - 1e-6
        : animation.value <= 1e-6;
    if (!animation.isAnimating && atTarget) {
      return;
    }
    final runId = ++_runId;
    _completionPending = true;
    onStarted?.call();
    try {
      if (toBack) {
        await animation.forward().orCancel;
      } else {
        await animation.reverse().orCancel;
      }
    } on TickerCanceled {
      if (runId == _runId) {
        _completionPending = false;
      }
    }
  }

  void _jump(bool toBack, {bool reportCompletion = false}) {
    _runId++;
    _completionPending = false;
    final animation = _animation;
    if (animation != null) {
      _ignoreStatus = true;
      animation.value = toBack ? 1 : 0;
      _ignoreStatus = false;
    }
    final changed = _isFlipped != toBack;
    _isFlipped = toBack;
    if (changed) {
      onFlipChanged?.call(toBack);
    }
    if (reportCompletion) {
      onCompleted?.call(toBack);
    }
    if (!_disposed) {
      notifyListeners();
    }
  }

  void _onTick() {
    if (_disposed) {
      return;
    }
    notifyListeners();
  }

  void _onStatus(AnimationStatus status) {
    if (_ignoreStatus || _disposed) {
      return;
    }
    if (status == AnimationStatus.completed) {
      _finish(true);
    } else if (status == AnimationStatus.dismissed) {
      _finish(false);
    }
  }

  void _finish(bool flipped) {
    final changed = _isFlipped != flipped;
    _isFlipped = flipped;
    final report = _completionPending;
    _completionPending = false;
    if (changed) {
      onFlipChanged?.call(flipped);
    }
    if (report) {
      onCompleted?.call(flipped);
    }
    notifyListeners();
  }

  void _replaceCurve(AnimationController controller) {
    _curved?.dispose();
    _curved = CurvedAnimation(
      parent: controller,
      curve: _curve,
      reverseCurve: _curve.flipped,
    );
  }

  void _detachAnimation() {
    final animation = _animation;
    if (animation == null) {
      return;
    }
    animation.removeListener(_onTick);
    animation.removeStatusListener(_onStatus);
    _curved?.dispose();
    _curved = null;
    if (_ownsAnimation) {
      animation.dispose();
    }
    _animation = null;
    _ownsAnimation = false;
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    onFlipChanged = null;
    onCompleted = null;
    onStarted = null;
    _detachAnimation();
    super.dispose();
  }
}
