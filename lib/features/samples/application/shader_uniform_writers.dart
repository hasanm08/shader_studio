import 'dart:ui' show Color, Size;

import 'package:shader_studio/core/rendering/shader_uniforms.dart';
import 'package:shader_studio/features/samples/application/shader_sample_controller.dart';

/// Writes one sample's uniforms by name.
///
/// Each branch is the contract for that shader. Shared uniforms are first
/// because every `.frag` file declares them first, but the binding does not
/// depend on that order: `FragmentShader.getUniformVec2` looks the name up
/// in the compiled program.
///
/// Color components are straight RGB in 0..1. They are data for the shader,
/// not a paint color the engine would premultiply.
///
/// A parameter edit only changes the values written on the next paint. The
/// `FragmentProgram` is not compiled again.
void writeSampleUniforms({
  required String sampleId,
  required FloatUniformSink sink,
  required ShaderSampleController controller,
  required Size size,
}) {
  switch (sampleId) {
    case 'liquid_aurora':
      writeLiquidAurora(sink, controller, size);
    case 'liquid_ripple':
      writeLiquidRipple(sink, controller, size);
    case 'procedural_energy':
      writeProceduralEnergy(sink, controller, size);
    case 'plasma_field':
      writePlasmaField(sink, controller, size);
    case 'domain_warp':
      writeDomainWarp(sink, controller, size);
    case 'radial_wave':
      writeRadialWave(sink, controller, size);
    case 'beehive_interior':
      writeBeehiveInterior(sink, controller, size);
    default:
      throw ArgumentError('No uniform writer for $sampleId');
  }
}

/// Width and height passed to `uResolution`.
///
/// A zero side becomes 1 so the shader's aspect ratio never divides by zero
/// on the first frame of an empty layout. The shader also guards this.
Size _safeSize(Size size) {
  final width = size.width <= 0 ? 1.0 : size.width;
  final height = size.height <= 0 ? 1.0 : size.height;
  return Size(width, height);
}

void _writeShared(
  FloatUniformSink sink,
  ShaderSampleController controller,
  Size size,
) {
  final safe = _safeSize(size);
  sink.setVec2('uResolution', safe.width, safe.height);
  sink.setFloat('uTime', controller.timeSeconds);
  sink.setVec2('uPointer', controller.pointer.dx, controller.pointer.dy);
  sink.setFloat('uPointerActive', controller.shaderPointerActive ? 1 : 0);
}

void _writeColor(FloatUniformSink sink, String name, Color color) {
  sink.setVec3(name, color.r, color.g, color.b);
}

// BEGIN liquid_aurora
/// Uniforms for `shaders/liquid_aurora.frag`.
void writeLiquidAurora(
  FloatUniformSink sink,
  ShaderSampleController controller,
  Size size,
) {
  _writeShared(sink, controller, size);
  sink.setFloat('uSpeed', controller.scalar('speed'));
  sink.setFloat('uScale', controller.scalar('scale'));
  sink.setFloat('uIntensity', controller.scalar('intensity'));
  sink.setFloat('uDistortion', controller.scalar('distortion'));
}
// END liquid_aurora

// BEGIN liquid_ripple
/// Uniforms for `shaders/liquid_ripple.frag`.
///
/// Empty ripple slots are written with z = -1, which `rippleHeight` rejects.
void writeLiquidRipple(
  FloatUniformSink sink,
  ShaderSampleController controller,
  Size size,
) {
  _writeShared(sink, controller, size);
  sink.setFloat('uAmplitude', controller.scalar('amplitude'));
  sink.setFloat('uFrequency', controller.scalar('frequency'));
  sink.setFloat('uSpeed', controller.scalar('speed'));
  sink.setFloat('uDamping', controller.scalar('damping'));
  _writeColor(sink, 'uColor', controller.colorOf('color'));
  const names = <String>['uRipple0', 'uRipple1', 'uRipple2', 'uRipple3'];
  for (var i = 0; i < names.length; i++) {
    final event = controller.ripples.slots[i];
    if (event == null) {
      sink.setVec3(names[i], 0, 0, -1);
    } else {
      sink.setVec3(names[i], event.origin.dx, event.origin.dy, event.startTime);
    }
  }
}
// END liquid_ripple

