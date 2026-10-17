# Platform compatibility

This project was written against Flutter 3.47.4 and Dart 3.13.3. `flutter analyze` and `flutter test` are the checks that were intended to be run in this workspace. A successful analyze does not mean every GPU backend was launched.

## Intended targets

Runtime-effect shaders with `FlutterFragCoord` are a Flutter engine feature. The shaders use:

- `#include <flutter/runtime_effect.glsl>`
- `precision highp float`
- `out vec4 fragColor`
- uniforms of type `float`, `vec2`, and `vec3`
- a fixed `for` loop of four iterations
- `sin`, `cos` via a matrix, `fract`, `mix`, `smoothstep`, `normalize`, `length`

They do not use samplers, `dFdx`, geometry shaders, or desktop-only GLSL.

Impeller is the default renderer on current stable Flutter for iOS, Android, and macOS. That is the path these samples were aimed at. `Paint.shader` is used instead of `ImageFilter.shader`, because the filter entry point requires a sampler and is Impeller-only.

## Not claimed

- Web (CanvasKit / skwasm) was not run here. Fragment shaders can compile for web in recent Flutter, and they can also fail or flip coordinates on a particular backend. Treat web as unverified until you run it.
- No physical device matrix was recorded.
- Skia versus Impeller coordinate differences are documented as a risk in `TROUBLESHOOTING.md`, not as a result from a side-by-side run.

## OpenGL ES Y

`ImageFilter.shader` documents a Y flip under `IMPELLER_TARGET_OPENGLES` because it samples an input texture. These shaders are not image filters. They assume `FlutterFragCoord` Y grows downward, matching Flutter's canvas. If a backend violates that, the pointer and the picture disagree. The troubleshooting note is the place to check.

## Reduced motion and input

Pointer, mouse, and touch all go through `Listener` and `MouseRegion` on the preview. Hover updates the pointer on desktop. Phones only see down and move. The interaction switch turns that influence off without removing the sliders.

`MediaQuery.disableAnimationsOf` starts playback paused. It does not remove the shaders.
