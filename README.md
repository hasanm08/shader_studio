# Shader Studio

Shader Studio is a Flutter learning lab for real-time GLSL fragment shaders. It is the demo project for the FlowForge video “GLSL Shaders: Create Effects Widgets Can't”.

The gallery opens six live fragment shaders. The playground edits their uniforms, pauses the clock, and shows the `.frag` source that Flutter compiled.

Screenshots were not captured in this repository. Run the app to see the shaders. A still image would not show the animation.

## Requirements

- Flutter 3.47.4 / Dart 3.13.3, the SDK used while building this project.
- A target whose Flutter engine can compile runtime-effect shaders. Impeller on macOS, iOS, and Android is the intended path. Web was not run here. See `docs/PLATFORM_COMPATIBILITY.md`.

## Setup

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Samples

| Sample | File | What it teaches |
|---|---|---|
| Living Liquid Aurora | `shaders/liquid_aurora.frag` | Noise, domain warp, fake lighting |
| Interactive Liquid Ripple | `shaders/liquid_ripple.frag` | Distance, a kinematic wave, four ripple slots |
| Procedural Energy Core | `shaders/procedural_energy.frag` | Circle SDF, analytic sphere normal, glow |
| Plasma Field | `shaders/plasma_field.frag` | Summed sines and color ramps |
| Domain Warping | `shaders/domain_warp.frag` | Displacing coordinates before sampling |
| Radial Wave | `shaders/radial_wave.frag` | Radial sine used as UV displacement |
| Inside the Hive | `shaders/beehive_interior.frag` | Hex tube ray march, far comb, ellipsoid bees |

## Add a shader

1. Add `shaders/your_effect.frag` with the header comment used by the other files: name, purpose, uniform index table, coordinates, and limits.
2. Declare uniforms. Start with `uResolution`, `uTime`, `uPointer`, and `uPointerActive` if the effect needs the shared clock and pointer. Do not assume std140 padding.
3. Register the file under `flutter: shaders` only. Then run `dart run tool/mirror_shader_sources.dart` so the code panel mirror matches. Do not also list the `.frag` path under `flutter: assets`. Flutter rejects that bundle.
4. Add a `ShaderSample` in `lib/features/playground/data/shader_sample_registry.dart` with ranges, defaults, and the index table.
5. Add a `writeYourEffect` function in `lib/features/samples/application/shader_uniform_writers.dart`, marked with `BEGIN` / `END` comments, and a branch in `writeSampleUniforms`.
6. Add `docs/samples/YOUR_EFFECT.md` and list it as an asset.
7. Extend `test/shader_contract_test.dart` coverage by keeping the header, the `uniform` lines, and the registry in agreement. The existing test reads all three.
8. Run `flutter analyze` and `flutter test`.

There is no code generator and no shader DSL.

## Tests

```bash
flutter test
```

Unit tests cover clamping, pause, reset, ripple slots, and uniform names. A contract test compares each `.frag` file with the registry. The widget test opens the aurora playground and toggles pause. It does not prove the picture is correct. Golden images are not used; GPU output is not stable enough across backends to treat a screenshot as a unit test. Check the six playgrounds by eye.

## Platform limits

Runtime effects need the Flutter shader compiler (`impellerc`). Shaders in this project use `FlutterFragCoord`, value noise, and a fixed loop of four octaves. They do not use samplers, derivatives, or ray marching. Details are in `docs/PLATFORM_COMPATIBILITY.md`.

## Documentation

The longer guides live in `docs/`. The same markdown opens inside the app from “Open documentation”.
