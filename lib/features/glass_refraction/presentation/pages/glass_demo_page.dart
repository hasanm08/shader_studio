import 'package:flutter/material.dart';
import 'package:shader_studio/app/theme/app_theme.dart';
import 'package:shader_studio/features/glass_refraction/domain/models/glass_preset.dart';
import 'package:shader_studio/features/glass_refraction/domain/models/glass_refraction_config.dart';
import 'package:shader_studio/features/glass_refraction/domain/models/glass_shape.dart';
import 'package:shader_studio/features/glass_refraction/presentation/widgets/glass_card.dart';
import 'package:shader_studio/features/glass_refraction/presentation/widgets/glass_controls.dart';
import 'package:shader_studio/features/glass_refraction/presentation/widgets/glass_demo_background.dart';
import 'package:shader_studio/features/glass_refraction/presentation/widgets/glass_media_controls.dart';
import 'package:shader_studio/features/glass_refraction/presentation/widgets/glass_navigation.dart';
import 'package:shader_studio/features/glass_refraction/presentation/widgets/glass_preset_selector.dart';
import 'package:shader_studio/features/glass_refraction/presentation/widgets/glass_refraction.dart';
import 'package:shader_studio/features/glass_refraction/presentation/widgets/glass_scene.dart';
import 'package:shader_studio/features/glass_refraction/utils/glass_preset_mapper.dart';

/// Interactive playground + production samples for glass refraction.
class GlassDemoPage extends StatefulWidget {
  /// Creates the glass demo page.
  const GlassDemoPage({super.key});

  @override
  State<GlassDemoPage> createState() => _GlassDemoPageState();
}

class _GlassDemoPageState extends State<GlassDemoPage> {
  final GlobalKey<GlassSceneState> _sceneKey = GlobalKey<GlassSceneState>();

  GlassRefractionConfig _config = GlassPreset.clearGlass.config;
  GlassShape _shape = GlassShape.roundedRectangle;
  Offset _glassOffset = const Offset(40, 48);
  double _glassWidth = 240;
  double _glassHeight = 170;
  bool _animateBackground = true;
  bool _playing = true;
  double _progress = 0.35;
  double _volume = 0.7;
  int _navIndex = 1;
  int _tab = 0;

  void _reset() {
    setState(() {
      _config = GlassPreset.clearGlass.config;
      _shape = GlassShape.roundedRectangle;
      _glassWidth = 240;
      _glassHeight = 170;
      _glassOffset = const Offset(40, 48);
    });
  }

  void _applyPreset(GlassPreset preset) {
    setState(() => _config = GlassPresetMapper.configFor(preset));
  }

  @override
  Widget build(BuildContext context) {
    final matching = GlassPresetMapper.matchingPreset(_config);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Glass Refraction'),
        actions: [
          IconButton(
            tooltip: 'Reset',
            onPressed: _reset,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 960;
            final canvas = _InteractiveCanvas(
              sceneKey: _sceneKey,
              config: _config,
              shape: _shape,
              offset: _glassOffset,
              width: _glassWidth,
              height: _glassHeight,
              animateBackground: _animateBackground,
              onOffsetChanged: (o) => setState(() => _glassOffset = o),
            );

            final controls = ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                SegmentedButton<int>(
                  segments: const <ButtonSegment<int>>[
                    ButtonSegment(value: 0, label: Text('Playground')),
                    ButtonSegment(value: 1, label: Text('Examples')),
                  ],
                  selected: <int>{_tab},
                  onSelectionChanged: (s) => setState(() => _tab = s.first),
                ),
                const SizedBox(height: 16),
                if (_tab == 0) ...[
                  GlassPresetSelector(
                    config: _config,
                    onSelected: _applyPreset,
                  ),
                  const SizedBox(height: 16),
                  _InfoPanel(preset: matching, config: _config, shape: _shape),
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Animate background'),
                    subtitle: const Text(
                      'Re-captures the wallpaper while orbs drift',
                    ),
                    value: _animateBackground,
                    onChanged: (v) {
                      setState(() => _animateBackground = v);
                      _sceneKey.currentState?.setContinuousCapture(v);
                    },
                  ),
                  const SizedBox(height: 8),
                  GlassControls(
                    config: _config,
                    shape: _shape,
                    glassWidth: _glassWidth,
                    glassHeight: _glassHeight,
                    onConfigChanged: (c) => setState(() => _config = c),
                    onShapeChanged: (s) => setState(() => _shape = s),
                    onSizeChanged: (w, h) => setState(() {
                      _glassWidth = w;
                      _glassHeight = h;
                    }),
                    onReset: _reset,
                  ),
                ] else ...[
                  Text(
                    'Production samples',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'These reuse GlassRefraction with a shared GlassScene capture. '
                    'Child content stays sharp on top of the lens.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  _ExamplesPane(
                    navIndex: _navIndex,
                    onNavChanged: (i) => setState(() => _navIndex = i),
                    playing: _playing,
                    progress: _progress,
                    volume: _volume,
                    onPlayPause: () => setState(() => _playing = !_playing),
                    onProgressChanged: (v) => setState(() => _progress = v),
                    onVolumeChanged: (v) => setState(() => _volume = v),
                  ),
                ],
              ],
            );

