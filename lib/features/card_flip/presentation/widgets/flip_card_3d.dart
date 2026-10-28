import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shader_studio/features/card_flip/application/card_flip_controller.dart';
import 'package:shader_studio/features/card_flip/domain/models/card_flip_config.dart';
import 'package:shader_studio/features/card_flip/presentation/rendering/card_flip_transform.dart';

/// A card that flips around its vertical axis with perspective.
///
/// Pass any [front] and [back]. They share one [cardFlipTransform]: perspective
/// is set, then the Y rotation runs from 0 to π. After the halfway angle the
/// back face is shown and a local π correction keeps it from rendering
/// mirrored. This is a real rotation, not a crossfade.
///
/// Provide [controller] to call [CardFlipController.flip], [flipForward],
/// [flipBack], [toggle], or [CardFlipController.reset]. When [controller] is
/// omitted, this widget creates one and disposes it. While a flip is running,
/// another [toggle] reverses direction.
///
/// [width] and [height] must be finite and greater than zero. [duration] must
/// not be negative; [Duration.zero] snaps to the other face. [perspective] is
/// clamped into a stable range by [CardFlipConfig.clampPerspective].
///
/// The widget writes [CardFlipController.onFlipChanged], [onCompleted], and
/// [onStarted]. Set [onFlipChanged] and [onFlipCompleted] here rather than on
/// the controller after it has been passed in.
class FlipCard3D extends StatefulWidget {
  /// Creates a 3D flip card.
  ///
  /// The constructor is not const because [width], [height], and [duration]
  /// are checked with runtime asserts.
  FlipCard3D({
    required this.front,
    required this.back,
    this.width = 300,
    this.height = 420,
    this.perspective = CardFlipConfig.defaultPerspective,
    this.duration = CardFlipConfig.defaultDuration,
    this.curve = Curves.easeInOutCubic,
    this.initiallyFlipped = false,
    this.enableTap = true,
    this.elevation = CardFlipConfig.defaultElevation,
    this.shadowColor = const Color(0x6614B8A6),
    this.borderRadius = const BorderRadius.all(
      Radius.circular(CardFlipConfig.defaultRadius),
    ),
    this.onFlipChanged,
    this.onFlipCompleted,
    this.controller,
    this.autoFlip = false,
    this.tiltEnabled = false,
    super.key,
  }) : assert(
         width.isFinite && width > 0,
         'width must be finite and greater than zero',
       ),
       assert(
         height.isFinite && height > 0,
         'height must be finite and greater than zero',
       ),
       assert(!duration.isNegative, 'duration must not be negative');

  /// Face shown at angle 0.
  final Widget front;

  /// Face shown after the rotation passes π/2.
  final Widget back;

  /// Card width. Both faces use this same size.
  final double width;

  /// Card height. Both faces use this same size.
  final double height;

  /// Perspective strength. Clamped; see [CardFlipConfig.clampPerspective].
  final double perspective;

  /// How long a one-way flip takes.
  final Duration duration;

  /// Easing for the flip. The demo offers three; any [Curve] is accepted.
  final Curve curve;

  /// Used only when [controller] is null. An attached controller wins.
  final bool initiallyFlipped;

  /// When false, taps and Enter / Space do not flip the card.
  final bool enableTap;

  /// Shadow depth. Zero removes both the contact shadow and the glow.
  final double elevation;

  /// Glow color drawn with [elevation].
  final Color shadowColor;

  /// Corners clipped on both faces.
  final BorderRadius borderRadius;

  /// Called when the settled side changes.
  ///
  /// Also runs for an instant flip and for [CardFlipController.reset] when
  /// the card was showing the back. It does not run on every frame.
  final ValueChanged<bool>? onFlipChanged;

  /// Called with the settled side when a flip finishes.
  ///
  /// [CardFlipController.reset] does not call this.
  final ValueChanged<bool>? onFlipCompleted;

  /// Optional owner of the flip ticker. Disposed by the caller.
  final CardFlipController? controller;

  /// When true, flips again after each settle. Off by default.
  final bool autoFlip;

