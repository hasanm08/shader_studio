import 'package:flutter/material.dart';
import 'package:shader_studio/app/routing/app_router.dart';
import 'package:shader_studio/core/widgets/sample_card.dart';
import 'package:shader_studio/features/playground/domain/shader_sample.dart';
import 'package:shader_studio/features/playground/presentation/widgets/shader_preview.dart';
import 'package:shader_studio/features/samples/application/shader_sample_controller.dart';

/// Gallery tile with a paused shader preview.
///
/// The preview is a real fragment shader at [ShaderSample.previewTime].
/// It does not create a ticker. Ripple cards seed two slots so the still is
/// not an empty surface. That seeding is labeled in [ShaderSample.stillNote].
class ShaderSampleCard extends StatefulWidget {
  /// Creates a card for [sample].
  const ShaderSampleCard({required this.sample, super.key});

  /// Sample shown on the card.
  final ShaderSample sample;

  @override
  State<ShaderSampleCard> createState() => _ShaderSampleCardState();
}

class _ShaderSampleCardState extends State<ShaderSampleCard> {
  late final ShaderSampleController _controller = ShaderSampleController.still(
    widget.sample,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SampleCard(
      title: widget.sample.name,
      subtitle: widget.sample.summary,
      techniques: widget.sample.techniques,
      footer: widget.sample.stillNote,
      onTap: () {
        Navigator.of(context)
            .pushNamed('${AppRouter.playground}/${widget.sample.id}');
      },
      child: ShaderPreview(
        controller: _controller,
        interactive: false,
        animate: false,
      ),
    );
  }
}
