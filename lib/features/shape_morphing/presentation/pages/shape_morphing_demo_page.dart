import 'package:flutter/material.dart';
import 'package:shader_studio/app/theme/app_theme.dart';
import 'package:shader_studio/core/geometry/shape_type.dart';
import 'package:shader_studio/features/shape_morphing/application/shape_morph_controller.dart';
import 'package:shader_studio/features/shape_morphing/domain/models/morph_shape.dart';
import 'package:shader_studio/features/shape_morphing/presentation/widgets/morphing_shape.dart';

/// Interactive demo for contour-based shape morphing.
///
/// Keeps controls outside [MorphingShape] so the widget stays reusable.
/// Animation ticks rebuild only [MorphingShape] and the small status label.
class ShapeMorphingDemoPage extends StatefulWidget {
  /// Creates the demo page.
  const ShapeMorphingDemoPage({super.key});

  @override
  State<ShapeMorphingDemoPage> createState() => _ShapeMorphingDemoPageState();
}

class _ShapeMorphingDemoPageState extends State<ShapeMorphingDemoPage>
    with SingleTickerProviderStateMixin {
  static const _background = Color(0xFF0B0D0F);

  late final ShapeMorphController _controller;
  ShapeType _source = ShapeType.circle;
  ShapeType _destination = ShapeType.star;
  double _size = 240;
  double _durationMs = 800;

  @override
  void initState() {
    super.initState();
    _controller = ShapeMorphController(
      initialShape: _source,
      targetShape: _source,
      duration: Duration(milliseconds: _durationMs.round()),
      curve: Curves.easeInOutCubic,
    );
    _controller.createAndAttach(this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleCircleStar() {
    return _controller.toggle(a: ShapeType.circle, b: ShapeType.star);
  }

  /// Morph from the current shape to the selected destination.
  Future<void> _morphToSelected() => _controller.morphTo(_destination);

  /// Play the labeled Source → Destination transition end-to-end.
  Future<void> _playForward() {
    return _controller.play(from: _source, to: _destination);
  }

  /// Reverse in-flight, or morph back to the selected source when idle.
  Future<void> _playReverse() {
    return _controller.reverse(toward: _source);
  }

  void _reset() {
    _controller.reset(_source);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        title: const Text('Shape Morphing'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 720;
            final stage = Center(
              child: MorphingShape(
                controller: _controller,
                size: _size,
                style: MorphShapeStyle.flowForge,
                initialShape: ShapeType.circle,
                targetShape: ShapeType.star,
                onTap: _toggleCircleStar,
              ),
            );
            final controls = _Controls(
              controller: _controller,
              source: _source,
              destination: _destination,
              size: _size,
              durationMs: _durationMs,
              onSourceChanged: (value) => setState(() => _source = value),
              onDestinationChanged: (value) {
                setState(() => _destination = value);
              },
              onSizeChanged: (value) => setState(() => _size = value),
              onDurationChanged: (value) {
                setState(() {
                  _durationMs = value;
                  _controller.duration = Duration(milliseconds: value.round());
                });
              },
              onToggleCircleStar: _toggleCircleStar,
              onMorph: _morphToSelected,
              onForward: _playForward,
              onReverse: _playReverse,
              onReset: _reset,
            );

            if (wide) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 3, child: stage),
                    const SizedBox(width: 28),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.center,
                        child: SingleChildScrollView(child: controls),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Expanded(child: stage),
                Material(
                  color: AppColors.surface,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: controls,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.controller,
    required this.source,
    required this.destination,
    required this.size,
    required this.durationMs,
    required this.onSourceChanged,
    required this.onDestinationChanged,
    required this.onSizeChanged,
    required this.onDurationChanged,
    required this.onToggleCircleStar,
    required this.onMorph,
    required this.onForward,
    required this.onReverse,
    required this.onReset,
  });

  final ShapeMorphController controller;
  final ShapeType source;
  final ShapeType destination;
  final double size;
  final double durationMs;
  final ValueChanged<ShapeType> onSourceChanged;
  final ValueChanged<ShapeType> onDestinationChanged;
  final ValueChanged<double> onSizeChanged;
  final ValueChanged<double> onDurationChanged;
  final VoidCallback onToggleCircleStar;
  final VoidCallback onMorph;
  final VoidCallback onForward;
  final VoidCallback onReverse;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Contour morph', style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Tap the shape or use the controls. Geometry interpolates between '
          'normalized contours — no crossfade.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final animating = controller.isAnimating;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${controller.fromShape.label}  →  ${controller.toShape.label}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF14B8A6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Displayed: ${controller.displayedShape.label}'
                  '${animating ? '  ·  animating' : ''}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton(
              onPressed: onToggleCircleStar,
              child: const Text('Toggle Circle ↔ Star'),
            ),
            OutlinedButton(
              onPressed: onMorph,
              child: const Text('Morph to target'),
            ),
            OutlinedButton(onPressed: onForward, child: const Text('Play')),
            OutlinedButton(onPressed: onReverse, child: const Text('Reverse')),
            TextButton(onPressed: onReset, child: const Text('Reset')),
          ],
        ),
        const SizedBox(height: 20),
        Text('Source', style: theme.textTheme.labelLarge),
        const SizedBox(height: 6),
        DropdownButtonFormField<ShapeType>(
          key: ValueKey('source-$source'),
          initialValue: source,
          dropdownColor: AppColors.surfaceHigh,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
          ),
          items: [
            for (final type in ShapeType.values)
              DropdownMenuItem(value: type, child: Text(type.label)),
          ],
          onChanged: (value) {
            if (value != null) {
              onSourceChanged(value);
            }
          },
        ),
        const SizedBox(height: 14),
        Text('Destination', style: theme.textTheme.labelLarge),
        const SizedBox(height: 6),
        DropdownButtonFormField<ShapeType>(
          key: ValueKey('destination-$destination'),
          initialValue: destination,
          dropdownColor: AppColors.surfaceHigh,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
          ),
          items: [
            for (final type in ShapeType.values)
              DropdownMenuItem(value: type, child: Text(type.label)),
          ],
          onChanged: (value) {
            if (value != null) {
              onDestinationChanged(value);
            }
          },
        ),
        const SizedBox(height: 18),
        _SliderRow(
          label: 'Size',
          valueLabel: '${size.round()}',
          value: size,
          min: 120,
          max: 320,
          onChanged: onSizeChanged,
        ),
        _SliderRow(
          label: 'Duration',
          valueLabel: '${durationMs.round()} ms',
          value: durationMs,
          min: 200,
          max: 2000,
          onChanged: onDurationChanged,
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
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.labelLarge),
            ),
            Text(
              valueLabel,
              style: const TextStyle(
                color: Color(0xFF14B8A6),
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }
}
