import 'package:flutter/material.dart';
import 'package:shader_studio/app/theme/app_theme.dart';
import 'package:shader_studio/features/gallery/presentation/widgets/featured_shader_card.dart';
import 'package:shader_studio/features/gallery/presentation/widgets/shader_sample_card.dart';
import 'package:shader_studio/features/playground/data/shader_sample_registry.dart';

/// Home screen: branding, a live featured shader, and a sample grid.
///
/// Grid previews are paused single frames so six full-screen shaders are
/// not all animated off to the side of the hero. The hero animates until
/// the user opens a sample; the covered route then disables its ticker.
class ShaderGalleryScreen extends StatelessWidget {
  /// Creates the gallery.
  const ShaderGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final samples = ShaderSampleRegistry.samples;
    final featured = samples.firstWhere((sample) => sample.featured);
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final padding = width >= 1100 ? 40.0 : 20.0;
          final columns = width >= 1100 ? 3 : (width >= 720 ? 2 : 1);
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding, 28, padding, 8),
                  child: const _BrandHeader(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding, 12, padding, 8),
                  child: FeaturedShaderCard(sample: featured),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding, 28, padding, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Samples',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Each card is a compiled shader at a fixed time. '
                        'Only the featured preview ticks. Open a sample for '
                        'controls, pointer input, and the source.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(padding, 0, padding, 32),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    mainAxisExtent: 360,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return ShaderSampleCard(sample: samples[index]);
                  }, childCount: samples.length),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          child: SizedBox(width: 14, height: 36),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shader Studio',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'GLSL effects Flutter widgets cannot draw on their own. '
                'Fragment shaders, live uniforms, and the math in the source.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
