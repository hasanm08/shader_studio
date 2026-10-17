// Procedural Energy Core
//
// Purpose
//   A glowing orb with a hard circular silhouette, turbulent interior, and
//   a bright rim. Depth comes from the equation of a sphere, not from
//   marching rays.
//
// Visual result
//   A teal core sits on a dark field. The interior swirls, the rim flares,
//   and the light direction leans toward the pointer.
//
// Techniques
//   Signed distance to a circle, the analytic normal of a front-facing
//   hemisphere, value-noise turbulence, diffuse plus rim lighting, and an
//   exponential glow outside the silhouette.
//
// This shader does not ray march. Nothing steps along a ray, and there is
// no iteration budget. The "sphere" is the closed-form z of x^2 + y^2 + z^2
// = r^2 for the pixels inside the circle.
//
// Uniforms — packed in declaration order, with no std140 padding.
//   Index  Type    Name             Meaning
//   0      vec2    uResolution      Preview size in canvas units
//   2      float   uTime            Elapsed seconds, wrapped by Dart into [0, 600)
//   3      vec2    uPointer         Pointer in normalized preview space, origin top-left
//   5      float   uPointerActive   1 while the pointer is inside the preview, else 0
//   6      float   uSpeed           Animation rate of the swirl and the pulse
//   7      float   uIntensity       Brightness of the lit core and the glow
//   8      float   uPulse           How much the radius breathes
//   9      float   uTurbulence      Spatial frequency of the interior noise
//   10     vec3    uColorCore       Interior color, RGB 0..1
//   13     vec3    uColorRim        Rim and outer glow color, RGB 0..1
//
// Coordinates
//   FlutterFragCoord is canvas space, origin top-left, Y down. aspectPoint()
//   corrects the aspect ratio before the distance test so the silhouette
//   stays circular when the preview is not square.
//
// How to run
//   Open "Procedural Energy Core" from the gallery.
//
// Limitations
//   The normal is valid only inside the circle. Outside it, the shader uses
//   glow instead of shading a surface. There is no self-shadow and no
//   refraction. Four noise octaves run for every fragment, including the
//   empty background, so the cost is flat across the preview.

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uPointer;
uniform float uPointerActive;
uniform float uSpeed;
uniform float uIntensity;
uniform float uPulse;
uniform float uTurbulence;
uniform vec3 uColorCore;
uniform vec3 uColorRim;

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

// Signed distance from `p` to a circle. Negative means inside.
// The zero set is the silhouette. Coloring by the sign is the whole
// inside/outside test; no ray is cast.
float sdCircle(vec2 p, float radius) {
  return length(p) - radius;
}

// Front-hemisphere normal from the sphere equation.
// z is solved, not marched. Outside the sphere z^2 would be negative, so
// callers must only use this where sdCircle is negative.
vec3 sphereNormal(vec2 p, float radius) {
  float z = sqrt(max(radius * radius - dot(p, p), 0.0));
  return normalize(vec3(p, z));
}

void main() {
  vec2 resolution = max(uResolution, vec2(1.0));
  vec2 uv = FlutterFragCoord().xy / resolution;
  vec2 p = aspectPoint(uv, resolution);

  float time = uTime * uSpeed;
  float radius = 0.34 + 0.018 * sin(time * 1.6) * uPulse;
  float sd = sdCircle(p, radius);

  // Interior coordinate drifts so the turbulence is not glued to the disc.
  float turb = fbm(p * (2.2 + uTurbulence) + vec2(time * 0.22, -time * 0.16));

  vec3 background = vec3(0.025, 0.035, 0.05);
  vec3 color = background;

  if (sd < 0.0) {
    vec3 normal = sphereNormal(p, radius);

    // Default light is up-left. The pointer offsets it in normalized space.
    // Mixing a direction (not a position) keeps the light stable when the
    // pointer sits on the orb.
    vec2 pointerOffset = (uPointer - vec2(0.5)) * 1.4;
    vec2 lightXY = mix(vec2(0.35, -0.5), pointerOffset, uPointerActive);
    vec3 lightDir = normalize(vec3(lightXY, 0.85));

    float diffuse = clamp(dot(normal, lightDir), 0.0, 1.0);
    float rim = pow(1.0 - clamp(normal.z, 0.0, 1.0), 2.4);
    float pulse = 0.85 + 0.15 * sin(time * 2.2);

    vec3 interior = mix(uColorCore, uColorRim, smoothstep(0.35, 0.85, turb));
    vec3 lit = interior * (0.18 + 0.82 * diffuse) * pulse;
    lit += uColorRim * rim * 1.15;
    lit += vec3(1.0) * pow(clamp(turb, 0.0, 1.0), 3.0) * 0.25;
    color = lit * max(uIntensity, 0.0);
  }

  // Glow is a function of how far outside the silhouette we are.
  // exp(-distance) is a cheap falloff. It is not a volumetric integral.
  float glow = exp(-max(sd, 0.0) * 8.0) * 0.55 * max(uIntensity, 0.0);
  color += uColorRim * glow;

  float vignette = smoothstep(1.15, 0.2, length(p));
  color *= mix(0.65, 1.0, vignette);

  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
