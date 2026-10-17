import 'package:flutter/material.dart';
import 'package:shader_studio/core/rendering/shader_loader.dart';

/// Exposes the process-wide [ShaderLoader] to canvases.
class ShaderStudioScope extends InheritedWidget {
  /// Shares [loader] with [child].
  const ShaderStudioScope({
    required this.loader,
    required super.child,
    super.key,
  });

  /// Loader used by every shader canvas under this scope.
  final ShaderLoader loader;

  /// The loader from the nearest scope.
  static ShaderLoader of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ShaderStudioScope>();
    assert(scope != null, 'ShaderStudioScope is missing above this context');
    return scope!.loader;
  }

  @override
  bool updateShouldNotify(ShaderStudioScope oldWidget) {
    return loader != oldWidget.loader;
  }
}
