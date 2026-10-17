/// A shader asset failed to compile or could not be read.
///
/// `ShaderLoader` throws this after removing the failed future from its cache,
/// so a later retry calls `FragmentProgram.fromAsset` again. The engine may
/// still remember a successful program for the process lifetime; this type
/// only describes the Dart-side failure the UI can show.
class ShaderLoadException implements Exception {
  /// Creates an exception for [assetPath] wrapping [cause].
  ShaderLoadException(this.assetPath, this.cause);

  /// The `shaders/...` key passed to `FragmentProgram.fromAsset`.
  final String assetPath;

  /// The underlying error from the Flutter shader loader.
  final Object cause;

  @override
  String toString() => 'Failed to load shader $assetPath: $cause';
}
