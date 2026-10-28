import 'package:flutter/material.dart';
import 'package:shader_studio/features/card_flip/presentation/painters/card_decoration_painter.dart';
import 'package:shader_studio/features/card_flip/presentation/theme/card_flip_colors.dart';
import 'package:shader_studio/features/card_flip/presentation/widgets/fancy_card_shell.dart';

/// Front of the FlowForge demo card.
class CardFront extends StatelessWidget {
  /// Creates the front face.
  const CardFront({super.key});

  @override
  Widget build(BuildContext context) {
    return const FancyCardShell(
      child: Padding(
        padding: EdgeInsets.fromLTRB(28, 24, 28, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _Eyebrow('FLOWFORGE LAB'),
            Expanded(
              child: CustomPaint(
                painter: CardMarkPainter(variant: CardMarkVariant.prism),
                child: SizedBox.expand(),
              ),
            ),
            Text(
              'Beyond Flat UI',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _titleStyle,
            ),
            SizedBox(height: 8),
            Text('Explore the third dimension.', style: _subtitleStyle),
            SizedBox(height: 18),
            _Hint(icon: Icons.flip, label: 'Tap to flip'),
          ],
        ),
      ),
    );
  }
}

const TextStyle _titleStyle = TextStyle(
  color: CardFlipColors.text,
  fontSize: 28,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.6,
  height: 1.05,
);

const TextStyle _subtitleStyle = TextStyle(
  color: CardFlipColors.textMuted,
  fontSize: 15,
  height: 1.35,
);

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label);

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

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 15, color: CardFlipColors.textMuted),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: CardFlipColors.textMuted,
              fontSize: 12,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}
