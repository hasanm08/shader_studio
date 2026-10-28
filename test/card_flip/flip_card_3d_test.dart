import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shader_studio/features/card_flip/application/card_flip_controller.dart';
import 'package:shader_studio/features/card_flip/presentation/pages/card_flip_demo_page.dart';
import 'package:shader_studio/features/card_flip/presentation/painters/card_decoration_painter.dart';
import 'package:shader_studio/features/card_flip/presentation/rendering/card_flip_transform.dart';
import 'package:shader_studio/features/card_flip/presentation/widgets/card_back.dart';
import 'package:shader_studio/features/card_flip/presentation/widgets/card_front.dart';
import 'package:shader_studio/features/card_flip/presentation/widgets/flip_card_3d.dart';

void main() {
  testWidgets('front is visible first, then the back, then the front again', (
    tester,
  ) async {
    final changed = <bool>[];
    final completed = <bool>[];
    late CardFlipController controller;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _Host(
            onCreated: (value) => controller = value,
            childBuilder: (value) => FlipCard3D(
              controller: value,
              width: 220,
              height: 300,
              duration: const Duration(milliseconds: 300),
              onFlipChanged: changed.add,
              onFlipCompleted: completed.add,
              front: const Text('FRONT-FACE'),
              back: const Text('BACK-FACE'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('FRONT-FACE'), findsOneWidget);
    expect(find.text('BACK-FACE'), findsNothing);
    expect(controller.isFlipped, isFalse);

    await tester.tap(find.byType(FlipCard3D));
    await tester.pump();
    expect(controller.isAnimating, isTrue);
    expect(find.text('BACK-FACE'), findsNothing);

    await tester.pump(const Duration(milliseconds: 360));
    expect(find.text('BACK-FACE'), findsOneWidget);
    expect(find.text('FRONT-FACE'), findsNothing);
    expect(controller.isFlipped, isTrue);
    expect(changed, <bool>[true]);
    expect(completed, <bool>[true]);

    await tester.tap(find.byType(FlipCard3D));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 360));
    expect(find.text('FRONT-FACE'), findsOneWidget);
    expect(find.text('BACK-FACE'), findsNothing);
    expect(controller.isFlipped, isFalse);
    expect(completed, <bool>[true, false]);
  });

  testWidgets('repeated taps do not throw', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlipCard3D(
            width: 180,
            height: 240,
            duration: Duration(milliseconds: 200),
            front: Text('FRONT-FACE'),
            back: Text('BACK-FACE'),
          ),
        ),
      ),
    );

    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byType(FlipCard3D));
      await tester.pump(const Duration(milliseconds: 40));
    }
    await tester.pumpAndSettle();
    expect(find.text('FRONT-FACE'), findsOneWidget);
    expect(find.text('BACK-FACE'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('programmatic commands flip and return', (tester) async {
    late CardFlipController controller;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _Host(
            onCreated: (value) => controller = value,
            childBuilder: (value) => FlipCard3D(
              controller: value,
              width: 180,
              height: 240,
              duration: const Duration(milliseconds: 200),
              front: const Text('FRONT-FACE'),
              back: const Text('BACK-FACE'),
            ),
          ),
        ),
      ),
    );

    controller.flipForward();
    await tester.pumpAndSettle();
    expect(find.text('BACK-FACE'), findsOneWidget);

    controller.flipBack();
    await tester.pumpAndSettle();
    expect(find.text('FRONT-FACE'), findsOneWidget);

    controller.toggle();
    await tester.pumpAndSettle();
    expect(controller.isFlipped, isTrue);
  });

  testWidgets('disabled interaction ignores taps', (tester) async {
    late CardFlipController controller;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _Host(
            onCreated: (value) => controller = value,
            childBuilder: (value) => FlipCard3D(
              controller: value,
              enableTap: false,
              width: 180,
              height: 240,
              front: const Text('FRONT-FACE'),
              back: const Text('BACK-FACE'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(FlipCard3D));
    await tester.pump(const Duration(milliseconds: 400));
    expect(controller.isFlipped, isFalse);
    expect(controller.isAnimating, isFalse);
    expect(find.text('FRONT-FACE'), findsOneWidget);

    controller.flipForward();
    await tester.pumpAndSettle();
    expect(find.text('BACK-FACE'), findsOneWidget);
  });

  testWidgets('custom faces and an initial back render', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlipCard3D(
            width: 160,
            height: 200,
            initiallyFlipped: true,
            front: Text('CUSTOM-FRONT'),
            back: ColoredBox(
              color: Color(0xFF112233),
              child: Text('CUSTOM-BACK'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('CUSTOM-BACK'), findsOneWidget);
    expect(find.text('CUSTOM-FRONT'), findsNothing);
  });

  testWidgets('reduced motion snaps to the other face', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: Scaffold(
          body: FlipCard3D(
            width: 160,
            height: 200,
            duration: Duration(milliseconds: 800),
            front: Text('FRONT-FACE'),
            back: Text('BACK-FACE'),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(FlipCard3D));
    await tester.pump();
    expect(find.text('BACK-FACE'), findsOneWidget);
    expect(find.text('FRONT-FACE'), findsNothing);
  });

  testWidgets('keyboard activation flips the card', (tester) async {
    late CardFlipController controller;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _Host(
            onCreated: (value) => controller = value,
            childBuilder: (value) => FlipCard3D(
              controller: value,
              width: 180,
              height: 220,
              duration: const Duration(milliseconds: 200),
              front: const Text('FRONT-FACE'),
              back: const Text('BACK-FACE'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    Focus.of(tester.element(find.text('FRONT-FACE'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(controller.isAnimating, isTrue);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('BACK-FACE'), findsOneWidget);
  });

  testWidgets('semantics describe the flip action', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlipCard3D(
            width: 160,
            height: 200,
            front: Text('FRONT-FACE'),
            back: Text('BACK-FACE'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.getSemantics(find.text('FRONT-FACE')),
      isSemantics(isButton: true, hint: 'Activate to flip the card'),
    );
    handle.dispose();
  });

  testWidgets('dispose during a flip does not leak a ticker', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlipCard3D(
            width: 140,
            height: 180,
            duration: Duration(milliseconds: 600),
            front: Text('FRONT-FACE'),
            back: Text('BACK-FACE'),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(FlipCard3D));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid dimensions and duration fail the contract', (
    tester,
  ) async {
    expect(
      () => FlipCard3D(
        width: 0,
        height: 120,
        front: const SizedBox.shrink(),
        back: const SizedBox.shrink(),
      ),
      throwsAssertionError,
    );
    expect(
      () => FlipCard3D(
        width: 120,
        height: double.nan,
        front: const SizedBox.shrink(),
        back: const SizedBox.shrink(),
      ),
      throwsAssertionError,
    );
    expect(
      () => FlipCard3D(
        width: 120,
        height: 120,
        duration: const Duration(milliseconds: -1),
        front: const SizedBox.shrink(),
        back: const SizedBox.shrink(),
      ),
      throwsAssertionError,
    );
  });

  testWidgets('demo page flips, resets, and stays within a narrow layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(home: CardFlipDemoPage()));
    await tester.pump();

    expect(find.text('3D Card Flip'), findsOneWidget);
    expect(find.text('Beyond Flat UI'), findsOneWidget);
    expect(find.text('FLOWFORGE LAB'), findsOneWidget);
    expect(find.text('Flip card'), findsOneWidget);
    expect(find.text('Reset to front'), findsOneWidget);
    expect(find.textContaining('Front ·'), findsOneWidget);

    await tester.tap(find.text('Flip card'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('MATRIX4'), findsOneWidget);
    expect(find.text('PERSPECTIVE'), findsOneWidget);
    expect(find.text('ROTATION'), findsOneWidget);
    expect(find.text('Beyond Flat UI'), findsNothing);
    expect(find.textContaining('Back ·'), findsOneWidget);

    await tester.tap(find.text('Reset to front'));
    await tester.pump();
    expect(find.text('Beyond Flat UI'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('flip-perspective-slider')),
      const Offset(40, 0),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpWidget(MaterialApp(home: CardFlipDemoPage()));
    await tester.pump();
    expect(find.text('Flip card'), findsOneWidget);
    expect(find.text('Beyond Flat UI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hover tilt changes the transform and then settles', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.macOS),
        home: Scaffold(
          body: FlipCard3D(
            width: 200,
            height: 260,
            tiltEnabled: true,
            front: Text('FRONT-FACE'),
            back: Text('BACK-FACE'),
          ),
        ),
      ),
    );
    await tester.pump();

    final resting = cardFlipTransform(
      angle: 0,
      perspective: 0.0015,
      correctBackFace: false,
      cardWidth: 200,
    );
    Transform cardTransform() {
      return tester.widget<Transform>(find.byType(Transform).first);
    }

    expect(cardTransform().transform.storage, resting.storage);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.byType(FlipCard3D)));
    await gesture.moveBy(const Offset(30, -20));
    await tester.pump();

    expect(cardTransform().transform.storage, isNot(equals(resting.storage)));

    await gesture.moveTo(const Offset(-20, -20));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));
    expect(cardTransform().transform.storage, resting.storage);
  });

  test('mark painter repaints only when its inputs change', () {
    const a = CardMarkPainter(variant: CardMarkVariant.prism);
    const b = CardMarkPainter(variant: CardMarkVariant.prism);
    const c = CardMarkPainter(variant: CardMarkVariant.schematic);
    expect(a.shouldRepaint(b), isFalse);
    expect(a.shouldRepaint(c), isTrue);
  });

  testWidgets('demo faces are the widgets the page builds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlipCard3D(
            width: 220,
            height: 320,
            front: CardFront(),
            back: CardBack(),
          ),
        ),
      ),
    );
    expect(find.byType(CardFront), findsOneWidget);
    expect(find.byType(CardBack), findsNothing);
    expect(find.text('Tap to flip'), findsOneWidget);
  });
}

class _Host extends StatefulWidget {
  const _Host({required this.childBuilder, required this.onCreated});

  final Widget Function(CardFlipController controller) childBuilder;
  final ValueChanged<CardFlipController> onCreated;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with SingleTickerProviderStateMixin {
  late final CardFlipController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CardFlipController(
      duration: const Duration(milliseconds: 300),
    )..createAndAttach(this);
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
