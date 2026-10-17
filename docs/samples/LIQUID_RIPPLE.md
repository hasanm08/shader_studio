# Interactive Liquid Ripple

## Goal

Show a pointer disturbance that propagates and dies, using only the uniforms Flutter can store. Four slots, not an infinite history.

## What the viewer sees

Concentric highlights expand from recent pointer positions on a dark surface. The finger also leaves a small dimple immediately.

## Techniques

Distance from a point, a kinematic circular wave (a sine of distance and age), exponential decay, and a finite-difference slope for the highlight.

## Uniforms

| Index | Uniform | Type | Meaning |
|---|---|---|---|
| 0 | `uResolution` | `vec2` | Preview size |
| 2 | `uTime` | `float` | Wrapped seconds |
| 3 | `uPointer` | `vec2` | Normalized pointer |
| 5 | `uPointerActive` | `float` | 1 while interaction is live |
| 6 | `uAmplitude` | `float` | Wave height |
| 7 | `uFrequency` | `float` | Spatial frequency |
| 8 | `uSpeed` | `float` | Wavefront growth |
| 9 | `uDamping` | `float` | Decay over age |
| 10 | `uColor` | `vec3` | Tint, straight RGB |
| 13 | `uRipple0` | `vec3` | xy origin, z start time |
| 16 | `uRipple1` | `vec3` | Second slot |
| 19 | `uRipple2` | `vec3` | Third slot |
| 22 | `uRipple3` | `vec3` | Fourth slot |

A start time below 0 means the slot is empty. `writeLiquidRipple` writes `(0, 0, -1)` for those.

## Shader walkthrough

`rippleHeight` computes age as `uTime - source.z`. The wavefront radius is `age * uSpeed`. `smoothstep` holds the exterior at zero. A sine supplies the crests. One exponential decays with distance, another with `uDamping * age`. Ages outside 0..8 seconds are dropped so a wrapped clock cannot revive a slot. `main` adds a contact dimple from the live pointer, then differences the height at a small epsilon to build a normal.

## Dart walkthrough

`RippleBuffer` on `ShaderSampleController` holds four `RippleEvent` values. `ShaderPreview` calls `setPointer` with `emitRipples` only for this sample. A tap uses `forceEmit`. A move emits when the aspect-corrected travel exceeds 0.04. `writeLiquidRipple` copies the slots. Gallery stills call `RippleBuffer.seedPreview` so the card is not an empty surface. The card caption says that.

## Animation

The wavefront moves because age grows with `uTime`. Pause freezes every crest. Reset clears the slots and the clock, so the surface goes quiet.

## Pointer

Dart converts the local position to normalized coordinates and stores them on the event. The shader runs those origins through `aspectPoint`, the same conversion as the fragment, so a ripple is circular. Spacing in Dart uses the preview aspect ratio and refuses to divide by a zero height.

## Performance

Each pixel evaluates the four slots once for the height and again from the finite-difference taps. That is the cost of not using fragment derivatives. Four slots is the whole history.

## Limitations

There is no wake beyond the ring buffer. This is not an integrated 2D wave equation. When `uTime` wraps at 600 seconds, a slot that now starts in the future expires. The gallery still is authored, not a recording of a gesture.

## Experiments

Drag a long stroke and watch the oldest wave disappear. Raise damping. Set amplitude to 0 and confirm the dimple leaves with the waves. Pause mid-flight and resume.

## On camera

“Dart remembers four gestures. The shader only knows the current uniform buffer. The crest moves because its radius is age times speed, and damping is why the surface eventually rests.”
