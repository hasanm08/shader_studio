import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shader_studio/features/card_flip/domain/models/card_flip_config.dart';

void main() {
  test('perspective clamps to a stable range', () {
    expect(CardFlipConfig.clampPerspective(0.0015), closeTo(0.0015, 1e-9));
    expect(CardFlipConfig.clampPerspective(-1), CardFlipConfig.minPerspective);
    expect(
      CardFlipConfig.clampPerspective(10),
      lessThanOrEqualTo(CardFlipConfig.maxPerspective),
    );
    expect(
      CardFlipConfig.clampPerspective(double.nan),
      CardFlipConfig.defaultPerspective,
    );
    expect(
      CardFlipConfig.clampPerspective(double.infinity),
      lessThanOrEqualTo(CardFlipConfig.maxPerspective),
    );
  });

  test('wide cards tighten the perspective upper bound', () {
    final wide = CardFlipConfig.clampPerspective(0.0028, width: 800);
    expect(wide, lessThan(0.0028));
    expect(wide, greaterThanOrEqualTo(CardFlipConfig.minPerspective));
  });

  test('durations are accepted and negatives become instant', () {
    expect(
      CardFlipConfig.normalizeDuration(const Duration(milliseconds: 450)),
      const Duration(milliseconds: 450),
    );
    expect(CardFlipConfig.normalizeDuration(Duration.zero), Duration.zero);
    expect(
      CardFlipConfig.normalizeDuration(const Duration(milliseconds: -20)),
      Duration.zero,
    );
  });

  test('tilt is clamped and limited to desktop pointers', () {
    expect(CardFlipConfig.clampTilt(0.05), closeTo(0.05, 1e-9));
    expect(CardFlipConfig.clampTilt(4), CardFlipConfig.maxTilt);
    expect(CardFlipConfig.clampTilt(-4), -CardFlipConfig.maxTilt);
    expect(CardFlipConfig.clampTilt(double.nan), 0);
    expect(CardFlipConfig.tiltSupportedOn(TargetPlatform.iOS), isFalse);
    expect(CardFlipConfig.tiltSupportedOn(TargetPlatform.android), isFalse);
    expect(CardFlipConfig.tiltSupportedOn(TargetPlatform.macOS), isTrue);
    expect(CardFlipConfig.tiltSupportedOn(TargetPlatform.linux), isTrue);
  });

  test('the back face starts after the edge-on angle', () {
    expect(CardFlipConfig.showsBack(0), isFalse);
    expect(CardFlipConfig.showsBack(1.57), isFalse);
    expect(CardFlipConfig.showsBack(1.58), isTrue);
    expect(CardFlipConfig.showsBack(double.nan), isFalse);
  });
}
