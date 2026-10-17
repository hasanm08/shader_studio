import 'package:flutter/material.dart';
import 'package:shader_studio/features/playground/domain/shader_documentation.dart';
import 'package:shader_studio/features/playground/domain/shader_parameter.dart';
import 'package:shader_studio/features/playground/domain/shader_sample.dart';

/// The samples shipped with Shader Studio.
///
/// Add another sample by appending one [ShaderSample] here, listing its
/// `.frag` file under `flutter: shaders`, regenerating the source mirror,
/// and adding a writer branch in `shader_uniform_writers.dart`.
abstract final class ShaderSampleRegistry {
  static const _resolution = ShaderUniform(
    index: 0,
    name: 'uResolution',
    type: ShaderUniformType.vec2,
    meaning: 'Preview size in logical pixels, width then height.',
  );
  static const _time = ShaderUniform(
    index: 2,
    name: 'uTime',
    type: ShaderUniformType.float,
    meaning: 'Elapsed seconds, wrapped to the range [0, 600).',
  );
  static const _pointer = ShaderUniform(
    index: 3,
    name: 'uPointer',
    type: ShaderUniformType.vec2,
    meaning: 'Pointer in normalized preview space. Origin is top-left, Y down.',
  );
  static const _pointerActive = ShaderUniform(
    index: 5,
    name: 'uPointerActive',
    type: ShaderUniformType.float,
    meaning:
        '1 while the pointer is inside and interaction is enabled, else 0.',
  );

  static const List<ColorPreset> _warpPresets = <ColorPreset>[
    ColorPreset(
      id: 'aurora',
      label: 'Aurora',
      colors: <Color>[Color(0xFF071018), Color(0xFF149E96), Color(0xFFE7F8FF)],
    ),
    ColorPreset(
      id: 'deep_sea',
      label: 'Deep sea',
      colors: <Color>[Color(0xFF041018), Color(0xFF1E6F9A), Color(0xFFB7F3FF)],
    ),
    ColorPreset(
      id: 'ember',
      label: 'Ember',
      colors: <Color>[Color(0xFF140806), Color(0xFFC4552A), Color(0xFFFFD2A8)],
    ),
    ColorPreset(
      id: 'graphite',
      label: 'Graphite',
      colors: <Color>[Color(0xFF0C0E12), Color(0xFF8A93A0), Color(0xFFF5F7FA)],
    ),
  ];

