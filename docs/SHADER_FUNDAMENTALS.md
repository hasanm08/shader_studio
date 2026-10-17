# Shader fundamentals

A fragment shader runs once per covered pixel and returns a color. In this project that function is `main` in a `.frag` file, and the color is `fragColor`. Flutter shows it by drawing a rectangle with a `Paint` whose `shader` is a `FragmentShader`.

## Fragment shaders

The GPU (through Impeller or Skia, depending on the engine) invokes the shader for fragments of that rectangle. The shader does not build widgets, hit-test, or keep memory from the previous frame unless Dart sends that memory in as uniforms. The ripple history exists only because Dart stores four origins and writes them every frame.

## UV coordinates

A UV coordinate is a position in 0..1 across the preview. These shaders build it as:

```glsl
vec2 uv = FlutterFragCoord().xy / uResolution;
```

`FlutterFragCoord` is the fragment position in the canvas coordinate system of the `drawRect`. `uResolution` is the logical width and height Dart passed in. `(0, 0)` is the top-left. Y grows downward, same as Flutter.

`aspectPoint` then subtracts 0.5 and multiplies X by `width / height`. One unit in X matches one unit in Y on screen, so a circle stays a circle. Plasma skips that step on purpose: it is a color field, and stretching with the preview is part of the scale control.

## Resolution

Resolution is the preview size, not the window size and not the device pixel size. `ShaderRenderer` passes the `CustomPainter` size. If the layout is empty, the writer substitutes 1 so nobody divides by zero. The shaders also use `max(uResolution, vec2(1.0))`.

## Uniforms

Uniforms are inputs that stay constant for every fragment of one draw. They change between frames when Dart writes them. Flutter's API is a flat list of floats plus a separate list of image samplers. This project uses no samplers.

`FragmentShaderSink` binds by name (`getUniformFloat`, `getUniformVec2`, `getUniformVec3`). The index tables in each shader and in `ShaderSampleRegistry` document the packed layout: a `vec2` takes two floats, a `vec3` takes three, and nothing is padded to a 16-byte boundary.

## Time

The shader has no clock. `ShaderCanvas` owns a `Ticker`. `ShaderController.addDelta` turns deltas into seconds, wraps them at 600, and the writer copies `timeSeconds` to `uTime`. Pause stops the ticker. Reset sets the seconds back to zero.

If Dart sent an ever-growing time, float32 would eventually quantize the phase and the motion would stutter. The wrap avoids that and is visible when it happens.

## Color output

`fragColor` is straight RGBA with alpha 1. Color uniforms are also straight RGB. Dart does not premultiply them. Premultiplying is for engine blending of a paint color. Here the uniform is palette data and the shader builds the final color itself.

## Dart to GLSL

1. A control calls `ShaderSampleController.setScalar` or `setColor`, which clamps and pings `paintTick`.
2. `ShaderRenderer.paint` calls `writeSampleUniforms`.
3. The writer sets named uniforms on the `FragmentShader`.
4. `canvas.drawRect` fills the preview with that shader.
5. Each fragment reads the uniforms, computes a color, and stores `fragColor`.

The widget tree does not rebuild for step 4. Only the painter runs.
