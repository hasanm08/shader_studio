import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shader_studio/core/geometry/shape_type.dart';
import 'package:shader_studio/features/shape_morphing/application/shape_morph_controller.dart';

void main() {
  late ShapeMorphController controller;

  setUp(() {
    controller = ShapeMorphController(
      initialShape: ShapeType.circle,
      duration: const Duration(milliseconds: 400),
    );
    controller.createAndAttach(const TestVSync());
  });

  tearDown(() {
    if (!controller.isDisposed) {
      controller.dispose();
    }
  });

  testWidgets('forward morph reaches the star', (tester) async {
    expect(controller.displayedShape, ShapeType.circle);
    // Do not await: drive the ticker via pumpAndSettle instead.
    controller.morphTo(ShapeType.star);
    expect(controller.isAnimating, isTrue);
    expect(controller.toShape, ShapeType.star);

    await tester.pumpAndSettle();

    expect(controller.isAnimating, isFalse);
    expect(controller.displayedShape, ShapeType.star);
    expect(controller.progress, closeTo(1.0, 1e-6));
  });

  testWidgets('toggle reverses mid-flight between circle and star', (
    tester,
  ) async {
    controller.morphTo(ShapeType.star);
    await tester.pump(const Duration(milliseconds: 120));
    expect(controller.isAnimating, isTrue);

    controller.toggle(a: ShapeType.circle, b: ShapeType.star);
    await tester.pumpAndSettle();

    expect(controller.displayedShape, ShapeType.circle);
  });

  testWidgets('repeated transitions settle without glitches', (tester) async {
    for (var i = 0; i < 4; i++) {
      final target = i.isEven ? ShapeType.star : ShapeType.circle;
      controller.morphTo(target);
      await tester.pumpAndSettle();
      expect(controller.displayedShape, target);
      expect(controller.currentContour.isFinite, isTrue);
    }
  });

  testWidgets('mid-animation target change captures live contour', (
    tester,
  ) async {
    controller.morphTo(ShapeType.star);
    await tester.pump(const Duration(milliseconds: 100));
    final midContour = controller.currentContour;

    controller.morphTo(ShapeType.hexagon);
    expect(controller.toShape, ShapeType.hexagon);
    expect(controller.progress, closeTo(0.0, 1e-6));
    final after = controller.currentContour;
    expect(after.isFinite, isTrue);
    expect(
      (after.points.first - midContour.points.first).distance,
      lessThan(0.05),
    );

    await tester.pumpAndSettle();
    expect(controller.displayedShape, ShapeType.hexagon);
  });

  testWidgets('reset snaps to the requested shape', (tester) async {
    controller.morphTo(ShapeType.star);
    await tester.pumpAndSettle();
    expect(controller.displayedShape, ShapeType.star);

    controller.reset(ShapeType.triangle);
    expect(controller.displayedShape, ShapeType.triangle);
    expect(controller.fromShape, ShapeType.triangle);
    expect(controller.toShape, ShapeType.triangle);
    expect(controller.progress, 0);
  });

  testWidgets('play runs source to destination from idle', (tester) async {
    // Idle with from == to; bare forward() used to no-op visually.
    expect(controller.fromShape, controller.toShape);

    controller.play(from: ShapeType.circle, to: ShapeType.star);
    expect(controller.isAnimating, isTrue);
    expect(controller.fromShape, ShapeType.circle);
    expect(controller.toShape, ShapeType.star);

    await tester.pumpAndSettle();
    expect(controller.displayedShape, ShapeType.star);
  });

  testWidgets('play snaps to source before morphing when needed', (tester) async {
    controller.morphTo(ShapeType.hexagon);
    await tester.pumpAndSettle();
    expect(controller.displayedShape, ShapeType.hexagon);

    controller.play(from: ShapeType.circle, to: ShapeType.star);
    // Should have reset to circle then started toward star.
    expect(controller.fromShape, ShapeType.circle);
    expect(controller.toShape, ShapeType.star);

    await tester.pumpAndSettle();
    expect(controller.displayedShape, ShapeType.star);
  });

  testWidgets('reverse toward source when idle at destination', (tester) async {
    controller.morphTo(ShapeType.star);
    await tester.pumpAndSettle();

    controller.reverse(toward: ShapeType.circle);
    expect(controller.toShape, ShapeType.circle);
    await tester.pumpAndSettle();
    expect(controller.displayedShape, ShapeType.circle);
  });

  testWidgets('reverse mid-flight goes back to source of pair', (tester) async {
    controller.morphTo(ShapeType.star);
    await tester.pump(const Duration(milliseconds: 120));
    expect(controller.isAnimating, isTrue);

    controller.reverse();
    await tester.pumpAndSettle();
    expect(controller.displayedShape, ShapeType.circle);
  });

  testWidgets('morphTo destination from idle circle works', (tester) async {
    controller.morphTo(ShapeType.hexagon);
    expect(controller.isAnimating, isTrue);
    await tester.pumpAndSettle();
    expect(controller.displayedShape, ShapeType.hexagon);
  });

  testWidgets('different sizes map through the engine safely', (tester) async {
    final small = controller.engine.morphPath(
      ShapeType.circle,
      ShapeType.star,
      0.3,
      size: const Size(50, 50),
    );
    final large = controller.engine.morphPath(
      ShapeType.circle,
      ShapeType.star,
      0.3,
      size: const Size(400, 400),
    );
    expect(small.getBounds().width, lessThan(large.getBounds().width));
  });

  testWidgets('dispose detaches animation and is idempotent', (tester) async {
    controller.dispose();
    expect(controller.isDisposed, isTrue);
    expect(controller.isAttached, isFalse);
    controller.dispose();
    expect(controller.isDisposed, isTrue);
  });
}
