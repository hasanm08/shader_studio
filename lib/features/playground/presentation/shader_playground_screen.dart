import 'package:flutter/material.dart';
import 'package:shader_studio/features/playground/presentation/widgets/shader_code_panel.dart';
import 'package:shader_studio/features/playground/presentation/widgets/shader_controls_panel.dart';
import 'package:shader_studio/features/playground/presentation/widgets/shader_info_panel.dart';
import 'package:shader_studio/features/playground/presentation/widgets/shader_preview.dart';
import 'package:shader_studio/features/samples/application/shader_sample_controller.dart';

/// Two-column playground on wide screens, stacked on narrow ones.
///
/// The preview is the only child that ticks. The side column listens to
/// parameter changes. 960 logical pixels is the breakpoint.
class ShaderPlaygroundScreen extends StatelessWidget {
  /// Lays out [controller]'s preview and panels.
  const ShaderPlaygroundScreen({required this.controller, super.key});

  /// Active sample state. The route owner disposes it.
  final ShaderSampleController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 960;
        final preview = ShaderPreview(
          controller: controller,
          interactive: true,
          showFrameTime: true,
        );
        if (wide) {
          return Row(
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 8, 20),
                  child: preview,
                ),
              ),
              SizedBox(
                width: 400,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 20, 28),
                  children: [
                    ShaderControlsPanel(controller: controller),
                    const SizedBox(height: 8),
                    ShaderInfoPanel(sample: controller.sample),
                    const SizedBox(height: 8),
                    ShaderCodePanel(sample: controller.sample),
                  ],
                ),
              ),
            ],
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            SizedBox(height: 420, child: preview),
            const SizedBox(height: 16),
            ShaderControlsPanel(controller: controller),
            const SizedBox(height: 8),
            ShaderInfoPanel(sample: controller.sample, compact: true),
            const SizedBox(height: 8),
            ShaderCodePanel(sample: controller.sample),
          ],
        );
      },
    );
  }
}