  /// Pointer tilt, independent of the flip. Desktop hover only.
  final bool tiltEnabled;

  @override
  State<FlipCard3D> createState() => _FlipCard3DState();
}

class _FlipCard3DState extends State<FlipCard3D> with TickerProviderStateMixin {
  late CardFlipController _controller;
  late Listenable _motion;
  late final AnimationController _tiltReset;
  final FocusNode _focusNode = FocusNode(debugLabel: 'flip-card');
  final ValueNotifier<Offset> _tilt = ValueNotifier<Offset>(Offset.zero);

  bool _ownsController = false;
  bool _attachedHere = false;
  bool _sawAnimating = false;
  bool _showBackForSemantics = false;
  double _tiltFromX = 0;
  double _tiltFromY = 0;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _tiltReset = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      debugLabel: 'card-tilt',
    )..addListener(_onTiltResetTick);
    _adopt(widget.controller);
    _showBackForSemantics = _controller.showBack;
    if (widget.autoFlip) {
      _armAutoFlip();
    }
  }

  void _adopt(CardFlipController? external) {
    if (external != null) {
      _controller = external;
      _ownsController = false;
      if (!_controller.isAttached) {
        _controller.createAndAttach(this);
        _attachedHere = true;
      } else {
        _attachedHere = false;
      }
    } else {
      _controller = CardFlipController(
        initiallyFlipped: widget.initiallyFlipped,
        duration: widget.duration,
        curve: widget.curve,
      )..createAndAttach(this);
      _ownsController = true;
      _attachedHere = false;
    }
    _syncSettings();
    _bindCallbacks();
    _motion = Listenable.merge(<Listenable>[_controller, _tilt]);
    _controller.addListener(_onControllerNotify);
  }

  void _syncSettings() {
    if (_controller.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (_controller.curve != widget.curve) {
      _controller.curve = widget.curve;
    }
  }

  void _bindCallbacks() {
    _controller.onFlipChanged = widget.onFlipChanged;
    _controller.onStarted = _cancelAutoFlip;
    _controller.onCompleted = (bool flipped) {
      widget.onFlipCompleted?.call(flipped);
      _armAutoFlip();
    };
  }

  void _release({bool disposeOwned = true}) {
    _cancelAutoFlip();
    _controller.removeListener(_onControllerNotify);
    _controller.onFlipChanged = null;
    _controller.onCompleted = null;
    _controller.onStarted = null;
    if (_ownsController && disposeOwned) {
      _controller.dispose();
    } else if (_attachedHere) {
      _controller.detachAndDisposeAnimation();
    }
    _ownsController = false;
    _attachedHere = false;
  }

  @override
  void didUpdateWidget(FlipCard3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _release();
      _adopt(widget.controller);
    } else {
      _syncSettings();
      _bindCallbacks();
    }
    if (widget.autoFlip != oldWidget.autoFlip ||
        (widget.autoFlip && widget.duration != oldWidget.duration)) {
      if (widget.autoFlip) {
        _armAutoFlip();
      } else {
        _cancelAutoFlip();
      }
    }
    if (!widget.tiltEnabled && oldWidget.tiltEnabled) {
      _beginTiltReset();
    }
  }

  @override
  void dispose() {
    _release();
    _tiltReset.dispose();
    _tilt.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _prefersReducedMotion => MediaQuery.disableAnimationsOf(context);

  bool _tiltActive() {
    return widget.tiltEnabled &&
        CardFlipConfig.tiltSupportedOn(Theme.of(context).platform) &&
        !_prefersReducedMotion;
  }

  void _onControllerNotify() {
    if (!mounted) {
      return;
    }
    final animating = _controller.isAnimating;
    if (animating) {
      _cancelAutoFlip();
    } else if (_sawAnimating && widget.autoFlip) {
      _armAutoFlip();
    }
    _sawAnimating = animating;
    final showBack = _controller.showBack;
    if (showBack != _showBackForSemantics) {
      setState(() => _showBackForSemantics = showBack);
    }
  }

  void _armAutoFlip() {
    _autoTimer?.cancel();
    if (!mounted || !widget.autoFlip) {
      _autoTimer = null;
      return;
    }
    _autoTimer = Timer(widget.duration + CardFlipConfig.autoFlipPause, () {
      if (!mounted || !widget.autoFlip || _controller.isDisposed) {
        return;
      }
      if (_controller.isAnimating) {
        _armAutoFlip();
        return;
      }
      _controller.toggle(instant: _prefersReducedMotion);
    });
  }

  void _cancelAutoFlip() {
    _autoTimer?.cancel();
    _autoTimer = null;
  }

  void _handleTap() {
    if (!widget.enableTap) {
      return;
    }
    _focusNode.requestFocus();
    _cancelAutoFlip();
    _controller.toggle(instant: _prefersReducedMotion);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!widget.enableTap || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      _handleTap();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _onHover(PointerHoverEvent event) {
    if (!_tiltActive()) {
      return;
    }
    _tiltReset.stop();
    final nx = (event.localPosition.dx / widget.width - 0.5) * 2;
    final ny = (event.localPosition.dy / widget.height - 0.5) * 2;
    _tilt.value = Offset(
      CardFlipConfig.clampTilt(ny * CardFlipConfig.maxTilt),
      CardFlipConfig.clampTilt(-nx * CardFlipConfig.maxTilt),
    );
  }

  void _onExit(PointerExitEvent event) {
    _beginTiltReset();
  }

  void _beginTiltReset() {
    _tiltFromX = _tilt.value.dx;
    _tiltFromY = _tilt.value.dy;
    if (!mounted || _prefersReducedMotion) {
      _tilt.value = Offset.zero;
      return;
    }
    _tiltReset.forward(from: 0);
  }

  void _onTiltResetTick() {
    final t = Curves.easeOutCubic.transform(_tiltReset.value);
    _tilt.value = Offset(_tiltFromX * (1 - t), _tiltFromY * (1 - t));
  }

  List<BoxShadow> get _shadows {
    if (widget.elevation <= 0) {
      return const <BoxShadow>[];
    }
    return <BoxShadow>[
      BoxShadow(
        color: const Color(0x99000000),
        blurRadius: widget.elevation,
        offset: Offset(0, widget.elevation * 0.28),
      ),
      BoxShadow(
        color: widget.shadowColor,
        blurRadius: widget.elevation * 1.35,
        spreadRadius: -2,
      ),
    ];
  }

  Widget _buildCard() {
    final angle = _controller.angle;
    final showBack = _controller.showBack;
    final matrix = cardFlipTransform(
      angle: angle,
      perspective: widget.perspective,
      correctBackFace: showBack,
      tiltX: _tilt.value.dx,
      tiltY: _tilt.value.dy,
      cardWidth: widget.width,
    );
    final faceOn = math.cos(angle).abs();
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: <Widget>[
        if (widget.elevation > 0)
          Positioned(
            left: widget.width * 0.16,
            right: widget.width * 0.16,
            bottom: 8,
            height: 14,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(999)),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.45 * faceOn),
                    blurRadius: widget.elevation,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        Transform(
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
          transform: matrix,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              boxShadow: _shadows,
            ),
            child: ClipRRect(
              borderRadius: widget.borderRadius,
              child: SizedBox.expand(
                child: showBack ? widget.back : widget.front,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tiltActive = _tiltActive();
    final hint = widget.enableTap
        ? (_showBackForSemantics
              ? 'Activate to return to the front'
              : 'Activate to flip the card')
        : null;
    return Focus(
      focusNode: _focusNode,
      canRequestFocus: widget.enableTap,
      onKeyEvent: _onKey,
      child: Semantics(
        button: widget.enableTap,
        enabled: widget.enableTap,
        onTap: widget.enableTap ? _handleTap : null,
        hint: hint,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _motion,
                    builder: (context, child) => _buildCard(),
                  ),
                ),
              ),
              Positioned.fill(
                child: MouseRegion(
                  onHover: tiltActive ? _onHover : null,
                  onExit: tiltActive ? _onExit : null,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.enableTap ? _handleTap : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
