import 'package:shader_studio/core/rendering/shader_uniforms.dart';

/// Records uniform writes for tests that do not create a `FragmentShader`.
class RecordingUniformSink implements FloatUniformSink {
  /// Values written, keyed by GLSL name.
  final Map<String, List<double>> values = <String, List<double>>{};

  @override
  void setFloat(String name, double value) {
    values[name] = <double>[value];
  }

  @override
  void setVec2(String name, double x, double y) {
    values[name] = <double>[x, y];
  }

  @override
  void setVec3(String name, double x, double y, double z) {
    values[name] = <double>[x, y, z];
  }
}
