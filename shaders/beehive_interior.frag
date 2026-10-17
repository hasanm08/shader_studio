// Inside the Hive
//
// Purpose
//   Look out from inside one honeycomb cell. The six wax walls are the
//   distance to a hexagonal tube. The wall ahead is a second comb. Bees are
//   ellipsoids tested against the same camera ray.
//
// Visual result
//   Amber wax frames a field of hexagonal cells. Some cells hold honey.
//   Two bees cross the opening. The pointer leans the camera inside the cell.
//
// Techniques
//   A hex grid, the signed distance to one hexagon, a fixed-budget ray march
//   along an extruded tube, a plane for the far comb, and closed-form ray
//   hits against ellipsoids. This march has an iteration budget. It is not
//   a fluid, and the bees are not simulated.
//
// Uniforms — packed in declaration order, with no std140 padding.
//   Index  Type    Name             Meaning
//   0      vec2    uResolution      Preview size in canvas units
//   2      float   uTime            Elapsed seconds, wrapped by Dart into [0, 600)
//   3      vec2    uPointer         Pointer in normalized preview space, origin top-left
//   5      float   uPointerActive   1 while the pointer is inside the preview, else 0
//   6      float   uSpeed           Bee flight and honey shimmer
//   7      float   uScale           Spatial frequency of the comb. Larger means smaller cells
//   8      float   uDepth           Distance from the camera to the far comb
//   9      float   uHoney           How full the far cells look, 0..1
//   10     vec3    uColorWax        Wax color, straight RGB
//   13     vec3    uColorHoney      Honey color, straight RGB
//
// Coordinates
//   FlutterFragCoord is canvas space, origin top-left, Y down. aspectPoint()
//   builds the camera ray so the cell stays regular when the preview is wide.
//   The pointer offsets the ray origin inside the current cell. It is clamped
//   so the camera does not start inside the wax.
//
// How to run
//   Open "Inside the Hive" from the gallery and drag in the preview.
//
// Limitations
//   The march is capped at 32 steps. The tube distance is exact, so the cap
//   is rarely the thing that stops a ray; the far comb does. Bees are two
//   rigid ellipsoids plus pulsing wings, not articulated bodies. There is no
//   shadow from a bee onto the wax. High scale makes the cell smaller than
//   the bees, and they will intersect the walls.

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uPointer;
uniform float uPointerActive;
uniform float uSpeed;
uniform float uScale;
uniform float uDepth;
uniform float uHoney;
uniform vec3 uColorWax;
uniform vec3 uColorHoney;

out vec4 fragColor;

const int kMaxSteps = 32;
const float kHitEpsilon = 0.003;

vec2 aspectPoint(vec2 normalized, vec2 resolution) {
  float aspect = resolution.x / max(resolution.y, 1.0);
  return (normalized - 0.5) * vec2(aspect, 1.0);
}

// Local coordinates of the nearest hex cell.
//
// The repeat is two offset rectangular lattices. Picking the closer of the
// two origins makes the Voronoi cell a hexagon. `p` is already scaled, so
// the distance between neighboring centers in this space is 1.
vec2 hexLocal(vec2 p) {
  const vec2 kSpacing = vec2(1.0, 1.7320508);
  const vec2 kHalf = vec2(0.5, 0.8660254);
  vec2 a = mod(p, kSpacing) - kHalf;
  vec2 b = mod(p - kHalf, kSpacing) - kHalf;
  return dot(a, a) < dot(b, b) ? a : b;
}

// Signed distance to a flat-top hexagon. Negative means inside.
// `r` is the distance from the center to a flat side, not to a vertex.
// Swapping axes turns it pointy-top, which matches hexLocal's vertical walls.
float sdHexagon(vec2 p, float r) {
  const vec3 k = vec3(-0.866025404, 0.5, 0.577350269);
  p = abs(p);
  p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
  p -= vec2(clamp(p.x, -k.z * r, k.z * r), r);
  return length(p) * sign(p.y);
}

// Positive in the air of a cell, negative inside the wax.
// 0.46 is a little under the 0.5 apothem of the tiling, so neighboring
// cells do not meet and the gap reads as a wall.
float airDist(vec2 p) {
  vec2 local = hexLocal(p);
  return -sdHexagon(vec2(local.y, local.x), 0.46);
}

