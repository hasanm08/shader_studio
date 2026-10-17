import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shader_studio/features/playground/data/shader_sample_registry.dart';
import 'package:shader_studio/features/playground/data/shader_sources.dart';
import 'package:shader_studio/features/playground/domain/shader_parameter.dart';

void main() {
  test('registry ids, ranges, and packed indexes are consistent', () {
    final ids = <String>{};
    for (final sample in ShaderSampleRegistry.samples) {
      expect(ids.add(sample.id), isTrue, reason: 'duplicate ${sample.id}');
      expect(
        File(sample.assetPath).existsSync(),
        isTrue,
        reason: sample.assetPath,
      );
      expect(File(sample.documentationAsset).existsSync(), isTrue);
      var cursor = 0;
      for (final uniform in sample.uniforms) {
        expect(uniform.index, cursor, reason: '${sample.id}.${uniform.name}');
        cursor += uniform.type.floatCount;
      }
      for (final parameter in sample.parameters) {
        if (parameter is SliderParameter) {
          expect(
            parameter.defaultValue,
            inInclusiveRange(parameter.min, parameter.max),
          );
          expect(parameter.max, greaterThan(parameter.min));
        }
      }
    }
    expect(
      ShaderSampleRegistry.samples.where((sample) => sample.featured),
      hasLength(1),
    );
    expect(ShaderSampleRegistry.samples, hasLength(7));
  });

  test('glsl declarations and header indexes match the registry', () {
    final uniformPattern = RegExp(
      r'^uniform\s+(float|vec2|vec3|vec4)\s+(\w+)\s*;',
      multiLine: true,
    );
    final headerPattern = RegExp(
      r'^//\s+(\d+)\s+(float|vec2|vec3|vec4)\s+(\w+)\s+.+$',
      multiLine: true,
    );
    for (final sample in ShaderSampleRegistry.samples) {
      final source = File(sample.assetPath).readAsStringSync();
      final declared = uniformPattern.allMatches(source).map((match) {
        return (type: match.group(1)!, name: match.group(2)!);
      }).toList();
      expect(
        declared.map((entry) => entry.name),
        sample.uniforms.map((u) => u.name),
      );
      for (var i = 0; i < declared.length; i++) {
        expect(
          declared[i].type,
          sample.uniforms[i].type.name,
          reason: sample.id,
        );
      }
      final headers = headerPattern.allMatches(source).map((match) {
        return (
          index: int.parse(match.group(1)!),
          type: match.group(2)!,
          name: match.group(3)!,
        );
      }).toList();
      expect(headers, hasLength(sample.uniforms.length), reason: sample.id);
      for (var i = 0; i < headers.length; i++) {
        expect(headers[i].index, sample.uniforms[i].index, reason: sample.id);
        expect(headers[i].name, sample.uniforms[i].name, reason: sample.id);
        expect(
          headers[i].type,
          sample.uniforms[i].type.name,
          reason: sample.id,
        );
      }
    }
  });

  test('pubspec registers shaders and the source mirror matches', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final shaders = _section(pubspec, 'shaders:');
    final assets = _section(pubspec, 'assets:');
    for (final sample in ShaderSampleRegistry.samples) {
      expect(shaders, contains(sample.assetPath));
      expect(assets, isNot(contains(sample.assetPath)));
      expect(assets, contains(sample.documentationAsset));
      expect(
        ShaderSources.byAsset[sample.assetPath],
        File(sample.assetPath).readAsStringSync(),
        reason:
            '${sample.assetPath} drifted. Run dart run tool/mirror_shader_sources.dart',
      );
    }
    expect(
      assets,
      contains('lib/features/samples/application/shader_uniform_writers.dart'),
    );
  });
}

List<String> _section(String pubspec, String header) {
  final lines = pubspec.split('\n');
  final values = <String>[];
  var collecting = false;
  for (final raw in lines) {
    final line = raw.split('#').first;
    if (line.trim() == header) {
      collecting = true;
      continue;
    }
    if (!collecting) {
      continue;
    }
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      continue;
    }
    if (!trimmed.startsWith('- ')) {
      break;
    }
    values.add(trimmed.substring(2).trim());
  }
  return values;
}
