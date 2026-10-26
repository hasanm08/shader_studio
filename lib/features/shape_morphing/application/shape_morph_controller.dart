import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:shader_studio/core/geometry/path_interpolator.dart';
import 'package:shader_studio/core/geometry/shape_geometry.dart';
import 'package:shader_studio/core/geometry/shape_type.dart';
import 'package:shader_studio/features/shape_morphing/domain/services/shape_morph_engine.dart';

/// Drives morph transitions between [ShapeType]s.
///
/// Attach via [MorphingShape] (which supplies a ticker) or call [attach]
/// with an [AnimationController] you own. Dispose the attached controller
/// yourself unless [ownsAnimation] is true.
class ShapeMorphController extends ChangeNotifier {
  /// Creates a controller starting at [initialShape].
  ShapeMorphController({
    ShapeType initialShape = ShapeType.circle,
    ShapeType? targetShape,
    this._duration = const Duration(milliseconds: 800),
    this._curve = Curves.easeInOutCubic,
    ShapeMorphEngine? engine,
  }) : _displayedShape = initialShape,
       _fromShape = initialShape,
       _toShape = targetShape ?? initialShape,
       _engine = engine ?? ShapeMorphEngine();

  final ShapeMorphEngine _engine;

  AnimationController? _animation;
  CurvedAnimation? _curved;
  bool _ownsAnimation = false;
  bool _disposed = false;
  bool _ignoreStatus = false;

  ShapeType _displayedShape;
  ShapeType _fromShape;
  ShapeType _toShape;
  Duration _duration;
  Curve _curve;

  /// Live contour captured when interrupting a morph mid-flight.
  ShapeContour? _overrideFrom;

  /// Optional lifecycle callbacks.
  VoidCallback? onCompleted;
  VoidCallback? onStarted;
  VoidCallback? onReversed;

  /// Shape currently shown when idle (destination of the last finished morph).
  ShapeType get displayedShape => _displayedShape;

  /// Source of the active (or last) transition.
  ShapeType get fromShape => _fromShape;

  /// Destination of the active (or last) transition.
  ShapeType get toShape => _toShape;

  /// Animation duration for upcoming transitions.
  Duration get duration => _duration;

  /// Easing curve applied to the controller value.
  Curve get curve => _curve;

  /// True while an animation is running.
  bool get isAnimating => _animation?.isAnimating ?? false;

  /// True after [dispose] has been called.
  bool get isDisposed => _disposed;

  /// Raw controller progress in `[0, 1]` before easing.
  double get progress {
    final animation = _animation;
    if (animation == null) {
      return _fromShape == _toShape ? 1.0 : 0.0;
    }
    return animation.value;
  }

  /// Eased progress used for geometry interpolation.
  double get curvedProgress {
    final curved = _curved;
    if (curved != null) {
      return curved.value;
    }
    return _curve.transform(progress.clamp(0.0, 1.0));
  }

  /// Contour for the current animation frame.
  ShapeContour get currentContour {
    final t = curvedProgress;
    final override = _overrideFrom;
    if (override != null) {
      return PathInterpolator.lerp(override, _engine.contourFor(_toShape), t);
    }
    return _engine.morph(_fromShape, _toShape, t);
  }

  /// Geometry engine used by this controller.
  ShapeMorphEngine get engine => _engine;

  /// Whether this controller created and owns the animation ticker.
  bool get ownsAnimation => _ownsAnimation;

  /// True after [attach] / [createAndAttach] and before detach/dispose.
  bool get isAttached => _animation != null;

  /// Binds an [AnimationController]. Replaces any previous attachment.
  void attach(AnimationController controller, {bool ownsAnimation = false}) {
    _detachAnimation();
    _ownsAnimation = ownsAnimation;
    _animation = controller;
    controller.duration = _duration;
    _curved = CurvedAnimation(parent: controller, curve: _curve);
    controller.addStatusListener(_onStatus);
    controller.addListener(_onTick);
  }

  /// Creates and attaches a controller using [vsync].
  void createAndAttach(TickerProvider vsync) {
    attach(
      AnimationController(vsync: vsync, duration: _duration),
      ownsAnimation: true,
    );
  }

  /// Detaches and disposes the animation ticker without disposing this
  /// [ChangeNotifier]. Used when a widget supplied the vsync for an
  /// otherwise externally owned controller.
  void detachAndDisposeAnimation() {
    _detachAnimation();
  }

  void _onTick() => notifyListeners();

