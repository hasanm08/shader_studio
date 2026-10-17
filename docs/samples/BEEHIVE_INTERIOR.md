# Inside the Hive

## Goal

Stand inside one honeycomb cell and look down it. The wax, the far comb, and the bees are all computed in the fragment shader.

## What the viewer sees

Six wax walls frame a wall of hexagonal cells. Honey sits in some of those cells. Two striped bees cross the opening. Dragging leans the view without leaving the cell.

## Techniques

`hexLocal` builds a hex grid from two offset lattices. `sdHexagon` is the signed distance to one cell. `marchTube` walks a camera ray with a budget of 32 steps. The far comb is a plane shaded with the same grid. Bees are ray-ellipsoid hits, not a simulation.

## Uniforms

| Index | Uniform | Type | Meaning |
|---|---|---|---|
| 0 | `uResolution` | `vec2` | Preview size |
| 2 | `uTime` | `float` | Wrapped seconds |
| 3 | `uPointer` | `vec2` | Normalized pointer |
| 5 | `uPointerActive` | `float` | 1 while interaction is live |
| 6 | `uSpeed` | `float` | Bee flight and shimmer |
| 7 | `uScale` | `float` | Comb frequency |
| 8 | `uDepth` | `float` | Distance to the far comb |
| 9 | `uHoney` | `float` | Fill of the far cells |
| 10 | `uColorWax` | `vec3` | Wax, straight RGB |
| 13 | `uColorHoney` | `vec3` | Honey, straight RGB |

Writer: `writeBeehiveInterior`.

## Shader walkthrough

`aspectPoint` builds a ray that keeps the cell regular on a wide preview. `airDist` is positive in the open cell because the hexagon radius is slightly smaller than the tile, which leaves wax in the gap. The march steps by that distance. If the far plane is closer than the tube, the shader shades a comb face instead: wax on the borders, honey or a dark hole in the middle. `rayEllipsoid` scales the ray into a unit sphere so the hit depth stays in the same units as the march.

## Dart walkthrough

`ShaderSampleRegistry` stores the ranges. `writeBeehiveInterior` writes speed, scale, depth, honey, and the two colors. The bees have no uniforms. Their paths are inside the shader so the uniform block stays small.

## Animation

`uSpeed` scales bee motion and the honey shimmer. The walls do not scroll. Pause freezes the bees and the shimmer. The 600 second wrap jumps those phases.

## Pointer

The pointer moves the ray origin and adds a little to the ray direction. The offset is a fraction of the cell apothem. A larger lean would start the ray inside the wax and the first step would report a solid wall.

## Performance

At most 32 distance evaluations for the tube, then two ellipsoid tests. The tube distance does not depend on z, so center rays usually hit the far comb before the budget. Cost still grows with preview resolution.

## Limitations

Bees do not cast shadows and do not avoid walls when scale is very high. Wings are a pulsing ellipsoid, not a flap with joints. The march is not a full hive of stacked boxes. One cell, then one comb face.

## Experiments

Lower honey to open the far cells. Raise scale until the wax frame tightens. Drag inside the preview. Set speed to 0 and the bees hang in place.

## On camera

“The opening is the inside of a hexagon. The ray stops on the wax or on the comb in front of you. The bees are the same ray tested against an ellipsoid.”
