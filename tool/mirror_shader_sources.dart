import 'dart:io';

/// Writes `lib/features/playground/data/shader_sources.dart` from `shaders/`.
///
/// Flutter will not bundle a file that is both a shader and an asset, so the
/// viewer needs this mirror. `test/shader_contract_test.dart` checks it.
void main() {
  final files =
      Directory('shaders').listSync().whereType<File>().where((file) {
        return file.path.endsWith('.frag');
      }).toList()..sort((a, b) => a.path.compareTo(b.path));

  final buffer = StringBuffer()
    ..writeln('// Shader text mirrored for the in-app viewer.')
    ..writeln('//')
    ..writeln('// Flutter rejects a file listed under both flutter/shaders')
    ..writeln('// and flutter/assets. The .frag files remain the compiled')
    ..writeln('// source of truth. Regenerate this file with')
    ..writeln('// `dart run tool/mirror_shader_sources.dart` after editing')
    ..writeln('// a shader. The contract test fails if the mirror drifts.')
    ..writeln('abstract final class ShaderSources {')
    ..writeln('  /// GLSL text keyed by the pubspec shader path.')
    ..writeln('  static const Map<String, String> byAsset = <String, String>{');

  for (final file in files) {
    final name = file.uri.pathSegments.last;
    final text = file.readAsStringSync();
    if (text.contains("'''")) {
      throw StateError('triple quote in $name');
    }
    buffer
      ..writeln("    'shaders/$name': r'''")
      ..write(text);
    if (!text.endsWith('\n')) {
      buffer.writeln();
    }
    buffer.writeln("''',");
  }

  buffer
    ..writeln('  };')
    ..writeln('}');

  File(
    'lib/features/playground/data/shader_sources.dart',
  ).writeAsStringSync(buffer.toString());
}
