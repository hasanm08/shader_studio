# Domain Warping

## Goal

Show the difference between changing a color and changing the coordinate a texture is sampled from.

## What the viewer sees

An abstract flowing texture. Low warp is soft blobs. Higher warp stretches them into sheets. Palette chips recolor the same shapes.

## Techniques

Value noise, fBm, and two layers of domain warping. The pointer adds a small extra displacement.

## Uniforms

| Index | Uniform | Type | Meaning |
|---|---|---|---|
| 0 | `uResolution` | `vec2` | Preview size |
| 2 | `uTime` | `float` | Wrapped seconds |
| 3 | `uPointer` | `vec2` | Normalized pointer |
| 5 | `uPointerActive` | `float` | 1 while interaction is live |
| 6 | `uSpeed` | `float` | Domain scroll |
| 7 | `uScale` | `float` | Frequency before warp |
| 8 | `uWarp` | `float` | Displacement amount |
| 9 | `uColorA` | `vec3` | Low color |
| 12 | `uColorB` | `vec3` | Mid color |
| 15 | `uColorC` | `vec3` | High color |

Writer: `writeDomainWarp`. The palette control is a `ChoiceParameter`. It is not a uniform. `selectPreset` writes the three colors.

## Shader walkthrough

`warpedField` returns plain `fbm` when warp is about zero. Otherwise it builds a noise vector `q`, samples again at `domain + warp * q` to build `r`, and samples a last time at `domain + warp * r`. Two layers tangle more than one because the second offset is not aligned with the first. `main` scrolls the domain with time, adds a local pointer push, then colors the scalar with `smoothstep` mixes.

## Dart walkthrough

`ShaderSampleController.selectPreset` copies a `ColorPreset` into `colorA`, `colorB`, and `colorC`. `setColor` clears `selectedPresetId` so a chip does not claim a palette the user edited. `writeDomainWarp` only sees the colors.

## Animation

`uSpeed` scrolls the domain. It does not change warp strength. Pause freezes the scroll. The 600 second wrap jumps the scroll position because time is added into the coordinate.

## Pointer

The shader adds `(pointer - p) * exp(-distance)` when `uPointerActive` is 1. It is a small extra warp so the cursor is visible without replacing the warp slider.

## Performance

Warp above zero evaluates fBm five times with four octaves. Warp at zero evaluates it once. The branch depends only on a uniform, so every pixel takes the same side. Raising warp does not add samples. It only increases the offset, and the image can look stringy.

## Limitations

No extra octaves at high warp. The hash can show a faint grid. Color presets cannot change the shape.

## Experiments

Set warp to 0, then to the default, then to the top of the range. Switch from Aurora to Ember and back. Then drag one RGB slider and watch the chip deselect.

## On camera

“A domain is the coordinate we were about to sample. Warping means we sample somewhere else. Recoloring is mix(). It does not move the blobs.”
