import 'dart:ui' as ui;

import 'package:shader_studio/core/rendering/shader_error.dart';

/// Loads and caches compiled fragment programs.
///
/// `FragmentProgram.fromAsset` asks Flutter for the shader produced from a
/// file listed under `flutter: shaders` in `pubspec.yaml`. The key is the
/// same path, for example `shaders/liquid_aurora.frag`. The engine keeps a
/// process-wide copy of each program that loaded successfully, because the
/// native shader stays alive until shutdown. This class adds a second cache
/// of the [Future] itself so two widgets that mount together share one
/// in-flight load instead of starting two.
///
/// A failed load is removed from this cache. The next call tries again.
/// There is no Dart API to dispose a `FragmentProgram`; ownership of the
/// program ends with the process. Per-frame `FragmentShader` instances
/// created from the program are owned by the widget that paints them.
class ShaderLoader {
  /// Creates a loader.
  ///
  /// [loadProgram] replaces `FragmentProgram.fromAsset` in tests that should
  /// not compile a shader.
  ShaderLoader({
    Future<ui.FragmentProgram> Function(String assetPath)? loadProgram,
  }) : _loadProgram = loadProgram ?? ui.FragmentProgram.fromAsset;

  final Future<ui.FragmentProgram> Function(String assetPath) _loadProgram;
  final Map<String, Future<ui.FragmentProgram>> _cache =
      <String, Future<ui.FragmentProgram>>{};

  /// Returns the compiled program for [assetPath], reusing a cached future.
  Future<ui.FragmentProgram> load(String assetPath) {
    final cached = _cache[assetPath];
    if (cached != null) {
      return cached;
    }
    final future = _load(assetPath);
    _cache[assetPath] = future;
    return future;
  }

  Future<ui.FragmentProgram> _load(String assetPath) async {
    try {
      return await _loadProgram(assetPath);
    } catch (error) {
      _cache.remove(assetPath);
      throw ShaderLoadException(assetPath, error);
    }
  }
}
