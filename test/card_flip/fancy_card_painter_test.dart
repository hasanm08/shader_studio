import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shader_studio/features/card_flip/presentation/painters/fancy_card_painter.dart';

void main() {
  test('the silhouette cuts the corners and both side notches', () {
    final path = fancyCardPath(const Size(300, 420));

    expect(path.contains(const Offset(2, 2)), isFalse);
    expect(path.contains(const Offset(298, 2)), isFalse);
    expect(path.contains(const Offset(150, 16)), isTrue);
    expect(path.contains(const Offset(150, 210)), isTrue);
    expect(path.contains(const Offset(294, 210)), isFalse);
    expect(path.contains(const Offset(6, 210)), isFalse);
    expect(path.contains(const Offset(40, 210)), isTrue);

    expect(fancyCardPath(const Size(4, 4)).getBounds(), Rect.zero);
    expect(
      const FancyCardClipper().shouldReclip(const FancyCardClipper()),
      isFalse,
    );
    expect(
      const FancyCardPainter().shouldRepaint(const FancyCardPainter()),
      isFalse,
    );
  });
}