  void _onStatus(AnimationStatus status) {
    if (_ignoreStatus) {
      return;
    }
    if (status == AnimationStatus.completed) {
      _displayedShape = _toShape;
      _fromShape = _toShape;
      _overrideFrom = null;
      onCompleted?.call();
      notifyListeners();
    } else if (status == AnimationStatus.dismissed) {
      _displayedShape = _fromShape;
      _toShape = _fromShape;
      _overrideFrom = null;
      onReversed?.call();
      notifyListeners();
    }
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

  /// Updates duration for future (and in-flight, if attached) animations.
  set duration(Duration value) {
    _duration = value;
    _animation?.duration = value;
    notifyListeners();
  }

  /// Updates the easing curve. Recreates the curved animation if attached.
  set curve(Curve value) {
    _curve = value;
    final animation = _animation;
    if (animation != null) {
      _curved?.dispose();
      _curved = CurvedAnimation(parent: animation, curve: _curve);
    }
    notifyListeners();
  }

  /// Morphs toward [shape], interrupting any in-flight animation smoothly.
  Future<void> morphTo(ShapeType shape) async {
    final animation = _animation;
    if (animation == null || _disposed) {
      _displayedShape = shape;
      _fromShape = shape;
      _toShape = shape;
      notifyListeners();
      return;
    }

    // Already settled on [shape] — nothing to do.
    if (shape == _displayedShape &&
        !animation.isAnimating &&
        _overrideFrom == null &&
        _fromShape == _toShape) {
      return;
    }

    final midFlight =
        animation.isAnimating ||
        (progress > 1e-6 && progress < 1.0 - 1e-6 && _fromShape != _toShape);

    if (midFlight) {
      _overrideFrom = currentContour;
      _fromShape = _displayedShape;
    } else {
      _overrideFrom = null;
      _fromShape = _displayedShape;
    }

    _toShape = shape;
    // Resetting value from 1 → 0 reports [AnimationStatus.dismissed]; ignore
    // that so the new destination is not clobbered.
    _ignoreStatus = true;
    animation.value = 0;
    _ignoreStatus = false;
    onStarted?.call();
    notifyListeners();
    await animation.forward();
  }

  /// Plays a full morph from [from] to [to].
  ///
  /// If the shape is not currently at [from], snaps there first so Play always
  /// runs the labeled source → destination transition.
  Future<void> play({
    required ShapeType from,
    required ShapeType to,
  }) async {
    if (_disposed) {
      return;
    }
    if (from == to) {
      reset(from);
      return;
    }

    final animation = _animation;
    if (animation != null &&
        animation.isAnimating &&
        _fromShape == from &&
        _toShape == to) {
      onStarted?.call();
      await animation.forward();
      return;
    }

    if (_displayedShape != from || _fromShape != _toShape) {
      reset(from);
    }
    await morphTo(to);
  }

  /// Toggles between [a] and [b].
  ///
  /// Mid-flight between the pair, reverses. Otherwise morphs to the shape
  /// that is not currently displayed.
  Future<void> toggle({
    ShapeType a = ShapeType.circle,
    ShapeType b = ShapeType.star,
  }) async {
    final animation = _animation;
    if (animation != null &&
        animation.isAnimating &&
        ((_fromShape == a && _toShape == b) ||
            (_fromShape == b && _toShape == a))) {
      await animation.reverse();
      return;
    }
    final next = _displayedShape == a ? b : a;
    await morphTo(next);
  }

  /// Resumes the active transition forward, or morphs to [to] when idle.
  Future<void> forward({ShapeType? to}) async {
    final animation = _animation;
    if (animation == null || _disposed) {
      return;
    }

    if (to != null) {
      await morphTo(to);
      return;
    }

    // Idle with no pending pair: nothing meaningful to resume.
    if (!animation.isAnimating && _fromShape == _toShape) {
      return;
    }

    if (progress >= 1.0 - 1e-6) {
      return;
    }

    onStarted?.call();
    await animation.forward();
  }

  /// Reverses an in-flight morph, or morphs toward [toward] when idle.
  Future<void> reverse({ShapeType? toward}) async {
    final animation = _animation;
    if (animation == null || _disposed) {
      return;
    }

    if (animation.isAnimating ||
        (progress > 1e-6 && progress < 1.0 - 1e-6 && _fromShape != _toShape)) {
      await animation.reverse();
      return;
    }

    if (toward != null && toward != _displayedShape) {
      await morphTo(toward);
      return;
    }
  }

  /// Instantly snaps to [shape] without animation.
  void reset([ShapeType? shape]) {
    final target = shape ?? ShapeType.circle;
    _overrideFrom = null;
    _fromShape = target;
    _toShape = target;
    _displayedShape = target;
    _ignoreStatus = true;
    _animation?.value = 0;
    _ignoreStatus = false;
    notifyListeners();
  }

  /// Snaps to the destination of the current pair without animation.
  void jumpToEnd() {
    _overrideFrom = null;
    _displayedShape = _toShape;
    _fromShape = _toShape;
    _ignoreStatus = true;
    _animation?.value = 1;
    _ignoreStatus = false;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _detachAnimation();
    super.dispose();
  }
}
