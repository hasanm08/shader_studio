import 'package:flutter/material.dart';
import 'package:shader_studio/app/theme/app_theme.dart';
import 'package:shader_studio/core/widgets/color_picker.dart';
import 'package:shader_studio/core/widgets/parameter_slider.dart';
import 'package:shader_studio/core/widgets/section_header.dart';
import 'package:shader_studio/features/playground/domain/shader_parameter.dart';
import 'package:shader_studio/features/samples/application/shader_sample_controller.dart';

/// Play, pause, and reset controls bound to [controller].
class PlaybackControls extends StatelessWidget {
  /// Creates playback controls.
  const PlaybackControls({required this.controller, super.key});

  /// Clock these buttons edit.
  final ShaderSampleController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller.controlsTick,
      builder: (context, _) {
        final playing = controller.playing;
        return Row(
          children: [
            IconButton(
              tooltip: playing ? 'Pause animation' : 'Resume animation',
              onPressed: () => controller.playing = !controller.playing,
              icon: Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
            ),
            IconButton(
              tooltip: 'Reset parameters',
              onPressed: controller.reset,
              icon: const Icon(Icons.restart_alt_rounded),
            ),
            const SizedBox(width: 8),
            Text(
              playing ? 'Running' : 'Paused',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }
}

/// Sliders, colors, presets, and the pointer-interaction switch.
///
/// This panel listens to `controlsTick`, not the per-frame paint signal.
/// Dragging a slider rebuilds the controls. A time tick does not.
///
/// Every slider writes the uniform named on its parameter. The pointer
/// switch does not remove the last coordinate; it forces `uPointerActive`
/// to 0 until it is enabled again.
class ShaderControlsPanel extends StatelessWidget {
  /// Creates the panel for [controller].
  const ShaderControlsPanel({required this.controller, super.key});

  /// Sample state edited by the controls.
  final ShaderSampleController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller.controlsTick,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(
              title: 'Controls',
              subtitle: 'Each control writes a uniform on the next paint.',
            ),
            PlaybackControls(controller: controller),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pointer interaction'),
              subtitle: Text(
                controller.sample.interaction,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              value: controller.interactionEnabled,
              onChanged: controller.setInteractionEnabled,
            ),
            const SizedBox(height: 8),
            for (final parameter in controller.sample.parameters)
              _ParameterControl(controller: controller, parameter: parameter),
          ],
        );
      },
    );
  }
}

class _ParameterControl extends StatelessWidget {
  const _ParameterControl({required this.controller, required this.parameter});

  final ShaderSampleController controller;
  final ShaderParameter parameter;

  @override
  Widget build(BuildContext context) {
    final value = parameter;
    if (value is SliderParameter) {
      return ParameterSlider(controller: controller, parameter: value);
    }
    if (value is ColorParameter) {
      return ShaderColorPicker(controller: controller, parameter: value);
    }
    if (value is ToggleParameter) {
      final enabled = controller.scalar(value.id) >= 0.5;
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(value.label),
        subtitle: Text(
          '${value.summary}  ${value.uniformName}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        value: enabled,
        onChanged: (next) => controller.setScalar(value.id, next ? 1 : 0),
      );
    }
    if (value is ChoiceParameter) {
      return _PresetChooser(controller: controller, parameter: value);
    }
    return const SizedBox.shrink();
  }
}

class _PresetChooser extends StatelessWidget {
  const _PresetChooser({required this.controller, required this.parameter});

  final ShaderSampleController controller;
  final ChoiceParameter parameter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(parameter.label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(parameter.summary, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in parameter.presets)
                ChoiceChip(
                  label: Text(preset.label),
                  selected: controller.selectedPresetId == preset.id,
                  onSelected: (_) => controller.selectPreset(preset.id),
                  selectedColor: AppColors.surfaceHigh,
                  labelStyle: TextStyle(
                    color: controller.selectedPresetId == preset.id
                        ? AppColors.accent
                        : AppColors.text,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
