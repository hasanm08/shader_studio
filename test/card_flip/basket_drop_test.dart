import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shader_studio/features/card_flip/application/basket_drop_controller.dart';
import 'package:shader_studio/features/card_flip/presentation/pages/card_flip_demo_page.dart';
import 'package:shader_studio/features/card_flip/presentation/widgets/basket_drop.dart';

void main() {
  testWidgets('the item lands in the box and comes back out', (tester) async {
    final controller = BasketDropController(
      duration: const Duration(milliseconds: 400),
    )..createAndAttach(const TestVSync());
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: BasketDrop(controller: controller)),
        ),
      ),
    );

    final start = tester.getTopLeft(find.text('PACK')).dy;
    expect(controller.isPacked, isFalse);

    controller.drop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(controller.itemProgress, greaterThan(0));
    expect(controller.lidProgress, 0);

    await tester.pumpAndSettle();
    expect(controller.isPacked, isTrue);
    expect(tester.getTopLeft(find.text('PACK')).dy, greaterThan(start + 40));

    controller.drop();
    expect(controller.isAnimating, isFalse);

    controller.open();
    await tester.pumpAndSettle();
    expect(controller.isPacked, isFalse);
    expect(controller.progress, closeTo(0, 1e-6));
    expect(tester.getTopLeft(find.text('PACK')).dy, closeTo(start, 1));
  });

  testWidgets('the demo can turn the cube and pack the basket', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: CardFlipDemoPage()));
    await tester.pump();

    await tester.tap(find.text('Cube'));
    await tester.pumpAndSettle();
    expect(find.text('ATLAS'), findsOneWidget);
    expect(find.text('Next face'), findsOneWidget);

    await tester.tap(find.text('Next face'));
    await tester.pumpAndSettle();
    expect(find.text('PRISM'), findsOneWidget);
    expect(find.text('ATLAS'), findsNothing);
    expect(find.textContaining('Face · PRISM'), findsOneWidget);

    await tester.tap(find.text('Basket'));
    await tester.pumpAndSettle();
    expect(find.text('Add to basket'), findsOneWidget);
    expect(find.textContaining('Basket · Ready'), findsOneWidget);

    final start = tester.getTopLeft(find.text('PACK')).dy;
    await tester.tap(find.text('Add to basket'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Basket · Packed'), findsOneWidget);
    expect(tester.getTopLeft(find.text('PACK')).dy, greaterThan(start + 20));

    await tester.tap(find.text('Open box'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Basket · Ready'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
