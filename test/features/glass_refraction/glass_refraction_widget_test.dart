import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shader_studio/app/theme/app_theme.dart';
import 'package:shader_studio/features/glass_refraction/domain/models/glass_refraction_config.dart';
import 'package:shader_studio/features/glass_refraction/domain/models/glass_shape.dart';
import 'package:shader_studio/features/glass_refraction/presentation/pages/glass_demo_page.dart';
import 'package:shader_studio/features/glass_refraction/presentation/widgets/glass_card.dart';
import 'package:shader_studio/features/glass_refraction/presentation/widgets/glass_media_controls.dart';
import 'package:shader_studio/features/glass_refraction/presentation/widgets/glass_navigation.dart';
import 'package:shader_studio/features/glass_refraction/presentation/widgets/glass_refraction.dart';
import 'package:shader_studio/features/glass_refraction/presentation/widgets/glass_scene.dart';
import 'package:shader_studio/features/glass_refraction/rendering/glass_shader_renderer.dart';

void main() {
  setUp(() {
    GlassShaderProgram.debugReset();
  });

  testWidgets('GlassRefraction builds under GlassScene and shows child', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: GlassScene(
            background: const ColoredBox(color: Color(0xFF224466)),
            child: const Center(
              child: GlassRefraction(
                width: 180,
                height: 100,
                config: GlassRefractionConfig(animateHighlights: false),
                shape: GlassShape.roundedRectangle,
                child: Text('Lens child'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Lens child'), findsOneWidget);
    expect(find.byType(GlassRefraction), findsOneWidget);
  });

  testWidgets('resizing the glass updates layout constraints', (tester) async {
    var width = 160.0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: GlassScene(
                background: const ColoredBox(color: Colors.black),
                child: Center(
                  child: GlassRefraction(
                    width: width,
                    height: 90,
                    config: const GlassRefractionConfig(
                      animateHighlights: false,
                    ),
                    child: Text('w=${width.round()}'),
                  ),
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () => setState(() => width = 240),
                child: const Icon(Icons.add),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    expect(find.text('w=160'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    expect(find.text('w=240'), findsOneWidget);
  });

  testWidgets('production examples construct', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: GlassScene(
            background: const ColoredBox(
              color: Color(0xFF102030),
              child: FlutterLogo(size: 200),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const GlassCard(),
                const SizedBox(height: 12),
                GlassNavigation(index: 0, onChanged: (_) {}),
                const SizedBox(height: 12),
                GlassMediaControls(
                  playing: false,
                  progress: 0.2,
                  volume: 0.5,
                  onPlayPause: () {},
                  onProgressChanged: (_) {},
                  onVolumeChanged: (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Optical stack'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Aurora Drift'), findsOneWidget);
  });

  testWidgets('demo page builds playground chrome', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark(), home: const GlassDemoPage()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text('Glass Refraction'), findsOneWidget);
    expect(find.text('Presets'), findsOneWidget);
    expect(find.text('Clear Glass'), findsOneWidget);
    expect(find.text('Drag the glass'), findsOneWidget);
  });

  testWidgets('fallback painter paints without a shader', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CustomPaint(
          size: const Size(120, 80),
          painter: GlassFallbackPainter(
            config: const GlassRefractionConfig(),
            shape: GlassShape.circle,
            borderRadius: BorderRadius.circular(40),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
