# Video walkthrough

Demo order for “GLSL Shaders: Create Effects Widgets Can't”. Times are a suggestion, not a measured edit.

## 1. Open the gallery

Show the live aurora hero and the still grid. Say the cards are real shaders at a fixed time, and only the hero ticks, so the grid is not six full animations.

Concept: a fragment shader colors a rectangle. Widgets did not draw this field.

## 2. Living Liquid Aurora

Open the playground. Pause and resume so the clock is obviously Dart's. Drag Distortion from 0 to the default and past it. Then drag Scale.

Point at `aspectPoint`, `fbm`, and `auroraField` in the source panel. Say domain warp moves the coordinate noise is sampled at. The lighting block reuses the warp vector as a slope. Say clearly that this is not a fluid simulation and not a refraction.

Experiment: set distortion to 0. The field is smoother and less folded. That is the warp term leaving.

Mistake to show: if `uResolution` were `(1, 1)` the aspect correction collapses. You do not need to ship that bug. Describe it, or temporarily pass a square resolution if you want it on camera. Do not claim you profiled it.

## 3. Dart to GLSL

Stay on aurora. Show `writeLiquidAurora`. Name `uTime`, `uPointer`, `uDistortion`. Move the pointer and show the pull staying local. Mention `paintTick` versus `controlsTick`: the slider widget is not rebuilding every frame.

## 4. Plasma Field

Switch samples. This one is sines only. Raise Scale until the bands shimmer, and say that is aliasing, not a broken clock. Raise Contrast and watch the ramp posterize. Move the pointer and point at the `mix` that recenters one wave.

## 5. Domain Warping

Set Warp to 0, then raise it. Switch palette chips and point out the shapes do not move. Edit one RGB slider and show the chip clear. The line to say: color is applied after the field exists. Warp edits the coordinate.

## 6. Radial Wave

Turn follow-pointer off and move Center X. Turn it on and drag. Raise Amplitude until the grid folds. That fold is the sampling consequence of pushing a coordinate past its neighbor. Point at `outward` and the displaced grid sample.

## 7. Interactive Liquid Ripple

Drag a short stroke. Four slots, then the oldest is replaced. Raise Damping and watch the trail die. Mention the contact dimple is not one of the four slots. Mention the finite-difference normal and why `dFdx` is not used.

## 8. Procedural Energy Core

Pause on the silhouette. Point at `sdCircle` and `sphereNormal`. Say z is solved from the sphere equation. Do not say ray marching. Move the pointer and show the light direction change. Lower Intensity and the glow drops with the core.

## Transitions

Gallery hero to playground: “same shader, now with the uniforms exposed.”

Aurora to plasma: “before noise, see how far sine gets.”

Plasma to domain warp: “noise, then noise that moves the coordinate.”

Domain warp to radial: “another way to move a coordinate: a wave of distance.”

Radial to ripple: “distance again, but now the center is a gesture Dart remembered.”

Ripple to energy: “distance as a silhouette, plus a normal, still without marching rays.”

## Lines worth putting on screen

- `shaders/liquid_aurora.frag`: `aspectPoint`, `auroraField`, the normal built from `field.yz`
- `shaders/plasma_field.frag`: the five `sin` lines and the `pow` contrast
- `shaders/domain_warp.frag`: `warpedField`
- `shaders/radial_wave.frag`: `displaced = p - outward(offset) * wave`
- `shaders/liquid_ripple.frag`: `rippleHeight`
- `shaders/procedural_energy.frag`: `sdCircle`, `sphereNormal`
- `shader_uniform_writers.dart`: the `BEGIN` block for whichever sample is on screen

## Do not invent

Do not read the ticker overlay as a benchmark result. Do not say the tests checked the picture. They check values, asset registration, and that the playground opens.
