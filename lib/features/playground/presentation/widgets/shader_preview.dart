import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shader_studio/app/theme/app_theme.dart';
import 'package:shader_studio/core/widgets/shader_canvas.dart';
import 'package:shader_studio/features/samples/application/shader_sample_controller.dart';

/// The large preview, including pointer tracking.
///
/// Pointer positions are converted from local logical pixels to normalized
/// coordinates: divide by the preview width and height, origin at the
/// top-left, Y down. That is the same convention as
/// `FlutterFragCoord / uResolution` in the shaders. A zero width or height
/// is ignored so a layout pass cannot divide by zero.
///
/// Hover counts as active on desktop. Leaving the preview clears
/// `uPointerActive` but keeps the last position, so a contact highlight
/// disappears without jumping the coordinate to the origin.
///
/// [interactive] is false for gallery thumbnails so they do not compete
/// with scrolling. Those thumbnails also pass a paused controller and do
/// not animate.
class ShaderPreview extends StatelessWidget {
  /// Creates a preview for [controller].
  const ShaderPreview({
    required this.controller,
    required this.interactive,
    this.animate = true,
    this.showFrameTime = false,
    super.key,
  });

  /// State written by pointer events and read by the shader.
  final ShaderSampleController controller;

  /// When true, pointer and hover update the controller.
  final bool interactive;

  /// When false, the canvas does not create a ticker.
  final bool animate;

  /// Shows the debug ticker estimate. Ignored in release builds.
  final bool showFrameTime;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return MouseRegion(
              onHover: interactive
                  ? (event) => _move(event.localPosition, size, active: true)
                  : null,
              onExit: interactive
                  ? (_) => controller.setPointer(
                      controller.pointer,
                      active: false,
                      size: size,
                      emitRipples: controller.sample.emitsRipples,
                    )
                  : null,
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: interactive
                    ? (event) => _move(
                        event.localPosition,
                        size,
                        active: true,
                        forceEmit: true,
                      )
                    : null,
                onPointerMove: interactive
                    ? (event) => _move(event.localPosition, size, active: true)
                    : null,
                onPointerUp: interactive
                    ? (event) => _move(event.localPosition, size, active: false)
                    : null,
                onPointerCancel: interactive
                    ? (_) => controller.setPointer(
                        controller.pointer,
                        active: false,
                        size: size,
                        emitRipples: controller.sample.emitsRipples,
                      )
                    : null,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ShaderCanvas(controller: controller, animate: animate),
                    if (showFrameTime && kDebugMode)
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: ListenableBuilder(
                          listenable: controller.frameTick,
                          builder: (context, _) {
                            return DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xCC080B10),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Text(
                                  controller.frameTime.label,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _move(
    Offset local,
    Size size, {
    required bool active,
    bool forceEmit = false,
  }) {
    if (!controller.interactionEnabled) {
      return;
    }
    if (size.width <= 0 || size.height <= 0) {
      return;
    }
    controller.setPointer(
      Offset(local.dx / size.width, local.dy / size.height),
      active: active,
      size: size,
      emitRipples: controller.sample.emitsRipples,
      forceEmit: forceEmit,
    );
  }
}
