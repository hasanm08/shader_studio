import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shader_studio/features/card_flip/application/cube_flip_controller.dart';
import 'package:shader_studio/features/card_flip/presentation/rendering/cube_face_transform.dart';
import 'package:shader_studio/features/card_flip/presentation/widgets/cube_flip_3d.dart';

void main() {
  test('a resting face sits in front and the opposite face sits behind', () {
    final front = cubeFaceTransform(spin: 0, index: 0, depth: 50);
    expect(front.storage[14], closeTo(50, 0.01));
    expect(cubeFaceDepth(spin: 0, index: 0), closeTo(1, 1e-6));
    expect(cubeFaceDepth(spin: 0, index: 2), closeTo(-1, 1e-6));

    final side = cubeFaceTransform(spin: 0, index: 1, depth: 50);
    expect(side.storage[12], closeTo(-50, 0.01));
    expect(cubeFaceDepth(spin: math.pi / 4, index: 0), greaterThan(0.02));
    expect(cubeFaceDepth(spin: math.pi / 4, index: 1), greaterThan(0.02));
  });

  testWidgets('next, previous, and reset settle on the expected face', (
    tester,
  ) async {
    final controller = CubeFlipController(
      duration: const Duration(milliseconds: 300),
    )..createAndAttach(const TestVSync());
    addTearDown(controller.dispose);

    expect(controller.face, 0);
    controller.next();
    await tester.pumpAndSettle();
    expect(controller.face, 1);
    expect(controller.isAnimating, isFalse);

    controller.previous();
    await tester.pumpAndSettle();
    expect(controller.face, 0);

    controller.previous();
    await tester.pumpAndSettle();
    expect(controller.face, 3);

    controller.next(instant: true);
    controller.next(instant: true);
    expect(controller.face, 1);
    expect(controller.spin, closeTo(math.pi / 2, 1e-6));

    controller.reset();
    expect(controller.face, 0);
    expect(controller.spin, 0);
  });

  testWidgets('a second next during a turn continues to the following face', (
    tester,
  ) async {
    final controller = CubeFlipController(
      duration: const Duration(milliseconds: 400),
    )..createAndAttach(const TestVSync());
    addTearDown(controller.dispose);

    controller.next();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(controller.isAnimating, isTrue);

    controller.next();
    await tester.pumpAndSettle();
    expect(controller.face, 2);
    expect(controller.isAnimating, isFalse);
  });

  testWidgets('the cube shows one face and turns to the next', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CubeFlip3D(
            faces: <Widget>[
              Text('FACE-ATLAS'),
              Text('FACE-PRISM'),
              Text('FACE-VECTOR'),
              Text('FACE-DEPTH'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('FACE-ATLAS'), findsOneWidget);
    expect(find.text('FACE-PRISM'), findsNothing);

    await tester.tap(find.text('FACE-ATLAS'));
    await tester.pumpAndSettle();

    expect(find.text('FACE-PRISM'), findsOneWidget);
    expect(find.text('FACE-ATLAS'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
