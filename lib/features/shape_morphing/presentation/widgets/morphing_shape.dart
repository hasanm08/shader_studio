import 'package:flutter/material.dart';
import 'package:shader_studio/core/geometry/shape_type.dart';
import 'package:shader_studio/features/shape_morphing/application/shape_morph_controller.dart';
import 'package:shader_studio/features/shape_morphing/domain/models/morph_shape.dart';
import 'package:shader_studio/features/shape_morphing/presentation/painters/morph_shape_painter.dart';

/// Reusable widget that morphs between two [ShapeType]s.
///
/// Provide an external [controller] that is already attached to a ticker
/// (see [ShapeMorphController.createAndAttach]), or omit it to let this
/// widget own the controller lifecycle.
///
/// Only this widget rebuilds on animation ticks; wrap heavy parents so they
/// do not listen to the controller directly.
class MorphingShape extends StatefulWidget {
  /// Creates a morphing shape.
  const MorphingShape({
    super.key,
    this.initialShape = ShapeType.circle,
    this.targetShape = ShapeType.star,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeInOutCubic,
    this.size = 220,
    this.style = MorphShapeStyle.flowForge,
    this.controller,
    this.autoPlay = false,
    this.onTap,
    this.onAnimationComplete,
    this.onAnimationStart,
  });

  /// Shape shown at progress 0.
  final ShapeType initialShape;

  /// Alternate shape used by the default tap toggle.
  final ShapeType targetShape;

  /// Duration of a full morph.
  final Duration duration;

  /// Easing curve for the morph.
  final Curve curve;

  /// Logical width and height of the paint box.
  final double size;

  /// Fill, stroke, shadow, and rotation.
  final MorphShapeStyle style;

  /// Optional external controller. When null, one is created and disposed.
  ///
  /// When non-null, the caller must attach a ticker before the first frame
  /// (typically in `initState` via [ShapeMorphController.createAndAttach]).
  final ShapeMorphController? controller;

  /// When true, morphs to [targetShape] once after the first frame.
  final bool autoPlay;

  /// Called when the shape is tapped. Defaults to toggling initial/target.
  final VoidCallback? onTap;

  /// Fired when a morph completes.
  final VoidCallback? onAnimationComplete;

  /// Fired when a morph starts.
  final VoidCallback? onAnimationStart;

  @override
  State<MorphingShape> createState() => _MorphingShapeState();
}

class _MorphingShapeState extends State<MorphingShape>
    with SingleTickerProviderStateMixin {
  late ShapeMorphController _controller;
  late bool _ownsController;

  @override
  void initState() {
    super.initState();
    _setupController();
    _controller.addListener(_onTick);
    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.morphTo(widget.targetShape);
        }
      });
    }
  }

  void _setupController() {
    final external = widget.controller;
    if (external != null) {
      assert(
        external.isAttached,
        'Pass a ShapeMorphController that has already called '
        'createAndAttach (or attach) before giving it to MorphingShape.',
      );
      _controller = external;
      _ownsController = false;
    } else {
      _controller = ShapeMorphController(
        initialShape: widget.initialShape,
        targetShape: widget.initialShape,
        duration: widget.duration,
        curve: widget.curve,
      );
      _ownsController = true;
      _controller.createAndAttach(this);
    }
    _applyConfig();
  }

  void _applyConfig() {
    _controller.duration = widget.duration;
    _controller.curve = widget.curve;
    _controller.onCompleted = widget.onAnimationComplete;
    _controller.onStarted = widget.onAnimationStart;
  }

  void _onTick() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant MorphingShape oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_onTick);
      if (_ownsController) {
        _controller.dispose();
      }
      _setupController();
      _controller.addListener(_onTick);
    } else {
      _applyConfig();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }
    await _controller.toggle(a: widget.initialShape, b: widget.targetShape);
  }

  @override
  Widget build(BuildContext context) {
    final side = widget.size;
    return Semantics(
      button: true,
      label: 'Morphing shape, ${_controller.displayedShape.label}',
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: side,
          height: side,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: MorphShapePainter(
                contour: _controller.currentContour,
                style: widget.style,
                engine: _controller.engine,
              ),
              size: Size.square(side),
            ),
          ),
        ),
      ),
    );
  }
}
