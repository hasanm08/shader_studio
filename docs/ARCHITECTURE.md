# Architecture

Shader Studio keeps four kinds of code apart: shader text, sample metadata, a shared renderer, and the screens.

```text
shaders/*.frag
    compiled by Flutter from pubspec `shaders:`
    mirrored into ShaderSources for the code panel

ShaderSampleRegistry
    names, ranges, uniform index tables

ShaderSampleController
    time, pointer, parameter values, ripple slots

writeSampleUniforms
    copies that state into a FragmentShader by name

ShaderCanvas / ShaderRenderer
    owns the FragmentShader, ticker, and paint
```

## Why this split

The `.frag` file is the technique. The registry is the contract a control panel can read without parsing GLSL at runtime. The controller is the only mutable playback state, so two previews of one sample do not share a clock. The writer is the only place that knows which Dart field becomes which uniform. The canvas is the only place that creates and disposes a `FragmentShader`.

A seventh sample should not copy the ticker, the loader, or the preview widget.

## State ownership

| State | Owner | Who listens |
|---|---|---|
| Compiled `FragmentProgram` | `ShaderLoader`, and the engine's own cache | Canvases awaiting `load` |
| `FragmentShader` | `ShaderCanvas` state | `ShaderRenderer` |
| Time, pause, pointer | `ShaderController` | `paintTick` for the painter, `controlsTick` for sliders |
| Slider and color values | `ShaderSampleController` | Same signals |
| Ripple slots | `RippleBuffer` on the controller | The ripple writer |
| Sample definitions | `ShaderSampleRegistry` | Gallery, router, tests |

`paintTick` fires every animation frame. `controlsTick` fires when a slider, color, preset, pause, or reset changes. The control panel does not listen to `paintTick`, so the widget tree is not rebuilt 60 times a second.

## Resource lifetime

`ShaderLoader.load` caches the `Future<FragmentProgram>`. `FragmentProgram.fromAsset` also caches a successful program for the process. There is no public dispose for the program. Failed futures are dropped so Retry can try again.

`ShaderCanvas` calls `program.fragmentShader()` once per successful load and `shader.dispose()` in `dispose`. The sink's uniform slots hold the shader and die with it.

The canvas creates one `Ticker` when `animate` is true. Gallery cards pass `animate: false`. The featured card and the playground pass true. The ticker stops when `playing` is false, when `TickerMode` is false (a route covered by another route), and on dispose. The first callback after `start` is ignored so a pause does not add the time spent stopped. `ShaderController.addDelta` is the only clock. There is no second `AnimationController`.

`ShaderSampleScreen` and the gallery cards own the controller and dispose it after the canvas has removed its listener. Children dispose first.

## Time

`ShaderController.timeWrapSeconds` is 600. `addDelta` accumulates seconds and applies modulo. Float32 time stays in a range where the fractional part is still fine for these sines. The wrap is a jump: domain offset and aurora flow use time as a coordinate, and ripple slots whose start time is now in the future expire inside `rippleHeight`.

Reduced motion (`MediaQuery.disableAnimationsOf`) starts the playground and the featured card paused. Play still works.

## Pointer

`ShaderPreview` divides the local position by the layout size. Origin is top-left, Y down, values clamped to 0..1. That matches `FlutterFragCoord().xy / uResolution` after the shader's own normalization. Zero width or height skips the update.

The interaction switch sets `interactionEnabled`. Writers then send `uPointerActive` as 0. The last position is kept.

Ripples emit only when `ShaderSample.emitsRipples` is true. `RippleBuffer` stores four events. Spacing uses aspect-corrected distance so a wide preview does not emit a denser trail on X. A tap uses `forceEmit`.

## Adding a sample

Follow the steps in `docs/README.md`. Do not give the sample its own painter. Call `writeSampleUniforms` from the existing renderer by id.

## What is intentionally absent

No shader DSL, no code generation, no extra packages. Syntax highlighting in `shader_code_panel.dart` is a regex. The in-app guide uses `MarkdownView`, which understands headings, lists, fences, and pipe tables.
