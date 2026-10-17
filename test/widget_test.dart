import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shader_studio/app/shader_studio_app.dart';

void main() {
  testWidgets('gallery opens the aurora playground controls', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ShaderStudioApp());
    expect(find.text('Shader Studio'), findsOneWidget);
    expect(find.text('Living Liquid Aurora'), findsWidgets);
    expect(find.text('Open playground'), findsOneWidget);

    await tester.tap(find.text('Open playground'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Distortion'), findsOneWidget);
    expect(find.text('Color intensity'), findsOneWidget);

    await tester.tap(find.byTooltip('Pause animation').first);
    await tester.pump();
    expect(find.byTooltip('Resume animation'), findsWidgets);

    await tester.tap(find.byTooltip('Reset parameters').first);
    await tester.pump();
    expect(find.text('1.25'), findsWidgets);
  });
}
