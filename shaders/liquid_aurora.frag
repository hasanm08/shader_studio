// Living Liquid Aurora
//
// Purpose
//   Featured Shader Studio sample. A full-screen procedural field that reads
//   as glossy liquid or an aurora, built only from coordinates, value noise,
//   domain warping, and a lighting approximation.
//
// Visual result
//   Layered teal, cyan, and white forms drift on a near-black field. Edges
//   pick up a soft highlight. A pointer inside the preview pulls the pattern,
//   like a finger dragged through viscous fluid.
//
// Techniques
//   Aspect-corrected UVs, value noise, fractional Brownian motion (fBm),
//   domain warping, a slope used as a fake normal, and a color ramp.
//
// This is not a 3D fluid simulation and it does not refract a scene.
// Depth is suggested by lighting a 2D scalar field.
//
// Uniforms — packed in declaration order, with no std140 padding.
//   Index  Type    Name             Meaning
//   0      vec2    uResolution      Preview size in canvas units (width, height)
//   2      float   uTime            Elapsed seconds, wrapped by Dart into [0, 600)
//   3      vec2    uPointer         Pointer in normalized preview space, origin top-left
//   5      float   uPointerActive   1 while the pointer is inside the preview, else 0
//   6      float   uSpeed           Multiplier on uTime
//   7      float   uScale           Spatial frequency of the field
//   8      float   uIntensity       How far the ramp is pushed toward cyan and white
//   9      float   uDistortion      How far noise is allowed to move the domain
//
// Coordinates
//   FlutterFragCoord() is the canvas position of the fragment, origin at the
//   top-left of the drawn rect, Y down, in the same units as uResolution.
//   uPointer is normalized: (0, 0) is the top-left of the preview and (1, 1)
//   is the bottom-right. Both are converted with aspectPoint() before any
//   distance or noise sample, so circles stay circular on wide layouts.
//
// How to run
//   Registered in pubspec.yaml under flutter/shaders and opened from the
//   Shader Studio gallery as "Living Liquid Aurora".
//
// Limitations
//   Four fBm evaluations, each with four noise octaves. Cost grows with
//   preview resolution, not with the Dart widget tree. There is no screen
//   reflection and no thickness. Very large uScale can shimmer because this
//   shader does not compute derivatives for antialiasing. uTime is expected
//   to stay in a modest range; Dart wraps it to protect sine precision.

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uPointer;
uniform float uPointerActive;
uniform float uSpeed;
uniform float uScale;
uniform float uIntensity;
uniform float uDistortion;

out vec4 fragColor;

// Turns a 2D cell coordinate into a stable value in [0, 1).
//
// This is a sine hash, the same family Flutter uses in its own shader
// fixtures. It is not a high-quality hash: low frequencies can show a faint
// grid. It only needs sin, dot, and fract, which Flutter's shader compiler
// accepts on every backend this project targets.
float hash21(vec2 cell) {
  return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

// Interpolates hashed cell corners so the field is continuous.
// The cubic Hermite curve on `t` (smoothstep's polynomial) gives zero slope
// at cell edges, which is what stops the noise from looking faceted.
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

// Stacks noise octaves. Each octave is rotated so ridges do not all share
// the same axis, then doubled in frequency and halved in amplitude.
// The loop bound is a constant because the shader compiler needs a fixed
// maximum. Four octaves is the whole cost model for this sample.
float fbm(vec2 p) {
  // cos(0.5), sin(0.5): a fixed rotation, not a random one.
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

// Normalized preview position with the aspect ratio baked in.
// Dividing by resolution maps the fragment into 0..1. Multiplying X by
// width/height makes one unit in X the same length on screen as one unit
// in Y. Without that, a radial falloff becomes an ellipse on a wide canvas.
vec2 aspectPoint(vec2 normalized, vec2 resolution) {
  float aspect = resolution.x / max(resolution.y, 1.0);
  return (normalized - 0.5) * vec2(aspect, 1.0);
}

// Returns (field, warpX, warpY).
//
// Domain warping samples noise at a coordinate that was itself displaced by
// noise. Changing the coordinate changes which value we read. It is not the
// same as mixing colors after the fact: the shape of the field moves.
// The warp vector is also reused as a slope for the fake light, so lighting
// does not require four extra full-field evaluations.
vec3 auroraField(vec2 p, vec2 touch, float time) {
  vec2 flow = p + vec2(time * 0.08, time * 0.035) + touch;

  vec2 q = vec2(
    fbm(flow),
    fbm(flow + vec2(5.2, 1.3))
  );

  float warp = max(uDistortion, 0.0);
  vec2 r = vec2(
    fbm(flow + q * warp + vec2(1.7, 9.2)),
    fbm(flow + q * warp + vec2(8.3, 2.8))
  );

  float field = fbm(flow + r * warp);
  return vec3(field, r);
}

void main() {
  vec2 resolution = max(uResolution, vec2(1.0));
  vec2 uv = FlutterFragCoord().xy / resolution;
  vec2 p = aspectPoint(uv, resolution) * max(uScale, 0.2);

  // The pointer is converted with the same function as the fragment, then
  // used as a localized pull. The exponential keeps the influence near the
  // finger so the rest of the field keeps its motion.
  vec2 pointer = aspectPoint(uPointer, resolution) * max(uScale, 0.2);
  vec2 delta = pointer - p;
  float pull = exp(-length(delta) * 3.2);
  vec2 touch = delta * pull * uPointerActive * 0.55;

  float time = uTime * uSpeed;
  vec3 field = auroraField(p, touch, time);
  float height = field.x;

  // Ridged noise flips the fBm so the mid-level becomes a bright crest.
  // That crest is the glossy edge, not a separate mesh.
  float ridge = pow(clamp(1.0 - abs(height * 2.0 - 1.0), 0.0, 1.0), 1.5);

  // Interpret the warp offset as a surface slope. A real normal would be
  // the gradient of `height`; this is cheaper and still responds to the
  // same distortion the viewer is controlling.
  vec3 normal = normalize(vec3(-field.y + 0.5, -field.z + 0.5, 1.35));
  vec3 lightDir = normalize(vec3(0.32, 0.58, 0.85));
  float diffuse = clamp(dot(normal, lightDir), 0.0, 1.0);
  float facing = clamp(normal.z, 0.0, 1.0);
  float rim = pow(1.0 - facing, 2.0);
  vec3 halfVector = normalize(lightDir + vec3(0.0, 0.0, 1.0));
  float specular = pow(clamp(dot(normal, halfVector), 0.0, 1.0), 16.0);

  vec3 deep = vec3(0.031, 0.043, 0.063);
  vec3 navy = vec3(0.035, 0.110, 0.165);
  vec3 teal = vec3(0.078, 0.902, 0.812);
  vec3 cyan = vec3(0.302, 0.733, 1.0);
  vec3 ice = vec3(0.910, 0.970, 1.0);

  float intensity = clamp(uIntensity, 0.0, 2.0);
  vec3 color = mix(deep, navy, smoothstep(0.18, 0.42, height));
  color = mix(color, teal, smoothstep(0.36, 0.68, height));
  color = mix(color, cyan, smoothstep(0.55, 0.84, height) * intensity);
  color = mix(color, ice, smoothstep(0.45, 0.95, ridge) * 0.8 * intensity);
  color += cyan * diffuse * 0.16;
  color += ice * specular * 0.45 * intensity;
  color += ice * rim * 0.22 * intensity;

  // Darken the corners so the luminous shapes read as a composed frame.
  float vignette = smoothstep(1.25, 0.2, length(aspectPoint(uv, resolution)));
  color *= mix(0.45, 1.0, vignette);

  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
