import 'package:flutter/material.dart';
import 'package:shader_studio/app/theme/app_theme.dart';
import 'package:shader_studio/features/playground/domain/shader_parameter.dart';
import 'package:shader_studio/features/samples/application/shader_sample_controller.dart';

/// Slider bound to one float uniform.
///
/// [parameter] names the uniform, the default, and the inclusive range.
/// Dragging calls [ShaderSampleController.setScalar], which clamps and pings
/// the paint signal. The shader program is not recreated. The displayed
/// number is the clamped value the next paint will write.
class ParameterSlider extends StatelessWidget {
  /// Creates a slider for [parameter] on [controller].
  const ParameterSlider({
    required this.controller,
    required this.parameter,
    super.key,
  });

  /// Controller that stores and clamps the value.
  final ShaderSampleController controller;

  /// Range, default, and uniform name.
  final SliderParameter parameter;

  @override
  Widget build(BuildContext context) {
    final value = controller.scalar(parameter.id);
    final text = value.toStringAsFixed(2);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  parameter.label,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Text(
                text,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          Slider(
            min: parameter.min,
            max: parameter.max,
            value: value,
            label: text,
            onChanged: (next) => controller.setScalar(parameter.id, next),
          ),
          Text(
            '${parameter.summary}  ${parameter.uniformName}  '
            '${parameter.min.toStringAsFixed(2)}–${parameter.max.toStringAsFixed(2)}'
            '  default ${parameter.defaultValue.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