float hash21(vec2 cell) {
  return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

// Steps along the ray until the extruded hex tube is hit or the budget ends.
//
// airDist does not depend on z, and it is a real distance in xy, so it is a
// valid step length for the tube. The loop bound is the iteration budget.
float marchTube(vec3 ro, vec3 rd, float scale, float maxT) {
  float t = 0.01;
  for (int step = 0; step < kMaxSteps; step++) {
    if (t >= maxT) {
      return maxT + 1.0;
    }
    float dist = airDist((ro + rd * t).xy * scale);
    if (dist < kHitEpsilon) {
      return t;
    }
    t += max(dist / max(scale, 0.35), 0.008);
  }
  return maxT + 1.0;
}

vec3 tubeNormal(vec2 p, float scale) {
  const float kEpsilon = 0.002;
  float dx = airDist((p + vec2(kEpsilon, 0.0)) * scale) -
      airDist((p - vec2(kEpsilon, 0.0)) * scale);
  float dy = airDist((p + vec2(0.0, kEpsilon)) * scale) -
      airDist((p - vec2(0.0, kEpsilon)) * scale);
  return normalize(vec3(dx, dy, 0.08));
}

// Ray hit against an axis-aligned ellipsoid, in world units.
// Negative means a miss. Scaling the ray into the ellipsoid's unit sphere
// keeps the returned t comparable with the tube march.
float rayEllipsoid(vec3 ro, vec3 rd, vec3 center, vec3 radius) {
  vec3 rad = max(radius, vec3(0.0008));
  vec3 oc = (ro - center) / rad;
  vec3 d = rd / rad;
  float a = dot(d, d);
  float b = dot(oc, d);
  float h = b * b - a * (dot(oc, oc) - 1.0);
  if (h < 0.0 || a <= 0.00001) {
    return -1.0;
  }
  float t = (-b - sqrt(h)) / a;
  return t > 0.0 ? t : -1.0;
}

vec3 beeCenter(float id, float time, float room, float depth) {
  float t = time * (0.85 + id * 0.35);
  float z = mix(0.45, max(depth * 0.72, 0.5), 0.5 + 0.5 * sin(t * 0.65 + id * 2.0));
  return vec3(
    sin(t + id * 3.0) * room * 0.62,
    cos(t * 0.8 + id * 1.7) * room * 0.42,
    z
  );
}

vec3 shadeBee(vec3 hit, vec3 center) {
  float stripe = 0.5 + 0.5 * sin((hit.x - center.x) * 70.0);
  stripe = smoothstep(0.15, 0.85, stripe);
  vec3 amber = vec3(0.95, 0.72, 0.12);
  vec3 black = vec3(0.12, 0.07, 0.03);
  return mix(black, amber, stripe);
}

void main() {
  vec2 resolution = max(uResolution, vec2(1.0));
  vec2 uv = FlutterFragCoord().xy / resolution;
  vec2 view = aspectPoint(uv, resolution);

  float scale = max(uScale, 0.35);
  float depth = max(uDepth, 0.25);
  float time = uTime * max(uSpeed, 0.0);
  float room = 0.46 / scale;

  // Lean inside the cell. The limit is a fraction of the apothem so the
  // ray origin stays in air. Starting inside the wax would paint a solid wall.
  vec2 lean = (uPointer - vec2(0.5)) * uPointerActive * room * 0.55;
  vec3 ro = vec3(lean, 0.0);
  vec3 rd = normalize(vec3(view * 0.85 + lean * 0.35, 1.15));

  float planeT = rd.z > 0.02 ? depth / rd.z : 40.0;
  float tubeT = marchTube(ro, rd, scale, planeT);
  bool hitTube = tubeT < planeT;

  vec3 hit = ro + rd * (hitTube ? tubeT : planeT);
  vec3 color;

  if (hitTube) {
    vec3 normal = tubeNormal(hit.xy, scale);
    vec3 lightDir = normalize(vec3(0.15, 0.35, 0.9));
    float diffuse = clamp(dot(normal, lightDir), 0.0, 1.0);
    float grain = 0.5 + 0.5 * sin(hit.x * scale * 28.0 + hit.y * scale * 17.0);
    color = uColorWax * (0.22 + 0.78 * diffuse) * (0.82 + 0.18 * grain);
    color += uColorHoney * pow(diffuse, 6.0) * 0.15;
  } else {
    vec2 local = hexLocal(hit.xy * scale);
    float sd = sdHexagon(vec2(local.y, local.x), 0.46);
    float wax = smoothstep(-0.02, 0.025, sd);
    float center = smoothstep(-0.05, -0.28, sd);
    float variation = hash21(floor(hit.xy * scale + local * 3.0));
    float fill = clamp(uHoney, 0.0, 1.0) * mix(0.25, 1.0, variation) * center;
    float shimmer = 0.5 + 0.5 * sin(hit.x * 16.0 + hit.y * 11.0 + time * 2.0);
    vec3 honey = uColorHoney * (0.55 + 0.45 * shimmer);
    vec3 hole = vec3(0.05, 0.025, 0.012);
    vec3 cell = mix(hole, honey, fill);
    color = mix(cell, uColorWax * 0.72, wax);
    float spec = pow(clamp(shimmer * fill, 0.0, 1.0), 3.0);
    color += vec3(1.0, 0.92, 0.75) * spec * 0.25;
  }

  float fog = smoothstep(0.2, depth + 1.5, hitTube ? tubeT : planeT);
  color = mix(color, vec3(0.18, 0.08, 0.02), fog * 0.45);

  // Bees are tested after the hive so a miss keeps the comb. A closer hit
  // replaces it. Wings are a second ellipsoid, blended rather than opaque.
  for (int id = 0; id < 2; id++) {
    vec3 center = beeCenter(float(id), time, room, depth);
    float bodyT = rayEllipsoid(ro, rd, center, vec3(0.07, 0.032, 0.03));
    float wingScale = 0.25 + 0.75 * abs(sin(time * 26.0 + float(id)));
    float wingT = rayEllipsoid(
      ro,
      rd,
      center + vec3(0.0, 0.01, 0.0),
      vec3(0.09, 0.012 * wingScale, 0.045)
    );
    float sceneT = hitTube ? tubeT : planeT;
    if (bodyT > 0.0 && bodyT < sceneT) {
      color = shadeBee(ro + rd * bodyT, center);
      sceneT = bodyT;
    }
    if (wingT > 0.0 && wingT < sceneT) {
      color = mix(color, vec3(0.85, 0.9, 0.95), 0.45);
    }
  }

  float vignette = smoothstep(1.15, 0.25, length(view));
  color *= mix(0.55, 1.0, vignette);

  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