            if (wide) {
              return Row(
                children: [
                  Expanded(flex: 3, child: canvas),
                  const VerticalDivider(width: 1),
                  SizedBox(width: 360, child: controls),
                ],
              );
            }
            return Column(
              children: [
                SizedBox(height: constraints.maxHeight * 0.46, child: canvas),
                const Divider(height: 1),
                Expanded(child: controls),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InteractiveCanvas extends StatefulWidget {
  const _InteractiveCanvas({
    required this.sceneKey,
    required this.config,
    required this.shape,
    required this.offset,
    required this.width,
    required this.height,
    required this.animateBackground,
    required this.onOffsetChanged,
  });

  final GlobalKey<GlassSceneState> sceneKey;
  final GlassRefractionConfig config;
  final GlassShape shape;
  final Offset offset;
  final double width;
  final double height;
  final bool animateBackground;
  final ValueChanged<Offset> onOffsetChanged;

  @override
  State<_InteractiveCanvas> createState() => _InteractiveCanvasState();
}

class _InteractiveCanvasState extends State<_InteractiveCanvas> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.sceneKey.currentState?.setContinuousCapture(
        widget.animateBackground,
      );
    });
  }

  @override
  void didUpdateWidget(covariant _InteractiveCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animateBackground != widget.animateBackground) {
      widget.sceneKey.currentState?.setContinuousCapture(
        widget.animateBackground,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: GlassScene(
          key: widget.sceneKey,
          pixelRatio: MediaQuery.devicePixelRatioOf(context).clamp(1.0, 2.0),
          captureInterval: const Duration(milliseconds: 40),
          background: AnimatedGlassDemoBackground(
            enabled: widget.animateBackground,
            onTick: (_) {
              widget.sceneKey.currentState?.scheduleCapture();
            },
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxX = (constraints.maxWidth - widget.width).clamp(
                0.0,
                double.infinity,
              );
              final maxY = (constraints.maxHeight - widget.height).clamp(
                0.0,
                double.infinity,
              );
              final pos = Offset(
                widget.offset.dx.clamp(0.0, maxX),
                widget.offset.dy.clamp(0.0, maxY),
              );
              return Stack(
                children: [
                  Positioned(
                    left: 16,
                    top: 16,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(
                          'Drag the glass',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: pos.dx,
                    top: pos.dy,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        final next = Offset(
                          (pos.dx + details.delta.dx).clamp(0.0, maxX),
                          (pos.dy + details.delta.dy).clamp(0.0, maxY),
                        );
                        widget.onOffsetChanged(next);
                      },
                      child: GlassRefraction(
                        width: widget.width,
                        height: widget.height,
                        config: widget.config,
                        shape: widget.shape,
                        borderRadius: BorderRadius.circular(
                          widget.config.cornerRadius *
                              widget.height.clamp(1, 400),
                        ),
                        child: const Center(
                          child: Text(
                            'Glass',
                            style: TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.preset,
    required this.config,
    required this.shape,
  });

  final GlassPreset? preset;
  final GlassRefractionConfig config;
  final GlassShape shape;

  @override
  Widget build(BuildContext context) {
    final c = config.clamp();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Technical', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Preset: ${preset?.label ?? 'Custom'}\n'
              'Shape: ${shape.label}\n'
              'refraction=${c.refractionStrength.toStringAsFixed(3)}  '
              'curvature=${c.curvature.toStringAsFixed(2)}\n'
              'blur=${c.blurSigma.toStringAsFixed(2)}  '
              'reflect=${c.reflectionIntensity.toStringAsFixed(2)}\n'
              'edge=${c.edgeHighlight.toStringAsFixed(2)}  '
              'chroma=${c.chromaticAberration.toStringAsFixed(3)}\n'
              'Capture → sampler2D → UV bend (not BackdropFilter)',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontFamily: 'monospace', height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamplesPane extends StatelessWidget {
  const _ExamplesPane({
    required this.navIndex,
    required this.onNavChanged,
    required this.playing,
    required this.progress,
    required this.volume,
    required this.onPlayPause,
    required this.onProgressChanged,
    required this.onVolumeChanged,
  });

  final int navIndex;
  final ValueChanged<int> onNavChanged;
  final bool playing;
  final double progress;
  final double volume;
  final VoidCallback onPlayPause;
  final ValueChanged<double> onProgressChanged;
  final ValueChanged<double> onVolumeChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 420,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GlassScene(
          pixelRatio: 1.5,
          background: const GlassDemoBackground(animate: false),
          child: Stack(
            children: [
              Align(
                alignment: const Alignment(0, -0.55),
                child: GlassCard(onAction: () {}),
              ),
              Align(
                alignment: const Alignment(0, 0.15),
                child: GlassMediaControls(
                  playing: playing,
                  progress: progress,
                  volume: volume,
                  onPlayPause: onPlayPause,
                  onProgressChanged: onProgressChanged,
                  onVolumeChanged: onVolumeChanged,
                ),
              ),
              Align(
                alignment: const Alignment(0, 0.85),
                child: GlassNavigation(
                  index: navIndex,
                  onChanged: onNavChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
