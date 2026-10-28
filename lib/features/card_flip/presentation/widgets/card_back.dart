import 'package:flutter/material.dart';
import 'package:shader_studio/features/card_flip/presentation/painters/card_decoration_painter.dart';
import 'package:shader_studio/features/card_flip/presentation/theme/card_flip_colors.dart';
import 'package:shader_studio/features/card_flip/presentation/widgets/fancy_card_shell.dart';

/// Back of the FlowForge demo card.
class CardBack extends StatelessWidget {
  /// Creates the back face.
  const CardBack({super.key});

  @override
  Widget build(BuildContext context) {
    return const FancyCardShell(
      child: Padding(
        padding: EdgeInsets.fromLTRB(28, 24, 28, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _BackEyebrow('RENDER PATH'),
            Expanded(
              child: CustomPaint(
                painter: CardMarkPainter(variant: CardMarkVariant.schematic),
                child: SizedBox.expand(),
              ),
            ),
            Text(
              'A Y-axis turn with perspective. '
              'The back face is corrected so type stays upright.',
              style: TextStyle(
                color: CardFlipColors.text,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                _Label('PERSPECTIVE'),
                _Label('MATRIX4'),
                _Label('ROTATION'),
              ],
            ),
            SizedBox(height: 18),
            _BackHint(),
          ],
        ),
      ),
    );
  }
}

class _BackEyebrow extends StatelessWidget {
  const _BackEyebrow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: CardFlipColors.tealBright,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.7,
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x2214B8A6),
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        border: Border.all(color: const Color(0x5514B8A6)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          text,
          style: const TextStyle(
            color: CardFlipColors.tealBright,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _BackHint extends StatelessWidget {
  const _BackHint();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        Icon(Icons.flip, size: 15, color: CardFlipColors.textMuted),
        SizedBox(width: 8),
        Text(
          'Tap to return',
          style: TextStyle(
            color: CardFlipColors.textMuted,
            fontSize: 12,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
