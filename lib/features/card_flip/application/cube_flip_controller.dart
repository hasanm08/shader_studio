import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

/// Quarter-turn rotation for a four-face cube.
///
/// [spin] increases as the cube turns toward the next face. A turn already
/// in flight is retargeted from the current angle, so repeated calls do not
/// stack or jump.
class CubeFlipController extends ChangeNotifier {
  /// Creates a controller resting on face 0.
  CubeFlipController({
    Duration duration = const Duration(milliseconds: 700),
    this._curve = Curves.easeInOutCubic,
  }) : _duration = duration.isNegative ? Duration.zero : duration;

  Duration _duration;

  /// How long one quarter turn takes.
  Duration get duration => _duration;

  set duration(Duration value) {
    _duration = value.isNegative ? Duration.zero : value;
    _animation?.duration = _duration;
  }

  Curve _curve;
  AnimationController? _animation;
  CurvedAnimation? _curved;
  bool _ownsAnimation = false;
  bool _disposed = false;
  bool _ignore = false;
  int _runId = 0;

  /// Face units at the start of the current turn.
  double _origin = 0;

  /// +1 for the next face, -1 for the previous, 0 when idle.
  double _delta = 0;

  /// Fired with the settled face index in `0…3`.
  ValueChanged<int>? onFaceChanged;

  /// Easing used for the quarter turn.
  Curve get curve => _curve;

  set curve(Curve value) {
    _curve = value;
    final animation = _animation;
    if (animation != null) {
      _curved?.dispose();
      _curved = CurvedAnimation(parent: animation, curve: _curve);
    }
    notifyListeners();
  }

  /// True after [dispose].
  bool get isDisposed => _disposed;

  /// True while a quarter turn is running.
  bool get isAnimating => _animation?.isAnimating ?? false;

  /// True after [attach].
  bool get isAttached => _animation != null;

  /// Linear progress of the current quarter turn.
  double get progress => _animation?.value ?? 0;

  /// Eased progress of the current quarter turn.
  double get curvedProgress {
    final curved = _curved;
    final raw = curved?.value ?? progress;
    if (!raw.isFinite) {
      return 0;
    }
    return raw.clamp(0.0, 1.0);
  }

  /// Continuous Y rotation in radians.
  double get spin => (_origin + curvedProgress * _delta) * math.pi / 2;

  /// Face most square to the camera, in `0…3`.
  int get face {
    final turns = _origin + curvedProgress * _delta;
    final index = turns.round() % 4;
    return index < 0 ? index + 4 : index;
  }

  /// Binds [controller] and disposes a previous owned ticker.
  void attach(AnimationController controller, {bool ownsAnimation = false}) {
    _detach();
    _ownsAnimation = ownsAnimation;
    _animation = controller;
    controller.duration = duration;
    _curved = CurvedAnimation(parent: controller, curve: _curve);
    controller.addStatusListener(_onStatus);
    controller.addListener(_onTick);
  }

  /// Creates the ticker owned by this controller.
  void createAndAttach(TickerProvider vsync) {
    attach(
      AnimationController(
        vsync: vsync,
        duration: duration,
        debugLabel: 'cube-flip',
      ),
      ownsAnimation: true,
    );
  }

  /// Turns one face so the next panel comes forward.
  Future<void> next({bool instant = false}) => _turn(1, instant: instant);

  /// Turns one face back.
  Future<void> previous({bool instant = false}) => _turn(-1, instant: instant);

  /// Snaps to face 0.
  void reset() {
    _runId++;
    _origin = 0;
    _delta = 0;
    _ignore = true;
    _animation?.value = 0;
    _ignore = false;
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> _turn(int direction, {required bool instant}) async {
    if (_disposed) {
      return;
    }
    final current = _origin + curvedProgress * _delta;
    _origin = current;
    _delta = direction.toDouble();
    if (instant || duration == Duration.zero || _animation == null) {
      _origin += _delta;
      _delta = 0;
      _ignore = true;
      _animation?.value = 0;
      _ignore = false;
      onFaceChanged?.call(face);
      if (!_disposed) {
        notifyListeners();
      }
      return;
    }
    final runId = ++_runId;
    _ignore = true;
    _animation!.value = 0;
    _ignore = false;
    try {
      await _animation!.forward().orCancel;
    } on TickerCanceled {
      if (runId == _runId) {
        return;
      }
    }
  }

  void _onTick() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (_ignore || _disposed || status != AnimationStatus.completed) {
      return;
    }
    _origin += _delta;
    _delta = 0;
    _ignore = true;
    _animation?.value = 0;
    _ignore = false;
    onFaceChanged?.call(face);
    notifyListeners();
  }

  void _detach() {
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
    onFaceChanged = null;
    _detach();
    super.dispose();
  }
}
