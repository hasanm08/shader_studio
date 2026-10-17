import 'package:shader_studio/features/playground/domain/shader_documentation.dart';
import 'package:shader_studio/features/playground/domain/shader_parameter.dart';

/// Metadata for one gallery entry.
///
/// The sample describes the shader. It does not own time, pointer position,
/// or the current slider values. Those live on `ShaderSampleController`,
/// because two previews of the same sample can be in different states.
class ShaderSample {
  /// Creates sample metadata.
  const ShaderSample({
    required this.id,
    required this.name,
    required this.summary,
    required this.assetPath,
    required this.documentationAsset,
    required this.techniques,
    required this.uniforms,
    required this.parameters,
    required this.previewTime,
    required this.interaction,
    required this.limitations,
    required this.notes,
    required this.stillNote,
    this.emitsRipples = false,
    this.featured = false,
  });

  /// Stable route id, also the marker in the uniform-writer source.
  final String id;

  /// Name shown in the gallery and the playground title.
  final String name;

  /// One or two sentences on the card and the info panel.
  final String summary;

  /// `FragmentProgram.fromAsset` key and the text asset for the code panel.
  final String assetPath;

  /// Markdown asset opened from the code panel.
  final String documentationAsset;

  /// Short technique labels such as noise or SDF.
  final List<String> techniques;

  /// Packed uniform contract, declaration order.
  final List<ShaderUniform> uniforms;

  /// Controls. Every slider here is read by that sample's writer.
  final List<ShaderParameter> parameters;

  /// Seconds shown in a paused gallery thumbnail.
  final double previewTime;

  /// How pointer input is supposed to affect this shader.
  final String interaction;

  /// What the shader does not do.
  final String limitations;

  /// Section notes for the code panel.
  final List<CodeNote> notes;

  /// Caption under a gallery thumbnail that is not ticking.
  final String stillNote;

  /// True only for the ripple sample, which stores four wave origins.
  final bool emitsRipples;

  /// True for the gallery hero.
  final bool featured;

  /// The parameter whose [ShaderParameter.id] is [id], or null.
  ShaderParameter? parameter(String id) {
    for (final parameter in parameters) {
      if (parameter.id == id) {
        return parameter;
      }
    }
    return null;
  }
}
