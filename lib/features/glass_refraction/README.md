# Glass Refraction

Realistic glass refraction for Flutter — a captured background texture sampled through a GLSL lens, not a translucent `BackdropFilter`.

![Demo placeholder](../../../docs/screenshots/glass-refraction-placeholder.png)

> Add a screenshot or GIF at `docs/screenshots/glass-refraction.gif` after recording the playground.

## What the effect does

A glass panel bends, softens, and edges whatever sits behind it:

- Screen-space UV refraction through a convex height field
- Fresnel-inspired rim light and a drifting specular
- Optional frost (multi-tap blur) and chromatic aberration
- Shape SDFs: circle, rounded rect, capsule, lens
- Smooth anti-aliased silhouettes

Child widgets (text, icons, controls) composite **on top** of the glass so UI stays legible.

## Why this is not `BackdropFilter`

| Approach | Result |
|---|---|
| Translucent white + opacity | Flat overlay, no bend |
| `BackdropFilter` blur | Frost only, no lens math |
| This feature | Captured `ui.Image` → `sampler2D` → refraction, Fresnel, specular |

Flutter fragment shaders cannot sample arbitrary live widgets. The valid compositing path here is:

1. Wrap the wallpaper in `RepaintBoundary` (`GlassScene`)
2. `toImage()` → bind with `FragmentShader.setImageSampler`
3. Map the glass layout rect into background UVs
4. Distort those UVs in `shaders/glass_refraction.frag`

Dragging the glass only updates UV uniforms. Re-capture when the **background** changes.

## Installation / setup

The shader is registered in the app `pubspec.yaml`:

```yaml
flutter:
  shaders:
    - shaders/glass_refraction.frag
```

Open **Glass Refraction** from the gallery, or:

```dart
Navigator.of(context).pushNamed(AppRouter.glassRefraction);
```

## Shader architecture

Uniforms (floats packed in declaration order; sampler index separate):

| Uniform | Meaning |
|---|---|
| `uResolution` | Glass size in canvas units |
| `uSampleOrigin` / `uSampleExtent` | Glass rect in background UV |
| `uTime` | Highlight drift |
| `uRefraction` | Bend strength |
| `uCurvature` | Lens bulge |
| `uBlur` | Frost amount |
| `uReflection` / `uEdgeHighlight` | Specular + Fresnel |
| `uChromatic` | R/B split |
| `uOpacity` | Body tint strength |
| `uShape` / `uCornerRadius` | Silhouette |
| `uBackground` | Captured scene |

Height field \(h = c\,(1-r^2)\) → analytic normal → UV offset ≈ refraction. SDF mask supplies AA and extra rim energy.

## Component API

```dart
GlassScene(
  background: MyWallpaper(),
  child: Center(
    child: GlassRefraction(
      width: 300,
      height: 180,
      config: const GlassRefractionConfig(
        refractionStrength: 0.035,
        curvature: 0.65,
        blurSigma: 1.5,
        reflectionIntensity: 0.35,
        edgeHighlight: 0.6,
        chromaticAberration: 0.002,
      ),
      shape: GlassShape.roundedRectangle,
      borderRadius: BorderRadius.circular(28),
      child: YourWidget(),
    ),
  ),
)
```

### Configuration reference

See `GlassRefractionConfig` for defaults and clamp ranges. Presets: Clear Glass, Thick Lens, Frosted Glass, Crystal, Subtle Glass (`GlassPreset`).

## Production examples

- **GlassCard** — icon, title, description, CTA
- **GlassNavigation** — floating capsule nav with selected state
- **GlassMediaControls** — play/pause, scrubber, volume (subtle frost for contrast)

All three call `GlassRefraction`; none reimplement the shader.

## Performance recommendations

- One `GlassScene` capture shared by many panels
- Keep capture `pixelRatio` ≤ 2; throttle with `captureInterval`
- Animate wallpaper → `scheduleCapture()`; glass motion does not need capture
- Highlight animation uses a painter `Listenable`, not full-tree rebuilds
- Prefer subtle presets in scrollable lists; Thick Lens + chroma is for hero moments

## Known limitations

- Snapshot refraction — not a live multi-layer liquid-glass graph
- Panels do not refract each other
- Blur is a fixed 9-tap kernel
- Strong bend can clamp at capture edges
- Shader compile failure falls back to a translucent rounded rect
- Impeller is the intended backend; validate on your target

## Platforms

Aimed at Impeller (macOS / iOS / Android). Web / older Skia paths may lack sampler runtime-effect support — the widget falls back gracefully.
