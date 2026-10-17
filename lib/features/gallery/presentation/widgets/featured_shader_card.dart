import 'package:flutter/material.dart';
import 'package:shader_studio/app/routing/app_router.dart';
import 'package:shader_studio/app/theme/app_theme.dart';
import 'package:shader_studio/features/playground/domain/shader_sample.dart';
import 'package:shader_studio/features/playground/presentation/widgets/shader_preview.dart';
import 'package:shader_studio/features/samples/application/shader_sample_controller.dart';

/// Live hero for the featured sample.
///
/// This card owns a controller and lets the preview tick. Grid cards do not.
/// Reduced motion starts the hero paused. A covered route disables ticker
/// mode, so the hero stops spending frames while a playground is open.
class FeaturedShaderCard extends StatefulWidget {
  /// Creates the hero for [sample].
  const FeaturedShaderCard({required this.sample, super.key});

  /// Featured sample, normally Living Liquid Aurora.
  final ShaderSample sample;

  @override
  State<FeaturedShaderCard> createState() => _FeaturedShaderCardState();
}

class _FeaturedShaderCardState extends State<FeaturedShaderCard> {
  late final ShaderSampleController _controller = ShaderSampleController(
    sample: widget.sample,
  );
  var _appliedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_appliedMotion) {
      return;
    }
    _appliedMotion = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.playing = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 800;
            final preview = ShaderPreview(
              controller: _controller,
              interactive: true,
            );
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FEATURED',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.accent, letterSpacing: 1.4),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.sample.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.sample.summary,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final technique in widget.sample.techniques)
                      Text(
                        technique,
                        style: const TextStyle(
                          color: AppColors.accentSecondary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushNamed('${AppRouter.playground}/${widget.sample.id}');
                  },
                  child: const Text('Open playground'),
                ),
              ],
            );
            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 280, child: preview),
                  const SizedBox(height: 16),
                  copy,
                ],
              );
            }
            return SizedBox(
              height: 360,
              child: Row(
                children: [
                  Expanded(flex: 3, child: preview),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: copy),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
