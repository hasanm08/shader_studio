// Radial Wave and Distortion
//
// Purpose
//   Concentric waves around a center point, used to displace the coordinate
//   of a second pattern. The lesson is the difference between coloring a
//   distance and moving a sample position.
//
// Visual result
//   Rings expand from a center. A faint grid bends with the same displacement,
//   which makes the distortion visible even where the rings are subtle.
//   With "center follows pointer" on, the origin tracks the cursor.
//
// Techniques
//   Distance from a center, polar direction, a sine of radius, exponential
//   attenuation, and UV displacement before a second sample.
//
// Uniforms — packed in declaration order, with no std140 padding.
//   Index  Type    Name              Meaning
//   0      vec2    uResolution       Preview size in canvas units
//   2      float   uTime             Elapsed seconds, wrapped by Dart into [0, 600)
//   3      vec2    uPointer          Pointer in normalized preview space, origin top-left
//   5      float   uPointerActive    1 while the pointer is inside the preview, else 0
//   6      float   uFrequency        How many rings fit into one UV unit
//   7      float   uAmplitude        How far the coordinate is pushed, in UV units
//   8      float   uSpeed            Phase speed of the sine
//   9      float   uAttenuation      How fast amplitude falls with distance
//   10     vec2    uCenter           Configured center, normalized, origin top-left
//   12     float   uFollowPointer    1 to replace uCenter with uPointer while active
//   13     vec3    uColor            Ring tint, RGB 0..1
//
// Coordinates
//   Distances are measured after aspectPoint(), so the rings stay circular
//   on a wide or tall preview. Frequency is in those corrected units, not in
//   pixels, so resizing the preview does not multiply the ring count.
//
// How to run
//   Open "Radial Wave" and drag in the preview, or turn off follow-pointer
//   and move the center sliders.
//
// Limitations
//   Displacement is a single sine of radius. It does not bounce off edges
//   and it is not a fluid. Large amplitude folds the grid over itself; that
//   is the sampling consequence of pushing a coordinate past its neighbor.
//   Attenuation is what keeps the corners from shimmering at high frequency.

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uPointer;
uniform float uPointerActive;
uniform float uFrequency;
uniform float uAmplitude;
uniform float uSpeed;
uniform float uAttenuation;
uniform vec2 uCenter;
uniform float uFollowPointer;
uniform vec3 uColor;

out vec4 fragColor;

vec2 aspectPoint(vec2 normalized, vec2 resolution) {
  float aspect = resolution.x / max(resolution.y, 1.0);
  return (normalized - 0.5) * vec2(aspect, 1.0);
}

// Unit radial direction. The center fragment has no direction; returning
// zero there avoids a flash from normalizing a zero vector.
vec2 outward(vec2 offset) {
  float dist = length(offset);
  if (dist < 1e-4) {
    return vec2(0.0);
  }
  return offset / dist;
}

void main() {
  vec2 resolution = max(uResolution, vec2(1.0));
  vec2 uv = FlutterFragCoord().xy / resolution;
  vec2 p = aspectPoint(uv, resolution);

  // Follow mode selects the center in normalized space first, then both
  // choices go through the same aspect correction. Mixing after correction
  // would make the center slide on an ellipse.
  vec2 selected = mix(uCenter, uPointer, clamp(uFollowPointer, 0.0, 1.0) * uPointerActive);
  vec2 center = aspectPoint(selected, resolution);
  vec2 offset = p - center;
  float radius = length(offset);

  float atten = exp(-radius * max(uAttenuation, 0.0));
  float wave = sin(radius * uFrequency - uTime * uSpeed) * uAmplitude * atten;

  // Move the sample coordinate along the radial direction by the wave.
  // The grid below is evaluated at `displaced`, so its lines travel with
  // the rings. Sampling "from a different place" is the distortion.
  vec2 displaced = p - outward(offset) * wave;

  float displacedRadius = length(displaced - center);
  float rings = 0.5 + 0.5 * sin(displacedRadius * uFrequency);

  // A low-frequency grid in the displaced coordinate. The smoothstep width
  // is wide enough that the lines survive modest frequencies without
  // sparkling as badly as a one-pixel stroke would.
  float lineX = smoothstep(0.06, 0.0, abs(fract(displaced.x * 6.0) - 0.5) - 0.45);
  float lineY = smoothstep(0.06, 0.0, abs(fract(displaced.y * 6.0) - 0.5) - 0.45);
  float grid = clamp(lineX + lineY, 0.0, 1.0);

  vec3 background = vec3(0.027, 0.04, 0.055);
  vec3 color = mix(background, uColor, rings * atten);
  color = mix(color, vec3(0.9, 0.96, 1.0), grid * 0.28);
  color += uColor * atten * 0.15;

  // A quiet marker at the configured center so the origin stays readable
  // when the amplitude is zero.
  float marker = exp(-displacedRadius * 28.0);
  color += vec3(1.0) * marker * 0.35;

  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
