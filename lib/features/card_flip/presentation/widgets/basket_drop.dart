import 'package:flutter/material.dart';
import 'package:shader_studio/features/card_flip/application/basket_drop_controller.dart';
import 'package:shader_studio/features/card_flip/presentation/painters/basket_painter.dart';
import 'package:shader_studio/features/card_flip/presentation/theme/card_flip_colors.dart';

/// Drops [item] into a carton and swings the lid shut.
///
/// The item is painted before the front lip, so it slides behind the lip as
/// it lands. The lid is a separate transform hinged on the back rim.
class BasketDrop extends StatefulWidget {
  /// Creates the basket scene.
  const BasketDrop({
    this.controller,
    this.width = 280,
    this.height = 340,
    this.item,
    super.key,
  }) : assert(width > 0 && height > 0, 'width and height must be positive');

  /// Optional ticker owner. Must already be attached.
  final BasketDropController? controller;

  /// Scene width.
  final double width;

  /// Scene height.
  final double height;

  /// Widget that travels into the box. Defaults to a chamfered token.
  final Widget? item;

  @override
  State<BasketDrop> createState() => _BasketDropState();
}

class _BasketDropState extends State<BasketDrop>
    with SingleTickerProviderStateMixin {
  late BasketDropController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    final external = widget.controller;
    if (external != null) {
      assert(
        external.isAttached,
        'Attach the BasketDropController before passing it in.',
      );
      _controller = external;
    } else {
      _controller = BasketDropController()..createAndAttach(this);
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item ?? const _DefaultToken();
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final travel = _controller.itemProgress;
        final lid = _controller.lidProgress;
        final itemSize = widget.width * 0.27;
        final itemLeft = (widget.width - itemSize) / 2;
        final startTop = widget.height * 0.03;
        final endTop = widget.height * 0.56;
        final top = startTop + (endTop - startTop) * travel;
        final scale = 1 - 0.22 * travel;
        final tilt = -0.2 * (1 - travel);
        // 0 lays the lid across the opening. A negative angle swings it up.
        final lidAngle = -1.15 * (1 - lid);

        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                left: widget.width * 0.12,
                right: widget.width * 0.12,
                top: widget.height * 0.40,
                bottom: widget.height * 0.05,
                child: const CustomPaint(
                  painter: BasketPainter(BasketPart.cavity),
                  child: SizedBox.expand(),
                ),
              ),
              Positioned(
                left: itemLeft,
                top: top,
                width: itemSize,
                height: itemSize,
                child: Transform.scale(
                  scale: scale,
                  child: Transform.rotate(angle: tilt, child: item),
                ),
              ),
              Positioned(
                left: widget.width * 0.08,
                right: widget.width * 0.08,
                bottom: widget.height * 0.04,
                height: widget.height * 0.28,
                child: const CustomPaint(
                  painter: BasketPainter(BasketPart.lip),
                  child: SizedBox.expand(),
                ),
              ),
              Positioned(
                left: widget.width * 0.1,
                right: widget.width * 0.1,
                top: widget.height * 0.58,
                height: widget.height * 0.2,
                child: Transform(
                  alignment: Alignment.topCenter,
                  filterQuality: FilterQuality.medium,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0018)
                    ..rotateX(lidAngle),
                  child: const CustomPaint(
                    painter: BasketPainter(BasketPart.lid),
                    child: SizedBox.expand(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DefaultToken extends StatelessWidget {
  const _DefaultToken();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: BasketTokenPainter(),
      child: Center(
        child: Text(
          'PACK',
          style: TextStyle(
            color: CardFlipColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}
