# Radial Wave

## Goal

Show a radial sine used as a displacement of a second pattern, not only as a color.

## What the viewer sees

Rings expand from a center. A faint grid bends with them. With follow-pointer on, the origin tracks the cursor. A small marker stays at the center when amplitude is zero.

## Techniques

Distance from a center, a unit radial direction, a sine of radius, exponential attenuation, and UV displacement before a second sample.

## Uniforms

| Index | Uniform | Type | Meaning |
|---|---|---|---|
| 0 | `uResolution` | `vec2` | Preview size |
| 2 | `uTime` | `float` | Wrapped seconds |
| 3 | `uPointer` | `vec2` | Normalized pointer |
| 5 | `uPointerActive` | `float` | 1 while interaction is live |
| 6 | `uFrequency` | `float` | Rings per UV unit |
| 7 | `uAmplitude` | `float` | How far the coordinate is pushed |
| 8 | `uSpeed` | `float` | Phase speed |
| 9 | `uAttenuation` | `float` | Falloff with distance |
| 10 | `uCenter` | `vec2` | Normalized center, top-left origin |
| 12 | `uFollowPointer` | `float` | 1 to use the pointer while active |
| 13 | `uColor` | `vec3` | Ring tint |

Writer: `writeRadialWave`. Center X and Center Y are the two floats of `uCenter`. Follow pointer is 0 or 1.

## Shader walkthrough

`aspectPoint` corrects both the fragment and the chosen center. The center is chosen in normalized space with `mix`, then converted. Mixing after conversion would slide it on an ellipse. `outward` is the unit direction, or zero at the exact center so a normalize does not flash. The wave is `sin(radius * frequency - time * speed) * amplitude * exp(-radius * attenuation)`. `displaced` is the fragment minus that push. The grid is sampled at `displaced`, which is why the lines travel with the rings.

## Dart walkthrough

`writeRadialWave` packs `centerX` and `centerY` into one `setVec2`. The toggle is stored as a scalar 0 or 1 by `setScalar`. Reset returns the center to `(0.5, 0.5)` and follow-pointer to on.

## Animation

`uSpeed` is the phase speed of the sine. Frequency does not change with the widget size, because the radius is in aspect-corrected units rather than pixels. Pause holds the rings.

## Pointer

With follow on and the pointer active, the shader replaces `uCenter` with `uPointer` before aspect correction. With follow off, the sliders win even while the pointer is inside. Interaction off forces `uPointerActive` to 0, which also disables follow, because the shader multiplies the two.

## Performance

A handful of trig calls and two smoothsteps for the grid. No noise loop. High frequency plus high amplitude shimmers at the corners if attenuation is also low. Attenuation is the control that keeps that in check.

## Limitations

One sine of radius. It does not reflect off edges. Large amplitude folds the grid. That fold is the point of the sampling lesson, not a bug to hide. The composition stays circular across aspect ratios because of `aspectPoint`.

## Experiments

Set amplitude to 0 and move the center. The marker moves and the grid is straight. Raise amplitude and watch the grid bend. Turn follow on and drag. Resize the window and confirm the ring count does not multiply.

## On camera

“Coloring a distance draws rings. Subtracting that wave from the coordinate moves whatever you sample next. The bent grid is the proof.”
