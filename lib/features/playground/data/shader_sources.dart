// Shader text mirrored for the in-app viewer.
//
// Flutter rejects a file listed under both flutter/shaders
// and flutter/assets. The .frag files remain the compiled
// source of truth. Regenerate this file with
// `dart run tool/mirror_shader_sources.dart` after editing
// a shader. The contract test fails if the mirror drifts.
abstract final class ShaderSources {
  /// GLSL text keyed by the pubspec shader path.
  static const Map<String, String> byAsset = <String, String>{
    'shaders/beehive_interior.frag': r'''
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
''',
    'shaders/domain_warp.frag': r'''
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
''',
    'shaders/liquid_aurora.frag': r'''
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
''',
    'shaders/liquid_ripple.frag': r'''
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
''',
    'shaders/plasma_field.frag': r'''
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
''',
    'shaders/procedural_energy.frag': r'''
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
''',
    'shaders/radial_wave.frag': r'''
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
''',
  };
}
