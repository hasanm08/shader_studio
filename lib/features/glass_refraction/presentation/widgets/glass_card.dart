import 'package:flutter/material.dart';
import 'package:shader_studio/app/theme/app_theme.dart';
import 'package:shader_studio/features/glass_refraction/domain/models/glass_preset.dart';
import 'package:shader_studio/features/glass_refraction/domain/models/glass_refraction_config.dart';
import 'package:shader_studio/features/glass_refraction/domain/models/glass_shape.dart';
import 'package:shader_studio/features/glass_refraction/presentation/widgets/glass_refraction.dart';
import 'package:shader_studio/features/glass_refraction/utils/glass_preset_mapper.dart';

/// Example A — a glass content card over a refracting background.
class GlassCard extends StatelessWidget {
  /// Creates the sample glass card.
  const GlassCard({
    this.title = 'Optical stack',
    this.description = 'Refraction, Fresnel rims, and a soft specular — without a translucent white overlay.',
    this.actionLabel = 'Open demo',
    this.onAction,
    this.config,
    super.key,
  });

  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback? onAction;
  final GlassRefractionConfig? config;

  @override
  Widget build(BuildContext context) {
    final cfg = (config ?? GlassPresetMapper.configFor(GlassPreset.clearGlass))
        .clamp();
    return GlassRefraction(
      width: 300,
      height: 196,
      config: cfg,
      shape: GlassShape.roundedRectangle,
      borderRadius: BorderRadius.circular(28),
      enableInteraction: true,
      onTap: onAction,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.blur_on, color: AppColors.accent),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.text.withValues(alpha: 0.7),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.text.withValues(alpha: 0.82),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              actionLabel,
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
