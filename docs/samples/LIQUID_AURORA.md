# Living Liquid Aurora

## Goal

Show a full-screen procedural material that widgets cannot approximate with gradients: layered motion, warped shapes, and a glossy edge. This is the featured sample.

## What the viewer sees

Teal, cyan, and white forms drift on a near-black field. Edges pick up a highlight. A pointer inside the preview pulls the nearby pattern.

## Techniques

Aspect-corrected UVs, value noise, four-octave fBm, two-layer domain warping, a slope used as a fake normal, and a color ramp. The shader header states that this is not a 3D fluid and does not refract a scene.

## Uniforms

| Index | Uniform | Type | Meaning |
|---|---|---|---|
| 0 | `uResolution` | `vec2` | Preview size |
| 2 | `uTime` | `float` | Wrapped seconds |
| 3 | `uPointer` | `vec2` | Normalized pointer, top-left origin |
| 5 | `uPointerActive` | `float` | 1 while interaction is live |
| 6 | `uSpeed` | `float` | Time scale |
| 7 | `uScale` | `float` | Spatial frequency |
| 8 | `uIntensity` | `float` | Push toward cyan and white |
| 9 | `uDistortion` | `float` | Warp distance |

`writeLiquidAurora` sets these by name. There is no sampler.

## Shader walkthrough

`hash21` and `valueNoise` build a continuous scalar. `fbm` stacks four octaves with a fixed rotation. `aspectPoint` corrects the aspect ratio before noise, so the pointer pull is round. `auroraField` samples noise at a coordinate displaced by earlier noise and returns the height plus the warp vector. `main` turns that vector into a normal, shades it with a diffuse term, a specular term, and a rim, then ramps the height through navy, teal, cyan, and white.

## Dart walkthrough

`ShaderSampleRegistry` defines the ranges. `ShaderSampleController` stores the four sliders. `ShaderRenderer.paint` calls `writeLiquidAurora`, which writes the shared uniforms and `uSpeed`, `uScale`, `uIntensity`, and `uDistortion`. The program is loaded once by `ShaderCanvas`.

## Animation

`uTime` comes from `ShaderController.addDelta`, wrapped at 600 seconds. `uSpeed` scales it inside the shader. Pause stops the ticker in `ShaderCanvas`.

## Pointer

`ShaderPreview` normalizes the local position. The shader converts it with `aspectPoint`, then applies an exponential falloff so the pull stays near the finger. The interaction switch forces `uPointerActive` to 0.

## Performance

The field path evaluates fBm several times per pixel (two components of `q`, two of `r`, and the final sample). Cost follows the preview resolution. The gallery hero is the one aurora that ticks. The grid card is a still at 3.2 seconds.

## Limitations

No thickness, no refraction, no derivative antialiasing. High scale can shimmer. The normal is not the true gradient of the height.

## Experiments

Set distortion to 0. Then raise it. Then raise intensity and watch the white edge without a change to the warp. Drag inside the preview with interaction on and off.

## On camera

“This is a 2D scalar field with warped coordinates and a lighting trick. The glossy edge is a ridge in the noise, not a mesh.”