// BEGIN procedural_energy
/// Uniforms for `shaders/procedural_energy.frag`.
void writeProceduralEnergy(
  FloatUniformSink sink,
  ShaderSampleController controller,
  Size size,
) {
  _writeShared(sink, controller, size);
  sink.setFloat('uSpeed', controller.scalar('speed'));
  sink.setFloat('uIntensity', controller.scalar('intensity'));
  sink.setFloat('uPulse', controller.scalar('pulse'));
  sink.setFloat('uTurbulence', controller.scalar('turbulence'));
  _writeColor(sink, 'uColorCore', controller.colorOf('core'));
  _writeColor(sink, 'uColorRim', controller.colorOf('rim'));
}
// END procedural_energy

// BEGIN plasma_field
/// Uniforms for `shaders/plasma_field.frag`.
void writePlasmaField(
  FloatUniformSink sink,
  ShaderSampleController controller,
  Size size,
) {
  _writeShared(sink, controller, size);
  sink.setFloat('uSpeed', controller.scalar('speed'));
  sink.setFloat('uScale', controller.scalar('scale'));
  sink.setFloat('uContrast', controller.scalar('contrast'));
  _writeColor(sink, 'uColorA', controller.colorOf('colorA'));
  _writeColor(sink, 'uColorB', controller.colorOf('colorB'));
  _writeColor(sink, 'uColorC', controller.colorOf('colorC'));
}
// END plasma_field

// BEGIN domain_warp
/// Uniforms for `shaders/domain_warp.frag`.
///
/// Palette chips are not uniforms. They assign the three color values
/// before this function runs.
void writeDomainWarp(
  FloatUniformSink sink,
  ShaderSampleController controller,
  Size size,
) {
  _writeShared(sink, controller, size);
  sink.setFloat('uSpeed', controller.scalar('speed'));
  sink.setFloat('uScale', controller.scalar('scale'));
  sink.setFloat('uWarp', controller.scalar('warp'));
  _writeColor(sink, 'uColorA', controller.colorOf('colorA'));
  _writeColor(sink, 'uColorB', controller.colorOf('colorB'));
  _writeColor(sink, 'uColorC', controller.colorOf('colorC'));
}
// END domain_warp

// BEGIN radial_wave
/// Uniforms for `shaders/radial_wave.frag`.
///
/// `centerX` and `centerY` are one vec2, `uCenter`. The follow toggle is a
/// float, 1 or 0, not a GLSL bool.
void writeRadialWave(
  FloatUniformSink sink,
  ShaderSampleController controller,
  Size size,
) {
  _writeShared(sink, controller, size);
  sink.setFloat('uFrequency', controller.scalar('frequency'));
  sink.setFloat('uAmplitude', controller.scalar('amplitude'));
  sink.setFloat('uSpeed', controller.scalar('speed'));
  sink.setFloat('uAttenuation', controller.scalar('attenuation'));
  sink.setVec2(
    'uCenter',
    controller.scalar('centerX'),
    controller.scalar('centerY'),
  );
  sink.setFloat('uFollowPointer', controller.scalar('followPointer'));
  _writeColor(sink, 'uColor', controller.colorOf('color'));
}
// END radial_wave

// BEGIN beehive_interior
/// Uniforms for `shaders/beehive_interior.frag`.
///
/// Wax and honey are straight RGB. Scale is a spatial frequency: a larger
/// value shrinks the cell you are standing in.
void writeBeehiveInterior(
  FloatUniformSink sink,
  ShaderSampleController controller,
  Size size,
) {
  _writeShared(sink, controller, size);
  sink.setFloat('uSpeed', controller.scalar('speed'));
  sink.setFloat('uScale', controller.scalar('scale'));
  sink.setFloat('uDepth', controller.scalar('depth'));
  sink.setFloat('uHoney', controller.scalar('honey'));
  _writeColor(sink, 'uColorWax', controller.colorOf('wax'));
  _writeColor(sink, 'uColorHoney', controller.colorOf('honeyColor'));
}
// END beehive_interior
