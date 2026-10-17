import 'package:flutter/material.dart';
import 'package:shader_studio/app/theme/app_theme.dart';
import 'package:shader_studio/core/widgets/section_header.dart';
import 'package:shader_studio/features/playground/domain/shader_sample.dart';

/// Technique summary and the uniform table for [sample].
///
/// [compact] wraps the longer sections in expansion tiles so a phone layout
/// can keep the preview on screen. The table is the same data the writer
/// and the `.frag` header agree on. No image samplers are used.
class ShaderInfoPanel extends StatelessWidget {
  /// Creates the info panel.
  const ShaderInfoPanel({
    required this.sample,
    this.compact = false,
    super.key,
  });

  /// Sample being described.
  final ShaderSample sample;

  /// When true, uniforms and limitations start collapsed.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(sample.summary, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final technique in sample.techniques)
              Chip(
                label: Text(technique),
                visualDensity: VisualDensity.compact,
                backgroundColor: AppColors.surfaceHigh,
                side: const BorderSide(color: AppColors.border),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Interaction', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(sample.interaction, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
    final uniforms = _UniformTable(sample: sample);
    final limits = Text(
      sample.limitations,
      style: Theme.of(context).textTheme.bodySmall,
    );
    if (!compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Technique'),
          body,
          const SizedBox(height: 16),
          const SectionHeader(title: 'Uniforms'),
          uniforms,
          const SizedBox(height: 16),
          const SectionHeader(title: 'Limitations'),
          limits,
        ],
      );
    }
    return Column(
      children: [
        body,
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Uniforms'),
          children: [uniforms],
        ),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Limitations'),
          children: [Align(alignment: Alignment.centerLeft, child: limits)],
        ),
      ],
    );
  }
}

class _UniformTable extends StatelessWidget {
  const _UniformTable({required this.sample});

  final ShaderSample sample;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Index    Type     Name', style: style),
          const SizedBox(height: 4),
          for (final uniform in sample.uniforms)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${uniform.index.toString().padLeft(2)}'
                '    ${uniform.type.name.padRight(6)}'
                '${uniform.name.padRight(16)}'
                '${uniform.meaning}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: AppColors.textMuted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          Text(
            'No samplers. Colors are straight RGB, not premultiplied.',
            style: style,
          ),
        ],
      ),
    );
  }
}