  /// Samples in gallery order. The featured flag marks the hero.
  static final List<ShaderSample> samples = <ShaderSample>[
    ShaderSample(
      id: 'liquid_aurora',
      name: 'Living Liquid Aurora',
      summary:
          'A glossy field built from value noise, domain warping, and a '
          'lighting approximation. It suggests depth. It does not simulate '
          'a 3D fluid.',
      assetPath: 'shaders/liquid_aurora.frag',
      documentationAsset: 'docs/samples/LIQUID_AURORA.md',
      techniques: <String>['Noise', 'Domain warp', 'Lighting'],
      featured: true,
      previewTime: 3.2,
      stillNote: 'Still frame at 3.2s. This card does not tick.',
      interaction:
          'The pointer pulls nearby coordinates, like a finger in viscous '
          'fluid. The pull falls off exponentially so the rest of the field '
          'keeps its motion.',
      limitations:
          'Four fBm evaluations, four octaves each. There is no refraction '
          'and no thickness. Very high scale can shimmer because the shader '
          'does not antialias with derivatives.',
      uniforms: <ShaderUniform>[
        _resolution,
        _time,
        _pointer,
        _pointerActive,
        const ShaderUniform(
          index: 6,
          name: 'uSpeed',
          type: ShaderUniformType.float,
          meaning: 'Multiplier on uTime.',
        ),
        const ShaderUniform(
          index: 7,
          name: 'uScale',
          type: ShaderUniformType.float,
          meaning: 'Spatial frequency of the field.',
        ),
        const ShaderUniform(
          index: 8,
          name: 'uIntensity',
          type: ShaderUniformType.float,
          meaning: 'How far the ramp is pushed toward cyan and white.',
        ),
        const ShaderUniform(
          index: 9,
          name: 'uDistortion',
          type: ShaderUniformType.float,
          meaning: 'How far noise is allowed to move the domain.',
        ),
      ],
      parameters: const <ShaderParameter>[
        SliderParameter(
          id: 'speed',
          label: 'Speed',
          uniformName: 'uSpeed',
          min: 0,
          max: 2.5,
          defaultValue: 0.85,
          summary: 'Scales uTime before the field scrolls.',
        ),
        SliderParameter(
          id: 'scale',
          label: 'Scale',
          uniformName: 'uScale',
          min: 0.4,
          max: 3,
          defaultValue: 1.35,
          summary: 'Multiplies the aspect-corrected coordinate before noise.',
        ),
        SliderParameter(
          id: 'intensity',
          label: 'Color intensity',
          uniformName: 'uIntensity',
          min: 0,
          max: 2,
          defaultValue: 1.05,
          summary:
              'Pushes the ramp toward cyan and white. This shader has no '
              'separate color uniform.',
        ),
        SliderParameter(
          id: 'distortion',
          label: 'Distortion',
          uniformName: 'uDistortion',
          min: 0,
          max: 2.5,
          defaultValue: 1.25,
          summary: 'Writes uDistortion, the domain-warp distance.',
        ),
      ],
      notes: const <CodeNote>[
        CodeNote(
          title: 'aspectPoint',
          body:
              'Maps a normalized position into a space where one unit in X '
              'is the same length on screen as one unit in Y. Without it, '
              'the pointer pull would be elliptical on a wide preview.',
        ),
        CodeNote(
          title: 'valueNoise and fbm',
          body:
              'A sine hash at cell corners, blended with a cubic Hermite '
              'curve, then stacked four times at roughly double frequency. '
              'The loop bound is constant because the compiler needs one.',
        ),
        CodeNote(
          title: 'auroraField',
          body:
              'Samples noise at a coordinate that was itself displaced by '
              'noise. Moving the coordinate changes which value is read. '
              'That is different from mixing colors after the fact.',
        ),
        CodeNote(
          title: 'Lighting',
          body:
              'The warp offset is reused as a slope. The normal is not the '
              'true gradient of the height field. Diffuse, a wide specular, '
              'and a rim term sell the gloss on a 2D scalar field.',
        ),
      ],
    ),
    ShaderSample(
      id: 'liquid_ripple',
      name: 'Interactive Liquid Ripple',
      summary:
          'Circular waves travel outward from the last four pointer '
          'gestures and then decay. This is a kinematic sine of distance '
          'and age, not a solved wave equation.',
      assetPath: 'shaders/liquid_ripple.frag',
      documentationAsset: 'docs/samples/LIQUID_RIPPLE.md',
      techniques: <String>['Distance', 'Waves', 'Pointer'],
      emitsRipples: true,
      previewTime: 1.2,
      stillNote: 'Still frame with two authored ripples. A live trail needs the playground.',
      interaction:
          'A drag emits into a four-slot ring when the pointer travels about '
          '0.04 aspect-corrected units. The live pointer also dents the '
          'surface immediately, before the next slot is due.',
      limitations:
          'Only four sources exist. When the 600 second clock wraps, a slot '
          'whose start time is now in the future expires. The normal is a '
          'finite difference, evaluated three times per pixel, because '
          'fragment derivatives are not reliable here.',
      uniforms: <ShaderUniform>[
        _resolution,
        _time,
        _pointer,
        _pointerActive,
        const ShaderUniform(
          index: 6,
          name: 'uAmplitude',
          type: ShaderUniformType.float,
          meaning: 'Height of each wave.',
        ),
        const ShaderUniform(
          index: 7,
          name: 'uFrequency',
          type: ShaderUniformType.float,
          meaning: 'Spatial frequency of the sine, in UV units.',
        ),
        const ShaderUniform(
          index: 8,
          name: 'uSpeed',
          type: ShaderUniformType.float,
          meaning: 'How fast the wavefront radius grows.',
        ),
        const ShaderUniform(
          index: 9,
          name: 'uDamping',
          type: ShaderUniformType.float,
          meaning: 'Exponential decay rate over age.',
        ),
        const ShaderUniform(
          index: 10,
          name: 'uColor',
          type: ShaderUniformType.vec3,
          meaning: 'Tint multiplied into the lit water, straight RGB.',
        ),
        const ShaderUniform(
          index: 13,
          name: 'uRipple0',
          type: ShaderUniformType.vec3,
          meaning: 'xy origin, z start time. z < 0 means the slot is empty.',
        ),
        const ShaderUniform(
          index: 16,
          name: 'uRipple1',
          type: ShaderUniformType.vec3,
          meaning: 'Second slot, same packing as uRipple0.',
        ),
        const ShaderUniform(
          index: 19,
          name: 'uRipple2',
          type: ShaderUniformType.vec3,
          meaning: 'Third slot, same packing as uRipple0.',
        ),
        const ShaderUniform(
          index: 22,
          name: 'uRipple3',
          type: ShaderUniformType.vec3,
          meaning: 'Fourth slot, same packing as uRipple0.',
        ),
      ],
      parameters: const <ShaderParameter>[
        SliderParameter(
          id: 'amplitude',
          label: 'Amplitude',
          uniformName: 'uAmplitude',
          min: 0,
          max: 1.5,
          defaultValue: 0.7,
          summary: 'Scales wave height and the contact dimple.',
        ),
        SliderParameter(
          id: 'frequency',
          label: 'Frequency',
          uniformName: 'uFrequency',
          min: 4,
          max: 48,
          defaultValue: 22,
          summary: 'How many crests fit into one UV unit of radius.',
        ),
        SliderParameter(
          id: 'speed',
          label: 'Speed',
          uniformName: 'uSpeed',
          min: 0,
          max: 2,
          defaultValue: 0.45,
          summary: 'Wavefront radius is age times this value.',
        ),
        SliderParameter(
          id: 'damping',
          label: 'Damping',
          uniformName: 'uDamping',
          min: 0,
          max: 3,
          defaultValue: 0.9,
          summary:
              'Exponential decay over age. Without it, old slots stay loud '
              'until the ring overwrites them.',
        ),
        ColorParameter(
          id: 'color',
          label: 'Tint',
          uniformName: 'uColor',
          defaultColor: Color(0xFF14E6CF),
          summary:
              'Straight RGB written to uColor. Alpha stays 1 in the shader.',
        ),
      ],
      notes: const <CodeNote>[
        CodeNote(
          title: 'rippleHeight',
          body:
              'Age is uTime minus the start time Dart stored. The crest sits '
              'at radius = age * speed. smoothstep keeps the undisturbed '
              'region outside that front at zero.',
        ),
        CodeNote(
          title: 'Why decay is separate',
          body:
              'The front only says whether the wave has arrived. Damping is '
              'what lets the surface go quiet. An age cap of 8 seconds also '
              'drops a slot that the wrapped clock would otherwise revive.',
        ),
        CodeNote(
          title: 'Finite-difference normal',
          body:
              'Three height evaluations per pixel, with an epsilon in '
              'aspect-corrected UV units. dFdx is not used.',
        ),
      ],
    ),
    ShaderSample(
      id: 'procedural_energy',
      name: 'Procedural Energy Core',
      summary:
          'A glowing orb with a hard circular silhouette. The sphere is the '
          'closed form of x² + y² + z² = r². This shader does not ray march.',
      assetPath: 'shaders/procedural_energy.frag',
      documentationAsset: 'docs/samples/PROCEDURAL_ENERGY.md',
      techniques: <String>['SDF', 'Lighting', 'Noise'],
      previewTime: 2,
      stillNote: 'Still frame at 2.0s. This card does not tick.',
      interaction:
          'The pointer offsets the light direction. It does not move the orb.',
      limitations:
          'The analytic normal is valid only inside the circle. Outside, the '
          'shader adds an exponential glow. There is no self-shadow. Noise '
          'runs for every fragment, including the background.',
      uniforms: <ShaderUniform>[
        _resolution,
        _time,
        _pointer,
        _pointerActive,
        const ShaderUniform(
          index: 6,
          name: 'uSpeed',
          type: ShaderUniformType.float,
          meaning: 'Animation rate of the swirl and the pulse.',
        ),
        const ShaderUniform(
          index: 7,
          name: 'uIntensity',
          type: ShaderUniformType.float,
          meaning: 'Brightness of the lit core and the glow.',
        ),
        const ShaderUniform(
          index: 8,
          name: 'uPulse',
          type: ShaderUniformType.float,
          meaning: 'How much the radius breathes.',
        ),
        const ShaderUniform(
          index: 9,
          name: 'uTurbulence',
          type: ShaderUniformType.float,
          meaning: 'Spatial frequency of the interior noise.',
        ),
        const ShaderUniform(
          index: 10,
          name: 'uColorCore',
          type: ShaderUniformType.vec3,
          meaning: 'Interior color, straight RGB.',
        ),
        const ShaderUniform(
          index: 13,
          name: 'uColorRim',
          type: ShaderUniformType.vec3,
          meaning: 'Rim and outer glow color, straight RGB.',
        ),
      ],
      parameters: const <ShaderParameter>[
        SliderParameter(
          id: 'speed',
          label: 'Speed',
          uniformName: 'uSpeed',
          min: 0,
          max: 3,
          defaultValue: 1,
          summary: 'Scales the swirl and the radius pulse.',
        ),
        SliderParameter(
          id: 'intensity',
          label: 'Intensity',
          uniformName: 'uIntensity',
          min: 0,
          max: 2,
          defaultValue: 1.1,
          summary: 'Scales the lit core and the outer glow together.',
        ),
        SliderParameter(
          id: 'pulse',
          label: 'Pulse',
          uniformName: 'uPulse',
          min: 0,
          max: 2,
          defaultValue: 1,
          summary: 'Amplitude of the sine added to the circle radius.',
        ),
        SliderParameter(
          id: 'turbulence',
          label: 'Turbulence',
          uniformName: 'uTurbulence',
          min: 0,
          max: 8,
          defaultValue: 3.2,
          summary: 'Raises the spatial frequency of the interior fBm.',
        ),
        ColorParameter(
          id: 'core',
          label: 'Core',
          uniformName: 'uColorCore',
          defaultColor: Color(0xFF0E7C86),
          summary: 'Straight RGB written to uColorCore.',
        ),
        ColorParameter(
          id: 'rim',
          label: 'Rim',
          uniformName: 'uColorRim',
          defaultColor: Color(0xFF4DBBFF),
          summary: 'Straight RGB written to uColorRim and the glow.',
        ),
      ],
      notes: const <CodeNote>[
        CodeNote(
          title: 'sdCircle',
          body:
              'Signed distance to a circle. Negative is inside. The zero set '
              'is the silhouette. No ray is cast.',
        ),
        CodeNote(
          title: 'sphereNormal',
          body:
              'z is solved from the sphere equation and normalized with x and '
              'y. Callers use it only where the distance is negative, because '
              'outside that the value under the square root would be clamped.',
        ),
        CodeNote(
          title: 'Glow',
          body:
              'exp(-distance) outside the silhouette. It is a falloff, not a '
              'volumetric integral.',
        ),
      ],
    ),
    ShaderSample(
      id: 'plasma_field',
      name: 'Plasma Field',
      summary:
          'A full-screen color field made by adding sine waves. No noise and '
          'no loops. High scale shows what the preview cannot resolve.',
      assetPath: 'shaders/plasma_field.frag',
      documentationAsset: 'docs/samples/PLASMA_FIELD.md',
      techniques: <String>['Waves', 'Color', 'UV'],
      previewTime: 1.6,
      stillNote: 'Still frame at 1.6s. This card does not tick.',
      interaction:
          'While the pointer is inside, one radial wave is centered on it. '
          'Outside, that wave uses a fixed center so the handoff stays continuous.',
      limitations:
          'Four sine terms plus the pointer term. High scale aliases because '
          'this shader does not antialias. High contrast posterizes the ramp. '
          'The pattern is not aspect-corrected; stretching with the preview '
          'is part of the scale lesson.',
      uniforms: <ShaderUniform>[
        _resolution,
        _time,
        _pointer,
        _pointerActive,
        const ShaderUniform(
          index: 6,
          name: 'uSpeed',
          type: ShaderUniformType.float,
          meaning: 'Multiplier on uTime.',
        ),
        const ShaderUniform(
          index: 7,
          name: 'uScale',
          type: ShaderUniformType.float,
          meaning: 'Spatial frequency of the sines.',
        ),
        const ShaderUniform(
          index: 8,
          name: 'uContrast',
          type: ShaderUniformType.float,
          meaning: 'Exponent applied after the waves are summed.',
        ),
        const ShaderUniform(
          index: 9,
          name: 'uColorA',
          type: ShaderUniformType.vec3,
          meaning: 'Color at the low end of the field.',
        ),
        const ShaderUniform(
          index: 12,
          name: 'uColorB',
          type: ShaderUniformType.vec3,
          meaning: 'Color through the middle of the field.',
        ),
        const ShaderUniform(
          index: 15,
          name: 'uColorC',
          type: ShaderUniformType.vec3,
          meaning: 'Color at the high end of the field.',
        ),
      ],
      parameters: const <ShaderParameter>[
        SliderParameter(
          id: 'speed',
          label: 'Speed',
          uniformName: 'uSpeed',
          min: 0,
          max: 3,
          defaultValue: 0.8,
          summary: 'Scales every temporal frequency together.',
        ),
        SliderParameter(
          id: 'scale',
          label: 'Scale',
          uniformName: 'uScale',
          min: 1,
          max: 24,
          defaultValue: 7.5,
          summary: 'Spatial frequency. High values alias on purpose.',
        ),
        SliderParameter(
          id: 'contrast',
          label: 'Contrast',
          uniformName: 'uContrast',
          min: 0.2,
          max: 2.5,
          defaultValue: 1.05,
          summary: 'Exponent on the 0..1 field. Higher spends more time at the palette ends.',
        ),
        ColorParameter(
          id: 'colorA',
          label: 'Low',
          uniformName: 'uColorA',
          defaultColor: Color(0xFF071018),
          summary: 'Straight RGB for the low end of the ramp.',
        ),
        ColorParameter(
          id: 'colorB',
          label: 'Mid',
          uniformName: 'uColorB',
          defaultColor: Color(0xFF149E90),
          summary: 'Straight RGB for the middle of the ramp.',
        ),
        ColorParameter(
          id: 'colorC',
          label: 'High',
          uniformName: 'uColorC',
          defaultColor: Color(0xFFE8F7FF),
          summary: 'Straight RGB for the high end of the ramp.',
        ),
      ],
      notes: const <CodeNote>[
        CodeNote(
          title: 'Summed sines',
          body:
              'Each sine is a stripe along a different direction. The time '
              'coefficients are not integer multiples, so the loop does not '
              'repeat after a short period.',
        ),
        CodeNote(
          title: 'Pointer term',
          body:
              'mix() blends a fixed center toward uPointer using '
              'uPointerActive, so the wave does not pop when the pointer enters.',
        ),
        CodeNote(
          title: 'Contrast',
          body:
              'The sum is mapped from [-1, 1] to [0, 1], then raised to '
              'uContrast. Color is a two-step mix along that value.',
        ),
      ],
    ),
    ShaderSample(
      id: 'domain_warp',
      name: 'Domain Warping',
      summary:
          'Noise displaces the coordinate that later noise is sampled at. '
          'Warp strength changes the shape. Color presets only recolor it.',
      assetPath: 'shaders/domain_warp.frag',
      documentationAsset: 'docs/samples/DOMAIN_WARP.md',
      techniques: <String>['Domain warp', 'Noise', 'Color'],
      previewTime: 2.8,
      stillNote: 'Still frame at 2.8s. This card does not tick.',
      interaction:
          'The pointer adds a small extra displacement near the cursor. '
          'It is there so interaction is visible without hiding the warp slider.',
      limitations:
          'The warped path evaluates fBm five times with four octaves. Warp '
          'at zero takes the cheaper branch and evaluates fBm once. The '
          'branch depends only on a uniform, so every pixel takes the same '
          'side. High warp looks stringy; it does not add samples.',
      uniforms: <ShaderUniform>[
        _resolution,
        _time,
        _pointer,
        _pointerActive,
        const ShaderUniform(
          index: 6,
          name: 'uSpeed',
          type: ShaderUniformType.float,
          meaning: 'How fast the domain scrolls.',
        ),
        const ShaderUniform(
          index: 7,
          name: 'uScale',
          type: ShaderUniformType.float,
          meaning: 'Spatial frequency before warping.',
        ),
        const ShaderUniform(
          index: 8,
          name: 'uWarp',
          type: ShaderUniformType.float,
          meaning: 'Displacement amount. Zero disables warping.',
        ),
        const ShaderUniform(
          index: 9,
          name: 'uColorA',
          type: ShaderUniformType.vec3,
          meaning: 'Low field color.',
        ),
        const ShaderUniform(
          index: 12,
          name: 'uColorB',
          type: ShaderUniformType.vec3,
          meaning: 'Mid field color.',
        ),
        const ShaderUniform(
          index: 15,
          name: 'uColorC',
          type: ShaderUniformType.vec3,
          meaning: 'High field color.',
        ),
      ],
      parameters: <ShaderParameter>[
        const SliderParameter(
          id: 'speed',
          label: 'Speed',
          uniformName: 'uSpeed',
          min: 0,
          max: 3,
          defaultValue: 0.7,
          summary: 'Scrolls the domain. It does not change warp strength.',
        ),
        const SliderParameter(
          id: 'scale',
          label: 'Scale',
          uniformName: 'uScale',
          min: 0.4,
          max: 6,
          defaultValue: 2.4,
          summary: 'Frequency of the coordinate before it is warped.',
        ),
        const SliderParameter(
          id: 'warp',
          label: 'Warp',
          uniformName: 'uWarp',
          min: 0,
          max: 2.5,
          defaultValue: 0.9,
          summary:
              'How far noise pushes the sample coordinate. Zero is plain fBm.',
        ),
        const ChoiceParameter(
          id: 'preset',
          label: 'Palette',
          defaultPresetId: 'aurora',
          colorParameterIds: <String>['colorA', 'colorB', 'colorC'],
          presets: _warpPresets,
          summary: 'Writes uColorA, uColorB, and uColorC. The shapes stay put.',
        ),
        const ColorParameter(
          id: 'colorA',
          label: 'Low',
          uniformName: 'uColorA',
          defaultColor: Color(0xFF071018),
          summary: 'Low field color. Editing it clears the preset chip.',
        ),
        const ColorParameter(
          id: 'colorB',
          label: 'Mid',
          uniformName: 'uColorB',
          defaultColor: Color(0xFF149E96),
          summary: 'Mid field color. Editing it clears the preset chip.',
        ),
        const ColorParameter(
          id: 'colorC',
          label: 'High',
          uniformName: 'uColorC',
          defaultColor: Color(0xFFE7F8FF),
          summary: 'High field color. Editing it clears the preset chip.',
        ),
      ],
      notes: const <CodeNote>[
        CodeNote(
          title: 'warpedField',
          body:
              'q is a noise vector used as an offset. r does it again at the '
              'already displaced coordinate. Two layers tangle more than one '
              'because the second offset is not aligned with the first.',
        ),
        CodeNote(
          title: 'Color after the field',
          body:
              'The palette is applied with smoothstep on the scalar field. '
              'Swapping a color does not move the shapes. Changing uWarp does, '
              'because it edits the coordinate.',
        ),
      ],
    ),
    ShaderSample(
      id: 'radial_wave',
      name: 'Radial Wave',
      summary:
          'Concentric waves around a center displace the coordinate of a '
          'second pattern. The grid moves with the rings, which is the '
          'distortion lesson.',
      assetPath: 'shaders/radial_wave.frag',
      documentationAsset: 'docs/samples/RADIAL_WAVE.md',
      techniques: <String>['Radial', 'Distortion', 'UV'],
      previewTime: 1.4,
      stillNote: 'Still frame at 1.4s. This card does not tick.',
      interaction:
          'With follow pointer on, the wave center tracks the cursor while '
          'it is inside the preview. Turn it off to place the center with '
          'the sliders.',
      limitations:
          'One sine of radius. It does not bounce off edges. Large amplitude '
          'folds the grid over itself. Attenuation keeps the corners from '
          'shimmering at high frequency. Distances are aspect-corrected, so '
          'the ring count does not change when the preview is resized.',
      uniforms: <ShaderUniform>[
        _resolution,
        _time,
        _pointer,
        _pointerActive,
        const ShaderUniform(
          index: 6,
          name: 'uFrequency',
          type: ShaderUniformType.float,
          meaning: 'How many rings fit into one UV unit.',
        ),
        const ShaderUniform(
          index: 7,
          name: 'uAmplitude',
          type: ShaderUniformType.float,
          meaning: 'How far the coordinate is pushed, in UV units.',
        ),
        const ShaderUniform(
          index: 8,
          name: 'uSpeed',
          type: ShaderUniformType.float,
          meaning: 'Phase speed of the sine.',
        ),
        const ShaderUniform(
          index: 9,
          name: 'uAttenuation',
          type: ShaderUniformType.float,
          meaning: 'How fast amplitude falls with distance.',
        ),
        const ShaderUniform(
          index: 10,
          name: 'uCenter',
          type: ShaderUniformType.vec2,
          meaning: 'Configured center, normalized, origin top-left.',
        ),
        const ShaderUniform(
          index: 12,
          name: 'uFollowPointer',
          type: ShaderUniformType.float,
          meaning:
              '1 to replace uCenter with uPointer while the pointer is active.',
        ),
        const ShaderUniform(
          index: 13,
          name: 'uColor',
          type: ShaderUniformType.vec3,
          meaning: 'Ring tint, straight RGB.',
        ),
      ],
      parameters: const <ShaderParameter>[
        SliderParameter(
          id: 'frequency',
          label: 'Frequency',
          uniformName: 'uFrequency',
          min: 2,
          max: 48,
          defaultValue: 18,
          summary: 'Ring count in aspect-corrected units, not pixels.',
        ),
        SliderParameter(
          id: 'amplitude',
          label: 'Amplitude',
          uniformName: 'uAmplitude',
          min: 0,
          max: 0.2,
          defaultValue: 0.045,
          summary: 'How far displaced sampling pushes the grid.',
        ),
        SliderParameter(
          id: 'speed',
          label: 'Speed',
          uniformName: 'uSpeed',
          min: 0,
          max: 8,
          defaultValue: 2.4,
          summary: 'Phase speed of the radial sine.',
        ),
        SliderParameter(
          id: 'attenuation',
          label: 'Attenuation',
          uniformName: 'uAttenuation',
          min: 0,
          max: 8,
          defaultValue: 1.8,
          summary: 'Exponential falloff with distance from the center.',
        ),
        SliderParameter(
          id: 'centerX',
          label: 'Center X',
          uniformName: 'uCenter',
          min: 0,
          max: 1,
          defaultValue: 0.5,
          summary: 'X component of uCenter, normalized, origin at the left.',
        ),
        SliderParameter(
          id: 'centerY',
          label: 'Center Y',
          uniformName: 'uCenter',
          min: 0,
          max: 1,
          defaultValue: 0.5,
          summary: 'Y component of uCenter, normalized, origin at the top.',
        ),
        ToggleParameter(
          id: 'followPointer',
          label: 'Center follows pointer',
          uniformName: 'uFollowPointer',
          defaultValue: true,
          summary:
              'Writes 1 or 0 to uFollowPointer. The shader mixes toward '
              'uPointer only while uPointerActive is also 1.',
        ),
        ColorParameter(
          id: 'color',
          label: 'Tint',
          uniformName: 'uColor',
          defaultColor: Color(0xFF4DBBFF),
          summary: 'Straight RGB written to uColor.',
        ),
      ],
      notes: const <CodeNote>[
        CodeNote(
          title: 'outward',
          body:
              'Unit radial direction. The center fragment returns zero so a '
              'normalize of a zero vector does not flash.',
        ),
        CodeNote(
          title: 'Displacement',
          body:
              'The grid is evaluated at p minus the radial direction times '
              'the wave. Sampling from a different place is the distortion. '
              'Large amplitude folds neighbors over each other.',
        ),
        CodeNote(
          title: 'Center selection',
          body:
              'Follow mode picks the center in normalized space, then both '
              'choices go through aspectPoint. Mixing after the aspect '
              'correction would slide the center on an ellipse.',
        ),
      ],
    ),
    ShaderSample(
      id: 'beehive_interior',
      name: 'Inside the Hive',
      summary:
          'A view from inside one honeycomb cell. Wax walls are a hexagonal '
          'tube, the far comb is a plane of cells, and the bees are ellipsoids '
          'on the same ray.',
      assetPath: 'shaders/beehive_interior.frag',
      documentationAsset: 'docs/samples/BEEHIVE_INTERIOR.md',
      techniques: <String>['Hex grid', 'Ray march', 'SDF'],
      previewTime: 1.6,
      stillNote: 'Still frame at 1.6s. This card does not tick.',
      interaction:
          'The pointer leans the camera inside the cell. The offset is '
          'clamped to a fraction of the cell radius so the ray does not '
          'start inside the wax.',
      limitations:
          'The march stops after 32 steps. The tube distance is exact, so '
          'the far comb usually ends the ray first. Bees are two ellipsoids '
          'with pulsing wings, not a simulation. They cast no shadows. A '
          'very high scale shrinks the cell until the bees intersect the walls.',
      uniforms: <ShaderUniform>[
        _resolution,
        _time,
        _pointer,
        _pointerActive,
        const ShaderUniform(
          index: 6,
          name: 'uSpeed',
          type: ShaderUniformType.float,
          meaning: 'Bee flight and honey shimmer.',
        ),
        const ShaderUniform(
          index: 7,
          name: 'uScale',
          type: ShaderUniformType.float,
          meaning: 'Spatial frequency of the comb. Larger means smaller cells.',
        ),
        const ShaderUniform(
          index: 8,
          name: 'uDepth',
          type: ShaderUniformType.float,
          meaning: 'Distance from the camera to the far comb.',
        ),
        const ShaderUniform(
          index: 9,
          name: 'uHoney',
          type: ShaderUniformType.float,
          meaning: 'How full the far cells look.',
        ),
        const ShaderUniform(
          index: 10,
          name: 'uColorWax',
          type: ShaderUniformType.vec3,
          meaning: 'Wax color, straight RGB.',
        ),
        const ShaderUniform(
          index: 13,
          name: 'uColorHoney',
          type: ShaderUniformType.vec3,
          meaning: 'Honey color, straight RGB.',
        ),
      ],
      parameters: const <ShaderParameter>[
        SliderParameter(
          id: 'speed',
          label: 'Speed',
          uniformName: 'uSpeed',
          min: 0,
          max: 2.5,
          defaultValue: 0.7,
          summary: 'Scales bee flight and the honey shimmer. The walls do not scroll.',
        ),
        SliderParameter(
          id: 'scale',
          label: 'Scale',
          uniformName: 'uScale',
          min: 0.45,
          max: 2.4,
          defaultValue: 0.85,
          summary:
              'Spatial frequency. Larger values shrink the cell you are in.',
        ),
        SliderParameter(
          id: 'depth',
          label: 'Depth',
          uniformName: 'uDepth',
          min: 0.35,
          max: 4,
          defaultValue: 1.7,
          summary: 'How far the far comb sits down the cell.',
        ),
        SliderParameter(
          id: 'honey',
          label: 'Honey',
          uniformName: 'uHoney',
          min: 0,
          max: 1,
          defaultValue: 0.72,
          summary: 'Fills the far cells. Zero leaves dark openings.',
        ),
        ColorParameter(
          id: 'wax',
          label: 'Wax',
          uniformName: 'uColorWax',
          defaultColor: Color(0xFFC47A32),
          summary: 'Straight RGB written to uColorWax.',
        ),
        ColorParameter(
          id: 'honeyColor',
          label: 'Honey color',
          uniformName: 'uColorHoney',
          defaultColor: Color(0xFFFFC14D),
          summary: 'Straight RGB written to uColorHoney.',
        ),
      ],
      notes: const <CodeNote>[
        CodeNote(
          title: 'hexLocal and sdHexagon',
          body:
              'Two offset lattices pick the nearest cell. The signed distance '
              'uses a slightly smaller apothem than the tiling, which leaves '
              'the wax gap. Swapping axes matches the grid’s vertical walls.',
        ),
        CodeNote(
          title: 'marchTube',
          body:
              'Thirty-two steps along the camera ray. The step is the tube '
              'distance divided by scale, because the distance is measured '
              'in scaled coordinates and the ray is in world units.',
        ),
        CodeNote(
          title: 'Bees',
          body:
              'rayEllipsoid scales the ray into a unit sphere. The hit is '
              'kept only when it is closer than the wax or the far comb. '
              'Wings are a flatter ellipsoid blended over that color.',
        ),
      ],
    ),
  ];

  /// The sample with [id], or null when the route is unknown.
  static ShaderSample? find(String id) {
    for (final sample in samples) {
      if (sample.id == id) {
        return sample;
      }
    }
    return null;
  }
}
