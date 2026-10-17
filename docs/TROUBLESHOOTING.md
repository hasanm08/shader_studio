# Troubleshooting

## Shader asset not found

`FragmentProgram.fromAsset` throws if the key is missing from `flutter: shaders` or does not match `ShaderSample.assetPath`. Do not also list that path under `flutter: assets`. Flutter rejects the bundle. The viewer uses `ShaderSources` instead. If the panel text is stale, run `dart run tool/mirror_shader_sources.dart`. `test/shader_contract_test.dart` checks the pubspec list and the mirror.

## Shader compilation failure

The canvas shows the exception and a Retry button. `ShaderLoader` drops the failed future first. Read the compiler message. Common causes in this style of shader: a missing `runtime_effect.glsl` include, a non-constant loop bound, or a uniform type the writer does not set.

## Incorrect uniform indexes

Symptoms: one slider moves the wrong feature, or the picture is black because time landed in a color. This app binds by name, so a wrong index in the comment table does not by itself shift the GPU values. It does fail `shader_contract_test.dart`. If you switch a writer to raw `setFloat` indexes, use the table in `UNIFORMS_AND_COORDINATES.md` and remember `vec3` consumes three slots.

## Invalid sampler assignment

None of these shaders declare a sampler. Calling `setImageSampler` would be a mistake. `ImageFilter.shader` will also reject these programs because they have no `sampler2D`.

## Black or transparent output

Uniforms default to zero until the first paint. If paint throws, the canvas replaces the preview with the error text. A zero `uIntensity` or `uAmplitude` is a legitimate black-ish frame, not a failed compile. Reset restores defaults.

Alpha is written as 1 by every `main`. A transparent preview means the shader did not run, not that alpha was animated.

## Coordinate orientation

Pointer and `FlutterFragCoord` are top-left, Y down. If the highlight appears above the cursor, the backend's fragment Y is flipped relative to the size you passed. Compare a radial center at `(0.5, 0.2)` with where the marker sits. Fixing that belongs in one shared conversion, not in each slider.

## Distorted aspect ratio

Circles go through `aspectPoint`. Plasma does not. If the energy orb is oval, check that `uResolution` matches the `Size` of the `drawRect` and that both components are non-zero. A swapped width and height ovalizes the other way.

## Animation not updating

The ticker is off when the controller is paused, when reduced motion started it paused, or when the route is covered. Press play. Confirm the canvas was created with `animate: true`. Gallery cards are stills on purpose.

If time advances in Dart and the picture is frozen, the painter is not listening to `paintTick`, or an exception during `paint` was captured into the error panel.

## Resource leaks

Dispose the controller after the canvas. The canvas disposes the ticker and the `FragmentShader`. Do not dispose the `FragmentProgram`. Creating a shader per frame without disposing the previous one is the leak to avoid. `ShaderCanvas` keeps one shader for the life of the state.

## Platform differences

A shader that compiles on macOS Impeller can still fail on a backend that rejects a construct. The error string on the preview is the source of truth. Web was not verified here.
