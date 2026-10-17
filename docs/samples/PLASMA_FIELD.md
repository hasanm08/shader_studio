# Plasma Field

## Goal

Show how far summed sine waves go before a shader needs noise.

## What the viewer sees

Soft bands of teal, cyan, blue, and white drift across the preview. The pattern bends around the pointer.

## Techniques

Normalized UVs, summed sinusoids, separate spatial and temporal frequencies, and a three-color mix. No noise and no loops.

## Uniforms

| Index | Uniform | Type | Meaning |
|---|---|---|---|
| 0 | `uResolution` | `vec2` | Preview size |
| 2 | `uTime` | `float` | Wrapped seconds |
| 3 | `uPointer` | `vec2` | Normalized pointer |
| 5 | `uPointerActive` | `float` | 1 while interaction is live |
| 6 | `uSpeed` | `float` | Time scale |
| 7 | `uScale` | `float` | Spatial frequency |
| 8 | `uContrast` | `float` | Exponent on the 0..1 field |
| 9 | `uColorA` | `vec3` | Low color |
| 12 | `uColorB` | `vec3` | Mid color |
| 15 | `uColorC` | `vec3` | High color |

Writer: `writePlasmaField`.

## Shader walkthrough

`main` builds a UV by dividing `FlutterFragCoord` by `uResolution`. It does not call `aspectPoint`. Five sine terms are added. Their time coefficients differ so the sum does not repeat quickly. The pointer term uses `mix` between a fixed center and `uPointer`. The sum is mapped from `[-1, 1]` to `[0, 1]` and raised to `uContrast`. Two `smoothstep` mixes apply the palette.

## Dart walkthrough

Speed, scale, and contrast are sliders. Three color pickers write `uColorA`, `uColorB`, and `uColorC` as straight RGB. `writePlasmaField` is the whole sample-specific mapping.

## Animation

`uSpeed` multiplies `uTime` once. Every temporal frequency scales together. Pause holds the bands.

## Pointer

While the pointer is inside, one radial wave is centered on it. Outside, that wave uses the fixed center. `mix` keeps the handoff continuous. The other four waves ignore the pointer.

## Performance

Five sines and no loops. This is the cheap sample. High `uScale` still looks expensive in the sense that the picture aliases: the preview cannot resolve the bands, so they shimmer as they move. That is a sampling problem, not a Dart rebuild.

## Limitations

No antialiasing. Fragment derivatives are not used. High contrast posterizes the ramp. The pattern stretches with the preview because UVs are not aspect-corrected.

## Experiments

Raise scale until the bands break into shimmer. Lower it again. Raise contrast. Swap the high color and confirm the motion is unchanged. Move the pointer in and out of the preview.

## On camera

“Each sine is a stripe. Adding them is the plasma. Scale is spatial frequency. Speed is temporal frequency. When scale is too high, you are looking at aliasing.”
