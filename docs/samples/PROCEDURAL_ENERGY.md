# Procedural Energy Core

## Goal

Draw a glowing orb with a hard silhouette and a sense of depth, using a signed distance and the sphere equation. Do not ray march.

## What the viewer sees

A teal core on a dark field. The interior swirls, the rim flares, and the light leans toward the pointer.

## Techniques

`sdCircle` for the silhouette, `sphereNormal` for the front hemisphere, value-noise turbulence, diffuse and rim lighting, and an exponential glow outside the disc.

## Uniforms

| Index | Uniform | Type | Meaning |
|---|---|---|---|
| 0 | `uResolution` | `vec2` | Preview size |
| 2 | `uTime` | `float` | Wrapped seconds |
| 3 | `uPointer` | `vec2` | Normalized pointer |
| 5 | `uPointerActive` | `float` | 1 while interaction is live |
| 6 | `uSpeed` | `float` | Swirl and pulse rate |
| 7 | `uIntensity` | `float` | Core and glow brightness |
| 8 | `uPulse` | `float` | Radius breathe amount |
| 9 | `uTurbulence` | `float` | Interior noise frequency |
| 10 | `uColorCore` | `vec3` | Interior color |
| 13 | `uColorRim` | `vec3` | Rim and glow color |

Writer: `writeProceduralEnergy`.

## Shader walkthrough

`sdCircle` is `length(p) - radius`. Inside, `sphereNormal` sets `z` to the square root of `r² - x² - y²` and normalizes. That z is solved, not marched. The light direction mixes a default with the pointer offset. Diffuse is the clamped dot of the normal and the light. Rim uses `1 - normal.z`. Outside, glow is `exp(-distance)`.

## Dart walkthrough

Sliders map to `uSpeed`, `uIntensity`, `uPulse`, and `uTurbulence`. The two color pickers write straight RGB to `uColorCore` and `uColorRim`. `ShaderCanvas` owns the shader. Nothing in this sample allocates a ray-march loop on either side.

## Animation

`uSpeed` scales time for the swirl and for `sin` on the radius. `uPulse` is the amplitude of that sine. Pause freezes both.

## Pointer

The pointer changes the light direction, not the orb's position. `uPointerActive` selects that offset. With interaction off, the light stays at the default.

## Performance

One fBm of four octaves runs for every fragment, including the background. The inside branch adds the lighting. There is no iteration budget because there is no march.

## Limitations

The normal is valid only inside the circle. No self-shadow and no refraction. Glow is a falloff, not a volume integral.

## Experiments

Set pulse to 0 and watch the radius lock. Raise turbulence. Drag the pointer around the orb and watch the highlight move while the silhouette stays centered. Drop intensity to see the glow and the core fall together.

## On camera

“The silhouette is a signed distance to a circle. The normal is the sphere equation solved for z. If I were ray marching, you would see a loop. You do not.”
