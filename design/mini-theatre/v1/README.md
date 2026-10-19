# Mini Theatre visual assets v1

Static design assets generated with the built-in image generation tool. Not yet wired into the app; no data model or runtime changes. Bunny selected by user. Palette: cream, warm gold, burgundy, espresso; muted rose and sage for flowers.

## Contents

- `bunny/`: base, idle, curious, celebrate. Independent full-body PNGs, not animation frames.
- `props/`: welcome_pennant (handheld), keepsake_ticket (decoration), golden_spotlight (decoration), velvet_curtain (background overlay), memory_bouquet (handheld), theatre_suitcase (decoration).

## Integration notes

Use aspect-fit, never stretch. Localize labels in UI, not images. These are v1 source illustrations, not shipping-approved sprites: normalize character scale and foot baseline, inspect transparency edges against light/dark backgrounds, and validate 48pt inventory rendering before integration. The curtain extends close to canvas edges; use inset placement. Handheld anchors must be calibrated per pose. No layered source or animation rig included. Do not infer unlock state from artwork. No customer photos or ticket information included.

## Preview

| Welcome pennant | Keepsake ticket | Golden spotlight |
|---|---|---|
| ![](props/welcome_pennant.png) | ![](props/keepsake_ticket.png) | ![](props/golden_spotlight.png) |
| Velvet curtain | Memory bouquet | Theatre suitcase |
| ![](props/velvet_curtain.png) | ![](props/memory_bouquet.png) | ![](props/theatre_suitcase.png) |

## Generation prompts

Common prompt:

Use case: stylized-concept. One standalone StageLight app prop sprite on genuine transparent background. Use supplied image only as palette and simple flat mobile illustration style reference. No phones, UI, characters, labels, text, cards, border, background or ground shadow. Square canvas, centered whole object with 15% clear margin. Smooth broad flat shapes, minimal gentle shading, no texture or realistic 3D, readable at 48px. Warm gold, cream, burgundy and muted brown. Exactly one prop, no extra decorations.

### welcome_pennant

A small burgundy triangular welcome pennant pointing right on a short dark brown wooden pole, one small gold star emblem, simple rounded shapes.

### keepsake_ticket

A horizontal warm golden keepsake theatre ticket, notched ends and a simple cream five-point star emblem centered, subtle inner border, slightly tilted 10 degrees. No codes, no letters.

### golden_spotlight

A small warm gold theatre spotlight on a simple U-shaped bracket and broad stable foot, angled upward right, large cream oval lens. No emitted beam outside the lamp.

### velvet_curtain

An open burgundy theatre curtain assembly: curved top valance joins two side drapes tied with simple golden bands. Large fully TRANSPARENT central opening, transparent below and outside too. No stage floor, no backdrop, no poles. Symmetric broad folds, simplified silhouette. One complete curtain frame.

### memory_bouquet

One small handheld bouquet of exactly five simple rounded cream and muted rose flowers with sage leaves, wrapped in cream paper tied with a burgundy ribbon. Compact simple graphic silhouette, no detailed petals.

### theatre_suitcase

One small caramel brown vintage theatre suitcase, front three-quarter view, chunky rounded rectangle, simple top handle, two dark brown straps and small gold clasps. One tiny cream star badge. No stickers or text.

Bunny prompts are preserved in `bunny/GENERATION.md`.
