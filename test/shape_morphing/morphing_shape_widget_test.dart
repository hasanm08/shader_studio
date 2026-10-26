import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shader_studio/core/geometry/shape_factory.dart';
import 'package:shader_studio/core/geometry/shape_type.dart';
import 'package:shader_studio/features/shape_morphing/application/shape_morph_controller.dart';
import 'package:shader_studio/features/shape_morphing/domain/models/morph_shape.dart';
import 'package:shader_studio/features/shape_morphing/presentation/painters/morph_shape_painter.dart';
import 'package:shader_studio/features/shape_morphing/presentation/pages/shape_morphing_demo_page.dart';
import 'package:shader_studio/features/shape_morphing/presentation/widgets/circle_shape.dart';
import 'package:shader_studio/features/shape_morphing/presentation/widgets/morphing_shape.dart';
import 'package:shader_studio/features/shape_morphing/presentation/widgets/star_shape.dart';

void main() {
  testWidgets('MorphingShape toggles circle to star on tap', (tester) async {
    late ShapeMorphController controller;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _ControllerHost(
            onCreated: (c) => controller = c,
            childBuilder: (c) => MorphingShape(
              controller: c,
              size: 180,
              duration: const Duration(milliseconds: 300),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(controller.displayedShape, ShapeType.circle);

    await tester.tap(find.byType(MorphingShape));
    await tester.pump();
    expect(controller.isAnimating, isTrue);
    expect(controller.toShape, ShapeType.star);

    await tester.pump(const Duration(milliseconds: 350));
    expect(controller.displayedShape, ShapeType.star);

    await tester.tap(find.byType(MorphingShape));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(controller.displayedShape, ShapeType.circle);
  });

  testWidgets('MorphingShape disposes owned controller', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MorphingShape(size: 100))),
    );
    await tester.pump();

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
  });

  testWidgets('static shape widgets paint without error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(children: [CircleShape(size: 80), StarShape(size: 80)]),
        ),
      ),
    );
    expect(find.byType(CircleShape), findsOneWidget);
    expect(find.byType(StarShape), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('demo page shows controls and morphing shape', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: ShapeMorphingDemoPage()));
    await tester.pump();

    expect(find.text('Shape Morphing'), findsOneWidget);
    expect(find.text('Toggle Circle ↔ Star'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
    expect(find.byType(MorphingShape), findsOneWidget);

    await tester.tap(find.text('Toggle Circle ↔ Star'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.textContaining('Star'), findsWidgets);

    await tester.tap(find.text('Reset'));
    await tester.pump();
    expect(find.textContaining('Circle'), findsWidgets);

    await tester.tap(find.text('Play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.textContaining('Star'), findsWidgets);

    await tester.tap(find.text('Reverse'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.textContaining('Circle'), findsWidgets);

    await tester.tap(find.text('Morph to target'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.textContaining('Star'), findsWidgets);
  });

  test('painter shouldRepaint reacts to contour and style', () {
    final a = MorphShapePainter(
      contour: ShapeFactory.contour(ShapeType.circle),
      style: MorphShapeStyle.flowForge,
    );
    final b = MorphShapePainter(
      contour: ShapeFactory.contour(ShapeType.circle),
      style: MorphShapeStyle.flowForge,
    );
    final c = MorphShapePainter(
      contour: ShapeFactory.contour(ShapeType.star),
      style: MorphShapeStyle.flowForge,
    );
    final d = MorphShapePainter(
      contour: ShapeFactory.contour(ShapeType.circle),
      style: const MorphShapeStyle(fillColor: Color(0xFFFF0000)),
    );

    expect(a.shouldRepaint(b), isFalse);
    expect(a.shouldRepaint(c), isTrue);
    expect(a.shouldRepaint(d), isTrue);
  });
}

/// Host that owns a [ShapeMorphController] and its ticker.
class _ControllerHost extends StatefulWidget {
  const _ControllerHost({required this.childBuilder, required this.onCreated});

  final Widget Function(ShapeMorphController controller) childBuilder;
  final ValueChanged<ShapeMorphController> onCreated;

  @override
  State<_ControllerHost> createState() => _ControllerHostState();
}

class _ControllerHostState extends State<_ControllerHost>
    with SingleTickerProviderStateMixin {
  late final ShapeMorphController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ShapeMorphController(
      initialShape: ShapeType.circle,
      duration: const Duration(milliseconds: 300),
    );
    _controller.createAndAttach(this);
    widget.onCreated(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.childBuilder(_controller);
}
