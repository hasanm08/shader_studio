// Domain Warping
//
// Purpose
//   Show what it means to distort a coordinate domain before sampling it.
//   The warp-strength control is the lesson: zero is plain noise, and
//   larger values feed noise back into the coordinate.
//
// Visual result
//   An abstract flowing texture. At low warp it is soft blobs. At high warp
//   the blobs stretch into fluid sheets. Color presets recolor the same
//   field, which is a different operation from warping.
//
// Techniques
//   Value noise, fBm, and two layers of domain warping. The pointer adds a
//   small extra displacement so interaction is visible without hiding the
//   warp control.
//
// Uniforms — packed in declaration order, with no std140 padding.
//   Index  Type    Name             Meaning
//   0      vec2    uResolution      Preview size in canvas units
//   2      float   uTime            Elapsed seconds, wrapped by Dart into [0, 600)
//   3      vec2    uPointer         Pointer in normalized preview space, origin top-left
//   5      float   uPointerActive   1 while the pointer is inside the preview, else 0
//   6      float   uSpeed           How fast the domain scrolls
//   7      float   uScale           Spatial frequency before warping
//   8      float   uWarp            Displacement amount. Zero disables warping
//   9      vec3    uColorA          Low field color
//   12     vec3    uColorB          Mid field color
//   15     vec3    uColorC          High field color
//
// Coordinates
//   aspectPoint() corrects the aspect ratio so the noise frequency is even
//   in screen space. uPointer uses that same space. Color uniforms do not
//   affect coordinates.
//
// How to run
//   Open "Domain Warping" and move the warp slider from 0 upward. Switch
//   color presets and notice the shapes do not change.
//
// Limitations
//   The full warp path evaluates fBm five times with four octaves each.
//   uWarp == 0 takes the cheaper branch and evaluates fBm once. The branch
//   depends only on a uniform, so every pixel takes the same side. Pushing
//   warp high does not add more samples; it only increases the offset, and
//   the image can look stringy rather than more detailed.

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uPointer;
uniform float uPointerActive;
uniform float uSpeed;
uniform float uScale;
uniform float uWarp;
uniform vec3 uColorA;
uniform vec3 uColorB;
uniform vec3 uColorC;

out vec4 fragColor;

float hash21(vec2 cell) {
  return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

float valueNoise(vec2 p) {
  vec2 cell = floor(p);
  vec2 t = fract(p);
  vec2 u = t * t * (3.0 - 2.0 * t);
  float a = hash21(cell);
  float b = hash21(cell + vec2(1.0, 0.0));
  float c = hash21(cell + vec2(0.0, 1.0));
  float d = hash21(cell + vec2(1.0, 1.0));
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
  const mat2 kRotate = mat2(0.877582, -0.479426, 0.479426, 0.877582);
  float value = 0.0;
  float amplitude = 0.5;
  for (int octave = 0; octave < 4; octave++) {
    value += amplitude * valueNoise(p);
    p = kRotate * p * 2.03;
    amplitude *= 0.5;
  }
  return value;
}

vec2 aspectPoint(vec2 normalized, vec2 resolution) {
  float aspect = resolution.x / max(resolution.y, 1.0);
  return (normalized - 0.5) * vec2(aspect, 1.0);
}

// The domain is the coordinate we are about to sample.
// q is a noise vector. Using q as an offset means "read the texture from
// over there instead of from here." r does it again, using a coordinate
// that was already wrong. Two layers are visibly more tangled than one
// because the second displacement is no longer aligned with the first.
float warpedField(vec2 domain, float warp) {
  if (warp <= 0.001) {
    return fbm(domain);
  }

  vec2 q = vec2(
    fbm(domain),
    fbm(domain + vec2(5.2, 1.3))
  );
  vec2 r = vec2(
    fbm(domain + warp * q + vec2(1.7, 9.2)),
    fbm(domain + warp * q + vec2(8.3, 2.8))
  );
  return fbm(domain + warp * r);
}

void main() {
  vec2 resolution = max(uResolution, vec2(1.0));
  vec2 uv = FlutterFragCoord().xy / resolution;
  vec2 p = aspectPoint(uv, resolution);

  vec2 pointer = aspectPoint(uPointer, resolution);
  vec2 touch = (pointer - p) * exp(-length(pointer - p) * 2.6) * uPointerActive;

  float time = uTime * uSpeed;
  vec2 domain = p * max(uScale, 0.15) + vec2(time * 0.07, time * 0.02) + touch * 0.45;

  float field = warpedField(domain, max(uWarp, 0.0));

  // Color is applied after the field exists. Swapping uColorB does not move
  // the shapes. Changing uWarp does, because it edits the coordinate.
  vec3 color = mix(uColorA, uColorB, smoothstep(0.25, 0.62, field));
  color = mix(color, uColorC, smoothstep(0.55, 0.92, field));

  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
