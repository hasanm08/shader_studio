# Uniforms and coordinates

Binding is by name in `shader_uniform_writers.dart`. The indexes below are the packed float positions for that declaration order. Non-sampler uniforms are tightly packed. There are no samplers, so sampler index 0 is unused.

Shared prefix, every sample:

| Index | Uniform | Type | Meaning |
|---|---|---|---|
| 0 | `uResolution` | `vec2` | Logical preview size |
| 2 | `uTime` | `float` | Seconds in `[0, 600)` |
| 3 | `uPointer` | `vec2` | Normalized pointer, origin top-left, Y down |
| 5 | `uPointerActive` | `float` | 1 if the pointer is inside and interaction is on |

`uPointerActive` is 0 when the pointer has left, when interaction is switched off, or before the first event. The last `uPointer` value remains.

Colors are straight RGB in 0..1, three floats, not premultiplied.

## Living Liquid Aurora

| Index | Uniform | Type | Meaning |
|---|---|---|---|
| 6 | `uSpeed` | `float` | Multiplier on `uTime` |
| 7 | `uScale` | `float` | Spatial frequency |
| 8 | `uIntensity` | `float` | Push toward cyan and white |
| 9 | `uDistortion` | `float` | Warp distance |

Writer: `writeLiquidAurora`. No color uniform. Intensity is the color control.

## Interactive Liquid Ripple

| Index | Uniform | Type | Meaning |
|---|---|---|---|
| 6 | `uAmplitude` | `float` | Wave height |
| 7 | `uFrequency` | `float` | Crests per UV unit of radius |
| 8 | `uSpeed` | `float` | Wavefront growth |
| 9 | `uDamping` | `float` | Exponential decay on age |
| 10 | `uColor` | `vec3` | Water tint |
| 13 | `uRipple0` | `vec3` | xy origin, z start. z < 0 is empty |
| 16 | `uRipple1` | `vec3` | Second slot |
| 19 | `uRipple2` | `vec3` | Third slot |
| 22 | `uRipple3` | `vec3` | Fourth slot |

Writer: `writeLiquidRipple`. Empty slots are `(0, 0, -1)`.

## Procedural Energy Core

| Index | Uniform | Type | Meaning |
|---|---|---|---|
| 6 | `uSpeed` | `float` | Swirl and pulse rate |
| 7 | `uIntensity` | `float` | Core and glow brightness |
| 8 | `uPulse` | `float` | Radius breathe |
| 9 | `uTurbulence` | `float` | Interior noise frequency |
| 10 | `uColorCore` | `vec3` | Interior color |
| 13 | `uColorRim` | `vec3` | Rim and glow color |

Writer: `writeProceduralEnergy`.

## Plasma Field

| Index | Uniform | Type | Meaning |
|---|---|---|---|
| 6 | `uSpeed` | `float` | Time scale |
| 7 | `uScale` | `float` | Spatial frequency |
| 8 | `uContrast` | `float` | Exponent after the sum |
| 9 | `uColorA` | `vec3` | Low color |
| 12 | `uColorB` | `vec3` | Mid color |
| 15 | `uColorC` | `vec3` | High color |

Writer: `writePlasmaField`. This shader does not aspect-correct.

## Domain Warping

| Index | Uniform | Type | Meaning |
|---|---|---|---|
| 6 | `uSpeed` | `float` | Domain scroll |
| 7 | `uScale` | `float` | Frequency before warp |
| 8 | `uWarp` | `float` | Displacement. Zero skips extra samples |
| 9 | `uColorA` | `vec3` | Low color |
| 12 | `uColorB` | `vec3` | Mid color |
| 15 | `uColorC` | `vec3` | High color |

Writer: `writeDomainWarp`. Palette chips are not uniforms. `selectPreset` writes the three colors first.

## Radial Wave

| Index | Uniform | Type | Meaning |
|---|---|---|---|
| 6 | `uFrequency` | `float` | Rings per UV unit |
| 7 | `uAmplitude` | `float` | UV push |
| 8 | `uSpeed` | `float` | Phase speed |
| 9 | `uAttenuation` | `float` | Distance falloff |
| 10 | `uCenter` | `vec2` | Normalized center, origin top-left |
| 12 | `uFollowPointer` | `float` | 1 to use the pointer while it is active |
| 13 | `uColor` | `vec3` | Ring tint |

Writer: `writeRadialWave`. `centerX` and `centerY` are the two components of `uCenter`. The follow control is a float, not a GLSL bool.

## Inside the Hive

| Index | Uniform | Type | Meaning |
|---|---|---|---|
| 6 | `uSpeed` | `float` | Bee flight and honey shimmer |
| 7 | `uScale` | `float` | Comb frequency. Larger means a smaller cell |
| 8 | `uDepth` | `float` | Distance to the far comb |
| 9 | `uHoney` | `float` | How full the far cells look |
| 10 | `uColorWax` | `vec3` | Wax color, straight RGB |
| 13 | `uColorHoney` | `vec3` | Honey color, straight RGB |

Writer: `writeBeehiveInterior`. `marchTube` uses a fixed budget of 32 steps. Bee positions are computed from `uTime` and `uSpeed`. They are not extra uniforms.

## Coordinates

Dart stores the pointer in normalized preview space. Shaders that care about circles convert with `aspectPoint` before measuring distance. Plasma keeps raw 0..1 UVs.

`uCenter` and ripple origins use the same normalized space as `uPointer`, and the shader converts them with the same function as the fragment. Mixing two points after aspect correction would move the center along an ellipse. Radial wave mixes first, then converts. The comment in `radial_wave.frag` says why.
