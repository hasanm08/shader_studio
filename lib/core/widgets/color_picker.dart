import 'package:flutter/material.dart';
import 'package:shader_studio/app/theme/app_theme.dart';
import 'package:shader_studio/features/playground/domain/shader_parameter.dart';
import 'package:shader_studio/features/samples/application/shader_sample_controller.dart';

/// Straight-RGB editor for one vec3 color uniform.
///
/// Swatches jump to a color. The three sliders write channels in 0..1,
/// which is what `Color.r`, `Color.g`, and `Color.b` store. The uniform
/// writer copies those channels without premultiplying, because the shader
/// treats them as palette data and writes its own alpha.
///
/// A change calls [ShaderSampleController.setColor] and repaints. It does
/// not recreate the shader. Editing a channel clears the active palette
/// chip on samples that have one.
class ShaderColorPicker extends StatelessWidget {
  /// Creates a picker for [parameter].
  const ShaderColorPicker({
    required this.controller,
    required this.parameter,
    super.key,
  });

  /// Controller that stores the color.
  final ShaderSampleController controller;

  /// Uniform name and default color.
  final ColorParameter parameter;

  static const List<Color> _swatches = <Color>[
    Color(0xFF14E6CF),
    Color(0xFF4DBBFF),
    Color(0xFFE7F8FF),
    Color(0xFF071018),
    Color(0xFF149E96),
    Color(0xFFC4552A),
    Color(0xFFFFD2A8),
    Color(0xFF8A93A0),
  ];

  @override
  Widget build(BuildContext context) {
    final color = controller.colorOf(parameter.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(parameter.label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(
            '${parameter.summary}  ${parameter.uniformName}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final swatch in _swatches)
                _Swatch(
                  color: swatch,
                  selected: _sameRgb(swatch, color),
                  onTap: () => controller.setColor(parameter.id, swatch),
                ),
            ],
          ),
          _ChannelSlider(
            label: 'R',
            value: color.r,
            onChanged: (channel) => _setChannel(color, r: channel),
          ),
          _ChannelSlider(
            label: 'G',
            value: color.g,
            onChanged: (channel) => _setChannel(color, g: channel),
          ),
          _ChannelSlider(
            label: 'B',
            value: color.b,
            onChanged: (channel) => _setChannel(color, b: channel),
          ),
        ],
      ),
    );
  }

  void _setChannel(Color color, {double? r, double? g, double? b}) {
    controller.setColor(
      parameter.id,
      Color.from(
        alpha: 1,
        red: r ?? color.r,
        green: g ?? color.g,
        blue: b ?? color.b,
      ),
    );
  }

  static bool _sameRgb(Color a, Color b) {
    return (a.r - b.r).abs() < 0.004 &&
        (a.g - b.g).abs() < 0.004 &&
        (a.b - b.b).abs() < 0.004;
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Color swatch',
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.text : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: const SizedBox(width: 22, height: 22),
        ),
      ),
    );
  }
}

class _ChannelSlider extends StatelessWidget {
  const _ChannelSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Slider(min: 0, max: 1, value: value, onChanged: onChanged),
        ),
      ],
    );
  }
}
