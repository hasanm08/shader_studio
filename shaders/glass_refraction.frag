// Realistic Glass Refraction
//
// Purpose
//   Sample a captured background texture through a thick, curved glass
//   surface. The glass refracts, softens, and edges the picture instead of
//   painting a translucent white overlay.
//
// Visual result
//   A convex lens-like panel: center magnification, edge pinching, Fresnel
//   rim light, a soft specular glint, optional chromatic fringing, and a
//   configurable frosted blur. Outside the shape the fragment is discarded
//   to alpha 0 so the scene shows through.
//
// Techniques
//   Shape SDFs, a parabolic height field for curvature, Snell-style UV
//   bend, multi-tap blur, Schlick Fresnel, and a single analytic specular.
//
// Uniforms — packed float order (sampler indexes separately).
//   Index  Type    Name              Meaning
//   0      vec2    uResolution       Glass widget size in canvas units
//   2      vec2    uSampleOrigin     Background UV of the glass top-left
//   4      vec2    uSampleExtent     Background UV size covered by the glass
//   6      float   uTime             Elapsed seconds for subtle highlight drift
//   7      float   uRefraction       UV bend strength
//   8      float   uCurvature        Lens bulge (height field amplitude)
//   9      float   uBlur            Softness / frost (tap radius scale)
//   10     float   uReflection       Specular highlight strength
//   11     float   uEdgeHighlight    Fresnel rim strength
//   12     float   uChromatic        R/B channel split along the bend
//   13     float   uOpacity          Glass body opacity (content still on top)
//   14     float   uShape            0 circle, 1 rrect, 2 capsule, 3 lens
//   15     float   uCornerRadius     Rounded-rect radius in local UV units
//   —      sampler uBackground       Full-scene capture (setImageSampler 0)
//
// Coordinates
//   FlutterFragCoord is local glass canvas space, origin top-left, Y down.
//   Background UVs are top-left origin. Distortion is applied in aspect-
//   corrected local space so circles stay circular on wide panels.
//
// Compositing
//   This shader cannot see live widgets. Dart captures a RepaintBoundary
//   behind the glass and binds that image. Moving the glass only updates
//   uSampleOrigin / uSampleExtent; the texture is re-captured when the
//   background itself changes.
//
// Limitations
//   Blur is a fixed 9-tap kernel, not a separable Gaussian. Very strong
//   refraction can sample outside the capture (clamped). Multiple glass
//   panels share one capture and do not refract each other.

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uResolution;
uniform vec2 uSampleOrigin;
uniform vec2 uSampleExtent;
uniform float uTime;
uniform float uRefraction;
uniform float uCurvature;
uniform float uBlur;
uniform float uReflection;
uniform float uEdgeHighlight;
uniform float uChromatic;
uniform float uOpacity;
uniform float uShape;
uniform float uCornerRadius;
uniform sampler2D uBackground;

out vec4 fragColor;

float sdCircle(vec2 p, float r) {
  return length(p) - r;
}

