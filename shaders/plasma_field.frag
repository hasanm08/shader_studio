// Plasma Field
//
// Purpose
//   A full-screen color field made by adding sine waves. This is the sample
//   that shows how far periodic functions go before noise is required.
//
// Visual result
//   Soft bands of teal, cyan, blue, and white drift across the preview.
//   Moving the pointer shifts one of the waves so the pattern bends around
//   the cursor.
//
// Techniques
//   Normalized UVs, summed sinusoids, spatial and temporal frequency, and
//   a three-color mix. No noise and no loops.
//
// Uniforms — packed in declaration order, with no std140 padding.
//   Index  Type    Name             Meaning
//   0      vec2    uResolution      Preview size in canvas units
//   2      float   uTime            Elapsed seconds, wrapped by Dart into [0, 600)
//   3      vec2    uPointer         Pointer in normalized preview space, origin top-left
//   5      float   uPointerActive   1 while the pointer is inside the preview, else 0
//   6      float   uSpeed           Multiplier on uTime
//   7      float   uScale           Spatial frequency of the sines
//   8      float   uContrast        Exponent applied after the waves are summed
//   9      vec3    uColorA          Color at the low end of the field
//   12     vec3    uColorB          Color through the middle of the field
//   15     vec3    uColorC          Color at the high end of the field
//
// Coordinates
//   UVs are 0..1 with the origin at the top-left, matching FlutterFragCoord
//   divided by uResolution. This sample does not aspect-correct. The pattern
//   is a color field, not a circle, and stretching with the preview is part
//   of what the scale control is showing.
//
// How to run
//   Open "Plasma Field" from the gallery.
//
// Limitations
//   Four sine evaluations per pixel. That is cheap next to the fBm samples.
//   High uScale produces spatial frequencies the preview cannot resolve, so
//   the bands shimmer as they move. This shader does not antialias; Flutter
//   runtime effects do not provide reliable derivatives here. uContrast can
//   posterize the ramp if it is pushed to the top of its range.

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uPointer;
uniform float uPointerActive;
uniform float uSpeed;
uniform float uScale;
uniform float uContrast;
uniform vec3 uColorA;
uniform vec3 uColorB;
uniform vec3 uColorC;

out vec4 fragColor;

void main() {
  vec2 resolution = max(uResolution, vec2(1.0));
  // UV: fragment position normalized by the preview size.
  // (0, 0) is the top-left because FlutterFragCoord grows downward.
  vec2 uv = FlutterFragCoord().xy / resolution;

  float time = uTime * uSpeed;
  float scale = max(uScale, 0.1);

  // Each sine is a stripe along a different direction. Adding them is the
  // plasma. The coefficients on `time` are the temporal frequencies: they
  // are intentionally not integer multiples, so the loop does not repeat
  // after a short period.
  float field = 0.0;
  field += sin(uv.x * scale + time);
  field += sin(uv.y * scale * 1.27 - time * 0.73);
  field += sin((uv.x + uv.y) * scale * 0.65 + time * 0.41);
  field += sin(length(uv - vec2(0.35, 0.6)) * scale * 1.6 - time * 0.9);

  // The pointer term uses distance from the cursor when the pointer is
  // inside, and a fixed point otherwise. mix() on the center keeps the
  // wave continuous at the moment the pointer enters.
  vec2 center = mix(vec2(0.5, 0.45), uPointer, uPointerActive);
  field += sin(length(uv - center) * scale * 2.1 - time * 1.15);
  field /= 5.0;

  // Map [-1, 1] into [0, 1], then bend the distribution. Contrast above 1
  // spends more of the range near the palette endpoints.
  float t = field * 0.5 + 0.5;
  t = pow(clamp(t, 0.0, 1.0), max(uContrast, 0.05));

  vec3 color = mix(uColorA, uColorB, smoothstep(0.15, 0.55, t));
  color = mix(color, uColorC, smoothstep(0.45, 0.9, t));

  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
