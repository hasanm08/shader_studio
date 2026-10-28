import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shader_studio/features/card_flip/application/basket_drop_controller.dart';
import 'package:shader_studio/features/card_flip/application/card_flip_controller.dart';
import 'package:shader_studio/features/card_flip/application/cube_flip_controller.dart';
import 'package:shader_studio/features/card_flip/domain/models/card_flip_config.dart';
import 'package:shader_studio/features/card_flip/presentation/theme/card_flip_colors.dart';
import 'package:shader_studio/features/card_flip/presentation/widgets/basket_drop.dart';
import 'package:shader_studio/features/card_flip/presentation/widgets/card_back.dart';
import 'package:shader_studio/features/card_flip/presentation/widgets/card_front.dart';
import 'package:shader_studio/features/card_flip/presentation/widgets/cube_flip_3d.dart';
import 'package:shader_studio/features/card_flip/presentation/widgets/flip_card_3d.dart';
import 'package:shader_studio/features/card_flip/presentation/widgets/flip_controls.dart';

/// Which study the demo page is showing.
enum _Study { card, cube, basket }

/// Interactive demonstration of the card, cube, and basket motions.
///
/// The page owns every controller. The card study stays the default so the
/// flip controls remain the first thing on screen.
class CardFlipDemoPage extends StatefulWidget {
  /// Creates the demo page.
  const CardFlipDemoPage({super.key});

  @override
  State<CardFlipDemoPage> createState() => _CardFlipDemoPageState();
}

