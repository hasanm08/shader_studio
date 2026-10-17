import 'package:flutter/material.dart';
import 'package:shader_studio/features/gallery/presentation/shader_gallery_screen.dart';
import 'package:shader_studio/features/playground/data/shader_sample_registry.dart';
import 'package:shader_studio/features/samples/presentation/shader_sample_screen.dart';

/// Named routes for the gallery and one playground per sample id.
abstract final class AppRouter {
  /// Gallery route.
  static const String gallery = '/';

  /// Prefix for `/playground/<sample id>`.
  static const String playground = '/playground';

  /// Builds the page for [settings].
  static Route<void> onGenerate(RouteSettings settings) {
    final name = settings.name ?? gallery;
    if (name == gallery) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => const ShaderGalleryScreen(),
      );
    }
    const prefix = '$playground/';
    if (name.startsWith(prefix)) {
      final id = Uri.decodeComponent(name.substring(prefix.length));
      final sample = ShaderSampleRegistry.find(id);
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) {
          if (sample == null) {
            return _MissingSample(sampleId: id);
          }
          return ShaderSampleScreen(sample: sample);
        },
      );
    }
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => const ShaderGalleryScreen(),
    );
  }
}

class _MissingSample extends StatelessWidget {
  const _MissingSample({required this.sampleId});

  final String sampleId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shader Studio')),
      body: Center(child: Text('No sample named $sampleId')),
    );
  }
}
