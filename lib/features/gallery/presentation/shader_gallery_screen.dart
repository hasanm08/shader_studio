import 'package:flutter/material.dart';
import 'package:shader_studio/app/routing/app_router.dart';
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
                  padding: EdgeInsets.fromLTRB(padding, 20, padding, 8),
                  child: const _ShapeMorphingCard(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding, 12, padding, 8),
                  child: const _CardFlipCard(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding, 12, padding, 8),
                  child: const _GlassRefractionCard(),
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

class _ShapeMorphingCard extends StatelessWidget {
  const _ShapeMorphingCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        onTap: () {
          Navigator.of(context).pushNamed(AppRouter.shapeMorphing);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color(0xFF2DD4BF),
                      Color(0xFF14B8A6),
                      Color(0xFF0F766E),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shape Morphing',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Contour interpolation between geometric shapes. '
                      'Circle → star and beyond — no shaders required.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardFlipCard extends StatelessWidget {
  const _CardFlipCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        onTap: () {
          Navigator.of(context).pushNamed(AppRouter.cardFlip);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color(0xFF5EEAD4),
                      Color(0xFF14B8A6),
                      Color(0xFF0F766E),
                    ],
                  ),
                  border: Border.all(color: const Color(0x665EEAD4)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '3D Card Flip',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chamfered card, quarter-turn cube, and an add-to-basket '
                      'drop that shuts the lid.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassRefractionCard extends StatelessWidget {
  const _GlassRefractionCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        onTap: () {
          Navigator.of(context).pushNamed(AppRouter.glassRefraction);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(14)),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color(0xAAE8FBFF),
                      Color(0x6614E6CF),
                      Color(0x334DBBFF),
                    ],
                  ),
                  border: Border.all(color: const Color(0x88E8FBFF)),
                ),
                child: const Icon(
                  Icons.blur_on,
                  color: Color(0xFFE8FBFF),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Glass Refraction',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Captured background, GLSL lens bend, Fresnel rims — '
                      'a reusable GlassRefraction component.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
