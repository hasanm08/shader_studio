# Performance

No frame rate was measured for a published number. The debug overlay estimates the ticker interval only. Do not quote it as a GPU benchmark.

## GPU work and Dart work

Dart's per-frame work is a handful of uniform writes and a `drawRect`. The expensive part is the shader, and it scales with how many pixels the preview covers and with how many noise samples each pixel performs.

Approximate sample counts, from the source, not from a profiler:

| Sample | Heavy work per fragment |
|---|---|
| Plasma | Five `sin` calls, no loops |
| Radial wave | A few trig and `smoothstep` calls, no noise |
| Domain warp at 0 | One `fbm` (4 noise octaves) |
| Domain warp above 0 | Five `fbm` calls |
| Aurora | The field helper runs several `fbm` calls, on the order of the domain-warp path |
| Energy | One `fbm` everywhere, including the background, plus a branch for the disc |
| Ripple | Height is cheap per slot, but the normal evaluates height three times |
| Inside the Hive | Up to 32 tube steps, plus two ellipsoid tests |

Aurora's `auroraField` calls `fbm` for two `q` components, two `r` components, and the final field: five `fbm` calls, four octaves each. That is the featured shader's cost. It is honest to say so on camera if you zoom a large preview and watch the ticker estimate move. It is not honest to read that estimate as a device FPS cap.

## Resolution and overdraw

The painter fills the preview once. There is no second full-screen pass. A larger preview is more fragments. Gallery cards are smaller than the playground and, except the hero, do not animate.

The grid is a still at `ShaderSample.previewTime`. Ripple stills include two seeded slots so the card is not blank. The gallery copy says the cards do not tick. The hero does, until a route covers it and `TickerMode` stops its ticker.

## Loops

Noise loops are `for (int octave = 0; octave < 4; octave++)`. The bound is constant. Do not raise it casually. Ripple unrolls four slots in Dart and in GLSL rather than pretending to store an unbounded history.

## Allocations

`addDelta` does not allocate maps. Uniform slots are cached on the sink. The control panel is not rebuilt on `paintTick`. The frame-time label rebuilds about twice a second, and only in debug.

## Practical levers

- Pause, or leave a sample, to stop its ticker.
- Lower the preview size if a noise shader is heavy on a phone.
- Set domain-warp strength to 0 to take the single-`fbm` branch. The branch is on a uniform, so the whole draw takes one side.
- Keep octave counts at four unless you have a reason and you look at the result on a device.

## What this project does not do

It does not downscale the offscreen target. It does not time individual GPU passes. It does not ship a benchmark harness.
