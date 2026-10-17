# GLSL math used here

The samples only use operations that appear in `shaders/`. Nothing below is a general textbook chapter.

## sin and cos

Plasma adds several `sin` waves with different directions and time coefficients. The coefficients on `uTime` are not integer multiples, so the pattern does not repeat after a couple of seconds. The aurora's hash also uses `sin`, as a cheap mixer, not as a wave you are meant to see.

Radial wave uses one sine of radius:

```glsl
sin(radius * uFrequency - uTime * uSpeed)
```

Frequency is spatial. Speed is how fast the phase moves. They are different knobs.

## length and distance

`length(p)` is the Euclidean length. `sdCircle` is `length(p) - radius`: negative inside the circle, zero on the silhouette, positive outside. Ripple and radial wave use `length` from a center after `aspectPoint`, so the rings are round on a wide preview.

## smoothstep

`smoothstep(edge0, edge1, x)` is a cubic fade from 0 to 1. Aurora uses it as a color ramp along the noise value. Ripple uses it to keep the region outside the wavefront at rest. Radial wave uses it for grid lines that are wider than one pixel, so they do not sparkle as badly as a hard stroke.

Value noise uses the same polynomial directly: `t * t * (3 - 2 * t)`. That is the interior of smoothstep. Zero slope at the cell edge is why the noise is not faceted.

## mix

`mix(a, b, t)` is the lerp `(1 - t) * a + t * b`. Plasma's pointer center is `mix(fixedCenter, uPointer, uPointerActive)`, so the wave does not pop when the pointer enters. Color ramps are nested mixes. Domain warp's point is that mix changes color after the field exists. Warp changes the coordinate before the field is sampled.

## dot

The hash is `sin(dot(cell, vec2(127.1, 311.7)))`. The dot combines two cell coordinates into one number. Lighting uses `dot(normal, lightDir)`. A positive dot means the surface faces the light. The code clamps it so the back side stays dark.

## Normalization

`normalize` makes a vector length 1. `aspectPoint` is a different kind of normalization: it maps the preview into a space where X and Y have the same scale. `outward` in the radial shader refuses to normalize a near-zero vector at the exact center, and returns zero instead of a flash.

## Noise

`hash21` maps a cell to a value in `[0, 1)`. `valueNoise` blends the four corners. `fbm` adds four octaves. Each octave is rotated by a fixed matrix (`cos(0.5)`, `sin(0.5)`) and scaled by about 2.03 so ridges do not all share an axis. Amplitude is halved each time. The loop count is a constant because the shader compiler wants a fixed bound. Four octaves is the cost model for the noise samples.

This is not a high-quality hash. It is the sine-hash family Flutter's own shader examples use, and it only needs `sin`, `dot`, and `fract`.

## Domain warping

`auroraField` and `warpedField` sample noise at `domain + warp * noise(domain)`. The value you read comes from somewhere else. Doing it twice (`q`, then `r`) tangles the field more because the second offset is not aligned with the first. `uWarp == 0` in the domain-warp shader skips the extra samples.

## Signed distance

Only the energy core uses an SDF, and only for a circle: `sdCircle`. The sphere normal solves `z = sqrt(r^2 - x^2 - y^2)` and normalizes `(x, y, z)`. That is the front hemisphere of the sphere equation. It is not a ray march. No loop steps along a ray. The documentation and the shader header both say so.

## Coordinate transforms used by name

| Function | Where | Effect |
|---|---|---|
| `aspectPoint` | aurora, ripple, energy, domain warp, radial | Corrects aspect ratio |
| `auroraField` | aurora | Two-layer warp, returns height and warp vector |
| `rippleHeight` | ripple | Sine of distance and age, with a front and decay |
| `sdCircle` / `sphereNormal` | energy | Silhouette and analytic normal |
| `warpedField` | domain warp | Zero-warp fast path, otherwise two layers |
| `outward` | radial | Unit direction used to push UVs |
