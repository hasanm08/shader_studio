import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shader_studio/features/card_flip/domain/models/card_flip_config.dart';
import 'package:shader_studio/features/card_flip/presentation/rendering/card_flip_transform.dart';

void main() {
  test('perspective is stored before a flat rotation', () {
    final matrix = cardFlipTransform(
      angle: 0,
      perspective: 0.0015,
      correctBackFace: false,
    );
    expect(matrix.entry(3, 2), closeTo(0.0015, 1e-9));
    for (final entry in matrix.storage) {
      expect(entry.isFinite, isTrue);
    }
  });

  test('out-of-range perspective is bounded and stays finite', () {
    final matrix = cardFlipTransform(
      angle: 0,
      perspective: 40,
      correctBackFace: false,
      cardWidth: 300,
    );
    expect(
      matrix.entry(3, 2),
      closeTo(CardFlipConfig.clampPerspective(40, width: 300), 1e-9),
    );
    expect(
      matrix.entry(3, 2),
      lessThanOrEqualTo(CardFlipConfig.maxPerspective),
    );

    final nanMatrix = cardFlipTransform(
      angle: math.pi,
      perspective: double.nan,
      correctBackFace: true,
    );
    for (final entry in nanMatrix.storage) {
      expect(entry.isFinite, isTrue);
    }
  });

  test(
    'back-face correction keeps the right edge unmirrored at 180 degrees',
    () {
      final corrected = cardFlipTransform(
        angle: math.pi,
        perspective: 0.0015,
        correctBackFace: true,
      );
      final mirrored = cardFlipTransform(
        angle: math.pi,
        perspective: 0.0015,
        correctBackFace: false,
      );

      final correctedX = _projectX(corrected, 80);
      final mirroredX = _projectX(mirrored, 80);

      expect(correctedX, greaterThan(0));
      expect(mirroredX, lessThan(0));
      expect(correctedX, closeTo(80, 1));
    },
  );

  test('the silhouette collapses at the edge and opens again on the back', () {
    expect(_span(0, back: false), closeTo(200, 1));
    expect(_span(math.pi / 2, back: false), lessThan(8));
    expect(_span(math.pi, back: true), closeTo(200, 8));

    final before = _span(math.pi / 2 - 0.03, back: false);
    final after = _span(math.pi / 2 + 0.03, back: true);
    expect((before - after).abs(), lessThan(12));
  });

  test('tilt beyond the limit matches the clamped angle', () {
    final over = cardFlipTransform(
      angle: 0,
      perspective: 0.001,
      correctBackFace: false,
      tiltX: 5,
      tiltY: -5,
    );
    final capped = cardFlipTransform(
      angle: 0,
      perspective: 0.001,
      correctBackFace: false,
      tiltX: CardFlipConfig.maxTilt,
      tiltY: -CardFlipConfig.maxTilt,
    );
    expect(over.storage, capped.storage);
  });
}

double _span(double angle, {required bool back}) {
  final matrix = cardFlipTransform(
    angle: angle,
    perspective: 0.001,
    correctBackFace: back,
  );
  return (_projectX(matrix, 100) - _projectX(matrix, -100)).abs();
}

/// Perspective divide for a point on the card, matching [Matrix4.perspectiveTransform].
double _projectX(Matrix4 matrix, double x) {
  final storage = matrix.storage;
  final projected = storage[0] * x + storage[12];
  final w = storage[3] * x + storage[15];
  return projected / w;
}
