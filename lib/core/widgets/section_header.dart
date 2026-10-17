import 'package:flutter/material.dart';
import 'package:shader_studio/app/theme/app_theme.dart';

/// A title and optional supporting line used between playground sections.
class SectionHeader extends StatelessWidget {
  /// Creates a header.
  const SectionHeader({required this.title, this.subtitle, super.key});

  /// Section title.
  final String title;

  /// Optional explanation under the title.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 8),
          const DecoratedBox(
            decoration: BoxDecoration(color: AppColors.accent),
            child: SizedBox(width: 28, height: 2),
          ),
        ],
      ),
    );
  }
}
