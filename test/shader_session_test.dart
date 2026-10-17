import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shader_studio/core/rendering/shader_controller.dart';
import 'package:shader_studio/features/playground/data/shader_sample_registry.dart';
import 'package:shader_studio/features/playground/domain/shader_parameter.dart';
import 'package:shader_studio/features/samples/application/shader_sample_controller.dart';
import 'package:shader_studio/features/samples/application/shader_uniform_writers.dart';

import 'recording_uniform_sink.dart';

void main() {
  test('pause ignores deltas, resume advances, reset restores defaults', () {
    final sample = ShaderSampleRegistry.find('liquid_aurora')!;
    final controller = ShaderSampleController(sample: sample);
    addTearDown(controller.dispose);

    controller.playing = false;
    controller.addDelta(const Duration(milliseconds: 32));
    expect(controller.timeSeconds, 0);

    controller.playing = true;
    controller.addDelta(const Duration(milliseconds: 500));
    expect(controller.timeSeconds, closeTo(0.5, 0.0001));

    controller.setScalar('distortion', 99);
    final distortion = sample.parameter('distortion')! as SliderParameter;
    expect(controller.scalar('distortion'), distortion.max);

    controller.setScalar('speed', double.nan);
    expect(controller.scalar('speed'), 0.85);

    controller.setPointer(
      const Offset(2, -1),
      active: true,
      size: const Size(400, 200),
    );
    expect(controller.pointer, const Offset(1, 0));

    controller.reset();
    expect(controller.timeSeconds, 0);
    expect(controller.scalar('distortion'), distortion.defaultValue);
    expect(controller.pointer, const Offset(0.5, 0.5));
    expect(controller.pointerActive, isFalse);
    expect(controller.interactionEnabled, isTrue);
  });

  test('time wraps at the documented period', () {
    final controller = ShaderSampleController(
      sample: ShaderSampleRegistry.samples.first,
    );
    addTearDown(controller.dispose);
    controller.timeSeconds = ShaderController.timeWrapSeconds - 0.25;
    controller.addDelta(const Duration(milliseconds: 500));
    expect(controller.timeSeconds, closeTo(0.25, 0.0001));
  });

  test('ripple buffer keeps four slots and overwrites the oldest', () {
    final controller = ShaderSampleController(
      sample: ShaderSampleRegistry.find('liquid_ripple')!,
      playing: false,
    );
    addTearDown(controller.dispose);
    const size = Size(400, 400);
    for (var i = 0; i < 6; i++) {
      controller.setPointer(
        Offset(0.1 * i, 0.2),
        active: true,
        size: size,
        emitRipples: true,
        forceEmit: true,
      );
    }
    expect(controller.ripples.slots.whereType<RippleEvent>().length, 4);
    expect(controller.ripples.slots[0]?.origin.dx, closeTo(0.4, 0.0001));
    expect(controller.ripples.slots[1]?.origin.dx, closeTo(0.5, 0.0001));
  });

  test('still ripple preview seeds two authored waves', () {
    final sample = ShaderSampleRegistry.find('liquid_ripple')!;
    final controller = ShaderSampleController.still(sample);
    addTearDown(controller.dispose);
    expect(controller.playing, isFalse);
    expect(controller.timeSeconds, sample.previewTime);
    expect(controller.ripples.slots.whereType<RippleEvent>().length, 2);
  });

  test('writers emit every uniform in the sample contract', () {
    for (final sample in ShaderSampleRegistry.samples) {
      final controller = ShaderSampleController(sample: sample, playing: false);
      addTearDown(controller.dispose);
      final sink = RecordingUniformSink();
      writeSampleUniforms(
        sampleId: sample.id,
        sink: sink,
        controller: controller,
        size: const Size(320, 180),
      );
      expect(
        sink.values.keys.toSet(),
        sample.uniforms.map((uniform) => uniform.name).toSet(),
        reason: sample.id,
      );
      expect(sink.values['uResolution'], <double>[320, 180]);
      expect(sink.values['uPointerActive'], <double>[0]);
    }
  });

  test('domain warp preset writes colors and a manual edit clears it', () {
    final controller = ShaderSampleController(
      sample: ShaderSampleRegistry.find('domain_warp')!,
      playing: false,
    );
    addTearDown(controller.dispose);
    expect(controller.selectedPresetId, 'aurora');
    controller.selectPreset('ember');
    expect(controller.colorOf('colorB'), const Color(0xFFC4552A));
    controller.setColor('colorB', const Color(0xFF4DBBFF));
    expect(controller.selectedPresetId, isNull);
  });

  test('zero-size pointer updates do not divide', () {
    final controller = ShaderSampleController(
      sample: ShaderSampleRegistry.find('liquid_ripple')!,
      playing: false,
    );
    addTearDown(controller.dispose);
    controller.setPointer(
      const Offset(0.2, 0.2),
      active: true,
      size: Size.zero,
      emitRipples: true,
    );
    expect(controller.ripples.slots.whereType<RippleEvent>().length, 1);
    controller.setPointer(
      const Offset(0.21, 0.2),
      active: true,
      size: Size.zero,
      emitRipples: true,
    );
    expect(controller.ripples.slots.whereType<RippleEvent>().length, 1);
  });
}
