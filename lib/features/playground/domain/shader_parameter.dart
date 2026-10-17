import 'package:flutter/material.dart';

/// GLSL type of one uniform, used to compute its packed float width.
enum ShaderUniformType {
  /// A single float.
  float,

  /// Two floats.
  vec2,

  /// Three floats.
  vec3,
}

/// How many `setFloat` slots a value of this type occupies.
extension ShaderUniformTypeLayout on ShaderUniformType {
  /// Packed float count. Flutter does not insert std140 padding.
  int get floatCount {
    switch (this) {
      case ShaderUniformType.float:
        return 1;
      case ShaderUniformType.vec2:
        return 2;
      case ShaderUniformType.vec3:
        return 3;
    }
  }
}

/// One uniform in a sample's packed layout.
///
/// [index] is the first float index if the values were written with
/// `FragmentShader.setFloat` in declaration order. The app binds by name;
/// the index is the documented contract and the value tests check against
/// the comment table at the top of each `.frag` file.
class ShaderUniform {
  /// Creates a uniform contract entry.
  const ShaderUniform({
    required this.index,
    required this.name,
    required this.type,
    required this.meaning,
  });

  /// First packed float index.
  final int index;

  /// GLSL uniform name.
  final String name;

  /// GLSL type.
  final ShaderUniformType type;

  /// What the shader reads this value for.
  final String meaning;
}

/// A control that edits one piece of sample state.
///
/// Subclasses name the uniform they write. Changing a control updates the
/// controller and repaints. It does not compile the shader again.
sealed class ShaderParameter {
  /// Creates a control labeled [label].
  const ShaderParameter({
    required this.id,
    required this.label,
    required this.summary,
  });

  /// Stable id used by the controller map.
  final String id;

  /// Short label shown beside the control.
  final String label;

  /// What changing the control does to the picture.
  final String summary;
}

/// A continuous float uniform.
class SliderParameter extends ShaderParameter {
  /// Creates a slider bound to [uniformName].
  const SliderParameter({
    required super.id,
    required super.label,
    required super.summary,
    required this.uniformName,
    required this.min,
    required this.max,
    required this.defaultValue,
  });

  /// GLSL float uniform written by the sample's uniform writer.
  ///
  /// Center sliders share `uCenter` and are packed by the writer as one vec2.
  /// Their summaries say which component they own.
  final String uniformName;

  /// Inclusive lower bound. Values outside this are clamped.
  final double min;

  /// Inclusive upper bound. Values outside this are clamped.
  final double max;

  /// Value used by reset and by gallery stills.
  final double defaultValue;
}

/// A vec3 color uniform edited as straight RGB, not premultiplied.
class ColorParameter extends ShaderParameter {
  /// Creates a color control bound to [uniformName].
  const ColorParameter({
    required super.id,
    required super.label,
    required super.summary,
    required this.uniformName,
    required this.defaultColor,
  });

  /// GLSL vec3 uniform. Alpha is not sent; the shader writes alpha itself.
  final String uniformName;

  /// Starting color. Components are read back as 0..1 floats.
  final Color defaultColor;
}

/// A uniform written as 0 or 1.
class ToggleParameter extends ShaderParameter {
  /// Creates a switch bound to [uniformName].
  const ToggleParameter({
    required super.id,
    required super.label,
    required super.summary,
    required this.uniformName,
    required this.defaultValue,
  });

  /// GLSL float uniform. The writer sends 1 when enabled and 0 otherwise.
  final String uniformName;

  /// Starting state.
  final bool defaultValue;
}

/// A named trio of colors for the domain-warp palette.
class ColorPreset {
  /// Creates a preset that fills three color parameters.
  const ColorPreset({
    required this.id,
    required this.label,
    required this.colors,
  });

  /// Stable id.
  final String id;

  /// Chip label.
  final String label;

  /// Three colors, in the order of [ChoiceParameter.colorParameterIds].
  final List<Color> colors;
}

/// A chip set that assigns several color uniforms at once.
///
/// The choice itself is not a GLSL uniform. It writes the color parameters
/// named by [colorParameterIds]. Recoloring does not move the pattern;
/// warp strength does.
class ChoiceParameter extends ShaderParameter {
  /// Creates a preset selector.
  const ChoiceParameter({
    required super.id,
    required super.label,
    required super.summary,
    required this.presets,
    required this.colorParameterIds,
    required this.defaultPresetId,
  });

  /// Available palettes.
  final List<ColorPreset> presets;

  /// Color parameter ids, in the same order as [ColorPreset.colors].
  final List<String> colorParameterIds;

  /// Preset applied on reset.
  final String defaultPresetId;
}