float sdRoundedBox(vec2 p, vec2 b, float r) {
  vec2 q = abs(p) - b + r;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

float sdCapsule(vec2 p, float halfLen, float r) {
  float x = abs(p.x) - halfLen;
  return length(vec2(max(x, 0.0), p.y)) - r;
}

float sdLens(vec2 p, float rx, float ry) {
  // Elliptical disc used as a bi-convex silhouette.
  vec2 n = p / max(vec2(rx, ry), vec2(0.001));
  return (length(n) - 1.0) * min(rx, ry);
}

float shapeSd(vec2 p, vec2 halfSize, float radius) {
  float kind = floor(uShape + 0.5);
  if (kind < 0.5) {
    return sdCircle(p, min(halfSize.x, halfSize.y));
  }
  if (kind < 1.5) {
    float r = clamp(radius, 0.0, min(halfSize.x, halfSize.y));
    return sdRoundedBox(p, halfSize, r);
  }
  if (kind < 2.5) {
    float r = min(halfSize.y, halfSize.x);
    float halfLen = max(halfSize.x - r, 0.0);
    return sdCapsule(p, halfLen, r);
  }
  return sdLens(p, halfSize.x, halfSize.y);
}

// Parabolic bulge: tallest in the center, zero near the rim.
float heightField(vec2 p, vec2 halfSize) {
  vec2 n = p / max(halfSize, vec2(0.001));
  float r2 = clamp(dot(n, n), 0.0, 1.0);
  return uCurvature * (1.0 - r2);
}

vec3 surfaceNormal(vec2 p, vec2 halfSize) {
  const float e = 0.004;
  float hx = heightField(p + vec2(e, 0.0), halfSize) -
      heightField(p - vec2(e, 0.0), halfSize);
  float hy = heightField(p + vec2(0.0, e), halfSize) -
      heightField(p - vec2(0.0, e), halfSize);
  return normalize(vec3(-hx, -hy, 0.22));
}

vec2 bendUv(vec2 localUv, vec3 normal, float strength) {
  // Approximate refraction: bend screen-space UVs opposite the normal xy.
  vec2 offset = normal.xy * strength * (0.35 + uCurvature);
  return localUv + offset;
}

vec4 sampleBg(vec2 localUv) {
  vec2 uv = uSampleOrigin + clamp(localUv, 0.0, 1.0) * uSampleExtent;
  uv = clamp(uv, vec2(0.001), vec2(0.999));
  return texture(uBackground, uv);
}

vec4 sampleBgBlur(vec2 localUv, float radius) {
  if (radius < 0.0005) {
    return sampleBg(localUv);
  }
  // 9-tap diamond / cross — cheap frost, not a true Gaussian.
  vec2 px = radius / max(uResolution, vec2(1.0));
  vec4 c = sampleBg(localUv) * 0.25;
  c += sampleBg(localUv + vec2(px.x, 0.0)) * 0.12;
  c += sampleBg(localUv - vec2(px.x, 0.0)) * 0.12;
  c += sampleBg(localUv + vec2(0.0, px.y)) * 0.12;
  c += sampleBg(localUv - vec2(0.0, px.y)) * 0.12;
  c += sampleBg(localUv + px) * 0.0675;
  c += sampleBg(localUv - px) * 0.0675;
  c += sampleBg(localUv + vec2(px.x, -px.y)) * 0.0675;
  c += sampleBg(localUv + vec2(-px.x, px.y)) * 0.0675;
  return c;
}

vec4 sampleRefracted(vec2 localUv, vec3 normal) {
  float strength = uRefraction;
  vec2 center = bendUv(localUv, normal, strength);
  float blurPx = uBlur * 10.0;

  if (uChromatic < 0.00005) {
    return sampleBgBlur(center, blurPx);
  }

  vec2 dir = normalize(normal.xy + vec2(0.0001));
  vec2 split = dir * uChromatic * (0.6 + length(normal.xy) * 2.0);
  float r = sampleBgBlur(center + split, blurPx).r;
  float g = sampleBgBlur(center, blurPx).g;
  float b = sampleBgBlur(center - split, blurPx).b;
  float a = sampleBgBlur(center, blurPx).a;
  return vec4(r, g, b, a);
}

void main() {
  vec2 resolution = max(uResolution, vec2(1.0));
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = frag / resolution;

  // Aspect-corrected local space centered on the glass.
  float aspect = resolution.x / resolution.y;
  vec2 p = (uv - 0.5) * vec2(aspect, 1.0);
  vec2 halfSize = vec2(0.5 * aspect, 0.5);

  float radius = uCornerRadius * min(halfSize.x, halfSize.y) * 2.0;
  float d = shapeSd(p, halfSize, radius);

  // Smooth AA on the silhouette.
  float aa = 1.5 / max(min(resolution.x, resolution.y), 1.0);
  float mask = 1.0 - smoothstep(-aa, aa, d);
  if (mask <= 0.001) {
    fragColor = vec4(0.0);
    return;
  }

  vec3 normal = surfaceNormal(p, halfSize);
  vec4 refracted = sampleRefracted(uv, normal);

  // Schlick-ish Fresnel from the view vector (0,0,1).
  float ndotv = clamp(normal.z, 0.0, 1.0);
  float fresnel = pow(1.0 - ndotv, 3.0);
  // Extra rim from the SDF so rounded shapes get a clear edge even with
  // flat curvature.
  float rim = 1.0 - smoothstep(0.0, 0.08, -d);
  float edge = clamp(fresnel * 0.85 + rim * 0.55, 0.0, 1.0);

  // Specular glint with a slow drift so static shots still feel alive.
  float ang = uTime * 0.35;
  vec3 lightDir = normalize(vec3(cos(ang) * 0.45, -0.55 + sin(ang) * 0.1, 0.85));
  vec3 halfV = normalize(lightDir + vec3(0.0, 0.0, 1.0));
  float spec = pow(clamp(dot(normal, halfV), 0.0, 1.0), 48.0);
  // Inner caustic-ish highlight near the center-top.
  float inner = pow(clamp(1.0 - length((p / halfSize) - vec2(0.0, -0.25)), 0.0, 1.0), 2.5);

  vec3 glassTint = vec3(0.92, 0.97, 1.0);
  vec3 color = refracted.rgb * mix(vec3(1.0), glassTint, 0.12 * uOpacity);
  color = mix(color, color * 0.92 + vec3(0.04), uOpacity * 0.25);
  color += vec3(0.85, 0.93, 1.0) * edge * uEdgeHighlight * 0.55;
  color += vec3(1.0) * spec * uReflection * 0.85;
  color += vec3(0.75, 0.9, 1.0) * inner * uReflection * 0.12;
  // Outer hairline.
  color += vec3(1.0) * smoothstep(aa * 2.0, 0.0, abs(d)) * uEdgeHighlight * 0.35;

  float alpha = mask * mix(0.72, 0.96, clamp(uOpacity, 0.0, 1.0));
  fragColor = vec4(clamp(color, 0.0, 1.0), alpha);
}
