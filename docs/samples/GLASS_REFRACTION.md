# Glass Refraction

Fragment shader that samples a captured background through a thick, curved glass surface.

## Asset

`shaders/glass_refraction.frag`

## Feature entry

Gallery → **Glass Refraction** → `/glass-refraction`

Full write-up: `lib/features/glass_refraction/README.md`

## Compositing

Not a procedural color field. Dart captures a `RepaintBoundary`, binds the `ui.Image` with `setImageSampler(0, …)`, and the shader bends UVs inside a shape SDF.

## Key uniforms

See the header comment in the `.frag` file for the packed float index table.
