import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shader_studio/app/theme/app_theme.dart';
import 'package:shader_studio/core/widgets/section_header.dart';
import 'package:shader_studio/features/playground/data/shader_sources.dart';
import 'package:shader_studio/features/playground/domain/shader_sample.dart';
import 'package:shader_studio/features/playground/presentation/documentation_screen.dart';

/// Scrollable viewer for the shader source and its Dart writer.
///
/// Flutter will not bundle a path that is both a shader and an asset, so the
/// GLSL text comes from [ShaderSources], a mirror of `shaders/`. The contract
/// test fails when that mirror drifts. The Dart excerpt is sliced out of the
/// real `shader_uniform_writers.dart` asset between `BEGIN` and `END` markers.
///
/// Highlighting is a small tokenizer for comments, types, and numbers. It
/// is not a full GLSL parser.
class ShaderCodePanel extends StatefulWidget {
  /// Creates a code panel for [sample].
  const ShaderCodePanel({required this.sample, super.key});

  /// Sample whose asset and writer marker are shown.
  final ShaderSample sample;

  @override
  State<ShaderCodePanel> createState() => _ShaderCodePanelState();
}

class _ShaderCodePanelState extends State<ShaderCodePanel> {
  late final Future<_Sources> _future = _load();

  Future<_Sources> _load() async {
    final shader = ShaderSources.byAsset[widget.sample.assetPath];
    if (shader == null) {
      throw StateError('No mirrored source for ${widget.sample.assetPath}');
    }
    final dartSource = await rootBundle.loadString(
      'lib/features/samples/application/shader_uniform_writers.dart',
    );
    return _Sources(shader, _extract(dartSource, widget.sample.id));
  }

  static String _extract(String source, String id) {
    final start = source.indexOf('// BEGIN $id');
    final end = source.indexOf('// END $id');
    if (start < 0 || end <= start) {
      return source;
    }
    return source.substring(start, end).trim();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Source',
          subtitle: 'Loaded from the asset bundle, not a second copy.',
        ),
        FutureBuilder<_Sources>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                'Could not read source: ${snapshot.error}',
                style: Theme.of(context).textTheme.bodySmall,
              );
            }
            final sources = snapshot.data;
            if (sources == null) {
              return const LinearProgressIndicator(color: AppColors.accent);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SourceBlock(
                  fileName: widget.sample.assetPath,
                  language: 'GLSL',
                  source: sources.shader,
                ),
                const SizedBox(height: 12),
                _SourceBlock(
                  fileName: 'lib/features/samples/application/shader_uniform_writers.dart',
                  language: 'Dart',
                  source: sources.dartWriter,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        for (final note in widget.sample.notes) ...[
          Text(note.title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(note.body, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => DocumentationScreen(
                    title: widget.sample.name,
                    assetPath: widget.sample.documentationAsset,
                  ),
                ),
              );
            },
            child: const Text('Open documentation'),
          ),
        ),
      ],
    );
  }
}

class _Sources {
  const _Sources(this.shader, this.dartWriter);

  final String shader;
  final String dartWriter;
}

class _SourceBlock extends StatelessWidget {
  const _SourceBlock({
    required this.fileName,
    required this.language,
    required this.source,
  });

  final String fileName;
  final String language;
  final String source;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Text(
              '$language  ·  $fileName',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          SizedBox(
            height: 280,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: SelectableText.rich(_highlight(source)),
            ),
          ),
        ],
      ),
    );
  }
}

final RegExp _token = RegExp(
  r'//.*?$|#.*?\n|\b(?:uniform|float|vec2|vec3|vec4|mat2|void|return|if|else|for|const|out|in|precision|highp|mediump|break|continue)\b|\b\d+(?:\.\d+)?\b',
  multiLine: true,
);

TextSpan _highlight(String source) {
  const base = TextStyle(
    fontFamily: 'monospace',
    color: AppColors.text,
    fontSize: 12,
    height: 1.45,
  );
  final spans = <TextSpan>[];
  var cursor = 0;
  for (final match in _token.allMatches(source)) {
    if (match.start > cursor) {
      spans.add(TextSpan(text: source.substring(cursor, match.start)));
    }
    final text = match.group(0) ?? '';
    Color color = AppColors.accentSecondary;
    if (text.startsWith('//') || text.startsWith('#')) {
      color = AppColors.textMuted;
    } else if (RegExp(r'^\d').hasMatch(text)) {
      color = AppColors.accent;
    }
    spans.add(
      TextSpan(
        text: text,
        style: TextStyle(color: color),
      ),
    );
    cursor = match.end;
  }
  if (cursor < source.length) {
    spans.add(TextSpan(text: source.substring(cursor)));
  }
  return TextSpan(style: base, children: spans);
}
