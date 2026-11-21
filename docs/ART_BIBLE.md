# Pet Kingdoms — Art Bible

> Version: 0.1  
> Status: visual direction baseline; production assets are not yet implemented.

## 1. Visual identity

Pet Kingdoms is a colorful, welcoming stylized-fantasy adventure. The world should feel magical, warm, playful, and readable at a glance.

### Core pillars
- **Cute, expressive characters:** strong silhouettes, readable faces, friendly proportions, distinct personalities.
- **Rich but organized environments:** lush foliage, flowers, water, rocks, cozy buildings, small discoveries; avoid visual noise.
- **Warm fantasy atmosphere:** soft lighting, inviting windows, magical accents, clear focal points.
- **Consistent materials:** hand-crafted stylized surfaces; avoid mixing photorealistic assets with cartoon models.
- **Readable gameplay:** interactive objects and paths must remain visually distinct from decoration.

## 2. Palette and mood

- Green Valley: fresh greens, warm wood, flower accents, turquoise water, gentle golden light.
- Frostpeak: cool blue, snow white, icy turquoise, restrained violet accents, crisp readable contrast.
- UI: dark warm panels with restrained gold framing; purple and turquoise may highlight special systems.
- Rarity colors may communicate collection tier, but must not be the only way to convey information.

## 3. Pet design rules

Every pet needs:
- A unique silhouette readable at gameplay camera distance.
- A distinct face and emotional range.
- A consistent scale family and grounded contact shadow.
- A clear primary color plus a small number of supporting accents.
- Materials that remain readable in bright and dark environments.
- Rigging that supports the approved companion animation set.

Avoid:
- Reusing the same body mesh with only recolors as the main source of variety.
- Excessive particles that obscure the pet.
- Tiny details that disappear on mobile.
- Unlicensed or unattributed third-party assets.

## 4. Environment rules

- Build modular kits for terrain edges, paths, bridges, rocks, trees, foliage, water features, props, and buildings.
- Keep walkable routes and interactable objects legible.
- Use layered composition: foreground framing, clear playable midground, readable background landmarks.
- Use repeated modular pieces carefully; break repetition with scale, rotation, and curated variants.
- Home island visual changes from Kingdom Bond must be modular and performance-aware.

## 5. UI rules

- Child-friendly language and recognizable icons.
- Large touch targets and readable text on small screens.
- Consistent spacing, panel hierarchy, and feedback states.
- Distinguish primary actions from secondary actions.
- Never communicate success/failure only through color; add iconography or text.
- Avoid placing important UI over the central gameplay focus.

## 6. Roblox asset production standards

These are project standards to validate in Roblox Studio before finalizing:
- Prefer original meshes, textures, and animations created for Pet Kingdoms.
- Use MeshParts and texture/material workflows appropriate to the chosen pipeline.
- Keep collision geometry simpler than visual geometry where practical.
- Use LOD or simplified variants for distant/high-count assets where beneficial.
- Limit particle emitters, transparency layers, and expensive dynamic lights on mobile.
- Keep pivots, scale, naming, and attachment conventions consistent.
- Record source, creator, license, attribution requirements, and modification history for every external asset.
- Do not ship Toolbox assets without review and documented provenance.

## 7. Asset acceptance checklist

An asset is not DONE until:
- [ ] It matches this art direction.
- [ ] Its silhouette and purpose are readable in gameplay.
- [ ] Scale, pivot, collision, and attachments are correct.
- [ ] Materials and textures work under Green Valley and Frostpeak lighting.
- [ ] Performance is checked in Roblox Studio on representative mobile settings.
- [ ] Source files and license/provenance are documented.
- [ ] It is integrated into the game and verified in context.

## 8. Concept art vs production asset

Generated concept images are references only. They are not Roblox-ready 3D models, rigs, textures, animations, or implemented UI. Keep this distinction explicit in the roadmap and asset tracker.
