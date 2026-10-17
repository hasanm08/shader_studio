import 'package:flutter/material.dart';
import 'package:shader_studio/app/theme/app_theme.dart';

/// Chrome shared by gallery cards: surface, border, title, and technique chips.
class SampleCard extends StatelessWidget {
  /// Creates a tappable card.
  const SampleCard({
    required this.title,
    required this.subtitle,
    required this.techniques,
    required this.onTap,
    required this.child,
    this.footer,
    super.key,
  });

  /// Sample name.
  final String title;

  /// Short description.
  final String subtitle;

  /// Technique labels.
  final List<String> techniques;

  /// Opens the playground.
  final VoidCallback onTap;

  /// Preview painted above the text.
  final Widget child;

  /// Optional caption under the description.
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: child),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final technique in techniques)
                          _TechniqueChip(label: technique),
                      ],
                    ),
                    if (footer != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        footer!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TechniqueChip extends StatelessWidget {
  const _TechniqueChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.accentSecondary,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
