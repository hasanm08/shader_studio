import 'package:flutter/material.dart';
import 'package:shader_studio/core/rendering/shader_uniforms.dart';
import 'package:shader_studio/features/samples/application/shader_sample_controller.dart';
import 'package:shader_studio/features/samples/application/shader_uniform_writers.dart';

/// Paints one fragment shader into the canvas rectangle.
///
/// The painter does not own the shader or the controller. [repaint] is the
/// controller's paint signal, so a time tick calls [paint] without building
/// a new widget. [paint] writes uniforms and then fills the rect with a
/// `Paint` whose shader is the fragment shader. Flutter samples that shader
/// across the rect. `FlutterFragCoord` for this path is in the canvas
/// coordinate system of the draw, which is the logical size passed as
/// `uResolution`.
///
/// A thrown write, usually a misspelled uniform, is reported through
/// [onPaintError] and the rect is left unpainted. The canvas turns that into
/// an error panel on the next frame. Painting must not call `setState`.
class ShaderRenderer extends CustomPainter {
  /// Creates a painter that fills its bounds with [sink]'s shader.
  ShaderRenderer({
    required this.sink,
    required this.controller,
    required Listenable repaint,
    this.onPaintError,
  }) : super(repaint: repaint);

  /// Uniform binding for the live shader.
  final FragmentShaderSink sink;

  /// Time, pointer, and parameter source.
  final ShaderSampleController controller;

  /// Called if uniform binding or another paint step throws.
  final void Function(Object error)? onPaintError;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    try {
      writeSampleUniforms(
        sampleId: controller.sample.id,
        sink: sink,
        controller: controller,
        size: size,
      );
      canvas.drawRect(Offset.zero & size, Paint()..shader = sink.shader);
    } catch (error) {
      onPaintError?.call(error);
    }
  }

  @override
  bool shouldRepaint(ShaderRenderer oldDelegate) {
    return oldDelegate.sink != sink || oldDelegate.controller != controller;
  }
}
