import 'package:flutter/material.dart';
import 'package:shader_studio/features/card_flip/application/cube_flip_controller.dart';
import 'package:shader_studio/features/card_flip/domain/models/card_flip_config.dart';
import 'package:shader_studio/features/card_flip/presentation/rendering/cube_face_transform.dart';

/// Four square faces arranged as a cube and turned around Y.
///
/// Faces whose normal points away from the camera are omitted so text is
/// never shown mirrored on the back of a plane. Two faces can be visible
/// together while the cube is mid-turn.
class CubeFlip3D extends StatefulWidget {
  /// Creates a cube. [faces] must contain exactly four children.
  CubeFlip3D({
    required this.faces,
    this.side = 180,
    this.perspective = 0.0022,
    this.duration = const Duration(milliseconds: 700),
    this.curve = Curves.easeInOutCubic,
    this.controller,
    this.onFaceChanged,
    super.key,
  }) : assert(side.isFinite && side > 0, 'side must be finite and > 0'),
       assert(faces.length == 4, 'CubeFlip3D requires exactly four faces'),
       assert(!duration.isNegative, 'duration must not be negative');

  /// Front, then the face that arrives on the next turn, then two more.
  final List<Widget> faces;

  /// Width and height of one face.
  final double side;

  /// Shared perspective. Clamped like the card flip.
  final double perspective;

  /// Length of one quarter turn.
  final Duration duration;

  /// Easing for a quarter turn.
  final Curve curve;

  /// Optional owner of the ticker.
  final CubeFlipController? controller;

  /// Settled face after each quarter turn.
  final ValueChanged<int>? onFaceChanged;

  @override
  State<CubeFlip3D> createState() => _CubeFlip3DState();
}

class _CubeFlip3DState extends State<CubeFlip3D>
    with SingleTickerProviderStateMixin {
  late CubeFlipController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _adopt(widget.controller);
  }

  void _adopt(CubeFlipController? external) {
    if (external != null) {
      assert(
        external.isAttached,
        'Attach the CubeFlipController before passing it in.',
      );
      _controller = external;
      _ownsController = false;
      _controller.duration = widget.duration;
      if (_controller.curve != widget.curve) {
        _controller.curve = widget.curve;
      }
    } else {
      _controller = CubeFlipController(
        duration: widget.duration,
        curve: widget.curve,
      )..createAndAttach(this);
      _ownsController = true;
    }
    _controller.onFaceChanged = widget.onFaceChanged;
  }

  void _release() {
    _controller.onFaceChanged = null;
    if (_ownsController) {
      _controller.dispose();
    }
    _ownsController = false;
  }

  @override
  void didUpdateWidget(CubeFlip3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _release();
      _adopt(widget.controller);
    } else {
      _controller.duration = widget.duration;
      if (_controller.curve != widget.curve) {
        _controller.curve = widget.curve;
      }
      _controller.onFaceChanged = widget.onFaceChanged;
    }
  }

  @override
  void dispose() {
    _release();
    super.dispose();
  }

  void _turn() {
    final instant = MediaQuery.disableAnimationsOf(context);
    _controller.next(instant: instant);
  }

  @override
  Widget build(BuildContext context) {
    final box = widget.side * 1.55;
    return Semantics(
      button: true,
      label: 'Cube. Activate to turn to the next face.',
      onTap: _turn,
      child: SizedBox(
        width: box,
        height: box,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _turn,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => _buildCube(),
          ),
        ),
      ),
    );
  }

  Widget _buildCube() {
    final perspective = CardFlipConfig.clampPerspective(
      widget.perspective,
      width: widget.side * 2,
    );
    final spin = _controller.spin;
    final order = List<int>.generate(4, (index) => index)
      ..sort((a, b) {
        final depthA = cubeFaceDepth(spin: spin, index: a);
        final depthB = cubeFaceDepth(spin: spin, index: b);
        return depthA.compareTo(depthB);
      });

    return Center(
      child: SizedBox(
        width: widget.side,
        height: widget.side,
        child: Transform(
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
          transform: Matrix4.identity()
            ..setEntry(3, 2, perspective)
            ..rotateX(-0.28),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: <Widget>[
              for (final index in order)
                if (cubeFaceDepth(spin: spin, index: index) > 0.02)
                  Transform(
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.medium,
                    transform: cubeFaceTransform(
                      spin: spin,
                      index: index,
                      depth: widget.side / 2,
                    ),
                    child: SizedBox(
                      width: widget.side,
                      height: widget.side,
                      child: widget.faces[index],
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Square panel used on the demo cube.
class CubeFacePanel extends StatelessWidget {
  /// Creates a labeled cube face.
  const CubeFacePanel({required this.kicker, required this.title, super.key});

  /// Small index label, such as `01`.
  final String kicker;

  /// Face title.
  final String title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF1A2427),
            Color(0xFF111719),
            Color(0xFF0C1214),
          ],
        ),
        border: Border.all(color: const Color(0xFF5EEAD4), width: 1.4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              kicker,
              style: const TextStyle(
                color: Color(0xFF5EEAD4),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.6,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFF5F7F7),
                fontSize: 28,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
