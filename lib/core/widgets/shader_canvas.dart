import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shader_studio/app/shader_studio_scope.dart';
import 'package:shader_studio/app/theme/app_theme.dart';
import 'package:shader_studio/core/rendering/shader_error.dart';
import 'package:shader_studio/core/rendering/shader_renderer.dart';
import 'package:shader_studio/core/rendering/shader_uniforms.dart';
import 'package:shader_studio/features/samples/application/shader_sample_controller.dart';

/// Loads one sample's program and paints it.
///
/// When [animate] is true this state owns the only ticker for [controller].
/// The ticker is stopped while the controller is paused, while ticker mode
/// is disabled (a covered route does this), or while the widget is disposed.
/// Stopping the ticker drops its elapsed origin, so the next start ignores
/// the first callback instead of adding the gap since the pause.
///
/// The `FragmentShader` is created once the program loads and disposed with
/// this state. The `FragmentProgram` stays in `ShaderLoader`. A hot reload
/// of the shader source is handled by the engine, which reinitializes
/// shaders it still has weak references to.
class ShaderCanvas extends StatefulWidget {
  /// Creates a canvas for [controller].
  const ShaderCanvas({
    required this.controller,
    required this.animate,
    super.key,
  });

  /// Clock and parameters read by the painter.
  final ShaderSampleController controller;

  /// When false, no ticker is created. Gallery thumbnails use this.
  final bool animate;

  @override
  State<ShaderCanvas> createState() => _ShaderCanvasState();
}

class _ShaderCanvasState extends State<ShaderCanvas>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  Duration? _previousElapsed;
  ui.FragmentShader? _shader;
  FragmentShaderSink? _sink;
  Object? _error;
  var _started = false;
  var _generation = 0;
  var _reportedPaintError = false;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _ticker = createTicker(_onTick);
      widget.controller.controlsTick.addListener(_syncTicker);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
    if (!_started) {
      _started = true;
      _load();
    }
  }

  @override
  void dispose() {
    if (widget.animate) {
      widget.controller.controlsTick.removeListener(_syncTicker);
    }
    _ticker?.dispose();
    _shader?.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final previous = _previousElapsed;
    _previousElapsed = elapsed;
    if (previous == null) {
      return;
    }
    final delta = elapsed - previous;
    if (delta < Duration.zero) {
      return;
    }
    widget.controller.addDelta(delta);
  }

  void _syncTicker() {
    final ticker = _ticker;
    if (ticker == null || !mounted) {
      return;
    }
    final enabled =
        widget.animate &&
        widget.controller.playing &&
        TickerMode.valuesOf(context).enabled;
    if (enabled) {
      if (!ticker.isActive) {
        _previousElapsed = null;
        ticker.start();
      }
    } else if (ticker.isActive) {
      ticker.stop();
      _previousElapsed = null;
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _error = null;
      _reportedPaintError = false;
    });
    try {
      final program = await ShaderStudioScope.of(context)
          .load(widget.controller.sample.assetPath);
      if (!mounted || generation != _generation) {
        return;
      }
      final shader = program.fragmentShader();
      setState(() {
        _shader?.dispose();
        _shader = shader;
        _sink = FragmentShaderSink(shader);
        _error = null;
      });
    } on ShaderLoadException catch (error) {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() => _error = error);
    }
  }

  void _handlePaintError(Object error) {
    if (_reportedPaintError) {
      return;
    }
    _reportedPaintError = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error);
    });
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error != null) {
      return _ShaderMessage(
        title: 'Shader failed',
        body: error.toString(),
        onRetry: _load,
      );
    }
    final sink = _sink;
    if (sink == null) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accent,
          ),
        ),
      );
    }
    return CustomPaint(
      painter: ShaderRenderer(
        sink: sink,
        controller: widget.controller,
        repaint: widget.controller.paintTick,
        onPaintError: _handlePaintError,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _ShaderMessage extends StatelessWidget {
  const _ShaderMessage({
    required this.title,
    required this.body,
    required this.onRetry,
  });

  final String title;
  final String body;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
