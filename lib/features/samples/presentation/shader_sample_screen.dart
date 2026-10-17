import 'package:flutter/material.dart';
import 'package:shader_studio/features/playground/domain/shader_sample.dart';
import 'package:shader_studio/features/playground/presentation/shader_playground_screen.dart';
import 'package:shader_studio/features/playground/presentation/widgets/shader_controls_panel.dart';
import 'package:shader_studio/features/samples/application/shader_sample_controller.dart';

/// Route that owns one [ShaderSampleController] and hosts the playground.
///
/// The controller is created after the first `MediaQuery` is available so
/// reduced-motion can start the clock paused. The user can still press play.
/// Disposal releases the controller's signals. The canvas stops its ticker
/// in its own `dispose` before that, because children dispose first.
class ShaderSampleScreen extends StatefulWidget {
  /// Opens [sample].
  const ShaderSampleScreen({required this.sample, super.key});

  /// Sample to edit.
  final ShaderSample sample;

  @override
  State<ShaderSampleScreen> createState() => _ShaderSampleScreenState();
}

class _ShaderSampleScreenState extends State<ShaderSampleScreen> {
  ShaderSampleController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= ShaderSampleController(
      sample: widget.sample,
      playing: !MediaQuery.disableAnimationsOf(context),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const SizedBox.shrink();
    }
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sample.name),
        actions: [PlaybackControls(controller: controller)],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (reduceMotion) const _ReducedMotionNote(),
          Expanded(child: ShaderPlaygroundScreen(controller: controller)),
        ],
      ),
    );
  }
}

class _ReducedMotionNote extends StatelessWidget {
  const _ReducedMotionNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Text(
        'Animation started paused because reduced motion is on. Press play to run it.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
