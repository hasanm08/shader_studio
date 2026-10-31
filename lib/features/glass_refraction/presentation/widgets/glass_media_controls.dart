import 'package:flutter/material.dart';
import 'package:shader_studio/app/theme/app_theme.dart';
import 'package:shader_studio/features/glass_refraction/domain/models/glass_preset.dart';
import 'package:shader_studio/features/glass_refraction/domain/models/glass_refraction_config.dart';
import 'package:shader_studio/features/glass_refraction/domain/models/glass_shape.dart';
import 'package:shader_studio/features/glass_refraction/presentation/widgets/glass_refraction.dart';
import 'package:shader_studio/features/glass_refraction/utils/glass_preset_mapper.dart';

/// Example C — media transport on glass without losing legibility.
class GlassMediaControls extends StatelessWidget {
  /// Creates glass media controls.
  const GlassMediaControls({
    required this.playing,
    required this.progress,
    required this.volume,
    required this.onPlayPause,
    required this.onProgressChanged,
    required this.onVolumeChanged,
    this.title = 'Aurora Drift',
    this.subtitle = 'Shader Studio Session',
    this.config,
    super.key,
  });

  final bool playing;
  final double progress;
  final double volume;
  final VoidCallback onPlayPause;
  final ValueChanged<double> onProgressChanged;
  final ValueChanged<double> onVolumeChanged;
  final String title;
  final String subtitle;
  final GlassRefractionConfig? config;

  @override
  Widget build(BuildContext context) {
    // Subtle frost keeps icons readable; refraction stays visible at the rim.
    final cfg =
        (config ??
                GlassPresetMapper.configFor(GlassPreset.subtleGlass).copyWith(
                  blurSigma: 2.2,
                  opacity: 0.55,
                  edgeHighlight: 0.5,
                  refractionStrength: 0.02,
                ))
            .clamp();

    return GlassRefraction(
      width: 340,
      height: 132,
      config: cfg,
      shape: GlassShape.roundedRectangle,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: playing ? 'Pause' : 'Play',
                  onPressed: onPlayPause,
                  icon: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: AppColors.text,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.text.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.volume_up_rounded,
                  size: 18,
                  color: AppColors.text.withValues(alpha: 0.8),
                ),
                SizedBox(
                  width: 88,
                  child: Slider(
                    value: volume.clamp(0.0, 1.0),
                    onChanged: onVolumeChanged,
                    activeColor: AppColors.accent,
                    inactiveColor: AppColors.border,
                  ),
                ),
              ],
            ),
            Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: onProgressChanged,
              activeColor: AppColors.accent,
              inactiveColor: AppColors.border,
            ),
          ],
        ),
      ),
    );
  }
}
