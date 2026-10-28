import 'package:flutter/material.dart';
import 'package:shader_studio/features/card_flip/application/card_flip_controller.dart';
import 'package:shader_studio/features/card_flip/domain/models/card_flip_config.dart';
import 'package:shader_studio/features/card_flip/presentation/theme/card_flip_colors.dart';

/// Secondary controls for the card-flip demo.
///
/// The rotation readout listens to [controller]. Sliders do not, so dragging
/// one does not rebuild on every animation frame.
class FlipControls extends StatelessWidget {
  /// Creates the demo controls.
  const FlipControls({
    required this.controller,
    required this.durationMs,
    required this.perspective,
    required this.curve,
    required this.autoFlip,
    required this.tapEnabled,
    required this.tiltEnabled,
    required this.tiltSupported,
    required this.onFlip,
    required this.onReset,
    required this.onDurationChanged,
    required this.onPerspectiveChanged,
    required this.onCurveChanged,
    required this.onAutoFlipChanged,
    required this.onTapEnabledChanged,
    required this.onTiltEnabledChanged,
    super.key,
  });

  /// Source of the rotation label.
  final CardFlipController controller;

  /// Duration slider position, in milliseconds.
  final double durationMs;

  /// Perspective slider position, before the card clamps it.
  final double perspective;

  /// Selected curve.
  final CardFlipCurve curve;

  /// Periodic flip switch.
  final bool autoFlip;

  /// Tap and keyboard switch.
  final bool tapEnabled;

  /// Pointer tilt switch.
  final bool tiltEnabled;

  /// False on touch platforms, where the tilt switch is disabled.
  final bool tiltSupported;

  /// Flips toward the other face.
  final VoidCallback onFlip;

  /// Snaps back to the front.
  final VoidCallback onReset;

  /// New duration in milliseconds.
  final ValueChanged<double> onDurationChanged;

  /// New perspective strength.
  final ValueChanged<double> onPerspectiveChanged;

  /// New curve.
  final ValueChanged<CardFlipCurve> onCurveChanged;

  /// Auto-flip switch.
  final ValueChanged<bool> onAutoFlipChanged;

  /// Tap interaction switch.
  final ValueChanged<bool> onTapEnabledChanged;

  /// Tilt switch.
  final ValueChanged<bool> onTiltEnabledChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('Y-axis flip', style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'One rotation, two faces. Perspective is a matrix entry, '
          'not a fade between cards.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 14),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return Text(
              controller.statusLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                color: CardFlipColors.tealBright,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            FilledButton(onPressed: onFlip, child: const Text('Flip card')),
            OutlinedButton(
              onPressed: onReset,
              child: const Text('Reset to front'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SliderRow(
          label: 'Duration',
          valueLabel: '${durationMs.round()} ms',
          value: durationMs,
          min: 250,
          max: 1600,
          onChanged: onDurationChanged,
          sliderKey: const Key('flip-duration-slider'),
        ),
        _SliderRow(
          label: 'Perspective',
          valueLabel: perspective.toStringAsFixed(4),
          value: perspective,
          min: CardFlipConfig.minPerspective,
          max: CardFlipConfig.maxPerspective,
          onChanged: onPerspectiveChanged,
          sliderKey: const Key('flip-perspective-slider'),
        ),
        const SizedBox(height: 6),
        Text('Curve', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final option in CardFlipCurve.values)
              ChoiceChip(
                label: Text(option.label),
                selected: curve == option,
                onSelected: (_) => onCurveChanged(option),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Auto flip'),
          subtitle: const Text('Off by default. Waits out the current flip.'),
          value: autoFlip,
          onChanged: onAutoFlipChanged,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Tap to flip'),
          subtitle: const Text('Card tap and Enter or Space.'),
          value: tapEnabled,
          onChanged: onTapEnabledChanged,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Pointer tilt'),
          subtitle: Text(
            tiltSupported
                ? 'Hover tilt, separate from the flip. Resets when the pointer leaves.'
                : 'Hover tilt is available on desktop pointers.',
          ),
          value: tiltEnabled && tiltSupported,
          onChanged: tiltSupported ? onTiltEnabledChanged : null,
        ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.sliderKey,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final Key sliderKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.labelLarge),
            ),
            Text(
              valueLabel,
              style: const TextStyle(
                color: CardFlipColors.teal,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        Slider(
          key: sliderKey,
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