class _CardFlipDemoPageState extends State<CardFlipDemoPage>
    with TickerProviderStateMixin {
  late final CardFlipController _controller;
  late final CubeFlipController _cube;
  late final BasketDropController _basket;
  double _durationMs = CardFlipConfig.defaultDuration.inMilliseconds.toDouble();
  double _perspective = CardFlipConfig.defaultPerspective;
  CardFlipCurve _curve = CardFlipCurve.easeInOutCubic;
  bool _autoFlip = false;
  bool _tapEnabled = true;
  bool _tiltEnabled = false;
  _Study _study = _Study.card;

  @override
  void initState() {
    super.initState();
    _controller = CardFlipController(
      duration: CardFlipConfig.defaultDuration,
      curve: _curve.curve,
    )..createAndAttach(this);
    _cube = CubeFlipController()..createAndAttach(this);
    _basket = BasketDropController()..createAndAttach(this);
  }

  @override
  void dispose() {
    _controller.dispose();
    _cube.dispose();
    _basket.dispose();
    super.dispose();
  }

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  void _flip() {
    _controller.flip(instant: _reduceMotion);
  }

  void _reset() {
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    final tiltSupported = CardFlipConfig.tiltSupportedOn(
      Theme.of(context).platform,
    );
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: CardFlipColors.teal,
          onPrimary: CardFlipColors.ink,
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: CardFlipColors.teal,
          thumbColor: CardFlipColors.tealBright,
          inactiveTrackColor: Color(0xFF243033),
          overlayColor: Color(0x3314B8A6),
        ),
      ),
      child: Scaffold(
        backgroundColor: CardFlipColors.background,
        appBar: AppBar(
          backgroundColor: CardFlipColors.background,
          foregroundColor: CardFlipColors.text,
          title: const Text('3D Card Flip'),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 840;
              final stage = _Stage(
                study: _study,
                controller: _controller,
                cube: _cube,
                basket: _basket,
                perspective: _perspective,
                duration: Duration(milliseconds: _durationMs.round()),
                curve: _curve.curve,
                autoFlip: _autoFlip,
                tapEnabled: _tapEnabled,
                tiltEnabled: _tiltEnabled,
              );
              final controls = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _StudyPicker(
                    study: _study,
                    onChanged: (value) => setState(() => _study = value),
                  ),
                  const SizedBox(height: 16),
                  if (_study == _Study.card)
                    FlipControls(
                      controller: _controller,
                      durationMs: _durationMs,
                      perspective: _perspective,
                      curve: _curve,
                      autoFlip: _autoFlip,
                      tapEnabled: _tapEnabled,
                      tiltEnabled: _tiltEnabled,
                      tiltSupported: tiltSupported,
                      onFlip: _flip,
                      onReset: _reset,
                      onDurationChanged: (value) {
                        setState(() => _durationMs = value);
                      },
                      onPerspectiveChanged: (value) {
                        setState(() => _perspective = value);
                      },
                      onCurveChanged: (value) => setState(() => _curve = value),
                      onAutoFlipChanged: (value) {
                        setState(() => _autoFlip = value);
                      },
                      onTapEnabledChanged: (value) {
                        setState(() => _tapEnabled = value);
                      },
                      onTiltEnabledChanged: (value) {
                        setState(() => _tiltEnabled = value);
                      },
                    )
                  else if (_study == _Study.cube)
                    _CubeControls(
                      controller: _cube,
                      onNext: () => _cube.next(instant: _reduceMotion),
                      onPrevious: () => _cube.previous(instant: _reduceMotion),
                      onReset: _cube.reset,
                    )
                  else
                    _BasketControls(
                      controller: _basket,
                      onDrop: () => _basket.drop(instant: _reduceMotion),
                      onOpen: () => _basket.open(instant: _reduceMotion),
                    ),
                ],
              );

              if (wide) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
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
                children: <Widget>[
                  Expanded(child: stage),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: math.max(180, constraints.maxHeight * 0.46),
                    ),
                    child: Material(
                      color: CardFlipColors.surface,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        child: controls,
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

class _StudyPicker extends StatelessWidget {
  const _StudyPicker({required this.study, required this.onChanged});

  final _Study study;
  final ValueChanged<_Study> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_Study>(
      showSelectedIcon: false,
      segments: const <ButtonSegment<_Study>>[
        ButtonSegment<_Study>(value: _Study.card, label: Text('Card')),
        ButtonSegment<_Study>(value: _Study.cube, label: Text('Cube')),
        ButtonSegment<_Study>(value: _Study.basket, label: Text('Basket')),
      ],
      selected: <_Study>{study},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _CubeControls extends StatelessWidget {
  const _CubeControls({
    required this.controller,
    required this.onNext,
    required this.onPrevious,
    required this.onReset,
  });

  final CubeFlipController controller;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onReset;

  static const List<String> _names = <String>[
    'ATLAS',
    'PRISM',
    'VECTOR',
    'DEPTH',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final name = _names[controller.face];
            final motion = controller.isAnimating ? 'turning' : 'resting';
            return Text(
              'Face · $name · $motion',
              style: const TextStyle(
                color: CardFlipColors.tealBright,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: onNext, child: const Text('Next face')),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: onPrevious,
          child: const Text('Previous face'),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: onReset, child: const Text('Reset cube')),
      ],
    );
  }
}

class _BasketControls extends StatelessWidget {
  const _BasketControls({
    required this.controller,
    required this.onDrop,
    required this.onOpen,
  });

  final BasketDropController controller;
  final VoidCallback onDrop;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final label = controller.isPacked
                ? 'Packed'
                : controller.isAnimating
                ? 'Moving'
                : 'Ready';
            return Text(
              'Basket · $label',
              style: const TextStyle(
                color: CardFlipColors.tealBright,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: onDrop, child: const Text('Add to basket')),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: onOpen, child: const Text('Open box')),
      ],
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({
    required this.study,
    required this.controller,
    required this.cube,
    required this.basket,
    required this.perspective,
    required this.duration,
    required this.curve,
    required this.autoFlip,
    required this.tapEnabled,
    required this.tiltEnabled,
  });

  final _Study study;
  final CardFlipController controller;
  final CubeFlipController cube;
  final BasketDropController basket;
  final double perspective;
  final Duration duration;
  final Curve curve;
  final bool autoFlip;
  final bool tapEnabled;
  final bool tiltEnabled;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        var width = math.min(300.0, math.max(1.0, maxWidth - 32));
        var height = math.min(420.0, width * 1.4);
        final heightCap = math.max(1.0, maxHeight - 24);
        if (height > heightCap) {
          height = heightCap;
          width = math.min(width, math.max(1.0, height / 1.4));
        }
        final side = math.min(180.0, math.min(width, height) * 0.72);
        return IndexedStack(
          index: study.index,
          alignment: Alignment.center,
          sizing: StackFit.expand,
          children: <Widget>[
            Center(
              child: FlipCard3D(
                controller: controller,
                width: width,
                height: height,
                perspective: perspective,
                duration: duration,
                curve: curve,
                autoFlip: autoFlip,
                enableTap: tapEnabled,
                tiltEnabled: tiltEnabled,
                front: const CardFront(),
                back: const CardBack(),
              ),
            ),
            Center(
              child: CubeFlip3D(
                controller: cube,
                side: math.max(96, side),
                faces: const <Widget>[
                  CubeFacePanel(kicker: '01', title: 'ATLAS'),
                  CubeFacePanel(kicker: '02', title: 'PRISM'),
                  CubeFacePanel(kicker: '03', title: 'VECTOR'),
                  CubeFacePanel(kicker: '04', title: 'DEPTH'),
                ],
              ),
            ),
            Center(
              child: BasketDrop(
                controller: basket,
                width: math.min(280, width),
                height: math.min(340, height),
              ),
            ),
          ],
        );
      },
    );
  }
}
