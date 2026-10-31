import 'package:flutter/material.dart';
import 'package:shader_studio/app/theme/app_theme.dart';
import 'package:shader_studio/features/glass_refraction/domain/models/glass_preset.dart';
import 'package:shader_studio/features/glass_refraction/domain/models/glass_refraction_config.dart';
import 'package:shader_studio/features/glass_refraction/domain/models/glass_shape.dart';
import 'package:shader_studio/features/glass_refraction/presentation/widgets/glass_refraction.dart';
import 'package:shader_studio/features/glass_refraction/utils/glass_preset_mapper.dart';

/// Example B — floating glass navigation over a colorful surface.
class GlassNavigation extends StatelessWidget {
  /// Creates a floating glass nav bar.
  const GlassNavigation({
    required this.index,
    required this.onChanged,
    this.labels = const <String>['Home', 'Lens', 'Library'],
    this.config,
    super.key,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final List<String> labels;
  final GlassRefractionConfig? config;

  @override
  Widget build(BuildContext context) {
    final cfg = (config ?? GlassPresetMapper.configFor(GlassPreset.subtleGlass))
        .clamp();
    return GlassRefraction(
      width: 320,
      height: 64,
      config: cfg,
      shape: GlassShape.capsule,
      borderRadius: BorderRadius.circular(999),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: _NavItem(
                label: labels[i],
                selected: i == index,
                onTap: () => onChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.22)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.accent : AppColors.text,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
