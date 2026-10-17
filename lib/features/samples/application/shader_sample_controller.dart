import 'package:flutter/material.dart';
import 'package:shader_studio/core/rendering/shader_controller.dart';
import 'package:shader_studio/features/playground/domain/shader_parameter.dart';
import 'package:shader_studio/features/playground/domain/shader_sample.dart';

/// Parameter state for one open sample, plus the shared clock.
///
/// Scalar and color values are clamped to the ranges declared on the sample
/// before listeners are told. A repaint reads those maps. It does not rebuild
/// the shader program. Pause, resume, and reset do not allocate a second
/// ticker; the canvas owns the only ticker and asks [addDelta] for time.
class ShaderSampleController extends ShaderController {
  /// Creates a controller at the sample's default parameters.
  ShaderSampleController({required this.sample, super.playing}) {
    _applyDefaults();
  }

  /// Paused controller at [ShaderSample.previewTime], with ripple stills seeded.
  factory ShaderSampleController.still(ShaderSample sample) {
    final controller = ShaderSampleController(sample: sample, playing: false);
    controller.timeSeconds = sample.previewTime;
    if (sample.emitsRipples) {
      controller.ripples.seedPreview(sample.previewTime);
    }
    return controller;
  }

  /// The sample whose ranges and uniforms this controller edits.
  final ShaderSample sample;

  final Map<String, double> _scalars = <String, double>{};
  final Map<String, Color> _colors = <String, Color>{};

  /// Selected domain-warp preset, or null after the user edits a color.
  String? selectedPresetId;

  /// Current finite value of a slider or toggle.
  ///
  /// Toggles are stored as 0 or 1. Throws if [id] is not a scalar parameter.
  double scalar(String id) {
    final value = _scalars[id];
    if (value == null) {
      throw ArgumentError('Unknown scalar parameter $id');
    }
    return value;
  }

  /// Current color for a color parameter. Throws if [id] is unknown.
  Color colorOf(String id) {
    final value = _colors[id];
    if (value == null) {
      throw ArgumentError('Unknown color parameter $id');
    }
    return value;
  }

  /// Clamps [value] into the slider range, or snaps a toggle to 0 or 1.
  ///
  /// Non-finite values are ignored. An unchanged value does not notify.
  void setScalar(String id, double value) {
    if (!value.isFinite) {
      return;
    }
    final parameter = sample.parameter(id);
    final double next;
    if (parameter is SliderParameter) {
      next = value.clamp(parameter.min, parameter.max).toDouble();
    } else if (parameter is ToggleParameter) {
      next = value >= 0.5 ? 1 : 0;
    } else {
      throw ArgumentError('$id is not a scalar parameter');
    }
    if (_scalars[id] == next) {
      return;
    }
    _scalars[id] = next;
    controlsTick.ping();
    paintTick.ping();
  }

  /// Replaces a color uniform's RGB. Straight alpha is ignored.
  ///
  /// Clears [selectedPresetId] so a preset chip does not claim a palette
  /// the user has since edited.
  void setColor(String id, Color color) {
    if (sample.parameter(id) is! ColorParameter) {
      throw ArgumentError('$id is not a color parameter');
    }
    if (_colors[id] == color) {
      return;
    }
    _colors[id] = color;
    selectedPresetId = null;
    controlsTick.ping();
    paintTick.ping();
  }

  /// Writes a preset into the color parameters it owns.
  void selectPreset(String presetId) {
    final choice = sample.parameters.whereType<ChoiceParameter>().first;
    ColorPreset? preset;
    for (final candidate in choice.presets) {
      if (candidate.id == presetId) {
        preset = candidate;
        break;
      }
    }
    if (preset == null) {
      throw ArgumentError('Unknown preset $presetId');
    }
    if (preset.colors.length != choice.colorParameterIds.length) {
      throw StateError('Preset $presetId does not match the color slots');
    }
    for (var i = 0; i < choice.colorParameterIds.length; i++) {
      _colors[choice.colorParameterIds[i]] = preset.colors[i];
    }
    selectedPresetId = presetId;
    controlsTick.ping();
    paintTick.ping();
  }

  /// Enables or disables pointer influence without moving the last position.
  @override
  void setInteractionEnabled(bool value) {
    if (interactionEnabled == value) {
      return;
    }
    super.setInteractionEnabled(value);
    controlsTick.ping();
    paintTick.ping();
  }

  /// Restores defaults, clears ripples, and zeroes the clock.
  ///
  /// The pointer returns to the center and is marked inactive, so the next
  /// picture matches a freshly opened sample.
  void reset() {
    _applyDefaults();
    pointer = const Offset(0.5, 0.5);
    pointerActive = false;
    ripples.clear();
    resetClock();
    controlsTick.ping();
    paintTick.ping();
    pointerTick.ping();
  }

  void _applyDefaults() {
    _scalars.clear();
    _colors.clear();
    selectedPresetId = null;
    interactionEnabled = true;
    for (final parameter in sample.parameters) {
      if (parameter is SliderParameter) {
        _scalars[parameter.id] = parameter.defaultValue;
      } else if (parameter is ToggleParameter) {
        _scalars[parameter.id] = parameter.defaultValue ? 1 : 0;
      } else if (parameter is ColorParameter) {
        _colors[parameter.id] = parameter.defaultColor;
      }
    }
    for (final parameter in sample.parameters.whereType<ChoiceParameter>()) {
      selectedPresetId = parameter.defaultPresetId;
      ColorPreset? preset;
      for (final candidate in parameter.presets) {
        if (candidate.id == parameter.defaultPresetId) {
          preset = candidate;
          break;
        }
      }
      if (preset == null) {
        continue;
      }
      for (var i = 0; i < parameter.colorParameterIds.length; i++) {
        _colors[parameter.colorParameterIds[i]] = preset.colors[i];
      }
    }
  }
}
