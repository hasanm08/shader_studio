import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

/// Plays the add-to-basket motion: the item travels in, then the lid shuts.
///
/// Progress `0` is an open box with the item waiting above it. Progress `1`
/// is packed. [drop] is ignored once the box is packed. [open] plays the
/// motion backward.
class BasketDropController extends ChangeNotifier {
  /// Creates a controller for an open box.
  BasketDropController({Duration duration = const Duration(milliseconds: 980)})
    : _duration = duration.isNegative ? Duration.zero : duration;

  Duration _duration;
  AnimationController? _animation;
  bool _ownsAnimation = false;
  bool _disposed = false;

  static const Interval _itemInterval = Interval(0, 0.64, curve: Curves.easeIn);
  static const Interval _lidInterval = Interval(
    0.5,
    1,
    curve: Curves.easeInOutCubic,
  );

  /// How long a full pack or unpack takes.
  Duration get duration => _duration;

  set duration(Duration value) {
    _duration = value.isNegative ? Duration.zero : value;
    _animation?.duration = _duration;
  }

  /// True after [dispose].
  bool get isDisposed => _disposed;

  /// True while packing or unpacking.
  bool get isAnimating => _animation?.isAnimating ?? false;

  /// True when [attach] has been called.
  bool get isAttached => _animation != null;

  /// Raw timeline, 0 open → 1 packed.
  double get progress => _animation?.value ?? 0;

  /// 0 until the item starts, 1 once it has landed.
  double get itemProgress => _itemInterval.transform(progress);

  /// 0 while the lid is open, 1 when it has shut.
  double get lidProgress => _lidInterval.transform(progress);

  /// True when the item is inside and the lid is down.
  bool get isPacked => progress >= 1 - 1e-6 && !isAnimating;

  /// Binds [controller].
  void attach(AnimationController controller, {bool ownsAnimation = false}) {
    _detach();
    _ownsAnimation = ownsAnimation;
    _animation = controller;
    controller.duration = _duration;
    controller.addListener(_onTick);
  }

  /// Creates the ticker owned by this controller.
  void createAndAttach(TickerProvider vsync) {
    attach(
      AnimationController(
        vsync: vsync,
        duration: _duration,
        debugLabel: 'basket-drop',
      ),
      ownsAnimation: true,
    );
  }

  /// Moves the item into the box and closes the lid.
  Future<void> drop({bool instant = false}) async {
    final animation = _animation;
    if (_disposed || animation == null || isPacked) {
      return;
    }
    if (instant || _duration == Duration.zero) {
      animation.value = 1;
      return;
    }
    await animation.forward();
  }

  /// Opens the lid and lifts the item back out.
  Future<void> open({bool instant = false}) async {
    final animation = _animation;
    if (_disposed || animation == null) {
      return;
    }
    if (animation.value <= 1e-6 && !animation.isAnimating) {
      return;
    }
    if (instant || _duration == Duration.zero) {
      animation.value = 0;
      return;
    }
    await animation.reverse();
  }

  void _onTick() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void _detach() {
    final animation = _animation;
    if (animation == null) {
      return;
    }
    animation.removeListener(_onTick);
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
    _detach();
    super.dispose();
  }
}
