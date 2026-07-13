# Midjourney asset prompt pack

Goal: replace every placeholder 1:1 (same names, docs/tasks.md list) + new garden life Damla asked for (grass tufts, bugs). Damla generates in MJ, Claude chroma-keys to transparent PNG, trims, and drops into the imagesets. No code changes needed for the 13 existing slots; grass + bugs get a small garden-decor code pass after assets exist.

## STATUS 13 Tem evening — read this first, it overrides the recipes below
- The wax crayon recipe below is DEAD for stickers (Damla: looks like a scanned crayon drawing). Also rejected: photo paper sticker look, thin fineliner, thick chunky mascot outline. Style is STILL OPEN; live candidate = childlike shapes + storybook painterly rendering. Do not run more blind rounds — get a concrete reference from Damla first.
- ground_texture DECIDED: plain calm green (dense grass textures tire the eyes on a 25 min screen). Grass life comes from a DYNAMIC sprite layer instead: ~50 single childlike doodle blades/tufts generated as MJ ASSET SHEETS (many per image), Claude cuts them to grass_blade_01..N. Wind + finger response in SwiftUI (Canvas + TimelineView + springs); NO texture-warp shader in v1.
- New sprite slots added on top of the table below: grass blade sheet, decor_daisy, decor_ladybug, decor_bee, decor_snail.

## The style (read before generating)

The current placeholders define it exactly:
- **wax crayon / oil pastel** strokes, thick and waxy, visible grainy texture everywhere
- **childlike naive doodle** — imperfect shapes, wobbly edges, like a kid's drawing done with love
- **soft pastel palette**: butter yellow, cherry red, baby blue, lilac purple, leaf green, blush pink
- white paper highlights left uncolored inside the strokes (see strawberry seeds, sparkle cores)
- flat, front-view, single subject, centered, no shading, no outline ink, no background scene
- NEVER: 3D, gradient, vector-smooth, watercolor bleed, anime/niji look, photorealism

## Workflow

1. Upload 3 style anchors to MJ and grab their URLs: `decor_strawberry.png`, `decor_butterfly_pink.png`, `sprout.png` (from `Sunflower/Assets.xcassets/*/`). Use them in every prompt as `--sref URL1 URL2 URL3`.
2. Generate at defaults (big canvas is good, everything gets scaled down).
3. Pick the variant that feels most hand-drawn (reject anything smooth/vector).
4. Drop the raw PNGs in `~/damla_projects_2026/00_currently_on_working/sunflower/mj-raw/` named by asset slot. Claude does background removal + halo cleanup + placement.

**Shared style suffix** (append to every prompt below):

```
, children's wax crayon doodle drawing, thick waxy pastel strokes, grainy crayon texture, naive childlike illustration, flat front view, single subject centered, isolated on plain white background, no shadow --sref <URL1> <URL2> <URL3> --ar 1:1 --v 7
```

## Existing slots (replace 1:1, keep names)

| asset | prompt subject (prepend to suffix) |
|---|---|
| flower_yellow | a single butter yellow flower with five round wobbly petals and a small lilac purple center dot |
| flower_red | a single cherry red flower with five round wobbly petals and a small dusty blue center |
| flower_blue | a single baby blue flower with five round wobbly petals and a small soft yellow center |
| flower_purple | a single lilac purple flower with pointed wobbly petals and a tiny red center |
| sprout | a small green seedling sprout with two leaves on a short stem |
| decor_strawberry | a plump red strawberry with white seed dashes and a pink-white blossom on top |
| decor_star | a chubby golden yellow shooting star with a rainbow trail |
| decor_sparkles | three four-pointed golden sparkles of different sizes with white centers |
| decor_cloud_1 | a fluffy baby blue cloud, wide and puffy |
| decor_cloud_2 | a smaller fluffy baby blue cloud |
| decor_butterfly_pink | a pink butterfly with white wing panels and soft yellow markings, wings open, three-quarter view |
| decor_butterfly_pastel | a big pastel rainbow butterfly with pink lilac and mint striped wings, wings fully spread, top view |

ground_texture is different (it is a full-bleed background, not a sticker) — use this complete prompt instead:

```
seamless leaf green fabric texture covered in loose hand-drawn white chalk swirls, tiny stars and scattered white dots, wax crayon and chalk on green paper, soft and even, no focal point --sref <URL1> <URL2> <URL3> --tile --ar 9:16 --v 7
```

AppIcon is not generated: Claude composes it at 1024 from the new flower_yellow + sparkles on the new ground_texture.

## New garden life (Damla 13 Tem: grass, bugs)

New slots — Claude wires them into the garden as ambient decor after generation:

| asset | prompt subject (prepend to suffix) |
|---|---|
| decor_grass_1 | a small tuft of leaf green grass, five wobbly blades fanning out |
| decor_grass_2 | a tiny tuft of green grass with three blades and a small white daisy |
| decor_ladybug | a round cherry red ladybug with black dots and tiny antennae, top view |
| decor_bee | a chubby round bumblebee with butter yellow and black stripes and small white wings, top view |
| decor_snail | a small smiling snail with a swirly blush pink shell and mint body, side view |

## Optional (later, only if v1 assets land well)

Wilt frames: 3 drawn frames per flower (upright, drooping, wilted) to replace the transform-based droop. Same prompts as the flowers plus "drooping to the side, petals sagging" / "fully wilted, petals hanging down, stem bent". Skip for v1.
