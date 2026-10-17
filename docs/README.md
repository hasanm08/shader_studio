# Shader Studio

Shader Studio is a Flutter learning lab for real-time GLSL fragment shaders. It is the demo project for the FlowForge video “GLSL Shaders: Create Effects Widgets Can't”.

The gallery opens six fragment shaders. The playground edits their uniforms, pauses the clock, and shows the `.frag` source that Flutter compiled.

Screenshots were not captured for this repository. Run the app to see the shaders.

## Requirements

- Flutter 3.47.4 with Dart 3.13.3, the SDK this project was written against.
- A target that compiles Flutter runtime-effect shaders. Impeller on macOS, iOS, and Android is the intended path. Web was not executed in this workspace. See [PLATFORM_COMPATIBILITY.md](PLATFORM_COMPATIBILITY.md).

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

1. Add `shaders/your_effect.frag` with the same header style as the existing files: purpose, uniform index table, coordinates, how to run it, and limits.
2. Declare uniforms in the order the table describes. Shared samples start with `uResolution`, `uTime`, `uPointer`, and `uPointerActive`. Flutter packs non-sampler uniforms tightly. Do not insert std140 padding in the table.
3. Register the file under `flutter: shaders` only, then run `dart run tool/mirror_shader_sources.dart`. Flutter rejects a path listed as both a shader and an asset. The code panel reads the generated mirror, and the contract test checks it against the `.frag` file.
4. Add a `ShaderSample` in `lib/features/playground/data/shader_sample_registry.dart`.
5. Add a writer in `lib/features/samples/application/shader_uniform_writers.dart` with `BEGIN` / `END` markers, and call it from `writeSampleUniforms`.
6. Add `docs/samples/YOUR_EFFECT.md` and list that file under `flutter: assets`.
7. Keep the `.frag` header, the `uniform` declarations, and the registry row in sync. `test/shader_contract_test.dart` fails when they drift.
8. Run `flutter analyze` and `flutter test`.

No code generator is used.

## Testing

```bash
flutter test
```

Tests check parameter ranges, pause / resume / reset, the four-slot ripple buffer, and that each writer emits every uniform name in the contract. They also parse shader source. They do not judge the image. Screenshot goldens are not used, because a GPU backend change would make them fail for reasons that are not logic bugs. Look at each playground while changing a slider.

## Platform limitations

See [PLATFORM_COMPATIBILITY.md](PLATFORM_COMPATIBILITY.md). Short version: these are Impeller-oriented runtime effects with no samplers and no ray marching.

## More guides

- [ARCHITECTURE.md](ARCHITECTURE.md)
- [SHADER_FUNDAMENTALS.md](SHADER_FUNDAMENTALS.md)
- [GLSL_MATH.md](GLSL_MATH.md)
- [FLUTTER_RENDERING.md](FLUTTER_RENDERING.md)
- [UNIFORMS_AND_COORDINATES.md](UNIFORMS_AND_COORDINATES.md)
- [PERFORMANCE.md](PERFORMANCE.md)
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- [VIDEO_WALKTHROUGH.md](VIDEO_WALKTHROUGH.md)
