import 'dart:ui' as ui;

/// Something that can receive the ordered float uniforms of one sample.
///
/// Production code writes into a `FragmentShader` by uniform name. Tests
/// write into a recorder. Names, not hard-coded indexes, are the call site
/// so a padding change inside the shader compiler cannot silently shift
/// later values. The index tables on each sample still document the packed
/// layout Flutter uses today: non-sampler uniforms are tightly packed in
/// declaration order, with no std140 padding.
abstract interface class FloatUniformSink {
  /// Sets the float uniform [name].
  void setFloat(String name, double value);

  /// Sets the vec2 uniform [name].
  void setVec2(String name, double x, double y);

  /// Sets the vec3 uniform [name].
  void setVec3(String name, double x, double y, double z);
}

/// Binds a sink to one live `FragmentShader`.
///
/// Slots from `getUniformFloat` and its vec helpers are cached for the
/// lifetime of this object. Creating them on every frame would allocate a
/// binding object per uniform per pixel-frame even though the underlying
/// storage is a single `Float32List` on the shader.
///
/// The sink does not dispose [shader]. The canvas that created the shader
/// owns that lifetime.
class FragmentShaderSink implements FloatUniformSink {
  /// Binds [shader] and caches name lookups on first use.
  FragmentShaderSink(this.shader);

  /// The shader whose uniform buffer this sink fills.
  final ui.FragmentShader shader;
  final Map<String, ui.UniformFloatSlot> _floats =
      <String, ui.UniformFloatSlot>{};
  final Map<String, ui.UniformVec2Slot> _vec2 = <String, ui.UniformVec2Slot>{};
  final Map<String, ui.UniformVec3Slot> _vec3 = <String, ui.UniformVec3Slot>{};

  @override
  void setFloat(String name, double value) {
    (_floats[name] ??= shader.getUniformFloat(name)).set(value);
  }

  @override
  void setVec2(String name, double x, double y) {
    (_vec2[name] ??= shader.getUniformVec2(name)).set(x, y);
  }

  @override
  void setVec3(String name, double x, double y, double z) {
    (_vec3[name] ??= shader.getUniformVec3(name)).set(x, y, z);
  }
}
