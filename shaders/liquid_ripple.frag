// Interactive Liquid Ripple
//
// Purpose
//   A dark liquid surface disturbed by the pointer. Each gesture emits a
//   circular wave that travels outward and fades.
//
// Visual result
//   Concentric highlights expand from recent pointer positions and die out.
//   The current pointer also leaves a small contact dimple so the response
//   is immediate, before the next stored ripple is far enough to emit.
//
// Techniques
//   Distance from a point, a kinematic circular wave (not a solved wave
//   equation), exponential decay, and a finite-difference slope for gloss.
//
// Uniforms — packed in declaration order, with no std140 padding.
//   Index  Type    Name             Meaning
//   0      vec2    uResolution      Preview size in canvas units
//   2      float   uTime            Elapsed seconds, wrapped by Dart into [0, 600)
//   3      vec2    uPointer         Pointer in normalized preview space, origin top-left
//   5      float   uPointerActive   1 while the pointer is inside the preview, else 0
//   6      float   uAmplitude       Height of each wave
//   7      float   uFrequency       Spatial frequency of the sine, in UV units
//   8      float   uSpeed           How fast the wavefront radius grows
//   9      float   uDamping         Exponential decay rate over age
//   10     vec3    uColor           Tint multiplied into the lit water, RGB 0..1
//   13     vec3    uRipple0         xy normalized origin, z start time (< 0 means empty)
//   16     vec3    uRipple1         Second slot, same packing
//   19     vec3    uRipple2         Third slot
//   22     vec3    uRipple3         Fourth slot
//
// Coordinates
//   Same convention as the other samples: FlutterFragCoord is canvas space,
//   origin top-left, Y down. Pointer and ripple origins arrive normalized
//   and are converted with aspectPoint() so a ripple is circular.
//
// How to run
//   Open "Interactive Liquid Ripple" from the gallery and drag inside the
//   preview. Dart keeps four ripple slots and overwrites the oldest.
//
// Limitations
//   Only four wave sources exist. There is no wake history beyond that ring
//   buffer. This shader does not integrate the 2D wave equation; each slot
//   is an independent sine of distance and age. When Dart wraps uTime, a
//   slot whose start time is now in the future is treated as expired.
//   The finite-difference normal evaluates the height three times per pixel.

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uPointer;
uniform float uPointerActive;
uniform float uAmplitude;
uniform float uFrequency;
uniform float uSpeed;
uniform float uDamping;
uniform vec3 uColor;
uniform vec3 uRipple0;
uniform vec3 uRipple1;
uniform vec3 uRipple2;
uniform vec3 uRipple3;

out vec4 fragColor;

vec2 aspectPoint(vec2 normalized, vec2 resolution) {
  float aspect = resolution.x / max(resolution.y, 1.0);
  return (normalized - 0.5) * vec2(aspect, 1.0);
}

// One stored gesture.
//
// `source.z` is the clock time when Dart emitted the ripple. Age is how long
// ago that was. The wavefront radius is age * speed, so the crest moves
// outward at a constant rate. smoothstep keeps the undisturbed region outside
// that front at zero — the wave has not arrived yet.
//
// Decay is separate from the front. Without damping, old slots would keep
// full amplitude until the ring buffer overwrites them, and the surface
// would never go quiet. The age cap is a hard stop so a wrapped clock cannot
// revive a stale slot.
float rippleHeight(vec2 p, vec3 source, vec2 resolution) {
  if (source.z < 0.0) {
    return 0.0;
  }
  float age = uTime - source.z;
  if (age < 0.0 || age > 8.0) {
    return 0.0;
  }

  vec2 origin = aspectPoint(source.xy, resolution);
  float dist = length(p - origin);
  float radius = age * max(uSpeed, 0.0);
  float front = 1.0 - smoothstep(max(radius - 0.045, 0.0), radius + 0.001, dist);
  float wave = sin(dist * uFrequency - age * 6.0);
  float spatial = exp(-dist * 2.4);
  float temporal = exp(-clamp(uDamping * age, 0.0, 12.0));
  return wave * spatial * temporal * front * uAmplitude;
}

float heightAt(vec2 p, vec2 resolution) {
  return rippleHeight(p, uRipple0, resolution) +
      rippleHeight(p, uRipple1, resolution) +
      rippleHeight(p, uRipple2, resolution) +
      rippleHeight(p, uRipple3, resolution);
}

void main() {
  vec2 resolution = max(uResolution, vec2(1.0));
  vec2 uv = FlutterFragCoord().xy / resolution;
  vec2 p = aspectPoint(uv, resolution);

  // Contact dimple: not a stored ripple. It tracks the live pointer so the
  // surface reacts even when the emit spacing has not produced a new slot.
  vec2 pointer = aspectPoint(uPointer, resolution);
  float contact = exp(-length(p - pointer) * 16.0) * uPointerActive * uAmplitude;

  float height = heightAt(p, resolution) - contact * 0.35;

  // Slope from central differences. dFdx is not used; Flutter runtime
  // effects do not guarantee fragment derivatives. The epsilon is in
  // aspect-corrected UV units, so the highlight width is stable as the
  // preview is resized.
  const float kEpsilon = 0.0035;
  float dx = heightAt(p + vec2(kEpsilon, 0.0), resolution) -
      heightAt(p - vec2(kEpsilon, 0.0), resolution);
  float dy = heightAt(p + vec2(0.0, kEpsilon), resolution) -
      heightAt(p - vec2(0.0, kEpsilon), resolution);
  vec3 normal = normalize(vec3(-dx, -dy, 0.085));

  vec3 lightDir = normalize(vec3(-0.25, -0.45, 0.9));
  float diffuse = clamp(dot(normal, lightDir), 0.0, 1.0);
  vec3 viewHalf = normalize(lightDir + vec3(0.0, 0.0, 1.0));
  float specular = pow(clamp(dot(normal, viewHalf), 0.0, 1.0), 30.0);

  vec3 deep = vec3(0.02, 0.035, 0.05);
  vec3 water = mix(deep, uColor, 0.22 + 0.55 * diffuse);
  water += vec3(0.85, 0.95, 1.0) * specular;
  water += uColor * clamp(height, 0.0, 1.0) * 0.35;

  float vignette = smoothstep(1.2, 0.25, length(p));
  water *= mix(0.5, 1.0, vignette);

  fragColor = vec4(clamp(water, 0.0, 1.0), 1.0);
}
