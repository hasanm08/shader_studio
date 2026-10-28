import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shader_studio/features/card_flip/application/card_flip_controller.dart';
import 'package:shader_studio/features/card_flip/domain/models/card_flip_config.dart';

void main() {
  late CardFlipController controller;

  setUp(() {
    controller = CardFlipController(duration: const Duration(milliseconds: 400))
      ..createAndAttach(const TestVSync());
  });

  tearDown(() {
    if (!controller.isDisposed) {
      controller.dispose();
    }
  });

  testWidgets('starts on the front and flipForward settles on the back', (
    tester,
  ) async {
    expect(controller.isFlipped, isFalse);
    expect(controller.showBack, isFalse);
    expect(controller.orientation, CardSide.front);

    final changed = <bool>[];
    final completed = <bool>[];
    controller.onFlipChanged = changed.add;
    controller.onCompleted = completed.add;

    controller.flipForward();
    expect(controller.isAnimating, isTrue);

    await tester.pumpAndSettle();

    expect(controller.isAnimating, isFalse);
    expect(controller.isFlipped, isTrue);
    expect(controller.showBack, isTrue);
    expect(controller.angle, closeTo(3.1415926535, 1e-6));
    expect(changed, <bool>[true]);
    expect(completed, <bool>[true]);
  });

  testWidgets('flipBack and a second toggle return to the front', (
    tester,
  ) async {
    controller.flipForward();
    await tester.pumpAndSettle();

    controller.flipBack();
    await tester.pumpAndSettle();
    expect(controller.isFlipped, isFalse);
    expect(controller.showBack, isFalse);

    controller.toggle();
    await tester.pumpAndSettle();
    expect(controller.isFlipped, isTrue);

    controller.flip();
    await tester.pumpAndSettle();
    expect(controller.isFlipped, isFalse);
  });

  testWidgets('a request during a flip reverses direction', (tester) async {
    controller.flipForward();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(controller.isAnimating, isTrue);
    expect(controller.progress, greaterThan(0.1));
    expect(controller.showBack, isFalse);

    controller.toggle();
    await tester.pumpAndSettle();

    expect(controller.isFlipped, isFalse);
    expect(controller.progress, closeTo(0, 1e-6));
  });

  testWidgets('repeated commands settle without throwing', (tester) async {
    for (var i = 0; i < 5; i++) {
      if (i.isEven) {
        controller.flipForward();
      } else {
        controller.flipBack();
      }
      await tester.pump(const Duration(milliseconds: 30));
    }
    await tester.pumpAndSettle();
    expect(controller.isAnimating, isFalse);
    expect(controller.angle.isFinite, isTrue);
    expect(controller.isFlipped, isTrue);
  });

  testWidgets('flipForward while reversing turns back toward the back', (
    tester,
  ) async {
    controller.flipForward();
    await tester.pumpAndSettle();
    controller.flipBack();
    await tester.pump(const Duration(milliseconds: 100));

    controller.flipForward();
    await tester.pumpAndSettle();
    expect(controller.isFlipped, isTrue);
  });

  testWidgets('reset snaps to the front without a completion callback', (
    tester,
  ) async {
    final completed = <bool>[];
    final changed = <bool>[];
    controller.onCompleted = completed.add;
    controller.onFlipChanged = changed.add;

    controller.flipForward();
    await tester.pumpAndSettle();
    completed.clear();
    changed.clear();

    controller.reset();
    expect(controller.isFlipped, isFalse);
    expect(controller.progress, 0);
    expect(controller.showBack, isFalse);
    expect(completed, isEmpty);
    expect(changed, <bool>[false]);
  });

  testWidgets('the curve changes progress inside the flip', (tester) async {
    controller.curve = Curves.linear;
    controller.flipForward();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.progress, closeTo(0.25, 0.04));
    expect(controller.curvedProgress, closeTo(0.25, 0.04));

    controller.reset();
    controller.curve = Curves.easeInOutCubic;
    controller.flipForward();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.curvedProgress, lessThan(0.12));
    await tester.pumpAndSettle();
  });

  testWidgets('different durations are accepted', (tester) async {
    controller.duration = const Duration(milliseconds: 1000);
    expect(controller.duration, const Duration(milliseconds: 1000));
    controller.duration = const Duration(milliseconds: -5);
    expect(controller.duration, Duration.zero);

    controller.duration = const Duration(milliseconds: 200);
    controller.flipForward();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    expect(controller.isFlipped, isTrue);
  });

  testWidgets('instant flip reports the final side', (tester) async {
    final completed = <bool>[];
    controller.onCompleted = completed.add;
    controller.flipForward(instant: true);
    expect(controller.isFlipped, isTrue);
    expect(controller.showBack, isTrue);
    expect(completed, <bool>[true]);
    await tester.pump();
  });

  testWidgets('dispose during a flip does not throw or leak a ticker', (
    tester,
  ) async {
    controller.flipForward();
    await tester.pump(const Duration(milliseconds: 40));
    controller.dispose();
    await tester.pump(const Duration(milliseconds: 500));
    expect(controller.isDisposed, isTrue);
  });
}
