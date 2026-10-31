import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shader_studio/features/glass_refraction/rendering/glass_background_capture.dart';

void main() {
  testWidgets('captures a repaint boundary and disposes the image', (
    tester,
  ) async {
    final capture = GlassBackgroundCapture(pixelRatio: 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: capture.boundaryKey,
              child: const SizedBox(
                width: 200,
                height: 120,
                child: ColoredBox(color: Color(0xFF14E6CF)),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await capture.captureNow(force: true);
    expect(capture.hasImage, isTrue);
    expect(capture.logicalSize, const Size(200, 120));

    final sample = capture.sampleRectFor(const Rect.fromLTWH(20, 10, 80, 40));
    expect(sample.origin.dx, closeTo(0.1, 1e-9));
    expect(sample.origin.dy, closeTo(10 / 120, 1e-9));
    expect(sample.extent.width, closeTo(80 / 200, 1e-9));
    expect(sample.extent.height, closeTo(40 / 120, 1e-9));

    capture.dispose();
    expect(capture.hasImage, isFalse);
  });

  test('sampleRectFor clamps empty logical sizes', () {
    final capture = GlassBackgroundCapture();
    final sample = capture.sampleRectFor(const Rect.fromLTWH(0, 0, 10, 10));
    expect(sample.origin, Offset.zero);
    expect(sample.extent, Size.zero);
    capture.dispose();
  });
}
