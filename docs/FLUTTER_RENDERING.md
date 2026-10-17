# Flutter rendering

## FragmentProgram

`ShaderLoader.load` calls `FragmentProgram.fromAsset` with a key such as `shaders/liquid_aurora.frag`. Flutter's tool runs that file through `impellerc` because it is listed under `flutter: shaders`. The key must match the pubspec path.

The engine caches a program that loaded successfully for the process lifetime. `ShaderLoader` also caches the `Future`, so the gallery's cards and a later playground share one load. There is no Dart method to dispose the program. A failure is removed from the Dart cache and rethrown as `ShaderLoadException`.

## FragmentShader

`program.fragmentShader()` allocates a uniform buffer sized to the compiled shader and zero-fills it. `ShaderCanvas` keeps one shader per preview and disposes it with the state. Two previews need two shaders even when they share a program, because each has its own uniform values.

`FragmentShaderSink` looks up uniforms by name and caches the slots. `setFloat` writes the `Float32List` the engine reads for that draw. Slots created through the named API are updated by the engine on shader hot reload.

## Canvas and CustomPainter

`ShaderRenderer.paint` writes uniforms, then:

```dart
canvas.drawRect(Offset.zero & size, Paint()..shader = sink.shader);
```

`CustomPainter(repaint: controller.paintTick)` is how a tick repaints without `setState`. `shouldRepaint` returns true only when the shader or the controller instance changes. The listenable covers the per-frame case.

`ShaderCanvas` puts a `SizedBox.expand` under the paint so the painter receives the parent's constraints. The preview clips with `ClipRRect`.

This path is `Paint.shader`, not `ImageFilter.shader`. The filter API wants the first uniform to be a `vec2` size and requires a `sampler2D`, and it is Impeller-only. These samples are full-screen colors, not filters of an input image, so they do not take that API.

## What Dart does and what the shader does

Dart loads the program, advances time, stores pointer and ripple history, clamps parameters, and fills the uniform buffer. The shader, for each fragment, reads those uniforms and writes `fragColor`. This document does not claim a specific GPU scheduling order beyond that split.

`FlutterFragCoord` for a shader attached to `Paint` comes from the runtime-effect vertex setup. On the Impeller backend it is an interpolated canvas position. The shaders treat it as the same space as the logical `Size` passed from the painter. If a backend ever reports device pixels instead, the picture stretches or letterboxes; `docs/TROUBLESHOOTING.md` says how to recognize that.

## Repainting

`ShaderController.addDelta` pings `paintTick` and, about twice a second, `frameTick`. It does not ping `controlsTick`. Sliders stay still while time moves.

The debug label `Ticker ~N fps` is the reciprocal of the mean of the last 30 ticker deltas, refreshed every half second. It is not a GPU query and it is compiled into the overlay only when `kDebugMode` is true. No frame rate is promised.

## Asset loading of source

The code panel reads GLSL from `ShaderSources`, because Flutter rejects a file listed under both `flutter: shaders` and `flutter: assets`. `tool/mirror_shader_sources.dart` rewrites that mirror, and the contract test compares it to `shaders/`. The Dart writer is a real asset, sliced between `// BEGIN <id>` and `// END <id>`.
